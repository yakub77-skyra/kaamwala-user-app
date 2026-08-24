const encoder = new TextEncoder();

interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
}

let cachedToken: { token: string; exp: number } | null = null;

export function pushConfigured(): boolean {
  return !!Deno.env.get("FCM_SERVICE_ACCOUNT_JSON");
}

function b64url(bytes: Uint8Array): string {
  let str = "";
  for (const b of bytes) str += String.fromCharCode(b);
  return btoa(str).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

async function accessToken(): Promise<string> {
  if (cachedToken && Date.now() < cachedToken.exp - 60_000) return cachedToken.token;

  const sa = JSON.parse(
    Deno.env.get("FCM_SERVICE_ACCOUNT_JSON") ?? "{}",
  ) as ServiceAccount;
  if (!sa.project_id || !sa.client_email || !sa.private_key) {
    throw new Error("FCM service account not configured");
  }

  const now = Math.floor(Date.now() / 1000);
  const header = b64url(encoder.encode(JSON.stringify({ alg: "RS256", typ: "JWT" })));
  const claims = b64url(
    encoder.encode(
      JSON.stringify({
        iss: sa.client_email,
        scope: "https://www.googleapis.com/auth/firebase.messaging",
        aud: "https://oauth2.googleapis.com/token",
        iat: now,
        exp: now + 3600,
      }),
    ),
  );

  const pemBody = sa.private_key
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s+/g, "");
  const der = Uint8Array.from(atob(pemBody), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey(
    "pkcs8",
    der,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    encoder.encode(`${header}.${claims}`),
  );
  const jwt = `${header}.${claims}.${b64url(new Uint8Array(sig))}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  if (!res.ok) throw new Error(`FCM token exchange failed (${res.status})`);
  const data = (await res.json()) as { access_token: string; expires_in: number };
  cachedToken = {
    token: data.access_token,
    exp: Date.now() + data.expires_in * 1000,
  };
  return cachedToken.token;
}

/** Best-effort push to every registered device of a user. Never throws. */
export async function sendPushToUser(
  admin: import("jsr:@supabase/supabase-js@2").SupabaseClient,
  userId: string,
  title: string,
  body: string,
  data?: Record<string, string>,
): Promise<boolean> {
  if (!pushConfigured()) return false;
  try {
    const token = await accessToken();
    const { data: rows, error } = await admin
      .from("push_tokens")
      .select("token")
      .eq("user_id", userId);
    if (error || !rows?.length) return false;
    let ok = false;
    for (const row of rows) {
      const res = await fetch(
        `https://fcm.googleapis.com/v1/projects/${
          (JSON.parse(Deno.env.get("FCM_SERVICE_ACCOUNT_JSON")!) as ServiceAccount).project_id
        }/messages:send`,
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${token}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            message: {
              token: row.token,
              notification: { title, body },
              data: data ?? {},
              android: { priority: "high" },
            },
          }),
        },
      );
      if (res.ok) ok = true;
    }
    return ok;
  } catch (_) {
    return false;
  }
}
