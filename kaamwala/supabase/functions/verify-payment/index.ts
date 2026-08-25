/**
 * verify-payment — dual mode endpoint (Phase 3 section 9):
 *
 * 1) Razorpay webhook  (no user JWT; authenticated by HMAC signature):
 *    - payment.captured -> orders PAID + notify worker "new job"
 *    - payment.failed   -> orders FAILED
 *    - refund.processed -> orders REFUNDED
 * 2) Authenticated refund request from the app:
 *    body: { type: "refund", booking_id }
 *    Caller must be the booking's client; booking must be cancelled
 *    and the order paid. Triggers a full refund of the Rs.20 fee.
 *
 * Deployed with verify_jwt = false (webhooks cannot carry our JWT);
 * the two modes are separated by the x-razorpay-signature header.
 */
import { createClient } from "jsr:@supabase/supabase-js@2";
import { callerUid, serviceClient } from "./_shared/db.ts";
import { corsHeaders, fail, json } from "./_shared/http.ts";
import { rzpRequest, verifyWebhookSignature, type RzpRefund } from "./_shared/razorpay.ts";
import { sendPushToUser } from "./_shared/push.ts";

interface OrderRow {
  id: string;
  booking_id: string;
  razorpay_order_id: string;
  razorpay_payment_id: string | null;
  status: string;
}

interface WebhookPayment {
  id?: string;
  order_id?: string;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  const rawBody = await req.text();
  let admin: ReturnType<typeof serviceClient>;
  try {
    admin = serviceClient();
  } catch {
    return fail("Service not configured", 500);
  }

  try {
    // ---------- Mode 1: Razorpay webhook ----------
    const signature = req.headers.get("x-razorpay-signature");
    if (signature) {
      const valid = await verifyWebhookSignature(rawBody, signature);
      if (!valid) return fail("Invalid signature", 401);

      const event = JSON.parse(rawBody) as {
        event?: string; // real Razorpay payloads use top-level "event"
        type?: string;
        payload?: { payment?: { entity?: WebhookPayment }; refund?: { entity?: { id?: string; payment_id?: string } } };
      };
      const eventType = event.event ?? event.type ?? "";
      const payment = event.payload?.payment?.entity;
      const refund = event.payload?.refund?.entity;

      switch (eventType) {
        case "payment.captured":
        case "payment.authorized": {
          await markOrderPaid(admin, payment?.order_id, payment?.id ?? null);
          break;
        }
        case "payment.failed": {
          if (payment?.order_id) {
            await admin
              .from("orders")
              .update({ status: "failed" })
              .eq("razorpay_order_id", payment.order_id)
              .eq("status", "created");
          }
          break;
        }
        case "refund.processed": {
          if (payment?.order_id) {
            await admin
              .from("orders")
              .update({ status: "refunded" })
              .eq("razorpay_order_id", payment.order_id)
              .in("status", ["paid", "failed"]);
          }
          break;
        }
        default:
          break;
      }
      return json({ received: true });
    }

    // ---------- Mode 2: authenticated refund ----------
    // rawBody is already consumed above; parse once and pass it down
    // (re-reading req.text() throws "Body already consumed").
    const parsedBody = JSON.parse(rawBody || "{}") as Record<string, unknown>;
    if (event2IsRefund(parsedBody)) {
      return await handleRefundRequest(admin, parsedBody as { booking_id: string });
    }
    return fail("Unsupported request");
  } catch (e) {
    return fail(e instanceof Error ? e.message : "Verification failed", 500);
  }

  function event2IsRefund(body: Record<string, unknown>): boolean {
    return body.type === "refund" && typeof body.booking_id === "string";
  }

  async function markOrderPaid(
    admn: ReturnType<typeof serviceClient>,
    rzpOrderId?: string,
    rzpPaymentId?: string | null,
  ): Promise<void> {
    if (!rzpOrderId) return;
    const { data: order } = await admn
      .from("orders")
      .select("id, booking_id, razorpay_payment_id, status")
      .eq("razorpay_order_id", rzpOrderId)
      .maybeSingle<OrderRow>();
    if (!order || order.status !== "created") return;

    const { error } = await admn
      .from("orders")
      .update({
        status: "paid",
        razorpay_payment_id: rzpPaymentId ?? order.razorpay_payment_id,
        paid_at: new Date().toISOString(),
      })
      .eq("id", order.id)
      .eq("status", "created");
    if (error) throw new Error("Could not update order");

    // DB trigger inserts the worker's in-app notification on this transition.
    const { data: booking } = await admn
      .from("bookings")
      .select("worker_id")
      .eq("id", order.booking_id)
      .maybeSingle<{ worker_id: string }>();
    if (booking) {
      const { data: wrow } = await admn
        .from("workers")
        .select("user_id")
        .eq("id", booking.worker_id)
        .maybeSingle<{ user_id: string }>();
      if (wrow) {
        await sendPushToUser(admn, wrow.user_id, "🔔 New job request!", "You have a new paid booking. Open the app to accept.", { kind: "new_job" });
      }
    }
  }

  async function handleRefundRequest(
    admn: ReturnType<typeof serviceClient>,
    body: { booking_id: string },
  ): Promise<Response> {
    const uid = await callerUid(req);
    if (!uid) return fail("Unauthorized", 401);

    const { data: booking } = await admn
      .from("bookings")
      .select("id, client_id, status, ref")
      .eq("id", body.booking_id)
      .maybeSingle<{ id: string; client_id: string; status: string; ref: string }>();
    if (!booking) return fail("Booking not found", 404);
    if (booking.client_id !== uid) return fail("Not your booking", 403);
    // Phase 3 hardening: refunds are only valid after a cancellation, so a
    // stray client call can't claw back the fee while the booking stays live.
    if (booking.status !== "cancelled") return fail("Booking is not cancelled", 409);

    const { data: order } = await admn
      .from("orders")
      .select("id, razorpay_payment_id, status")
      .eq("booking_id", booking.id)
      .maybeSingle<OrderRow>();
    if (!order || order.status !== "paid") return fail("Nothing to refund", 409);

    const refund = await rzpRequest<RzpRefund>(
      `payments/${order.razorpay_payment_id}/refund`,
      { method: "POST", body: {} },
    );

    await admn
      .from("orders")
      .update({ status: "refunded" })
      .eq("id", order.id)
      .in("status", ["paid"]);

    await admn.from("notifications").insert({
      user_id: uid,
      type: "payment",
      title: "↩️ Refund initiated",
      body: `Rs. 20 refund for ${booking.ref} is on its way to your account.`,
    });

    return json({ refunded: true, refund_id: refund.id });
  }
});
