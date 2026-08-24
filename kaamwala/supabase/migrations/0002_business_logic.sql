-- KaamWala v2 — 0002 business logic (applied 20260824104839 + 20260824105236)
-- Final bookings_guard includes the service-role path fix.

-- Generic updated_at toucher
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

create trigger trg_payment_info_updated before update on public.worker_payment_info
  for each row execute function public.set_updated_at();
create trigger trg_push_token_updated before update on public.push_tokens
  for each row execute function public.set_updated_at();
create trigger trg_platform_config_updated before update on public.platform_config
  for each row execute function public.set_updated_at();

-- Who is acting on this row?
create or replace function public.booking_actor(p_client uuid, p_worker_row uuid)
returns text language sql stable as $$
  select case
    when coalesce(current_setting('request.jwt.claims', true)::jsonb ->> 'role', '') = 'service_role'
      or current_setting('request.jwt.claim.sub', true) is null then 'service'
    when p_client::text = current_setting('request.jwt.claim.sub', true) then 'client'
    when p_worker_row::text = current_setting('request.jwt.claim.sub', true) then 'worker'
    else 'other'
  end
$$;

-- ============================================================
-- users: phone immutable, role locked once chosen (FR-AUTH-05)
-- ============================================================
create or replace function public.users_guard()
returns trigger language plpgsql as $$
declare v_role text;
begin
  v_role := coalesce(current_setting('request.jwt.claims', true)::jsonb ->> 'role', '');
  if v_role = 'service_role' then return new; end if;

  if new.phone is distinct from old.phone then
    raise exception 'phone number cannot be changed';
  end if;

  -- Role choice is FINAL
  if old.role is not null and new.role is distinct from old.role then
    raise exception 'role is locked and cannot be changed';
  end if;

  -- Only owner may self-edit name/city/photo
  if current_setting('request.jwt.claim.sub', true) is distinct from old.id::text then
    raise exception 'not permitted';
  end if;
  return new;
end $$;

create trigger trg_users_guard before update on public.users
  for each row execute function public.users_guard();

-- ============================================================
-- workers: protect admin-controlled columns from owner edits
-- ============================================================
create or replace function public.workers_guard()
returns trigger language plpgsql as $$
declare
  v_role text;
  v_uid text;
begin
  v_role := coalesce(current_setting('request.jwt.claims', true)::jsonb ->> 'role', '');
  v_uid := current_setting('request.jwt.claim.sub', true);
  if v_role = 'service_role' or v_uid is null then return new; end if;

  if tg_op = 'INSERT' then
    -- Workers always start pending; owner cannot self-approve
    new.approval_status := 'pending';
    new.rejection_reason := null;
    new.rating_avg := 0;
    new.rating_count := 0;
    if new.user_id::text <> v_uid then
      raise exception 'cannot create profile for another user';
    end if;
    return new;
  end if;

  -- UPDATE: owner cannot touch approval/rating columns
  if old.user_id::text = v_uid then
    if new.approval_status is distinct from old.approval_status
       or new.rating_avg is distinct from old.rating_avg
       or new.rating_count is distinct from old.rating_count
       or new.rejection_reason is distinct from old.rejection_reason
       or new.user_id is distinct from old.user_id then
      raise exception 'approval and rating fields are admin-controlled';
    end if;
  end if;
  return new;
end $$;

create trigger trg_workers_insert before insert on public.workers
  for each row execute function public.workers_guard();
create trigger trg_workers_update before update on public.workers
  for each row execute function public.workers_guard();

-- ============================================================
-- bookings: human ref generation KW-YYYY-NNNN
-- ============================================================
create or replace function public.generate_booking_ref()
returns trigger language plpgsql as $$
begin
  if new.ref is null or new.ref = '' then
    new.ref := 'KW-' || to_char(now(), 'YYYY') || '-' ||
               lpad(nextval('public.booking_ref_seq')::text, 4, '0');
  end if;
  return new;
end $$;

create trigger trg_booking_ref before insert on public.bookings
  for each row execute function public.generate_booking_ref();

-- ============================================================
-- bookings: lifecycle state machine + money integrity (FR-WORKER-07)
-- ============================================================
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
    return new;
  end if;

  -- Immutable identity/money fields for non-service actors (NFR-SEC-02)
  if new.ref is distinct from old.ref
     or new.client_id is distinct from old.client_id
     or new.worker_id is distinct from old.worker_id
     or new.category is distinct from old.category
     or new.booking_fee is distinct from old.booking_fee
     or new.commission_rate is distinct from old.commission_rate
     or new.commission_amount is distinct from old.commission_amount
     or new.worker_earning is distinct from old.worker_earning then
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
    return new;
  end if;

  case v_actor
    when 'worker' then
      if not (
        (old.status = 'pending'   and new.status in ('accepted','declined')) or
        (old.status = 'accepted'  and new.status = 'traveling') or
        (old.status = 'traveling' and new.status = 'arrived') or
        (old.status = 'arrived'   and new.status = 'in_progress') or
        (old.status = 'in_progress' and new.status = 'completed')
      ) then
        raise exception 'invalid status transition % -> % for worker', old.status, new.status;
      end if;
    when 'client' then
      if not (old.status = 'pending' and new.status = 'cancelled') then
        raise exception 'invalid status transition % -> % for client', old.status, new.status;
      end if;
    else
      raise exception 'not a participant of this booking';
  end case;

  if new.status = 'completed' then
    new.completed_at := coalesce(new.completed_at, now());
  end if;
  return new;
end $$;

create trigger trg_bookings_guard before update on public.bookings
  for each row execute function public.bookings_guard();

-- ============================================================
-- reviews: atomic rating recompute (Phase 3 section 7.5)
-- ============================================================
create or replace function public.recompute_worker_rating()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  update public.workers w
     set rating_avg = coalesce(s.avg_rating, 0),
         rating_count = coalesce(s.cnt, 0)
    from (
      select avg(rating)::numeric(3,2) as avg_rating, count(*)::int as cnt
        from public.reviews where worker_id = new.worker_id
    ) s
   where w.id = new.worker_id;
  return new;
end $$;

create trigger trg_reviews_rating after insert on public.reviews
  for each row execute function public.recompute_worker_rating();

-- ============================================================
-- Server-side notifications (SECURITY DEFINER bypasses RLS)
-- ============================================================
create or replace function public.notify_booking_accepted()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.status = 'accepted' and old.status = 'pending' then
    insert into public.notifications(user_id, type, title, body)
    values (new.client_id, 'booking',
            'Booking accepted ✅',
            'Your worker accepted booking ' || new.ref);
  end if;
  return new;
end $$;

create trigger trg_booking_accepted after update on public.bookings
  for each row execute function public.notify_booking_accepted();

create or replace function public.notify_booking_completed()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.status = 'completed' and old.status <> 'completed' then
    insert into public.notifications(user_id, type, title, body)
    values (new.client_id, 'booking',
            'Job done 🎉 Rate your worker',
            'Confirm and rate booking ' || new.ref);
  end if;
  return new;
end $$;

create trigger trg_booking_completed after update on public.bookings
  for each row execute function public.notify_booking_completed();

create or replace function public.notify_order_paid()
returns trigger language plpgsql security definer set search_path = public as $$
declare v_wuid uuid; v_wrow uuid; v_ref text;
begin
  if new.status = 'paid' and old.status = 'created' then
    select b.worker_id, b.ref into v_wrow, v_ref
      from public.bookings b
     where b.id = new.booking_id;
    select user_id into v_wuid from public.workers where id = v_wrow;
    insert into public.notifications(user_id, type, title, body)
    values (v_wuid, 'booking',
            '🔔 New job request!',
            'You have a new paid booking ' || v_ref || '. Open the app to accept.');
  end if;
  return new;
end $$;

create trigger trg_order_paid after update on public.orders
  for each row execute function public.notify_order_paid();

create or replace function public.notify_payout_success()
returns trigger language plpgsql security definer set search_path = public as $$
declare v_wuid uuid;
begin
  if new.status = 'success' and old.status <> 'success' then
    select user_id into v_wuid from public.workers where id = new.worker_id;
    insert into public.notifications(user_id, type, title, body)
    values (v_wuid, 'payment',
            '💰 Payment received',
            'Rs. ' || new.amount::text || ' sent to your account.');
  end if;
  return new;
end $$;

create trigger trg_payout_success after update on public.payouts
  for each row execute function public.notify_payout_success();
