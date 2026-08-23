// KaamWala v2 - Cloudflare Worker: Supabase reverse proxy
// Flow (Phase 4 section 2.2): Flutter App -> api.kaamwala.com (this worker)
//                              -> xyz.supabase.co
// Critical for India: Jio/Airtel DNS-block supabase.co; Cloudflare isn't blocked.
// Free tier: 100,000 requests/day.

const UPSTREAM = 'https://YOUR-PROJECT-REF.supabase.co'; // <- your project ref

export default {
  async fetch(request) {
    const url = new URL(request.url);

    // Health check
    if (url.pathname === '/__health') {
      return new Response('ok', { status: 200 });
    }

    const upstreamUrl = new URL(request.url);
    upstreamUrl.hostname = UPSTREAM.replace('https://', '');

    const upstreamRequest = new Request(upstreamUrl, request);
    upstreamRequest.headers.set('Host', upstreamUrl.hostname);

    const response = await fetch(upstreamRequest, {
      body: request.body,
      method: request.method,
      headers: upstreamRequest.headers,
      redirect: 'follow',
    });

    // Pass through, adding basic caching for storage assets.
    const res = new Response(response.body, response);
    res.headers.set('X-Proxied-By', 'kaamwala-cf-worker');
    return res;
  },
};
