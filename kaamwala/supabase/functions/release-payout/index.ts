/**
 * release-payout — client confirms completion; worker gets paid (Phase 3 section 9).
 *
 * body: { booking_id, action: "confirm" }
 *
 * Flow:
 *   1. Caller must be the booking's client; booking must be completed.
 *   2. Sets client_confirmed = true (gates payout).
 *   3. Creates the PENDING payouts row (idempotent, 1 per booking).
 *   4. If Razorpay X keys are configured: ensures contact + fund account
 *      (cached on worker_payment_info), fires a UPI payout and records
 *      processing/success. Otherwise leaves it PENDING for ops.
 */
import { callerUid, serviceClient } from "./_shared/db.ts";
import { fail, json } from "./_shared/http.ts";
import {
  rzpRequest,
  type RzpContact,
  type RzpFundAccount,
  type RzpPayout,
} from "./_shared/razorpay.ts";

interface BookingRow {
  id: string;
  ref: string;
  client_id: string;
  status: string;
  client_confirmed: boolean;
  worker_id: string;
  worker_earning: number | string | null;
}

interface PaymentInfoRow {
  user_id: string;
  payout_method: string;
  upi_id: string | null;
  rzp_contact_id: string | null;
  rzp_fund_account_id: string | null;
}

function xpConfigured(): boolean {
  return !!Deno.env.get("RZPX_KEY_ID") && !!Deno.env.get("RZPX_KEY_SECRET");
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

    const { booking_id: bookingId, action } = await req.json().catch(() => ({}) as Record<string, unknown>);
    if (action !== "confirm") return fail("Unsupported action");
    if (!bookingId) return fail("booking_id is required");

    const { data: booking } = await admin
      .from("bookings")
      .select(
        "id, ref, client_id, status, client_confirmed, worker_id, worker_earning",
      )
      .eq("id", bookingId)
      .maybeSingle<BookingRow>();
    if (!booking) return fail("Booking not found", 404);
    if (booking.client_id !== uid) return fail("Not your booking", 403);
    if (booking.status !== "completed") return fail("Worker has not completed this job yet", 409);

    const earning = Number(booking.worker_earning ?? 0);
    if (!(earning > 0)) return fail("Payout amount not finalized", 409);

    // 2. Client confirmation (service path of bookings_guard allows this)
    if (!booking.client_confirmed) {
      const { error } = await admin
        .from("bookings")
        .update({ client_confirmed: true })
        .eq("id", booking.id);
      if (error) throw new Error("Could not confirm completion");
    }

    // 3. Idempotent payout row
    let { data: payout } = await admin
      .from("payouts")
      .select("id, status, razorpay_payout_id")
      .eq("booking_id", booking.id)
      .maybeSingle<{ id: string; status: string; razorpay_payout_id: string | null }>();

    if (!payout) {
      const ins = await admin
        .from("payouts")
        .insert({
          booking_id: booking.id,
          worker_id: booking.worker_id,
          amount: earning,
          status: "pending",
        })
        .select("id, status, razorpay_payout_id")
        .single<{ id: string; status: string; razorpay_payout_id: string | null }>();
      if (ins.error) throw new Error("Could not create payout record");
      payout = ins.data;
    }
    if (!payout) throw new Error("Payout record missing");

    if (["processing", "success"].includes(payout.status)) {
      return json({ confirmed: true, payout_status: payout.status, payout_id: payout.razorpay_payout_id });
    }

    // 4. Attempt instant payout when Razorpay X is configured
    if (!xpConfigured()) {
      return json({
        confirmed: true,
        payout_status: "pending",
        message: "Payout queued; will be processed by operations.",
      });
    }

    const { data: wrow } = await admin
      .from("workers")
      .select("user_id")
      .eq("id", booking.worker_id)
      .maybeSingle<{ user_id: string }>();
    if (!wrow) return fail("Worker not found", 404);

    const { data: pinfo } = await admin
      .from("worker_payment_info")
      .select("user_id, payout_method, upi_id, rzp_contact_id, rzp_fund_account_id")
      .eq("user_id", wrow.user_id)
      .maybeSingle<PaymentInfoRow>();
    if (!pinfo?.upi_id) {
      return json({
        confirmed: true,
        payout_status: "pending",
        message: "Worker payment setup pending.",
      });
    }

    try {
      await admin.from("payouts").update({ status: "processing" }).eq("id", payout.id).in("status", ["pending"]);

      // Contact (vendor) — cached for reuse
      let contactId = pinfo.rzp_contact_id;
      if (!contactId) {
        const contact = await rzpRequest<RzpContact>("contacts", {
          method: "POST",
          xp: true,
          body: {
            name: `worker_${wrow.user_id.slice(0, 8)}`,
            type: "vendor",
            reference_id: `kw_${wrow.user_id}`,
            notes: { kaamwala_uid: wrow.user_id },
          },
        });
        contactId = contact.id;
      }

      // Fund account (UPI VPA) — cached for reuse
      let fundAccountId = pinfo.rzp_fund_account_id;
      if (!fundAccountId) {
        const fundAccount = await rzpRequest<RzpFundAccount>("fund_accounts", {
          method: "POST",
          xp: true,
          body: {
            contact_id: contactId,
            account_type: "vpa",
            vpa: { address: pinfo.upi_id },
          },
        });
        fundAccountId = fundAccount.id;
      }

      await admin
        .from("worker_payment_info")
        .update({ rzp_contact_id: contactId, rzp_fund_account_id: fundAccountId })
        .eq("user_id", wrow.user_id);

      const payoutRes = await rzpRequest<RzpPayout>("payouts", {
        method: "POST",
        xp: true,
        body: {
          fund_account_id: fundAccountId,
          amount: Math.round(earning * 100),
          currency: "INR",
          mode: "UPI",
          purpose: "payout",
          queue_if_low_balance: true,
          reference_id: `kw_payout_${booking.ref}`,
          narration: `KaamWala ${booking.ref}`,
        },
      });

      const succeeded = ["processed", "payout_initiated"].includes(payoutRes.status);
      await admin
        .from("payouts")
        .update({
          status: succeeded ? "success" : "processing",
          razorpay_payout_id: payoutRes.id,
          processed_at: succeeded ? new Date().toISOString() : null,
        })
        .eq("id", payout.id)
        .in("status", ["pending", "processing"]);

      return json({ confirmed: true, payout_status: succeeded ? "success" : "processing" });
    } catch (e) {
      const reason = e instanceof Error ? e.message : "Payout failed";
      await admin
        .from("payouts")
        .update({ status: "failed", failure_reason: reason })
        .eq("id", payout.id)
        .in("status", ["pending", "processing"]);
      return json({
        confirmed: true,
        payout_status: "failed",
        message: "Payout failed; operations have been notified via payout record.",
      });
    }
  } catch (e) {
    return fail(e instanceof Error ? e.message : "Could not release payout", 500);
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
