-- KaamWala v2 — 0008 Phase 2: booking/payment hardening.
-- Adds payment fields to bookings, splits pre-payment lifecycle states
-- (payment_pending / payment_failed / pending_acceptance), protects
-- payment-sensitive columns from client writes, seeds pricing config and
-- opens booking_photos read to the worker (public read).

-- ============ bookings: new statuses ============
alter table public.bookings drop constraint bookings_status_check;
alter table public.bookings add constraint bookings_status_check check (
  status in ('payment_pending','payment_failed','pending_acceptance',
             'pending','accepted','traveling','arrived','in_progress',
             'completed','cancelled','declined')
);

-- ============ bookings: payment columns ============
alter table public.bookings add column payment_status text not null default 'pending'
  constraint bookings_payment_status_check check (payment_status in ('pending','paid','failed','refunded'));
alter table public.bookings add column payment_provider text
  constraint bookings_payment_provider_check check (payment_provider in ('razorpay','mock'));
alter table public.bookings add column payment_order_id text;
alter table public.bookings add column payment_id text;
alter table public.bookings add column payment_signature_verified boolean not null default false;
alter table public.bookings add column amount_paise integer;
alter table public.bookings add column booking_fee_paise integer;
alter table public.bookings add column estimated_min_paise integer;
alter table public.bookings add column estimated_max_paise integer;
alter table public.bookings add column payment_attempts integer not null default 0
  constraint bookings_payment_attempts_check check (payment_attempts >= 0);
alter table public.bookings add column payment_error_message text;
alter table public.bookings add column payment_expires_at timestamptz;
alter table public.bookings add column transaction_reference text;
alter table public.bookings add column idempotency_key text unique;
alter table public.bookings add column cancellation_reason text;
alter table public.bookings add column cancelled_at timestamptz;
alter table public.bookings add column refund_status text
  constraint bookings_refund_status_check check (refund_status in ('none','pending','processed','failed'));
alter table public.bookings add column refund_message text;

-- ============ bookings: indexes (Phase 2 task 15) ============
create index if not exists bookings_status_idx on public.bookings (status);
create index if not exists bookings_scheduled_idx on public.bookings (service_date);
create index if not exists bookings_payment_status_idx on public.bookings (payment_status);
create index if not exists bookings_worker_slot_idx on public.bookings (worker_id, service_date, time_slot);

-- ============ bookings_guard: protect payment fields + new transitions ============
create or replace function public.bookings_guard()
returns trigger language plpgsql as $$
declare
  v_actor text;
  v_owner uuid;
begin
  select w.user_id into v_owner from public.workers w where w.id = new.worker_id;
  v_actor := public.booking_actor(new.client_id, v_owner);

  if v_actor = 'service' then
    if new.status = 'completed' then
      new.completed_at := coalesce(new.completed_at, now());
    end if;
    if new.status = 'cancelled' and old.status <> 'cancelled' then
      new.cancelled_at := coalesce(new.cancelled_at, now());
    end if;
    return new;
  end if;

  -- Immutable identity/money/payment fields for non-service actors (NFR-SEC-02)
  if new.ref is distinct from old.ref
     or new.client_id is distinct from old.client_id
     or new.worker_id is distinct from old.worker_id
     or new.category is distinct from old.category
     or new.booking_fee is distinct from old.booking_fee
     or new.commission_rate is distinct from old.commission_rate
     or new.commission_amount is distinct from old.commission_amount
     or new.worker_earning is distinct from old.worker_earning
     or new.payment_status is distinct from old.payment_status
     or new.payment_provider is distinct from old.payment_provider
     or new.payment_order_id is distinct from old.payment_order_id
     or new.payment_id is distinct from old.payment_id
     or new.payment_signature_verified is distinct from old.payment_signature_verified
     or new.amount_paise is distinct from old.amount_paise
     or new.booking_fee_paise is distinct from old.booking_fee_paise
     or new.estimated_min_paise is distinct from old.estimated_min_paise
     or new.estimated_max_paise is distinct from old.estimated_max_paise
     or new.payment_attempts is distinct from old.payment_attempts
     or new.payment_error_message is distinct from old.payment_error_message
     or new.payment_expires_at is distinct from old.payment_expires_at
     or new.transaction_reference is distinct from old.transaction_reference
     or new.idempotency_key is distinct from old.idempotency_key
     or new.refund_status is distinct from old.refund_status
     or new.refund_message is distinct from old.refund_message then
    raise exception 'protected booking fields cannot be modified';
  end if;

  -- No status change: only client confirmation flag may flip
  if new.status = old.status then
    if v_actor = 'client' and new.client_confirmed and not old.client_confirmed
       and old.status = 'completed' then
      return new;
    end if;
    if new.client_confirmed is distinct from old.client_confirmed then
      raise exception 'only the client may confirm completion';
    end if;
    if new.cancellation_reason is distinct from old.cancellation_reason
       and old.status <> 'cancelled' then
      raise exception 'cancellation reason only when cancelled';
    end if;
    return new;
  end if;

  case v_actor
    when 'worker' then
      if not (
        (old.status = 'pending_acceptance' and new.status in ('accepted','declined')) or
        (old.status = 'pending'   and new.status in ('accepted','declined')) or
        (old.status = 'accepted'  and new.status = 'traveling') or
        (old.status = 'traveling' and new.status = 'arrived') or
        (old.status = 'arrived'   and new.status = 'in_progress') or
        (old.status = 'in_progress' and new.status = 'completed')
      ) then
        raise exception 'invalid status transition % -> % for worker', old.status, new.status;
      end if;
    when 'client' then
      if not (
        old.status in ('payment_pending','payment_failed','pending_acceptance','pending')
        and new.status = 'cancelled'
      ) then
        raise exception 'invalid status transition % -> % for client', old.status, new.status;
      end if;
      new.cancelled_at := coalesce(new.cancelled_at, now());
    else
      raise exception 'not a participant of this booking';
  end case;

  if new.status = 'completed' then
    new.completed_at := coalesce(new.completed_at, now());
  end if;
  return new;
end $$;

-- ============ bookings insert policy: new pre-payment status ============
drop policy bookings_insert_client on public.bookings;
create policy bookings_insert_client on public.bookings for insert to authenticated
  with check (
    client_id = (select auth.uid())
    and status in ('payment_pending','pending')
    and exists (
      select 1 from public.workers w
       where w.id = worker_id and w.approval_status = 'approved'
    )
  );

-- ============ notifications: accepted fires from pending_acceptance ============
create or replace function public.notify_booking_accepted()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.status = 'accepted' and old.status in ('pending_acceptance','pending') then
    insert into public.notifications(user_id, type, title, body)
    values (new.client_id, 'booking',
            'Booking accepted ✅',
            'Your worker accepted booking ' || new.ref);
  end if;
  return new;
end $$;

-- ============ pricing source of truth (Phase 2 task 7) ============
insert into public.platform_config (key, value) values
  ('pricing', jsonb_build_object(
    'booking_fee_paise', 2000,
    'min_lead_minutes', 30,
    'max_lead_days', 30,
    'cancellation_policy', 'Free cancellation before the worker accepts your booking. The booking fee is refunded in full.',
    'refund_timeline', 'Refunds are initiated immediately on cancellation and usually reach your bank in 3-5 business days.'
  ))
on conflict (key) do nothing;

-- ============ storage: booking photos readable by worker ============
create policy booking_photos_public_read on storage.objects for select
  using (bucket_id = 'booking_photos');

-- ============ kw_private guard (robust actor detection, live trigger) ============
-- The bookings trigger executes kw_private.bookings_guard (set by the
-- robust-actor hardening applied directly to the DB). Mirror it here with
-- the same Phase 2 rules as public.bookings_guard above.
create or replace function kw_private.bookings_guard()
returns trigger language plpgsql set search_path = '' as $function$
declare
  v_actor text;
  v_owner uuid;
begin
  select w.user_id into v_owner from public.workers w where w.id = new.worker_id;
  v_actor := kw_private.booking_actor(new.client_id, v_owner);

  if v_actor = 'service' then
    if new.status = 'completed' then
      new.completed_at := coalesce(new.completed_at, now());
    end if;
    if new.status = 'cancelled' and old.status <> 'cancelled' then
      new.cancelled_at := coalesce(new.cancelled_at, now());
    end if;
    return new;
  end if;

  if new.ref is distinct from old.ref
     or new.client_id is distinct from old.client_id
     or new.worker_id is distinct from old.worker_id
     or new.category is distinct from old.category
     or new.booking_fee is distinct from old.booking_fee
     or new.commission_rate is distinct from old.commission_rate
     or new.commission_amount is distinct from old.commission_amount
     or new.worker_earning is distinct from old.worker_earning
     or new.payment_status is distinct from old.payment_status
     or new.payment_provider is distinct from old.payment_provider
     or new.payment_order_id is distinct from old.payment_order_id
     or new.payment_id is distinct from old.payment_id
     or new.payment_signature_verified is distinct from old.payment_signature_verified
     or new.amount_paise is distinct from old.amount_paise
     or new.booking_fee_paise is distinct from old.booking_fee_paise
     or new.estimated_min_paise is distinct from old.estimated_min_paise
     or new.estimated_max_paise is distinct from old.estimated_max_paise
     or new.payment_attempts is distinct from old.payment_attempts
     or new.payment_error_message is distinct from old.payment_error_message
     or new.payment_expires_at is distinct from old.payment_expires_at
     or new.transaction_reference is distinct from old.transaction_reference
     or new.idempotency_key is distinct from old.idempotency_key
     or new.refund_status is distinct from old.refund_status
     or new.refund_message is distinct from old.refund_message then
    raise exception 'protected booking fields cannot be modified';
  end if;

  if new.status = old.status then
    if v_actor = 'client' and new.client_confirmed and not old.client_confirmed
       and old.status = 'completed' then
      return new;
    end if;
    if new.client_confirmed is distinct from old.client_confirmed then
      raise exception 'only the client may confirm completion';
    end if;
    if new.cancellation_reason is distinct from old.cancellation_reason
       and old.status <> 'cancelled' then
      raise exception 'cancellation reason only when cancelled';
    end if;
    return new;
  end if;

  case v_actor
    when 'worker' then
      if not (
        (old.status = 'pending_acceptance' and new.status in ('accepted','declined')) or
        (old.status = 'pending'   and new.status in ('accepted','declined')) or
        (old.status = 'accepted'  and new.status = 'traveling') or
        (old.status = 'traveling' and new.status = 'arrived') or
        (old.status = 'arrived'   and new.status = 'in_progress') or
        (old.status = 'in_progress' and new.status = 'completed')
      ) then
        raise exception 'invalid status transition % -> % for worker', old.status, new.status;
      end if;
    when 'client' then
      if not (
        old.status in ('payment_pending','payment_failed','pending_acceptance','pending')
        and new.status = 'cancelled'
      ) then
        raise exception 'invalid status transition % -> % for client', old.status, new.status;
      end if;
      new.cancelled_at := coalesce(new.cancelled_at, now());
    else
      raise exception 'not a participant of this booking';
  end case;

  if new.status = 'completed' then
    new.completed_at := coalesce(new.completed_at, now());
  end if;
  return new;
end $function$;
