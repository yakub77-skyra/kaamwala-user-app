/**
 * verify-payment — three mode endpoint:
 *
 * 1) Razorpay webhook (no user JWT; HMAC-authenticated):
 *    - payment.captured -> order PAID + booking payment_status=paid,
 *      status=pending_acceptance, payment/transaction ids stored; worker
 *      notified ("new job").
 *    - payment.failed   -> order FAILED + booking payment_status=failed,
 *      status=payment_failed (retryable).
 *    - refund.processed -> order REFUNDED + booking refund_status=processed.
 * 2) Authenticated refund request (legacy):
 *    body: { type: "refund", booking_id } — client of a cancelled booking.
 * 3) Mock payment confirm (Phase 2, dev):
 *    body: { type: "mock_confirm", booking_id } — client marks their own
 *    booking paid, ONLY allowed when the booking's payment_provider='mock'
 *    (created while Razorpay keys were absent). With real keys configured,
 *    bookings are provider='razorpay' and this mode is rejected.
 *
 * Deployed with verify_jwt = false (webhooks cannot carry our JWT); modes
 * are separated by the x-razorpay-signature header / body.type.
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

interface BookingRow {
  id: string;
  status: string;
  payment_status: string;
  payment_provider: string | null;
}

const PAYABLE_STATUSES = ["payment_pending", "payment_failed", "pending"];

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
        event?: string;
        type?: string;
        payload?: {
          payment?: { entity?: WebhookPayment };
          refund?: { entity?: { id?: string; payment_id?: string } };
        };
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
            const { data: failedRows } = await admin
              .from("bookings")
              .update({
                payment_status: "failed",
                status: "payment_failed",
                payment_error_message: "Payment failed at the gateway",
              })
              .eq("payment_order_id", payment.order_id)
              .in("status", PAYABLE_STATUSES)
              .select("id, client_id, ref");
            for (const row of failedRows ?? []) {
              await admin.from("notifications").insert({
                user_id: row.client_id,
                type: "payment_failed",
                title: "Payment failed",
                body:
                  `Your payment for ${row.ref} could not be processed. ` +
                  "You can retry from the booking.",
                data_json: { booking_id: row.id },
                action_route: `/payment/${row.id}`,
              });
            }
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
            const { data: refundedRows } = await admin
              .from("bookings")
              .update({
                refund_status: "processed",
                refund_message: "Refund completed by your bank",
              })
              .eq("payment_order_id", payment.order_id)
              .eq("status", "cancelled")
              .select("id, client_id, ref");
            for (const row of refundedRows ?? []) {
              await admin.from("notifications").insert({
                user_id: row.client_id,
                type: "payment",
                title: "Refund completed",
                body: `The refund for ${row.ref} has reached your account.`,
                data_json: { booking_id: row.id },
                action_route: `/booking/${row.id}`,
              });
            }
          }
          break;
        }
        default:
          break;
      }
      return json({ received: true });
    }

    // ---------- Mode 2/3: authenticated app requests ----------
    // rawBody is consumed above; parse once (re-reading req.text() throws).
    const parsedBody = JSON.parse(rawBody || "{}") as Record<string, unknown>;
    if (parsedBody.type === "refund") {
      return await handleRefundRequest(admin, req, parsedBody as { booking_id: string });
    }
    if (parsedBody.type === "mock_confirm") {
      return await handleMockConfirm(admin, req, parsedBody as { booking_id: string });
    }
    return fail("Unsupported request");
  } catch (e) {
    return fail(e instanceof Error ? e.message : "Verification failed", 500);
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

    const paymentId = rzpPaymentId ?? order.razorpay_payment_id;
    const { error } = await admn
      .from("orders")
      .update({
        status: "paid",
        razorpay_payment_id: paymentId,
        paid_at: new Date().toISOString(),
      })
      .eq("id", order.id)
      .eq("status", "created");
    if (error) throw new Error("Could not update order");

    // Booking: paid -> waiting for worker acceptance (Phase 2 lifecycle).
    await admn
      .from("bookings")
      .update({
        payment_status: "paid",
        status: "pending_acceptance",
        payment_id: paymentId,
        transaction_reference: paymentId,
        payment_signature_verified: true,
        payment_error_message: null,
      })
      .eq("id", order.booking_id)
      .in("status", PAYABLE_STATUSES);

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
        await sendPushToUser(admn, wrow.user_id, "New job request!", "You have a new paid booking. Open the app to accept.", { kind: "new_job", route: "/w/jobs" });
      }
    }
  }

  async function handleRefundRequest(
    admn: ReturnType<typeof serviceClient>,
    req: Request,
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

    await admn
      .from("bookings")
      .update({ refund_status: "pending", refund_message: "Refund initiated" })
      .eq("id", booking.id);

    await admn.from("notifications").insert({
      user_id: uid,
      type: "payment",
      title: "Refund initiated",
      body: `Rs. 20 refund for ${booking.ref} is on its way to your account.`,
      data_json: { booking_id: booking.id },
      action_route: `/booking/${booking.id}`,
    });

    return json({ refunded: true, refund_id: refund.id });
  }

  async function handleMockConfirm(
    admn: ReturnType<typeof serviceClient>,
    req: Request,
    body: { booking_id: string },
  ): Promise<Response> {
    const uid = await callerUid(req);
    if (!uid) return fail("Unauthorized", 401);

    const { data: booking } = await admn
      .from("bookings")
      .select("id, client_id, status, payment_status, payment_provider, ref")
      .eq("id", body.booking_id)
      .maybeSingle<BookingRow>();
    if (!booking) return fail("Booking not found", 404);
    if (booking.client_id !== uid) return fail("Not your booking", 403);
    if (booking.payment_status === "paid") return json({ already_paid: true });
    if (booking.payment_provider !== "mock") {
      // Real keys configured for this booking -> mock confirm is rejected.
      return fail("Mock payments are disabled for this booking", 403, "mock_disabled");
    }
    if (!PAYABLE_STATUSES.includes(booking.status)) {
      return fail(`Booking is ${booking.status}; payment not allowed`, 409, "not_payable");
    }

    const paymentId = `mock_pay_${booking.id}`;
    await admn
      .from("orders")
      .update({
        status: "paid",
        razorpay_payment_id: paymentId,
        paid_at: new Date().toISOString(),
      })
      .eq("booking_id", booking.id)
      .eq("status", "created");

    await admn
      .from("bookings")
      .update({
        payment_status: "paid",
        status: "pending_acceptance",
        payment_id: paymentId,
        transaction_reference: paymentId,
        payment_error_message: null,
      })
      .eq("id", booking.id)
      .in("status", PAYABLE_STATUSES);

    return json({ confirmed: true });
  }
});
