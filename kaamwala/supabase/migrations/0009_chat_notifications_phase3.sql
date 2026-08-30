-- KaamWala v2 — 0009 Phase 3: chat + notifications hardening.
--  - chat_messages: text/image/location/system types, delivery/read state,
--    immutable-content guard, participant-only update RLS.
--  - New-message -> in-app notification trigger (receiver-side).
--  - notifications: richer types + data_json + action_route (deep links).
--  - Booking lifecycle events -> notifications (both sides) + system chat
--    message on accept.
--  - chat_images private storage bucket (participant-only read/write).

-- Participant helper (mirrors 0003; the live DB's hardening pass rewrote
-- policies inline, so re-create the function here for storage policies).
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

revoke execute on function public.is_booking_participant(uuid) from public, anon;
grant execute on function public.is_booking_participant(uuid) to authenticated;

-- ============ chat_messages: Phase 3 columns ============
alter table public.chat_messages drop constraint chat_msg_type_check;
alter table public.chat_messages drop constraint chat_content_len;
alter table public.chat_messages
  add constraint chat_msg_type_check check (message_type in ('text','image','location','system'));
alter table public.chat_messages
  add constraint chat_content_len check (char_length(content) <= 1000);
-- System messages have no sender.
alter table public.chat_messages alter column sender_id drop not null;
alter table public.chat_messages add column receiver_id uuid
  references public.users(id) on delete set null;
alter table public.chat_messages add column image_url text;
alter table public.chat_messages add column thumbnail_url text;
alter table public.chat_messages add column location_lat double precision;
alter table public.chat_messages add column location_lng double precision;
alter table public.chat_messages add column location_label text;
alter table public.chat_messages add column metadata_json jsonb;
alter table public.chat_messages add column status text not null default 'sent'
  constraint chat_status_check check (status in ('sent','delivered','read','failed'));
alter table public.chat_messages add column sent_at timestamptz;
alter table public.chat_messages add column delivered_at timestamptz;
alter table public.chat_messages add column read_at timestamptz;
alter table public.chat_messages add column updated_at timestamptz;

create index if not exists chat_messages_sender_idx on public.chat_messages (sender_id);
create index if not exists chat_messages_receiver_idx on public.chat_messages (receiver_id);
create index if not exists chat_messages_status_idx on public.chat_messages (status);
create index if not exists chat_messages_unread_idx on public.chat_messages (booking_id)
  where read_at is null and message_type <> 'system';

-- ============ chat_messages: update RLS + immutability guard ============
-- Participants may update (mark read); the guard below forbids touching
-- anything except read-tracking fields.
create policy chat_update_participants on public.chat_messages for update
  to authenticated
  using (public.is_booking_participant(booking_id))
  with check (public.is_booking_participant(booking_id));

create or replace function public.chat_messages_guard()
returns trigger language plpgsql as $$
declare v_role text;
begin
  v_role := coalesce(current_setting('request.jwt.claims', true)::jsonb->>'role', '');
  if v_role = 'service_role' then return new; end if;

  if new.id is distinct from old.id
     or new.booking_id is distinct from old.booking_id
     or new.sender_id is distinct from old.sender_id
     or new.receiver_id is distinct from old.receiver_id
     or new.message_type is distinct from old.message_type
     or new.content is distinct from old.content
     or new.image_url is distinct from old.image_url
     or new.thumbnail_url is distinct from old.thumbnail_url
     or new.location_lat is distinct from old.location_lat
     or new.location_lng is distinct from old.location_lng
     or new.location_label is distinct from old.location_label
     or new.metadata_json is distinct from old.metadata_json
     or new.created_at is distinct from old.created_at
     or new.sent_at is distinct from old.sent_at
     or new.delivered_at is distinct from old.delivered_at then
    raise exception 'chat messages are immutable; only read state may change';
  end if;
  new.updated_at := now();
  return new;
end $$;

create trigger trg_chat_messages_guard before update on public.chat_messages
  for each row execute function public.chat_messages_guard();

-- ============ new message -> in-app notification for the receiver ============
create or replace function public.notify_chat_message()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_recv uuid;
  v_sender_name text;
  v_ref text;
begin
  if new.message_type = 'system' or new.sender_id is null then return new; end if;
  select case when b.client_id = new.sender_id then w.user_id else b.client_id end,
         coalesce(u.name, 'Your booking partner'),
         b.ref
    into v_recv, v_sender_name, v_ref
    from public.bookings b
    join public.workers w on w.id = b.worker_id
    left join public.users u on u.id = new.sender_id
   where b.id = new.booking_id;
  if v_recv is null or v_recv = new.sender_id then return new; end if;
  insert into public.notifications (user_id, type, title, body, data_json, action_route)
  values (v_recv, 'new_message',
          v_sender_name,
          case new.message_type
            when 'image' then 'Sent you a photo'
            when 'location' then 'Shared a location'
            else coalesce(nullif(new.content, ''), 'New message')
          end,
          jsonb_build_object('booking_id', new.booking_id, 'message_id', new.id),
          '/chat/' || new.booking_id::text);
  return new;
end $$;

create trigger trg_chat_message_notify after insert on public.chat_messages
  for each row execute function public.notify_chat_message();

-- ============ notifications: richer types + deep-link payload ============
alter table public.notifications drop constraint notif_type_check;
alter table public.notifications add constraint notif_type_check check (type in (
  'booking','payment','system',
  'new_message','booking_created','payment_pending','payment_success',
  'payment_failed','booking_declined','booking_cancelled',
  'worker_approved','worker_rejected'
));
alter table public.notifications add column data_json jsonb;
alter table public.notifications add column action_route text;

-- ============ booking lifecycle notifications ============
-- Booking created (payment_pending) -> client.
create or replace function public.notify_booking_created()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.notifications(user_id, type, title, body, data_json, action_route)
  values (new.client_id, 'booking_created',
          'Booking created',
          'Complete the payment to confirm booking ' || new.ref,
          jsonb_build_object('booking_id', new.id),
          '/payment/' || new.id::text);
  return new;
end $$;

create trigger trg_booking_created after insert on public.bookings
  for each row execute function public.notify_booking_created();

-- Accepted -> client notification + system chat message.
create or replace function public.notify_booking_accepted()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.status = 'accepted' and old.status in ('pending_acceptance','pending') then
    insert into public.notifications(user_id, type, title, body, data_json, action_route)
    values (new.client_id, 'booking',
            'Booking accepted',
            'Your worker accepted booking ' || new.ref,
            jsonb_build_object('booking_id', new.id),
            '/booking/' || new.id::text);
    insert into public.chat_messages(booking_id, sender_id, message_type, content, status, sent_at)
    values (new.id, null, 'system',
            'Your worker accepted this booking. They will join the chat when they start.',
            'sent', now());
  end if;
  return new;
end $$;

-- Declined -> client.
create or replace function public.notify_booking_declined()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.status = 'declined' and old.status <> 'declined' then
    insert into public.notifications(user_id, type, title, body, data_json, action_route)
    values (new.client_id, 'booking_declined',
            'Booking declined',
            'The worker declined booking ' || new.ref || '. You can book another worker.',
            jsonb_build_object('booking_id', new.id),
            '/booking/' || new.id::text);
  end if;
  return new;
end $$;

create trigger trg_booking_declined after update on public.bookings
  for each row execute function public.notify_booking_declined();

-- Cancelled -> worker.
create or replace function public.notify_booking_cancelled()
returns trigger language plpgsql security definer set search_path = public as $$
declare v_wuid uuid;
begin
  if new.status = 'cancelled' and old.status <> 'cancelled' then
    select user_id into v_wuid from public.workers where id = new.worker_id;
    insert into public.notifications(user_id, type, title, body, data_json, action_route)
    values (v_wuid, 'booking_cancelled',
            'Booking cancelled',
            'The customer cancelled booking ' || new.ref,
            jsonb_build_object('booking_id', new.id),
            '/w/jobs');
  end if;
  return new;
end $$;

create trigger trg_booking_cancelled after update on public.bookings
  for each row execute function public.notify_booking_cancelled();

-- Completed -> client (rate link).
create or replace function public.notify_booking_completed()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.status = 'completed' and old.status <> 'completed' then
    insert into public.notifications(user_id, type, title, body, data_json, action_route)
    values (new.client_id, 'booking',
            'Job completed',
            'Confirm and rate booking ' || new.ref,
            jsonb_build_object('booking_id', new.id),
            '/rate/' || new.id::text);
  end if;
  return new;
end $$;

-- Order paid -> worker (new job) + client (payment success).
create or replace function public.notify_order_paid()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_wuid uuid;
  v_wrow uuid;
  v_client uuid;
  v_ref text;
  v_id uuid;
begin
  if new.status = 'paid' and old.status = 'created' then
    select b.worker_id, b.client_id, b.ref, b.id
      into v_wrow, v_client, v_ref, v_id
      from public.bookings b
     where b.id = new.booking_id;
    select user_id into v_wuid from public.workers where id = v_wrow;
    insert into public.notifications(user_id, type, title, body, data_json, action_route)
    values (v_wuid, 'booking',
            'New job request',
            'Paid booking ' || v_ref || ' is waiting for you to accept.',
            jsonb_build_object('booking_id', v_id),
            '/w/jobs');
    insert into public.notifications(user_id, type, title, body, data_json, action_route)
    values (v_client, 'payment_success',
            'Payment successful',
            'Your booking request for ' || v_ref || ' was sent to the worker.',
            jsonb_build_object('booking_id', v_id),
            '/booking/' || v_id::text);
  end if;
  return new;
end $$;

-- ============ realtime ============
alter publication supabase_realtime add table public.notifications;

-- ============ storage: chat_images (private, participant-only) ============
insert into storage.buckets (id, name, public)
values ('chat_images', 'chat_images', false) on conflict (id) do nothing;

create policy chat_images_participant_insert on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'chat_images'
    and (storage.foldername(name))[1] = 'chat'
    and public.is_booking_participant((storage.foldername(name))[2]::uuid)
  );

create policy chat_images_participant_select on storage.objects for select
  to authenticated
  using (
    bucket_id = 'chat_images'
    and (storage.foldername(name))[1] = 'chat'
    and public.is_booking_participant((storage.foldername(name))[2]::uuid)
  );
