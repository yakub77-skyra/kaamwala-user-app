// Edge Function: approve-worker (A1 / FR-WORKER-02)
// Admin-only (service role). Approve or reject a worker application.
// approve: true|false, reason?: string
import { fail, json, preflight } from '../_shared/utils.ts';
import { createClient } from 'npm:@supabase/supabase-js@2';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return preflight();
  if (req.method !== 'POST') return fail('method not allowed', 405);

  // This function must be invoked with the SERVICE role key by the admin
  // (Supabase Studio / admin tooling) - never with anon key.
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  const authHeader = req.headers.get('Authorization') ?? '';
  if (!authHeader.includes(serviceKey)) {
    return fail('admin only', 403);
  }

  const { worker_id: workerId, approve, reason } = await req.json().catch(() => ({}) as any);
  if (!workerId || typeof approve !== 'boolean') {
    return fail('worker_id and approve required');
  }

  const admin = createClient(
    Deno.env.get('SUPABASE_URL')!,
    serviceKey,
  );

  const { data: worker, error } = await admin
    .from('workers')
    .update({
      approval_status: approve ? 'approved' : 'rejected',
      rejection_reason: approve ? null : (reason ?? 'Documents unclear'),
    })
    .eq('id', workerId)
    .select('user_id')
    .single();

  if (error || !worker) return fail('worker not found', 404);

  // Notify worker (FR-NOTIF-07): "Your profile is approved!"
  await admin.from('notifications').insert({
    user_id: worker.user_id,
    type: 'system',
    title: approve
      ? '🎉 Your profile is approved! Start accepting jobs.'
      : `❌ Profile rejected: ${reason ?? 'Documents unclear'}`,
    body: approve ? 'Dashboard unlocked' : 'You can re-upload documents',
  });

  await admin.functions.invoke('send-push', {
    body: { user_id: worker.user_id, kind: approve ? 'approved' : 'rejected' },
  });

  return json({ approved: approve });
});
