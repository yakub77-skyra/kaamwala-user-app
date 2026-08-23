// Edge Function: send-push (Phase 4 section 6.2)
// Reads FCM token from push_tokens and delivers via FCM HTTP v1.
// Kinds: new_job | accepted | declined | payment_received | approved | rejected
import { fail, json, preflight } from '../_shared/utils.ts';
import { createClient } from 'npm:@supabase/supabase-js@2';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return preflight();
  if (req.method !== 'POST') return fail('method not allowed', 405);

  const admin = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );

  const body = await req.json().catch(() => ({}) as any);

  let userId = body.user_id as string | undefined;
  let title = '';
  let bodyText = '';

  if (!userId && body.booking_id) {
    const { data: booking } = await admin
      .from('bookings')
      .select('client_id, worker_id, ref')
      .eq('id', body.booking_id)
      .single();
    if (!booking) return fail('booking not found', 404);

    switch (body.kind) {
      case 'new_job': {
        const { data: wu } = await admin
          .from('workers').select('user_id, category, city').eq('id', booking.worker_id).single();
        userId = wu?.user_id;
        title = `🔔 New Job! ${wu?.category ?? ''} needed in ${wu?.city ?? ''}`;
        bodyText = `Booking ${booking.ref}`;
        break;
      }
      case 'accepted':
        userId = booking.client_id;
        title = '✅ Your booking was accepted!';
        break;
      case 'declined':
        userId = booking.client_id;
        title = '❌ Worker declined. Try another worker.';
        break;
      case 'payment_received':
        userId = booking.client_id;
        title = `💰 ₹${body.amount ?? ''} sent to worker UPI!`;
        break;
      default:
        return fail('unknown kind');
    }
  }

  if (body.kind === 'approved') title = '🎉 Your profile is approved!';
  if (body.kind === 'rejected') title = '❌ Profile needs re-upload';

  if (!userId) return fail('no target user');

  const { data: tokens } = await admin
    .from('push_tokens')
    .select('token, platform')
    .eq('user_id', userId);
  if (!tokens || tokens.length === 0) return json({ sent: 0 });

  // In production use FCM HTTP v1 with a service-account JWT.
  // Legacy server key kept for MVP simplicity.
  const serverKey = Deno.env.get('FCM_SERVER_KEY');
  if (!serverKey) return json({ sent: 0, note: 'FCM key not configured' });

  const results = await Promise.allSettled(
    tokens.map((t) =>
      fetch('https://fcm.googleapis.com/fcm/send', {
        method: 'POST',
        headers: {
          Authorization: `key=${serverKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          to: t.token,
          notification: { title, body: bodyText },
          data: { kind: body.kind ?? '', booking_id: String(body.booking_id ?? '') },
          android: { priority: 'high' },
        }),
      }),
    ),
  );

  const sent = results.filter((r) => r.status === 'fulfilled').length;
  return json({ sent });
});
