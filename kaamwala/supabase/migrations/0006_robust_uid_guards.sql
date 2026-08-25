-- KaamWala v2 — 0006 robust uid derivation in guards (applied via MCP)
-- users_guard/workers_guard now derive the caller uid from BOTH GUC sources
-- (request.jwt.claim.sub OR request.jwt.claims->>'sub'), matching what
-- PostgREST actually populates.

create or replace function kw_private.current_uid()
returns text language sql stable set search_path = '' as $$
  select coalesce(
    nullif(current_setting('request.jwt.claim.sub', true), ''),
    nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub')
$$;

create or replace function kw_private.users_guard()
returns trigger language plpgsql set search_path = '' as $$
declare v_role text;
begin
  v_role := coalesce(current_setting('request.jwt.claims', true)::jsonb ->> 'role', '');
  if v_role = 'service_role' then return new; end if;

  if new.phone is distinct from old.phone then
    raise exception 'phone number cannot be changed';
  end if;

  if old.role is not null and new.role is distinct from old.role then
    raise exception 'role is locked and cannot be changed';
  end if;

  if kw_private.current_uid() is distinct from old.id::text then
    raise exception 'not permitted';
  end if;
  return new;
end $$;

create or replace function kw_private.workers_guard()
returns trigger language plpgsql set search_path = '' as $$
declare
  v_role text;
  v_uid text;
begin
  v_role := coalesce(current_setting('request.jwt.claims', true)::jsonb ->> 'role', '');
  v_uid := kw_private.current_uid();
  if v_role = 'service_role' or v_uid is null then return new; end if;

  if tg_op = 'INSERT' then
    new.approval_status := 'pending';
    new.rejection_reason := null;
    new.rating_avg := 0;
    new.rating_count := 0;
    if new.user_id::text <> v_uid then
      raise exception 'cannot create profile for another user';
    end if;
    return new;
  end if;

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
