-- KaamWala v2 — 0005 admin verification queue (applied via MCP)

create or replace function public.admin_pending_workers()
returns table (
  id uuid,
  user_id uuid,
  name text,
  photo_url text,
  phone text,
  category text,
  city text,
  area text,
  bio text,
  skills text[],
  price_min numeric,
  price_max numeric,
  portfolio_urls text[],
  aadhar_front_url text,
  aadhar_back_url text,
  created_at timestamptz
)
language sql stable security definer set search_path = public as $$
  select w.id, w.user_id, u.name, u.photo_url, u.phone,
         w.category, w.city, w.area, w.bio, w.skills,
         w.price_min, w.price_max, w.portfolio_urls,
         w.aadhar_front_url, w.aadhar_back_url, w.created_at
    from public.workers w
    join public.users u on u.id = w.user_id
   where w.approval_status = 'pending'
     and coalesce(
           current_setting('request.jwt.claims', true)::jsonb ->> 'sub', ''
         ) in (
           select jsonb_array_elements_text(value)
             from public.platform_config
            where key = 'admin_user_ids'
         )
   order by w.created_at asc;
$$;

revoke execute on function public.admin_pending_workers() from public, anon;
grant execute on function public.admin_pending_workers() to authenticated;
