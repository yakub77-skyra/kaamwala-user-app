/**
 * create-order — server-side Razorpay order creation (FR-PAY-01..04).
 *
 * Contract with the Flutter app (BookingsRepository.createOrder):
 *   body:  { booking_id }
 *   200 :  { order_id, amount(paise), currency, key_id, booking_ref }
 *   4xx :  { error }
 *
 * All money math happens here; the client never sends amounts.
 */
import { callerUid, serviceClient } from "./_shared/db.ts";
import { fail, json } from "./_shared/http.ts";
import { rzpRequest, type RzpOrder } from "./_shared/razorpay.ts";

interface BookingRow {
  id: string;
  ref: string;
  client_id: string;
  status: string;
  booking_fee: number | string;
  estimate_min: number | string;
  estimate_max: number | string;
  commission_rate: number | string;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: { ...corsHeaders() } });
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
    if (!bookingId) return fail("booking_id is required");

    // Caller must own this booking (checked against service read, RLS bypassed)
    const { data: booking, error: bErr } = await admin
      .from("bookings")
      .select(
        "id, ref, client_id, status, booking_fee, estimate_min, estimate_max, commission_rate",
      )
      .eq("id", bookingId)
      .maybeSingle<BookingRow>();
    if (bErr || !booking) return fail("Booking not found", 404);
    if (booking.client_id !== uid) return fail("Not your booking", 403);
    if (!["pending", "accepted"].includes(booking.status)) {
      return fail(`Booking is ${booking.status}; payment not allowed`, 409);
    }

    // Idempotent: reuse an existing unpaid order instead of double-charging
    const { data: existing } = await admin
      .from("orders")
      .select("razorpay_order_id, status")
      .eq("booking_id", booking.id)
      .maybeSingle<{ razorpay_order_id: string; status: string }>();
    if (existing?.status === "paid") return fail("Booking already paid", 409);

    const feeRupees = Number(booking.booking_fee ?? 20);
    const amountPaise = Math.round(feeRupees * 100);

    // Server-side money math (NFR-SEC-02): commission on estimate midpoint
    const mid = (Number(booking.estimate_min) + Number(booking.estimate_max)) / 2;
    const rate = Number(booking.commission_rate ?? 0.10);
    const commissionAmount = Math.round(mid * rate * 100) / 100;
    const workerEarning = Math.max(0, Math.round((mid - commissionAmount) * 100) / 100);

    let razorpayOrderId: string;
    if (existing && existing.status === "created") {
      razorpayOrderId = existing.razorpay_order_id;
    } else {
      const order = await rzpRequest<RzpOrder>("orders", {
        method: "POST",
        body: {
          amount: amountPaise,
          currency: "INR",
          receipt: booking.ref,
          notes: { booking_id: booking.id },
        },
      });
      razorpayOrderId = order.id;

      const { error: oErr } = await admin.from("orders").upsert({
        booking_id: booking.id,
        razorpay_order_id: order.id,
        amount: feeRupees,
        status: "created",
      });
      if (oErr) throw new Error("Could not record order");
    }

    const { error: uErr } = await admin
      .from("bookings")
      .update({ commission_amount: commissionAmount, worker_earning: workerEarning })
      .eq("id", booking.id);
    if (uErr) throw new Error("Could not finalize booking amounts");

    return json({
      order_id: razorpayOrderId,
      amount: amountPaise,
      currency: "INR",
      key_id: Deno.env.get("RZP_KEY_ID") ?? "",
      booking_ref: booking.ref,
    });
  } catch (e) {
    return fail(e instanceof Error ? e.message : "Payment failed. Try again.", 500);
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
