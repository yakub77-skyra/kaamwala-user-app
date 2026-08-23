-- KaamWala v2 - Migration 0001: Tables & Indexes
-- Source: Phase 3 section 7 (Database Schema + ERD)
-- Run in Supabase SQL Editor or via `supabase db push`.

-- ============ TABLES ============

create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  phone text unique not null,
  name text default '',
  role text not null default 'client' check (role in ('client','worker')),
  city text default '',
  photo_url text,
  created_at timestamptz not null default now()
);

create table if not exists public.workers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid unique not null references public.users(id) on delete cascade,
  category text not null check (category in ('plumber','electrician','painter','carpenter')),
  city text default '',
  area text default '',
  bio text default '',
  skills text[] default '{}',
  price_min numeric(10,2) default 0,
  price_max numeric(10,2) default 0,
  rating_avg numeric(3,2) not null default 0,
  rating_count int not null default 0,
  is_available boolean not null default false,
  approval_status text not null default 'pending' check (approval_status in ('pending','approved','rejected')),
  rejection_reason text,
  aadhar_front_url text,
  aadhar_back_url text,
  portfolio_urls text[] default '{}',
  created_at timestamptz not null default now()
);

create table if not exists public.bookings (
  id uuid primary key default gen_random_uuid(),
  ref text unique not null default ('KW-' || to_char(now(),'YYYY') || '-' || lpad((floor(random()*9000)+1000)::text, 4, '0')),
  client_id uuid not null references public.users(id) on delete cascade,
  worker_id uuid not null references public.workers(id) on delete restrict,
  category text not null,
  description text not null check (char_length(description) <= 500),
  service_date date,
  time_slot text default '',
  address text default '',
  status text not null default 'pending' check (status in ('pending','accepted','traveling','arrived','in_progress','completed','cancelled','declined')),
  estimate_min numeric(10,2),
  estimate_max numeric(10,2),
  booking_fee numeric(10,2) not null default 20,
  commission_rate numeric(4,2) not null default 0.10,
  commission_amount numeric(10,2),
  worker_earning numeric(10,2),
  client_confirmed boolean not null default false,
  created_at timestamptz not null default now(),
  completed_at timestamptz
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid unique not null references public.bookings(id) on delete cascade,
  razorpay_order_id text,
  razorpay_payment_id text,
  amount numeric(10,2) not null default 20,
  status text not null default 'CREATED' check (status in ('CREATED','PAID','FAILED','REFUNDED')),
  created_at timestamptz not null default now(),
  paid_at timestamptz
);

create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid unique not null references public.bookings(id) on delete cascade,
  worker_id uuid not null references public.workers(id) on delete cascade,
  client_id uuid not null references public.users(id) on delete cascade,
  rating int not null check (rating between 1 and 5),
  text text default '' check (char_length(text) <= 500),
  tags text[] default '{}',
  created_at timestamptz not null default now()
);

create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  sender_id uuid not null references public.users(id) on delete cascade,
  message_type text not null default 'text',
  content text not null,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.payouts (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid unique not null references public.bookings(id) on delete cascade,
  worker_id uuid not null references public.workers(id) on delete restrict,
  amount numeric(10,2) not null,
  status text not null default 'PENDING' check (status in ('PENDING','PROCESSING','SUCCESS','FAILED')),
  razorpay_payout_id text,
  created_at timestamptz not null default now(),
  processed_at timestamptz
);

create table if not exists public.worker_payment_info (
  user_id uuid primary key references public.users(id) on delete cascade,
  payout_method text not null default 'upi' check (payout_method in ('upi','bank')),
  upi_id text,
  bank_account text,
  ifsc text,
  account_holder text,
  updated_at timestamptz not null default now()
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  type text not null default 'system' check (type in ('booking','payment','system')),
  title text not null default '',
  body text not null default '',
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.push_tokens (
  user_id uuid primary key references public.users(id) on delete cascade,
  token text not null,
  platform text not null default 'android',
  updated_at timestamptz not null default now()
);

create table if not exists public.platform_config (
  key text primary key,
  value jsonb not null
);

insert into public.platform_config (key, value) values
  ('booking_fee', '20'),
  ('commission_rate', '0.10')
on conflict (key) do nothing;

-- ============ INDEXES (Phase 3 section 7.2 / NFR-SCAL-02) ============

create index if not exists idx_bookings_worker_status on public.bookings(worker_id, status);
create index if not exists idx_bookings_client_created on public.bookings(client_id, created_at desc);
create index if not exists idx_workers_discovery on public.workers(category, city, approval_status, is_available);
create index if not exists idx_workers_rating on public.workers(rating_avg desc);
create index if not exists idx_reviews_worker_created on public.reviews(worker_id, created_at desc);
create index if not exists idx_chat_booking_created on public.chat_messages(booking_id, created_at);
create index if not exists idx_notifications_unread on public.notifications(user_id, is_read);
