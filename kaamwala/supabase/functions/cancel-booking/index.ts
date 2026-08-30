/**
 * cancel-booking — server-side cancellation (Phase 2).
 *
 * Auth: booking's client only.
 *
 * Rules:
 *  - Cancellable only before the worker accepts (payment_pending /
 *    payment_failed / pending_acceptance / legacy pending).
 *  - Stores cancellation_reason + cancelled_at (guard also sets cancelled_at).
 *  - Refund: if the booking was PAID, initiates a Razorpay refund when the
 *    booking's provider is razorpay (and keys exist); mock bookings get a
 *    simulated refund (refund_status=pending, orders -> refunded). If never
 *    paid, refund_status='none' (nothing to refund).
 *  - refund.processed webhook later flips refund_status to 'processed'.
 *
 * Contract:
 *   body: { booking_id, reason? }
 *   200 : { cancelled, refund_status, refund_message, refund_id? }
 *   4xx : { error }
 */
import { callerUid, serviceClient } from "./_shared/db.ts";
import { fail, json } from "./_shared/http.ts";
import { rzpRequest, type RzpRefund } from "./_shared/razorpay.ts";

interface BookingRow {
  id: string;
  client_id: string;
  status: string;
  payment_status: string;
  payment_provider: string | null;
  payment_order_id: string | null;
  ref: string;
}

interface OrderRow {
  id: string;
  razorpay_payment_id: string | null;
  status: string;
}

const CANCELLABLE_STATUSES = ["payment_pending", "payment_failed", "pending_acceptance", "pending"];
const MAX_REASON = 200;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: { ...corsHeaders() } });
  }
  let admin: ReturnType<typeof serviceClient>;
  try {
    admin = serviceClient();
  } catch {
    return fail("Service not configured", 500);
  }

  try {
    const uid = await callerUid(req);
    if (!uid) return fail("Unauthorized", 401);

    const body = await req.json().catch(() => ({}) as Record<string, unknown>);
    const bookingId = body.booking_id;
    if (typeof bookingId !== "string") return fail("booking_id is required");

    const reason =
      typeof body.reason === "string" && body.reason.trim()
        ? body.reason.trim().slice(0, MAX_REASON)
        : null;

    const { data: booking, error: bErr } = await admin
      .from("bookings")
      .select("id, client_id, status, payment_status, payment_provider, payment_order_id, ref")
      .eq("id", bookingId)
      .maybeSingle<BookingRow>();
    if (bErr || !booking) return fail("Booking not found", 404);
    if (booking.client_id !== uid) return fail("Not your booking", 403);
    if (!CANCELLABLE_STATUSES.includes(booking.status)) {
      return fail(
        booking.status === "cancelled"
          ? "This booking is already cancelled"
          : "This booking can no longer be cancelled — the worker has accepted it.",
        409,
        "not_cancellable",
      );
    }

    // Guard trigger (service role path) records cancelled_at; we set the rest.
    await admin
      .from("bookings")
      .update({
        status: "cancelled",
        cancellation_reason: reason,
      })
      .eq("id", booking.id);

    const { data: order } = await admin
      .from("orders")
      .select("id, razorpay_payment_id, status")
      .eq("booking_id", booking.id)
      .maybeSingle<OrderRow>();

    if (!order || order.status !== "paid") {
      // Nothing was ever charged -> no refund applicable.
      await admin
        .from("bookings")
        .update({ refund_status: "none", refund_message: null })
        .eq("id", booking.id);
      return json({
        cancelled: true,
        refund_status: "none",
        refund_message: null,
      });
    }

    const isMock = booking.payment_provider === "mock";
    let refundId: string | null = null;

    if (isMock) {
      // Simulated refund: no gateway call; webhook never fires in mock mode.
      await admin.from("orders").update({ status: "refunded" }).eq("id", order.id);
      await admin
        .from("bookings")
        .update({
          refund_status: "pending",
          refund_message: "Refund initiated — usually reaches your bank in 3-5 business days (mock mode)",
        })
        .eq("id", booking.id);
    } else {
      const refund = await rzpRequest<RzpRefund>(
        `payments/${order.razorpay_payment_id}/refund`,
        { method: "POST", body: {} },
      );
      refundId = refund.id;
      await admin
        .from("bookings")
        .update({
          refund_status: "pending",
          refund_message: "Refund initiated — usually reaches your bank in 3-5 business days",
        })
        .eq("id", booking.id);
      // orders flips to 'refunded' when the refund.processed webhook lands.
    }

    await admin.from("notifications").insert({
      user_id: uid,
      type: "payment",
      title: "Refund initiated",
      body: `Your refund for ${booking.ref} is on its way to your account.`,
      data_json: { booking_id: booking.id },
      action_route: `/booking/${booking.id}`,
    });

    return json({
      cancelled: true,
      refund_status: "pending",
      refund_message: isMock
        ? "Refund initiated — usually reaches your bank in 3-5 business days (mock mode)"
        : "Refund initiated — usually reaches your bank in 3-5 business days",
      ...(refundId ? { refund_id: refundId } : {}),
    });
  } catch (e) {
    return fail(e instanceof Error ? e.message : "Could not cancel booking", 500);
  }
});

function corsHeaders(): Record<string, string> {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers":
      "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
  };
}
