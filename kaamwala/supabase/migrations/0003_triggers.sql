-- KaamWala v2 - Migration 0003: Triggers & Functions
-- Source: Phase 3 section 7.5 (fixes v1 atomicity bug).

-- 1) on_review_insert -> recompute worker rating atomically
create or replace function public.recalc_worker_rating() returns trigger
language plpgsql security definer set search_path = public as $$
declare wid uuid;
begin
  select r.worker_id into wid from reviews r where r.booking_id = new.booking_id;
  if wid is null then return new; end if;

  update workers w set
    rating_avg = coalesce(sub.avg_rating, 0),
    rating_count = coalesce(sub.cnt, 0)
  from (
    select avg(rating)::numeric(3,2) as avg_rating, count(*)::int as cnt
    from reviews where worker_id = wid
  ) sub
  where w.id = wid;
  return new;
end $$;

drop trigger if exists trg_recalc_rating on public.reviews;
create trigger trg_recalc_rating
after insert on public.reviews
for each row execute function public.recalc_worker_rating();

-- 2) on_booking_completed -> notify client + stamp completed_at
create or replace function public.on_booking_status_change() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.status <> old.status then
    -- stamp completion time
    if new.status = 'completed' and old.completed_at is null then
      new.completed_at := now();
    end if;

    -- notify the client about status changes
    insert into notifications (user_id, type, title, body)
    values (
      new.client_id,
      'booking',
      case new.status
        when 'accepted'    then '✅ Booking accepted!'
        when 'declined'    then '❌ Worker declined'
        when 'traveling'   then '🛵 Worker started travel'
        when 'arrived'     then '📍 Worker has arrived'
        when 'in_progress' then '🔧 Work in progress'
        when 'completed'   then '🎉 Job completed! Please rate your worker.'
        else 'Booking update'
      end,
      'Booking ' || new.ref
    );
  end if;
  return new;
end $$;

drop trigger if exists trg_booking_status on public.bookings;
create trigger trg_booking_status
after update on public.bookings
for each row execute function public.on_booking_status_change();

-- 3) on_payout_success -> notify worker
create or replace function public.on_payout_success() returns trigger
language plpgsql security definer set search_path = public as $$
declare uid uuid;
begin
  if new.status = 'SUCCESS' then
    select user_id into uid from workers where id = new.worker_id;
    if uid is not null then
      insert into notifications (user_id, type, title, body)
      values (uid, 'payment', '💰 ₹' || new.amount::text || ' sent to your UPI!', 'Payout complete');
    end if;
  end if;
  return new;
end $$;

drop trigger if exists trg_payout_success on public.payouts;
create trigger trg_payout_success
after update on public.payouts
for each row execute function public.on_payout_success();

-- 4) Auto-create profile row after phone OTP signup (FR-AUTH-05 flow support)
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.users (id, phone)
  values (new.id, coalesce(new.phone, ''))
  on conflict (id) do nothing;
  return new;
end $$;

drop trigger if exists trg_new_user on auth.users;
create trigger trg_new_user
after insert on auth.users
for each row execute function public.handle_new_user();
