/**
 * check-payment-status — recovery for unclear payment states (Phase 2).
 *
 * Auth: booking participant (client or worker).
 *
 * Behavior:
 *  - Reads booking payment fields + the linked order.
 *  - For REAL razorpay bookings stuck in payment_pending/failed with a
 *    'created' order, reconciles against the Razorpay orders API so a
 *    payment that succeeded outside the app still lands (webhook missed /
 *    app closed mid-checkout).
 *  - Mock bookings are never reconciled against Razorpay.
 *
 * Contract:
 *   body: { booking_id }
 *   200 : { booking_id, booking_ref, status, payment_status, order_status,
 *           paid, amount_paise, payment_provider, payment_id,
 *           transaction_reference, refund_status, mock }
 *   4xx : { error }
 */
import { callerUid, serviceClient } from "./_shared/db.ts";
import { fail, json } from "./_shared/http.ts";
import { rzpRequest } from "./_shared/razorpay.ts";

interface BookingRow {
  id: string;
  ref: string;
  client_id: string;
  worker_id: string;
  status: string;
  payment_status: string;
  payment_provider: string | null;
  amount_paise: number | null;
  payment_id: string | null;
  transaction_reference: string | null;
  refund_status: string | null;
  refund_message: string | null;
  payment_order_id: string | null;
}

interface OrderRow {
  razorpay_order_id: string;
  status: string;
}

const PAYABLE_STATUSES = ["payment_pending", "payment_failed", "pending"];

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

    const { booking_id: bookingId } = await req.json().catch(() => ({}) as Record<string, unknown>);
    if (typeof bookingId !== "string") return fail("booking_id is required");

    const { data: booking, error: bErr } = await admin
      .from("bookings")
      .select(
        "id, ref, client_id, worker_id, status, payment_status, payment_provider, amount_paise, payment_id, transaction_reference, refund_status, refund_message, payment_order_id",
      )
      .eq("id", bookingId)
      .maybeSingle<BookingRow>();
    if (bErr || !booking) return fail("Booking not found", 404);

    // Participant check: client or the assigned worker (service reads bypass RLS).
    const { data: worker } = await admin
      .from("workers")
      .select("user_id")
      .eq("id", booking.worker_id)
      .maybeSingle<{ user_id: string }>();
    const isClient = booking.client_id === uid;
    const isWorker = worker?.user_id === uid;
    if (!isClient && !isWorker) return fail("Not a participant", 403);

    const { data: order } = await admin
      .from("orders")
      .select("razorpay_order_id, status")
      .eq("booking_id", booking.id)
      .maybeSingle<OrderRow>();

    // Reconcile real razorpay orders that never reached us (recovery).
    if (
      booking.payment_provider === "razorpay" &&
      order &&
      order.status === "created" &&
      PAYABLE_STATUSES.includes(booking.status) &&
      order.razorpay_order_id.startsWith("order_")
    ) {
      try {
        const remote = await rzpRequest<{ status: string; amount_due: number }>(
          `orders/${order.razorpay_order_id}`,
        );
        if (remote.status === "paid" || remote.amount_due === 0) {
          // Mirror what the webhook would have done.
          const paymentId = `pay_reconciled_${booking.id}`;
          await admin
            .from("orders")
            .update({ status: "paid", razorpay_payment_id: paymentId, paid_at: new Date().toISOString() })
            .eq("razorpay_order_id", order.razorpay_order_id)
            .eq("status", "created");
          await admin
            .from("bookings")
            .update({
              payment_status: "paid",
              status: "pending_acceptance",
              payment_id: paymentId,
              transaction_reference: paymentId,
              payment_signature_verified: true,
              payment_error_message: null,
            })
            .eq("id", booking.id)
            .in("status", PAYABLE_STATUSES);
        } else if (remote.status === "attempted" || remote.status === "created") {
          // Still unpaid; nothing to do.
        }
      } catch {
        // Gateway unreachable: report current local state, never fail hard.
      }
    }

    const { data: refreshed } = await admin
      .from("bookings")
      .select(
        "id, ref, status, payment_status, payment_provider, amount_paise, payment_id, transaction_reference, refund_status, refund_message",
      )
      .eq("id", booking.id)
      .maybeSingle<BookingRow>();

    const current = refreshed ?? booking;
    const { data: refreshedOrder } = await admin
      .from("orders")
      .select("status")
      .eq("booking_id", booking.id)
      .maybeSingle<{ status: string }>();

    return json({
      booking_id: current.id,
      booking_ref: current.ref,
      status: current.status,
      payment_status: current.payment_status,
      order_status: refreshedOrder?.status ?? null,
      paid: current.payment_status === "paid",
      amount_paise: current.amount_paise,
      payment_provider: current.payment_provider,
      payment_id: current.payment_id,
      transaction_reference: current.transaction_reference,
      refund_status: current.refund_status,
      refund_message: current.refund_message,
      mock: current.payment_provider === "mock",
    });
  } catch (e) {
    return fail(e instanceof Error ? e.message : "Could not check payment status", 500);
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
