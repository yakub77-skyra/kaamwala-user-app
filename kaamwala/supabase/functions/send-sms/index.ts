// Edge Function: send-sms — Supabase Auth "Send SMS" hook (Phase 4).
//
// Replaces GoTrue's built-in SMS sending so Indian OTPs go out via MSG91's
// DLT-registered transactional route (~₹0.15-0.25/OTP instead of Twilio's
// ₹1.50+). Supabase still generates and verifies the code itself - this
// function only delivers the message.
//
// Contract (supabase.com/docs/guides/auth/auth-hooks/send-sms-hook):
//   - POST from Auth service, signed with Standard Webhooks
//     (webhook-id / webhook-timestamp / webhook-signature headers)
//   - body: { user: { phone }, sms: { otp } }
//   - success: HTTP 200 + empty JSON object {}
// Security: verify_jwt stays FALSE (Auth servers don't carry user JWTs);
// authenticity is guaranteed by the webhook signature check below.
//
// Required function secrets (set when MSG91 account is ready):
//   SEND_SMS_HOOK_SECRET - the hook secret WITHOUT the v1,whsec_ prefix
//   MSG91_AUTH_KEY       - MSG91 account auth key
//   MSG91_TEMPLATE_ID    - DLT-approved OTP template id (contains #OTP# var)
import { Webhook } from "https://esm.sh/standardwebhooks@1.0.0";

interface HookPayload {
  user: { phone?: string };
  sms: { otp?: string };
}

interface Msg91FlowResponse {
  type?: string;
  message?: string;
}

Deno.serve(async (req) => {
  const rawBody = await req.text();

  // ---- 1. Authenticate the caller (Supabase Auth) ----
  const hookSecret = Deno.env.get("SEND_SMS_HOOK_SECRET");
  if (!hookSecret) {
    console.error("send-sms: SEND_SMS_HOOK_SECRET not configured");
    return new Response(
      JSON.stringify({ error: { http_code: 500, message: "not configured" } }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
  const headers = Object.fromEntries(req.headers);
  let payload: HookPayload;
  try {
    const wh = new Webhook(hookSecret);
    payload = wh.verify(rawBody, headers) as HookPayload;
  } catch (e) {
    console.error("send-sms: invalid webhook signature", e);
    return new Response(
      JSON.stringify({ error: { http_code: 401, message: "invalid signature" } }),
      { status: 401, headers: { "Content-Type": "application/json" } },
    );
  }

  const otp = payload.sms?.otp;
  const e164 = payload.user?.phone ?? "";
  if (!otp || !e164.startsWith("+")) {
    return new Response(
      JSON.stringify({ error: { http_code: 400, message: "bad payload" } }),
      { status: 400, headers: { "Content-Type": "application/json" } },
    );
  }

  // ---- 2. Deliver via MSG91 DLT transactional route ----
  const authKey = Deno.env.get("MSG91_AUTH_KEY");
  const templateId = Deno.env.get("MSG91_TEMPLATE_ID");
  if (!authKey || !templateId) {
    console.error("send-sms: MSG91 creds not configured");
    return new Response(
      JSON.stringify({ error: { http_code: 500, message: "provider not configured" } }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }

  // E.164 "+91XXXXXXXXXX" -> MSG91 mobiles "91XXXXXXXXXX"
  const mobiles = e164.replace(/^\+/, "");
  try {
    const res = await fetch("https://control.msg91.com/api/v5/flow/", {
      method: "POST",
      headers: {
        authkey: authKey,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        template_id: templateId,
        short_url: "0",
        realTimeResponse: "1",
        recipients: [{ mobiles, OTP: otp }],
      }),
    });
    const data = (await res.json().catch(() => ({}))) as Msg91FlowResponse;
    if (!res.ok || (data.type && data.type !== "success")) {
      console.error(`send-sms: MSG91 failed (${res.status})`, data);
      return new Response(
        JSON.stringify({
          error: { http_code: 502, message: `msg91: ${data.message ?? res.status}` },
        }),
        { status: 502, headers: { "Content-Type": "application/json" } },
      );
    }
    // ---- 3. Success contract: 200 + empty object ----
    return new Response(JSON.stringify({}), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("send-sms: MSG91 request threw", e);
    return new Response(
      JSON.stringify({ error: { http_code: 502, message: "provider unreachable" } }),
      { status: 502, headers: { "Content-Type": "application/json" } },
    );
  }
});
