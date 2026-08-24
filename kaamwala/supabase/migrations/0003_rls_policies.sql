-- KaamWala v2 - 0003 RLS (applied 20260824105100). See live migration history
-- (supabase_migrations.schema_migrations) for the authoritative statement set.
-- This file mirrors it 1:1 for local dev bootstrapping.

create or replace function public.is_booking_participant(p_booking_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1
      from public.bookings b
      join public.workers w on w.id = b.worker_id
     where b.id = p_booking_id
       and (select auth.uid()) in (b.client_id, w.user_id)
  )
$$;

create or replace function public.is_booking_client(p_booking_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.bookings
     where id = p_booking_id and client_id = (select auth.uid())
  )
$$;

create or replace function public.i_am_worker_of(p_worker_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.workers
     where id = p_worker_id and user_id = (select auth.uid())
  )
$$;

revoke execute on function public.is_booking_participant(uuid),
  public.is_booking_client(uuid), public.i_am_worker_of(uuid) from public, anon;
grant execute on function public.is_booking_participant(uuid),
  public.is_booking_client(uuid), public.i_am_worker_of(uuid) to authenticated;

alter table public.users             enable row level security;
alter table public.workers           enable row level security;
alter table public.bookings          enable row level security;
alter table public.orders            enable row level security;
alter table public.reviews           enable row level security;
alter table public.chat_messages     enable row level security;
alter table public.payouts           enable row level security;
alter table public.worker_payment_info enable row level security;
alter table public.notifications     enable row level security;
alter table public.push_tokens       enable row level security;
alter table public.platform_config   enable row level security;

create policy users_select on public.users for select to authenticated using (
  users.id = (select auth.uid())
  or exists (
    select 1 from public.workers w
     where w.user_id = users.id and w.approval_status = 'approved'
  )
  or exists (
    select 1
      from public.bookings b
      join public.workers w2 on w2.id = b.worker_id
     where (b.client_id = (select auth.uid()) and w2.user_id = users.id)
        or (w2.user_id = (select auth.uid()) and b.client_id = users.id)
  )
);

create policy users_insert_self on public.users for insert to authenticated
  with check (id = (select auth.uid()));

create policy users_update_self on public.users for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

create policy workers_select on public.workers for select to authenticated using (true);

create policy workers_insert_self on public.workers for insert to authenticated
  with check (user_id = (select auth.uid()));

create policy workers_update_self on public.workers for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy bookings_select_participants on public.bookings for select to authenticated
  using (public.is_booking_participant(id));

create policy bookings_insert_client on public.bookings for insert to authenticated
  with check (
    client_id = (select auth.uid())
    and status = 'pending'
    and exists (
      select 1 from public.workers w
       where w.id = worker_id and w.approval_status = 'approved'
    )
  );

create policy bookings_update_participants on public.bookings for update to authenticated
  using (public.is_booking_participant(id))
  with check (public.is_booking_participant(id));

create policy orders_select_participants on public.orders for select to authenticated
  using (public.is_booking_participant(booking_id));

create policy reviews_select_authenticated on public.reviews for select to authenticated using (true);

create policy reviews_insert_client on public.reviews for insert to authenticated
  with check (
    client_id = (select auth.uid())
    and exists (
      select 1 from public.bookings b
       where b.id = booking_id
         and b.client_id = (select auth.uid())
         and b.worker_id = worker_id
         and b.status = 'completed'
    )
  );

create policy chat_select_participants on public.chat_messages for select to authenticated
  using (public.is_booking_participant(booking_id));

create policy chat_insert_participants on public.chat_messages for insert to authenticated
  with check (
    sender_id = (select auth.uid())
    and public.is_booking_participant(booking_id)
  );

create policy payouts_select_worker on public.payouts for select to authenticated
  using (public.i_am_worker_of(worker_id));

create policy wpi_all_self on public.worker_payment_info for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy push_tokens_all_self on public.push_tokens for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy notifications_select_self on public.notifications for select to authenticated
  using (user_id = (select auth.uid()));

create policy notifications_update_self on public.notifications for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy platform_config_read on public.platform_config for select to authenticated using (true);
