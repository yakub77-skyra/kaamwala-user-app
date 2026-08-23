// Edge Function: release-payout (FR-PAY-03 / NFR-SEC-10)
// Double-payout prevention: checks order is PAID, no existing payout,
// client_confirmed = true. Then pays worker via Razorpay X.
import { fail, json, preflight, rzpXPayout } from '../_shared/utils.ts';
import { createClient } from 'npm:@supabase/supabase-js@2';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return preflight();
  if (req.method !== 'POST') return fail('method not allowed', 405);

  const authHeader = req.headers.get('Authorization') ?? '';
  const supabaseAnon = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    { global: { headers: { Authorization: authHeader } } },
  );
  const { data: authUser } = await supabaseAnon.auth.getUser();
  if (!authUser?.user) return fail('unauthorized', 401);

  const { booking_id: bookingId, action } = await req.json().catch(() => ({}) as any);
  if (!bookingId) return fail('booking_id required');

  const admin = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );

  // Action "confirm": client confirms completion -> unlocks payout.
  if (action === 'confirm') {
    const { data: booking } = await admin
      .from('bookings')
      .update({ client_confirmed: true })
      .eq('id', bookingId)
      .eq('client_id', authUser.user.id)
      .eq('status', 'completed')
      .select()
      .single();
    if (!booking) return fail('cannot confirm this booking');
    return json({ confirmed: true });
  }

  // Default action: release payout to worker's UPI/bank.
  const { data: booking } = await admin
    .from('bookings')
    .select('*')
    .eq('id', bookingId)
    .single();
  if (!booking) return fail('booking not found', 404);

  // GUARD 1: order must be PAID
  const { data: order } = await admin
    .from('orders')
    .select('status')
    .eq('booking_id', bookingId)
    .single();
  if (!order || order.status !== 'PAID') return fail('order not paid');

  // GUARD 2: client must have confirmed completion
  if (!booking.client_confirmed) return fail('client has not confirmed');

  // GUARD 3: no double payout (NFR-SEC-10)
  const { data: existingPayout } = await admin
    .from('payouts')
    .select('id')
    .eq('booking_id', bookingId)
    .maybeSingle();
  if (existingPayout) return fail('payout already exists');

  // Compute money SERVER-SIDE (FR-PAY-04).
  const configRate = await admin
    .from('platform_config')
    .select('value')
    .eq('key', 'commission_rate')
    .single();
  const rate = Number(configRate.data?.value ?? booking.commission_rate ?? 0.10);
  const jobValue = Number(booking.worker_earning ?? 0) > 0
    ? Number(booking.worker_earning) / (1 - rate)
    : Number(booking.estimate_min ?? 0); // final amount agreed on completion
  const commission = Math.round(jobValue * rate * 100) / 100;
  const earning = Math.round((jobValue - commission) * 100) / 100;

  await admin.from('bookings').update({
    commission_amount: commission,
    worker_earning: earning,
  }).eq('id', bookingId);

  const { data: payInfo } = await admin
    .from('worker_payment_info')
    .select('*')
    .eq('user_id', (
      await admin.from('workers').select('user_id').eq('id', booking.worker_id).single()
    ).data!.user_id)
    .single();
  if (!payInfo) return fail('worker payment setup missing');

  try {
    const payout = await rzpXPayout({
      upiId: payInfo.payout_method === 'upi' ? payInfo.upi_id : undefined,
      accountNumber:
        payInfo.payout_method === 'bank' ? payInfo.bank_account : undefined,
      ifsc: payInfo.ifsc ?? undefined,
      name: payInfo.account_holder ?? 'KaamWala Worker',
      amountRupees: earning,
      narration: `KaamWala ${booking.ref}`,
    });

    await admin.from('payouts').insert({
      booking_id: bookingId,
      worker_id: booking.worker_id,
      amount: earning,
      status: payout.status === 'processed' ? 'SUCCESS' : 'PROCESSING',
      razorpay_payout_id: payout.id,
      processed_at: new Date().toISOString(),
    });

    // Notify worker: "₹ sent to your UPI!" (FR-NOTIF-06)
    await admin.functions.invoke('send-push', {
      body: { booking_id: bookingId, kind: 'payment_received', amount: earning },
    });

    return json({ released: true, payout_id: payout.id, amount: earning });
  } catch (e) {
    console.error(e);
    await admin.from('payouts').insert({
      booking_id: bookingId,
      worker_id: booking.worker_id,
      amount: earning,
      status: 'FAILED',
    });
    return fail('payout failed', 502);
  }
});
