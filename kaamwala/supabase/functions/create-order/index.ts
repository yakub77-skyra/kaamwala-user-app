// Edge Function: create-order (FR-PAY-01)
// Validates booking, computes amount SERVER-SIDE, creates Razorpay order.
// Client receives ONLY {order_id, amount, key_id} (Phase 4 section 5.1).
// Idempotent (NFR-REL-02): re-calling for the same booking returns the
// existing order instead of creating a duplicate.
import {
  corsHeaders,
  fail,
  json,
  preflight,
  rzpCreateOrder,
} from '../_shared/utils.ts';
import { createClient } from 'npm:@supabase/supabase-js@2';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return preflight();
  if (req.method !== 'POST') return fail('method not allowed', 405);

  // Must be called by an authenticated client (RLS context).
  const authHeader = req.headers.get('Authorization') ?? '';
  if (!authHeader) return fail('unauthorized', 401);

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    { global: { headers: { Authorization: authHeader } } },
  );

  const { data: authUser } = await supabase.auth.getUser();
  if (!authUser?.user) return fail('unauthorized', 401);

  const { booking_id: bookingId } = await req.json().catch(() => ({}) as any);
  if (!bookingId) return fail('booking_id required');

  const { data: booking, error: bErr } = await supabase
    .from('bookings')
    .select('id, ref, client_id, status, booking_fee')
    .eq('id', bookingId)
    .single();

  if (bErr || !booking) return fail('booking not found', 404);
  if (booking.client_id !== authUser.user.id) return fail('forbidden', 403);
  if (booking.status !== 'pending') return fail('booking not payable');

  const configFee = await supabase
    .from('platform_config')
    .select('value')
    .eq('key', 'booking_fee')
    .single();
  const feeRupees = Number(configFee.data?.value ?? booking.booking_fee ?? 20);

  // Idempotency: existing order wins (NFR-REL-02).
  const { data: existing } = await supabase
    .from('orders')
    .select('razorpay_order_id, amount')
    .eq('booking_id', bookingId)
    .maybeSingle();

  let orderId = existing?.razorpay_order_id as string | null;
  if (!orderId) {
    try {
      const order = await rzpCreateOrder(
        Math.round(feeRupees * 100),
        `kw_${booking.ref}`,
      );
      orderId = order.id;
      await supabase.from('orders').upsert({
        booking_id: bookingId,
        razorpay_order_id: order.id,
        amount: feeRupees,
        status: 'CREATED',
      });
    } catch (e) {
      console.error(e);
      return fail('could not create payment order', 502);
    }
  }

  return json({
    order_id: orderId,
    amount: Math.round(feeRupees * 100),
    key_id: Deno.env.get('RAZORPAY_KEY_ID'), // PUBLIC key id - safe for client
    currency: 'INR',
  });
});
