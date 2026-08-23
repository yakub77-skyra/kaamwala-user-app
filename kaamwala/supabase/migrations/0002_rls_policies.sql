-- KaamWala v2 - Migration 0002: Row Level Security
-- Source: Phase 3 section 7.4 RLS Policy Summary + NFR-SEC-01.

alter table public.users enable row level security;
alter table public.workers enable row level security;
alter table public.bookings enable row level security;
alter table public.orders enable row level security;
alter table public.reviews enable row level security;
alter table public.chat_messages enable row level security;
alter table public.payouts enable row level security;
alter table public.worker_payment_info enable row level security;
alter table public.notifications enable row level security;
alter table public.push_tokens enable row level security;
alter table public.platform_config enable row level security;

-- Helper: is current user the worker behind this workers.id?
create or replace function public.is_worker_of(wid uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from workers w where w.id = wid and w.user_id = auth.uid());
$$;

-- users: self only
create policy "users_select_self" on public.users for select using (auth.uid() = id);
create policy "users_insert_self" on public.users for insert with check (auth.uid() = id);
create policy "users_update_self" on public.users for update using (auth.uid() = id);

-- workers: readable by any authenticated; self can update profile but NOT
-- approval_status / rating_* (admin/trigger only)
create policy "workers_select_auth" on public.workers for select to authenticated using (true);
create policy "workers_insert_self" on public.workers for insert with check (auth.uid() = user_id);
create policy "workers_update_self" on public.workers for update using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- bookings: client OR owning worker of the row (Phase 3 7.4)
create policy "bookings_select_participants" on public.bookings for select to authenticated
  using (
    auth.uid() = client_id
    or public.is_worker_of(worker_id)
  );
create policy "bookings_insert_client" on public.bookings for insert to authenticated
  with check (auth.uid() = client_id);
create policy "bookings_update_participants" on public.bookings for update to authenticated
  using (auth.uid() = client_id or public.is_worker_of(worker_id));

-- orders & payouts: edge functions use service role (bypasses RLS).
-- Clients/workers may read their own.
create policy "orders_select_client" on public.orders for select to authenticated
  using (exists (select 1 from bookings b where b.id = booking_id and b.client_id = auth.uid()));
create policy "payouts_select_worker" on public.payouts for select to authenticated
  using (public.is_worker_of(worker_id));

-- reviews: any authenticated reads; client of a completed booking writes once; immutable
create policy "reviews_select_auth" on public.reviews for select to authenticated using (true);
create policy "reviews_insert_client" on public.reviews for insert to authenticated
  with check (
    auth.uid() = client_id
    and exists (
      select 1 from bookings b
      where b.id = booking_id and b.client_id = auth.uid() and b.status = 'completed'
    )
  );

-- chat: participants only, insert-only updates blocked (immutable messages)
create policy "chat_select_participants" on public.chat_messages for select to authenticated
  using (
    exists (
      select 1 from bookings b
      where b.id = booking_id
        and (b.client_id = auth.uid() or public.is_worker_of(b.worker_id))
    )
  );
create policy "chat_insert_participants" on public.chat_messages for insert to authenticated
  with check (
    auth.uid() = sender_id
    and exists (
      select 1 from bookings b
      where b.id = booking_id
        and (b.client_id = auth.uid() or public.is_worker_of(b.worker_id))
    )
  );

-- payment info: self
create policy "wpi_all_self" on public.worker_payment_info for all to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- notifications: read own, mark-read own
create policy "notif_select_self" on public.notifications for select to authenticated using (auth.uid() = user_id);
create policy "notif_update_self" on public.notifications for update to authenticated using (auth.uid() = user_id);

-- push tokens: self
create policy "push_all_self" on public.push_tokens for all to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- platform config: authenticated read; admin write via service role/dashboard
create policy "config_select_auth" on public.platform_config for select to authenticated using (true);
