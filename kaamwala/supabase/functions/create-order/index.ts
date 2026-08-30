/**
 * create-order — Phase 2 dual-mode endpoint.
 *
 * Mode 1 (existing): body { booking_id } — creates/reuses a payment order
 *   for an already-created booking (payment_pending / payment_failed).
 * Mode 2 (Phase 2): body { worker_id, category, description, service_date,
 *   time_slot, address, estimate_min, estimate_max, idempotency_key } —
 *   VALIDATES the booking server-side (worker approved+available, no slot
 *   overlap, date/slot lead time, field lengths), creates the booking in
 *   `payment_pending`, then creates the payment order.
 *
 * Money rule (NFR-SEC-02): the client NEVER sends amounts. The fee comes
 * from platform_config['pricing'] (fallback Rs.20); order amount is paise.
 *
 * Provider: real Razorpay order when RZP keys are configured, else a
 * `mock_<bookingId>` order id (mock mode — the app then simulates payment).
 *
 * Contract:
 *   200 : { order_id, amount(paise), currency, key_id, booking_id,
 *           booking_ref, mock }
 *   4xx : { error, code }
 */
import { callerUid, serviceClient } from "./_shared/db.ts";
import { fail, json } from "./_shared/http.ts";
import { loadPricing, razorpayEnabled, SLOTS, slotStartHour } from "./_shared/pricing.ts";
import { rzpRequest, type RzpOrder } from "./_shared/razorpay.ts";

interface BookingRow {
  id: string;
  ref: string;
  client_id: string;
  status: string;
  payment_status: string;
  payment_provider: string | null;
  payment_attempts?: number;
  payment_expires_at?: string | null;
  booking_fee: number | string;
  estimate_min: number | string;
  estimate_max: number | string;
  commission_rate: number | string;
}

const ACTIVE_SLOT_STATUSES = [
  "payment_pending", "payment_failed", "pending_acceptance",
  "accepted", "traveling", "arrived", "in_progress", "pending",
];
const PAYABLE_STATUSES = ["payment_pending", "payment_failed", "pending"];
const ORDER_TTL_MINUTES = 30;

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
    if (typeof body.booking_id === "string") {
      return await orderForBooking(admin, uid, body.booking_id);
    }
    if (typeof body.worker_id === "string") {
      return await createBookingWithOrder(admin, uid, body);
    }
    return fail("booking_id or worker_id required", 400, "bad_request");
  } catch (e) {
    return fail(e instanceof Error ? e.message : "Payment failed. Try again.", 500, "internal");
  }
});

// ---------------- Mode 2: create booking + order ----------------

async function createBookingWithOrder(
  admin: ReturnType<typeof serviceClient>,
  uid: string,
  body: Record<string, unknown>,
): Promise<Response> {
  const workerId = body.worker_id as string;
  const category = String(body.category ?? "");
  const description = String(body.description ?? "").trim();
  const address = String(body.address ?? "").trim();
  const timeSlot = String(body.time_slot ?? "");
  const serviceDateRaw = String(body.service_date ?? "");
  const idempotencyKey = typeof body.idempotency_key === "string" ? body.idempotency_key : null;
  const pricing = await loadPricing(admin);

  // Field validation (mirrors bookings_* length checks).
  if (description.length < 10 || description.length > 500) {
    return fail("Describe the work in at least 10 characters", 400, "invalid_description");
  }
  if (address.length < 10 || address.length > 300) {
    return fail("Enter your full address", 400, "invalid_address");
  }
  const startHour = slotStartHour(timeSlot);
  if (startHour === null) {
    return fail("Please select a valid time slot", 400, "invalid_slot");
  }
  const parsed = new Date(serviceDateRaw);
  if (!Number.isFinite(parsed.getTime())) {
    return fail("Please select a valid date", 400, "invalid_date");
  }
  const day = new Date(parsed.getUTCFullYear(), parsed.getUTCMonth(), parsed.getUTCDate());
  const now = new Date();
  const today = new Date(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate());
  if (day.getTime() < today.getTime()) {
    return fail("You cannot book a past date", 400, "past_date");
  }
  const maxDay = new Date(today.getTime() + pricing.maxLeadDays * 86400000);
  if (day.getTime() > maxDay.getTime()) {
    return fail("Please pick a date within the next " + pricing.maxLeadDays + " days", 400, "date_too_far");
  }
  if (day.getTime() === today.getTime()) {
    // Lead-time rule: the slot must START at least minLeadMinutes from now.
    const slotStartMin = startHour * 60;
    const earliestAllowed = now.getUTCHours() * 60 + now.getUTCMinutes() + pricing.minLeadMinutes;
    if (slotStartMin < earliestAllowed) {
      return fail(
        "This time slot is too soon. Please pick a later slot (at least " +
          pricing.minLeadMinutes + " minutes ahead).",
        400,
        "slot_too_soon",
      );
    }
  }

  // Worker must exist, be approved and available.
  const { data: worker, error: wErr } = await admin
    .from("workers")
    .select("id, category, is_available, approval_status, user_id")
    .eq("id", workerId)
    .maybeSingle<{ id: string; category: string; is_available: boolean; approval_status: string; user_id: string }>();
  if (wErr || !worker) return fail("Worker not found", 404, "worker_not_found");
  if (worker.approval_status !== "approved" || !worker.is_available) {
    return fail("This worker is currently unavailable. Please choose another worker.", 409, "worker_unavailable");
  }
  if (worker.category !== category) {
    return fail("This worker does not offer that service", 400, "category_mismatch");
  }

  // Idempotent retry: same draft key -> reuse the existing booking + order.
  let bookingId: string | null = null;
  if (idempotencyKey) {
    const { data: dup } = await admin
      .from("bookings")
      .select("id")
      .eq("idempotency_key", idempotencyKey)
      .maybeSingle<{ id: string }>();
    bookingId = dup?.id ?? null;
  }

  let booking: BookingRow;
  if (bookingId === null) {
    // No duplicate: validate slot is still free (basic overlap, Task 2.4).
    const { data: clash } = await admin
      .from("bookings")
      .select("id")
      .eq("worker_id", workerId)
      .eq("service_date", serviceDateRaw)
      .eq("time_slot", timeSlot)
      .in("status", ACTIVE_SLOT_STATUSES)
      .limit(1)
      .maybeSingle<{ id: string }>();
    if (clash) {
      return fail("This time slot is no longer available. Please select another slot.", 409, "slot_taken");
    }

    const estMin = Number(body.estimate_min ?? 0);
    const estMax = Number(body.estimate_max ?? 0);
    const feePaise = pricing.bookingFeePaise;
    const provider = razorpayEnabled() ? "razorpay" : "mock";
    const row = {
      client_id: uid,
      worker_id: workerId,
      category,
      description,
      service_date: serviceDateRaw,
      time_slot: timeSlot,
      address,
      status: "payment_pending",
      payment_status: "pending",
      payment_provider: provider,
      booking_fee: feePaise / 100,
      booking_fee_paise: feePaise,
      amount_paise: feePaise,
      estimated_min_paise: Number.isFinite(estMin) && estMin >= 0 ? Math.round(estMin * 100) : null,
      estimated_max_paise: Number.isFinite(estMax) && estMax >= 0 ? Math.round(estMax * 100) : null,
      estimate_min: Number.isFinite(estMin) && estMin >= 0 ? estMin : 0,
      estimate_max: Number.isFinite(estMax) && estMax >= 0 ? estMax : 0,
      ...(idempotencyKey ? { idempotency_key: idempotencyKey } : {}),
    };
    const { data: created, error: iErr } = await admin.from("bookings").insert(row).select().single<BookingRow>();
    if (iErr) {
      if (iErr.message.includes("idempotency_key") || iErr.code === "23505") {
        return fail("Please try again", 409, "duplicate_draft");
      }
      return fail("Could not create booking. Please try again.", 500, "insert_failed");
    }
    booking = created;
  } else {
    const { data: existing, error: eErr } = await admin
      .from("bookings")
      .select("id, ref, client_id, status, payment_status, payment_provider, booking_fee, estimate_min, estimate_max, commission_rate")
      .eq("id", bookingId)
      .maybeSingle<BookingRow>();
    if (eErr || !existing) return fail("Booking not found", 404, "booking_not_found");
    if (existing.client_id !== uid) return fail("Not your booking", 403, "forbidden");
    booking = existing;
  }

  return await orderForBooking(admin, uid, booking.id);
}

// ---------------- Mode 1: order for an existing booking ----------------

async function orderForBooking(
  admin: ReturnType<typeof serviceClient>,
  uid: string,
  bookingId: string,
): Promise<Response> {
  const { data: booking, error: bErr } = await admin
    .from("bookings")
    .select("id, ref, client_id, status, payment_status, payment_provider, booking_fee, estimate_min, estimate_max, commission_rate")
    .eq("id", bookingId)
    .maybeSingle<BookingRow>();
  if (bErr || !booking) return fail("Booking not found", 404, "booking_not_found");
  if (booking.client_id !== uid) return fail("Not your booking", 403, "forbidden");
  if (booking.payment_status === "paid") {
    return fail("Booking already paid", 409, "already_paid");
  }
  if (!PAYABLE_STATUSES.includes(booking.status)) {
    return fail(`Booking is ${booking.status}; payment not allowed`, 409, "not_payable");
  }

  const pricing = await loadPricing(admin);
  const feeRupees = Number(booking.booking_fee ?? 20);
  const amountPaise = Math.round(feeRupees * 100);
  const provider = booking.payment_provider ?? (razorpayEnabled() ? "razorpay" : "mock");

  // Server-side money math (NFR-SEC-02): commission on estimate midpoint.
  const mid = (Number(booking.estimate_min) + Number(booking.estimate_max)) / 2;
  const rate = Number(booking.commission_rate ?? 0.1);
  const commissionAmount = Math.round(mid * rate * 100) / 100;
  const workerEarning = Math.max(0, Math.round((mid - commissionAmount) * 100) / 100);

  const existing = await activeOrder(admin, booking.id);
  let razorpayOrderId: string;
  let attempts = booking.payment_attempts ?? 0;

  if (existing && existing.status === "paid") {
    return fail("Booking already paid", 409, "already_paid");
  }

  if (existing && existing.status === "created") {
    const notExpired =
      !booking.payment_expires_at || new Date(booking.payment_expires_at).getTime() > Date.now();
    if (notExpired) {
      razorpayOrderId = existing.razorpay_order_id;
    } else {
      // Order expired -> fresh order (Task 8.7); old row's unique constraint
      // would clash, so rotate the order id in place.
      razorpayOrderId = await createRzpOrder(booking, amountPaise, provider);
      await admin.from("orders").update({ razorpay_order_id: razorpayOrderId }).eq("id", existing.id);
      attempts += 1;
    }
  } else if (existing) {
    // Order exists but is not retryable ('failed') - rotate to a fresh one
    // so the payment_failed -> retry path never dead-ends.
    razorpayOrderId = await createRzpOrder(booking, amountPaise, provider);
    await admin.from("orders").update({ razorpay_order_id: razorpayOrderId }).eq("id", existing.id);
    attempts += 1;
  } else {
    razorpayOrderId = await createRzpOrder(booking, amountPaise, provider);
    const { error: oErr } = await admin.from("orders").insert({
      booking_id: booking.id,
      razorpay_order_id: razorpayOrderId,
      amount: feeRupees,
      status: "created",
    });
    if (oErr) throw new Error("Could not record order");
    attempts += 1;
  }

  const { error: uErr } = await admin
    .from("bookings")
    .update({
      commission_amount: commissionAmount,
      worker_earning: workerEarning,
      payment_order_id: razorpayOrderId,
      payment_provider: provider,
      payment_expires_at: new Date(Date.now() + ORDER_TTL_MINUTES * 60000).toISOString(),
      payment_attempts: attempts,
      ...(booking.payment_status === "failed" ? { payment_status: "pending" } : {}),
    })
    .eq("id", booking.id);
  if (uErr) throw new Error("Could not finalize booking amounts");

  return json({
    order_id: razorpayOrderId,
    amount: amountPaise,
    currency: "INR",
    key_id: provider === "razorpay" ? (Deno.env.get("RZP_KEY_ID") ?? "") : "",
    booking_id: booking.id,
    booking_ref: booking.ref,
    mock: provider === "mock",
  });
}

async function activeOrder(
  admin: ReturnType<typeof serviceClient>,
  bookingId: string,
): Promise<{ id: string; razorpay_order_id: string; status: string } | null> {
  const { data } = await admin
    .from("orders")
    .select("id, razorpay_order_id, status")
    .eq("booking_id", bookingId)
    .maybeSingle<{ id: string; razorpay_order_id: string; status: string }>();
  return data ?? null;
}

async function createRzpOrder(
  booking: BookingRow,
  amountPaise: number,
  provider: string,
): Promise<string> {
  if (provider !== "razorpay" || !razorpayEnabled()) {
    return `mock_${booking.id}`;
  }
  const order = await rzpRequest<RzpOrder>("orders", {
    method: "POST",
    body: {
      amount: amountPaise,
      currency: "INR",
      receipt: booking.ref,
      notes: { booking_id: booking.id },
    },
  });
  return order.id;
}

function corsHeaders(): Record<string, string> {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers":
      "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
  };
}
