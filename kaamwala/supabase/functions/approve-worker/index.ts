/**
 * approve-worker — admin gate for the Aadhar verification queue (5.3).
 *
 * body: { worker_id, action: "approve" | "reject", reason?: string }
 *
 * Authorization: caller uid must appear in platform_config.admin_user_ids.
 * Writes run via service role (RLS bypass) and notify the worker in-app +
 * push (best effort). Rejection requires a reason.
 */
import { callerUid, serviceClient } from "./_shared/db.ts";
import { corsHeaders, fail, json } from "./_shared/http.ts";
import { sendPushToUser } from "./_shared/push.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  let admin: ReturnType<typeof serviceClient>;
  try {
    admin = serviceClient();
  } catch {
    return fail("Service not configured", 500);
  }

  try {
    const uid = await callerUid(req);
    if (!uid) return fail("Unauthorized", 401);

    const { data: cfg } = await admin
      .from("platform_config")
      .select("value")
      .eq("key", "admin_user_ids")
      .maybeSingle<{ value: string[] }>();
    const admins = Array.isArray(cfg?.value) ? cfg!.value : [];
    if (!admins.includes(uid)) return fail("Forbidden", 403);

    const { worker_id: workerId, action, reason } = await req.json().catch(() => ({}) as Record<string, unknown>);
    if (!workerId || !["approve", "reject"].includes(action as string)) {
      return fail("worker_id and valid action are required");
    }
    if (action === "reject" && !reason) return fail("Rejection reason is required");

    const status = action === "approve" ? "approved" : "rejected";
    const { data: worker } = await admin
      .from("workers")
      .update({
        approval_status: status,
        ...(action === "approve" ? { rejection_reason: null } : { rejection_reason: reason }),
      })
      .eq("id", workerId)
      .select("user_id")
      .maybeSingle<{ user_id: string }>();
    if (!worker) return fail("Worker not found", 404);

    const title = action === "approve" ? "🎉 Profile approved!" : "❌ Verification failed";
    const bodyText =
      action === "approve"
        ? "You can now receive jobs. Go online from your dashboard."
        : `Reason: ${reason}. Please re-upload your documents.`;

    await admin.from("notifications").insert({
      user_id: worker.user_id,
      type: "system",
      title,
      body: bodyText,
    });

    const delivered = await sendPushToUser(admin, worker.user_id, title, bodyText, { kind: action === "approve" ? "approved" : "rejected", route: "/w/home" });
    return json({ ok: true, status, push_sent: delivered });
  } catch (e) {
    return fail(e instanceof Error ? e.message : "Approval failed", 500);
  }
});
