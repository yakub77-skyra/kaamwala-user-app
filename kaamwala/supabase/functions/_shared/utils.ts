// Shared helpers for KaamWala Edge Functions.
// SECURITY: All secrets live HERE ONLY (Phase 4 section 8).
//   - RAZORPAY_KEY_ID / RAZORPAY_KEY_SECRET / RAZORPAY_WEBHOOK_SECRET
//   - FCM_SERVER_KEY
//   - SUPABASE_SERVICE_ROLE_KEY + SUPABASE_URL are injected by the platform.

export const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

export function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

export function fail(message: string, status = 400): Response {
  return json({ error: message }, status);
}

export function preflight(): Response | null {
  return new Response('ok', { headers: corsHeaders });
}

// ---------- Razorpay REST helpers (server-side only) ----------

const RZP_AUTH = btoa(
  `${Deno.env.get('RAZORPAY_KEY_ID')}:${Deno.env.get('RAZORPAY_KEY_SECRET')}`,
);

export async function rzpCreateOrder(amountPaise: number, receipt: string) {
  const res = await fetch('https://api.razorpay.com/v1/orders', {
    method: 'POST',
    headers: {
      Authorization: `Basic ${RZP_AUTH}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      amount: amountPaise,
      currency: 'INR',
      receipt,
      payment_capture: 1,
    }),
  });
  if (!res.ok) throw new Error(`razorpay order failed: ${await res.text()}`);
  return res.json() as Promise<{ id: string; amount: number }>;
}

export async function rzpVerifySignature(
  orderId: string,
  paymentId: string,
  signature: string,
): Promise<boolean> {
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(Deno.env.get('RAZORPAY_KEY_SECRET') ?? ''),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const sig = await crypto.subtle.sign(
    'HMAC',
    key,
    new TextEncoder().encode(`${orderId}|${paymentId}`),
  );
  const hex = Array.from(new Uint8Array(sig))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
  return hex === signature;
}

/** Verifies webhook HMAC-SHA256 (NFR-SEC-03). */
export async function verifyWebhookSignature(rawBody: string, received: string) {
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(Deno.env.get('RAZORPAY_WEBHOOK_SECRET') ?? ''),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const sig = await crypto.subtle.sign(
    'HMAC',
    key,
    new TextEncoder().encode(rawBody),
  );
  const hex = Array.from(new Uint8Array(sig))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
  return hex === received;
}

/** Razorpay X payout to UPI (FR-PAY-03). */
export async function rzpXPayout(opts: {
  upiId?: string;
  accountNumber?: string;
  ifsc?: string;
  name: string;
  amountRupees: number;
  narration: string;
}) {
  const res = await fetch('https://api.razorpay.com/v1/payouts', {
    method: 'POST',
    headers: {
      Authorization: `Basic ${RZP_AUTH}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      account_number: Deno.env.get('RZPX_ACCOUNT_NUMBER'), // KaamWala's X account
      amount: Math.round(opts.amountRupees * 100),
      currency: 'INR',
      mode: 'UPI',
      purpose: 'payout',
      narration: opts.narration.slice(0, 30),
      fund_account: {
        account_type: opts.upiId ? 'vpa' : 'bank_account',
        ...(opts.upiId
          ? { vpa: { address: opts.upiId } }
          : {
              bank_account: {
                name: opts.name,
                ifsc_code: opts.ifsc,
                account_number: opts.accountNumber,
              },
            }),
      },
      queue_if_low_balance: true,
    }),
  });
  if (!res.ok) throw new Error(`payout failed: ${await res.text()}`);
  return res.json() as Promise<{ id: string; status: string }>;
}
