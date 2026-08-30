-- KaamWala v2 — 0011: kw_private notification triggers -> Phase 3 parity.
-- The LIVE booking/order triggers execute the kw_private variants (robust
-- actor hardening). 0009 updated the public copies; this mirrors the Phase 3
-- bodies (action_route/data_json + system chat message on accept + client
-- payment_success) into kw_private so the live paths match.

create or replace function kw_private.notify_booking_accepted()
returns trigger language plpgsql security definer set search_path = '' as $function$
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
end $function$;

create or replace function kw_private.notify_booking_completed()
returns trigger language plpgsql security definer set search_path = '' as $function$
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
end $function$;

create or replace function kw_private.notify_order_paid()
returns trigger language plpgsql security definer set search_path = '' as $function$
declare
  v_wuid uuid;
  v_client uuid;
  v_ref text;
  v_id uuid;
begin
  if new.status = 'paid' and old.status = 'created' then
    select b.worker_id, b.client_id, b.ref, b.id
      into v_wuid, v_client, v_ref, v_id
      from public.bookings b
     where b.id = new.booking_id;
    select user_id into v_wuid from public.workers w where w.id = v_wuid;
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
end $function$;

create or replace function kw_private.notify_payout_success()
returns trigger language plpgsql security definer set search_path = '' as $function$
declare v_wuid uuid;
begin
  if new.status = 'success' and old.status <> 'success' then
    select user_id into v_wuid from public.workers w where w.id = new.worker_id;
    insert into public.notifications(user_id, type, title, body, data_json, action_route)
    values (v_wuid, 'payment',
            'Payment received',
            'Rs. ' || new.amount::text || ' sent to your account.',
            jsonb_build_object('booking_id', new.booking_id),
            '/w/earnings');
  end if;
  return new;
end $function$;
