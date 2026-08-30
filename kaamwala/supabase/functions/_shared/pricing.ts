/**
 * Shared booking/pricing helpers for Phase 2 booking + payment functions.
 * Single source of truth for: fee, lead time, slots, payment provider mode.
 */

export interface Pricing {
  bookingFeePaise: number;
  minLeadMinutes: number;
  maxLeadDays: number;
  cancellationPolicy: string;
  refundTimeline: string;
}

export const DEFAULT_PRICING: Pricing = {
  bookingFeePaise: 2000,
  minLeadMinutes: 30,
  maxLeadDays: 30,
  cancellationPolicy:
    "Free cancellation before the worker accepts your booking. The booking fee is refunded in full.",
  refundTimeline:
    "Refunds are initiated immediately on cancellation and usually reach your bank in 3-5 business days.",
};

/** 2-hour booking windows, wire format is 'start-end' in 24h hours. */
export const SLOTS = ["8-10", "10-12", "12-14", "14-16", "16-18", "18-20"];

/** Parse '8-10' -> 8 (start hour) or null when malformed/unknown. */
export function slotStartHour(slot: string): number | null {
  if (!SLOTS.includes(slot)) return null;
  const start = Number(slot.split("-")[0]);
  return Number.isFinite(start) ? start : null;
}

/** Loads pricing from platform_config['pricing']; falls back to legacy
 * 'booking_fee_rupees' key and finally DEFAULT_PRICING. */
export async function loadPricing(
  admin: ReturnType<typeof import("./db.ts").serviceClient>,
): Promise<Pricing> {
  const { data } = await admin
    .from("platform_config")
    .select("key, value")
    .eq("key", "pricing")
    .maybeSingle<{ key: string; value: Record<string, unknown> }>();
  if (!data) {
    const { data: legacy } = await admin
      .from("platform_config")
      .select("key, value")
      .eq("key", "booking_fee_rupees")
      .maybeSingle<{ key: string; value: string }>();
    const legacyFee = legacy ? Number(legacy.value) * 100 : null;
    return {
      ...DEFAULT_PRICING,
      bookingFeePaise: Number.isFinite(legacyFee) ? legacyFee! : DEFAULT_PRICING.bookingFeePaise,
    };
  }
  const v = data.value ?? {};
  const fee = Number(v.booking_fee_paise ?? DEFAULT_PRICING.bookingFeePaise);
  const lead = Number(v.min_lead_minutes ?? DEFAULT_PRICING.minLeadMinutes);
  const days = Number(v.max_lead_days ?? DEFAULT_PRICING.maxLeadDays);
  return {
    bookingFeePaise: Number.isFinite(fee) && fee > 0 ? fee : DEFAULT_PRICING.bookingFeePaise,
    minLeadMinutes: Number.isFinite(lead) && lead >= 0 ? lead : DEFAULT_PRICING.minLeadMinutes,
    maxLeadDays: Number.isFinite(days) && days > 0 ? days : DEFAULT_PRICING.maxLeadDays,
    cancellationPolicy:
      typeof v.cancellation_policy === "string" && v.cancellation_policy
        ? v.cancellation_policy
        : DEFAULT_PRICING.cancellationPolicy,
    refundTimeline:
      typeof v.refund_timeline === "string" && v.refund_timeline
        ? v.refund_timeline
        : DEFAULT_PRICING.refundTimeline,
  };
}

/** Whether real Razorpay keys are configured on this function. */
export function razorpayEnabled(): boolean {
  return Boolean(Deno.env.get("RZP_KEY_ID")) && Boolean(Deno.env.get("RZP_KEY_SECRET"));
}
