// Edge Function: send-push — FCM HTTP v1 (Phase 4 section 6.2).
//
// body: { user_id, title, body }  OR  { kind, booking_id, amount? }
// kinds: new_job | accepted | declined | payment_received | approved | rejected
//
// Uses the service account (FCM_SERVICE_ACCOUNT_JSON) for OAuth; DB
// notifications remain the source of truth — push is best-effort.
import { createClient } from "jsr:@supabase/supabase-js@2";
import { fail, json, corsHeaders } from "./_shared/http.ts";
import { sendPushToUser, pushConfigured } from "./_shared/push.ts";
import { callerUid } from "./_shared/db.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return fail("method not allowed", 405);

  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { persistSession: false, autoRefreshToken: false } },
  );

  // Admin-only gate (Phase 3 hardening): this endpoint can push arbitrary
  // text to any user - never callable by ordinary authenticated users.
  // Internal flows (triggers/other functions) use _shared/push.ts directly.
  const uid = await callerUid(req);
  let isAdmin = false;
  if (uid) {
    const { data: cfg } = await admin
      .from("platform_config")
      .select("value")
      .eq("key", "admin_user_ids")
      .maybeSingle<{ value: string[] }>();
    isAdmin = !!uid && ((cfg?.value as string[] | null) ?? []).includes(uid);
  }
  if (!isAdmin) return fail("Forbidden", 403);

  const body = await req.json().catch(() => ({}) as Record<string, unknown>);
  let userId = body.user_id as string | undefined;
  let title = (body.title as string) ?? "";
  let bodyText = (body.body as string) ?? "";

  if (!userId && body.booking_id) {
    const { data: booking } = await admin
      .from("bookings")
      .select("client_id, worker_id, ref")
      .eq("id", body.booking_id)
      .single();
    if (!booking) return fail("booking not found", 404);

    const workerUser = async () => {
      const { data: w } = await admin
        .from("workers")
        .select("user_id")
        .eq("id", booking.worker_id)
        .maybeSingle();
      return w?.user_id as string | undefined;
    };

    switch (body.kind) {
      case "new_job":
        userId = await workerUser();
        title = "🔔 New job request!";
        bodyText = `Booking ${booking.ref}. Open the app to accept.`;
        break;
      case "accepted":
        userId = booking.client_id;
        title = "✅ Your booking was accepted!";
        break;
      case "declined":
        userId = booking.client_id;
        title = "❌ Worker declined. Try another worker.";
        break;
      case "payment_received":
        userId = await workerUser();
        title = `💰 Rs.${body.amount ?? ""} received`;
        bodyText = `Payout for ${booking.ref} completed.`;
        break;
      default:
        return fail("unknown kind");
    }
  }

  if (!userId) return fail("no target user");
  if (!pushConfigured()) return json({ sent: false, note: "FCM not configured" });

  const sent = await sendPushToUser(admin, userId, title, bodyText);
  return json({ sent });
});
