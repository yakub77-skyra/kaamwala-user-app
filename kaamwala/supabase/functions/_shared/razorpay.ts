const encoder = new TextEncoder();

type RzpCreds = { id: string; secret: string };

function creds(prefix = "RZP"): RzpCreds {
  const id = Deno.env.get(`${prefix}_KEY_ID`) ?? "";
  const secret = Deno.env.get(`${prefix}_KEY_SECRET`) ?? "";
  if (!id || !secret) throw new Error("Razorpay keys not configured");
  return { id, secret };
}

/** Thin Razorpay REST wrapper. Throws with the gateway's error description. */
export async function rzpRequest<T>(
  path: string,
  init: { method?: string; body?: unknown; xp?: boolean } = {},
): Promise<T> {
  const { id, secret } = creds(init.xp ? "RZPX" : "RZP");
  const res = await fetch(`https://api.razorpay.com/v1/${path}`, {
    method: init.method ?? "GET",
    headers: {
      Authorization: `Basic ${btoa(`${id}:${secret}`)}`,
      "Content-Type": "application/json",
    },
    body: init.body === undefined ? undefined : JSON.stringify(init.body),
  });
  const data = await res.json().catch(() => ({}) as Record<string, unknown>);
  if (!res.ok) {
    const err = data as { error?: { description?: string } };
    throw new Error(
      err.error?.description ?? `Razorpay ${init.method ?? "GET"} ${path} failed (${res.status})`,
    );
  }
  return data as T;
}

/** Constant-time HMAC-SHA256 verification of Razorpay webhook payloads. */
export async function verifyWebhookSignature(
  rawBody: string,
  signature: string,
): Promise<boolean> {
  const secret = Deno.env.get("RZP_WEBHOOK_SECRET");
  if (!secret || !signature) return false;
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const mac = await crypto.subtle.sign("HMAC", key, encoder.encode(rawBody));
  const expected = [...new Uint8Array(mac)]
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
  if (expected.length !== signature.length) return false;
  let diff = 0;
  for (let i = 0; i < expected.length; i++) {
    diff |= expected.charCodeAt(i) ^ signature.charCodeAt(i);
  }
  return diff === 0;
}

export interface RzpOrder {
  id: string;
  amount: number;
  currency: string;
  receipt?: string;
}

export interface RzpRefund {
  id: string;
  status: string;
}

export interface RzpContact {
  id: string;
}

export interface RzpFundAccount {
  id: string;
}

export interface RzpPayout {
  id: string;
  status: string;
}
