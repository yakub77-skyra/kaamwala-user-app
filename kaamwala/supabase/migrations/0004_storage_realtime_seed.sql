-- KaamWala v2 - 0004 storage + realtime + seed (applied 20260824105132)

insert into storage.buckets (id, name, public)
values ('profiles', 'profiles', true) on conflict (id) do nothing;
insert into storage.buckets (id, name, public)
values ('portfolios', 'portfolios', true) on conflict (id) do nothing;
insert into storage.buckets (id, name, public)
values ('aadhar_scans', 'aadhar_scans', false) on conflict (id) do nothing;

create policy profiles_public_read on storage.objects for select
  using (bucket_id = 'profiles');
create policy portfolios_public_read on storage.objects for select
  using (bucket_id = 'portfolios');

create policy profiles_owner_insert on storage.objects for insert to authenticated
  with check (bucket_id = 'profiles' and (storage.foldername(name))[1] = auth.uid()::text);
create policy profiles_owner_update on storage.objects for update to authenticated
  using (bucket_id = 'profiles' and (storage.foldername(name))[1] = auth.uid()::text);
create policy profiles_owner_delete on storage.objects for delete to authenticated
  using (bucket_id = 'profiles' and (storage.foldername(name))[1] = auth.uid()::text);

create policy portfolios_owner_insert on storage.objects for insert to authenticated
  with check (bucket_id = 'portfolios' and (storage.foldername(name))[1] = auth.uid()::text);
create policy portfolios_owner_update on storage.objects for update to authenticated
  using (bucket_id = 'portfolios' and (storage.foldername(name))[1] = auth.uid()::text);
create policy portfolios_owner_delete on storage.objects for delete to authenticated
  using (bucket_id = 'portfolios' and (storage.foldername(name))[1] = auth.uid()::text);

-- Aadhar scans: NO select policy => invisible to anon/authenticated.
create policy aadhar_owner_insert on storage.objects for insert to authenticated
  with check (bucket_id = 'aadhar_scans' and (storage.foldername(name))[1] = auth.uid()::text);
create policy aadhar_owner_update on storage.objects for update to authenticated
  using (bucket_id = 'aadhar_scans' and (storage.foldername(name))[1] = auth.uid()::text);

alter publication supabase_realtime add table public.bookings;
alter publication supabase_realtime add table public.chat_messages;
alter publication supabase_realtime add table public.orders;

insert into public.platform_config (key, value) values
  ('booking_fee_rupees', '20'),
  ('commission_rate', '0.10'),
  ('max_portfolio_photos', '5'),
  ('otp_max_resends_per_hour', '3'),
  ('admin_user_ids', '[]'::jsonb)
on conflict (key) do nothing;
