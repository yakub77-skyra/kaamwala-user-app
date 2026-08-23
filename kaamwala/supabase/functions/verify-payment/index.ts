// Edge Function: verify-payment (Razorpay webhook, FR-PAY-02)
// HMAC-SHA256 verified (NFR-SEC-03). Marks order PAID and notifies worker.
import { fail, json, preflight, verifyWebhookSignature } from '../_shared/utils.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return preflight();

  const raw = await req.text();
  const signature = req.headers.get('x-razorpay-signature') ?? '';

  const ok = await verifyWebhookSignature(raw, signature);
  if (!ok) return fail('invalid signature', 401); // reject unsigned/modified

  const event = JSON.parse(raw);

  if (event.event === 'payment.captured' || event.event === 'order.paid') {
    const rzpOrderId =
      event.payload?.payment?.entity?.order_id ??
      event.payload?.order?.entity?.id;
    if (!rzpOrderId) return fail('no order id in payload');

    const supabase = (await import('npm:@supabase/supabase-js@2')).createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    const { data: order } = await supabase
      .from('orders')
      .update({
        status: 'PAID',
        razorpay_payment_id: event.payload?.payment?.entity?.id ?? null,
        paid_at: new Date().toISOString(),
      })
      .eq('razorpay_order_id', rzpOrderId)
      .select('booking_id')
      .single();

    if (order) {
      // Push notification to the worker: "New Job!" (FR-NOTIF-02)
      await supabase.functions.invoke('send-push', {
        body: {
          booking_id: order.booking_id,
          kind: 'new_job',
        },
      });
    }
  }

  // Refund path (FR-PAY-06): cancellation while pending auto-refunds via
  // Razorpay dashboard/API; webhook marks REFUNDED.
  if (event.event === 'refund.processed') {
    const paymentId = event.payload?.refund?.entity?.payment_id;
    const supabase = (await import('npm:@supabase/supabase-js@2')).createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );
    await supabase
      .from('orders')
      .update({ status: 'REFUNDED' })
      .eq('razorpay_payment_id', paymentId);
  }

  return json({ received: true });
});
