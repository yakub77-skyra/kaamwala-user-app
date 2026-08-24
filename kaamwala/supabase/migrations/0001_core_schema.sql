-- KaamWala v2 — 0001 core schema (applied 20260824104710)
create extension if not exists pgcrypto with schema extensions;
create extension if not exists pg_trgm with schema extensions;

-- ============ users ============
create table public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  phone text not null unique
    constraint users_phone_format check (phone ~ '^\+[1-9][0-9]{7,14}$'),
  name text not null default '',
  role text constraint users_role_check check (role in ('client','worker')),
  city text not null default '',
  photo_url text,
  created_at timestamptz not null default now()
);

-- ============ workers ============
create table public.workers (
  id uuid primary key default extensions.gen_random_uuid(),
  user_id uuid not null unique references public.users(id) on delete cascade,
  category text not null
    constraint workers_category_check check (category in ('plumber','electrician','painter','carpenter')),
  city text not null default '',
  area text not null default '',
  bio text not null default '' constraint workers_bio_len check (char_length(bio) <= 1000),
  skills text[] not null default '{}',
  price_min numeric(10,2) not null default 0 constraint workers_price_min_check check (price_min >= 0),
  price_max numeric(10,2) not null default 0 constraint workers_price_max_check check (price_max >= price_min),
  rating_avg numeric(3,2) not null default 0 constraint workers_rating_avg_check check (rating_avg >= 0 and rating_avg <= 5),
  rating_count int not null default 0 constraint workers_rating_count_check check (rating_count >= 0),
  is_available boolean not null default false,
  approval_status text not null default 'pending'
    constraint workers_approval_check check (approval_status in ('pending','approved','rejected')),
  rejection_reason text,
  aadhar_front_url text,
  aadhar_back_url text,
  portfolio_urls text[] not null default '{}'
    constraint workers_portfolio_max check (array_length(portfolio_urls, 1) is null or array_length(portfolio_urls, 1) <= 5),
  created_at timestamptz not null default now()
);

-- ============ bookings ============
create sequence public.booking_ref_seq start 1;

create table public.bookings (
  id uuid primary key default extensions.gen_random_uuid(),
  ref text not null unique,
  client_id uuid not null references public.users(id) on delete cascade,
  worker_id uuid not null references public.workers(id) on delete restrict,
  category text not null
    constraint bookings_category_check check (category in ('plumber','electrician','painter','carpenter')),
  description text not null constraint bookings_desc_len check (char_length(description) between 1 and 500),
  service_date date,
  time_slot text not null default '',
  address text not null constraint bookings_addr_len check (char_length(address) between 1 and 300),
  status text not null default 'pending'
    constraint bookings_status_check check (status in ('pending','accepted','traveling','arrived','in_progress','completed','cancelled','declined')),
  estimate_min numeric(10,2) not null default 0 constraint bookings_est_min_check check (estimate_min >= 0),
  estimate_max numeric(10,2) not null default 0 constraint bookings_est_max_check check (estimate_max >= estimate_min),
  booking_fee numeric(10,2) not null default 20 constraint bookings_fee_check check (booking_fee >= 0),
  commission_rate numeric(5,4) not null default 0.1000
    constraint bookings_rate_check check (commission_rate >= 0 and commission_rate <= 1),
  commission_amount numeric(10,2),
  worker_earning numeric(10,2),
  client_confirmed boolean not null default false,
  created_at timestamptz not null default now(),
  completed_at timestamptz
);

create index bookings_worker_status_idx on public.bookings (worker_id, status);
create index bookings_client_created_idx on public.bookings (client_id, created_at desc);
alter table public.bookings add constraint bookings_completed_at_required
  check ((status = 'completed') = (completed_at is not null));

-- ============ orders (Razorpay collection) ============
create table public.orders (
  id uuid primary key default extensions.gen_random_uuid(),
  booking_id uuid not null unique references public.bookings(id) on delete cascade,
  razorpay_order_id text not null unique,
  razorpay_payment_id text unique,
  amount numeric(10,2) not null constraint orders_amount_positive check (amount > 0),
  status text not null default 'created'
    constraint orders_status_check check (status in ('created','paid','failed','refunded')),
  created_at timestamptz not null default now(),
  paid_at timestamptz
);

create index orders_razorpay_order_idx on public.orders (razorpay_order_id);

-- ============ reviews ============
create table public.reviews (
  id uuid primary key default extensions.gen_random_uuid(),
  booking_id uuid not null unique references public.bookings(id) on delete cascade,
  worker_id uuid not null references public.workers(id) on delete cascade,
  client_id uuid not null references public.users(id) on delete cascade,
  rating int not null constraint reviews_rating_range check (rating between 1 and 5),
  text text not null default '' constraint reviews_text_len check (char_length(text) <= 500),
  tags text[] not null default '{}',
  created_at timestamptz not null default now()
);

create index reviews_worker_created_idx on public.reviews (worker_id, created_at desc);

-- ============ chat_messages ============
create table public.chat_messages (
  id uuid primary key default extensions.gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  sender_id uuid not null references public.users(id) on delete cascade,
  message_type text not null default 'text' constraint chat_msg_type_check check (message_type in ('text')),
  content text not null constraint chat_content_len check (char_length(content) between 1 and 1000),
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create index chat_messages_booking_created_idx on public.chat_messages (booking_id, created_at);

-- ============ payouts ============
create table public.payouts (
  id uuid primary key default extensions.gen_random_uuid(),
  booking_id uuid not null unique references public.bookings(id) on delete cascade,
  worker_id uuid not null references public.workers(id) on delete restrict,
  amount numeric(10,2) not null constraint payouts_amount_positive check (amount > 0),
  status text not null default 'pending'
    constraint payouts_status_check check (status in ('pending','processing','success','failed')),
  razorpay_payout_id text unique,
  failure_reason text,
  created_at timestamptz not null default now(),
  processed_at timestamptz
);

create index payouts_worker_idx on public.payouts (worker_id, created_at desc);

-- ============ worker_payment_info ============
create table public.worker_payment_info (
  user_id uuid primary key references public.users(id) on delete cascade,
  payout_method text not null default 'upi' constraint wpi_method_check check (payout_method in ('upi','bank')),
  upi_id text constraint wpi_upi_format check (upi_id is null or upi_id ~ '^[a-zA-Z0-9._-]{2,}@[a-zA-Z]{2,}$'),
  bank_account text,
  ifsc text constraint wpi_ifsc_format check (ifsc is null or ifsc ~ '^[A-Z]{4}0[A-Z0-9]{6}$'),
  account_holder text,
  -- Razorpay X handles (server-populated)
  rzp_contact_id text,
  rzp_fund_account_id text,
  updated_at timestamptz not null default now()
);

-- ============ notifications ============
create table public.notifications (
  id uuid primary key default extensions.gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  type text not null constraint notif_type_check check (type in ('booking','payment','system')),
  title text not null,
  body text not null default '',
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create index notifications_user_unread_idx on public.notifications (user_id, is_read) where is_read = false;

-- ============ push_tokens ============
create table public.push_tokens (
  user_id uuid not null references public.users(id) on delete cascade,
  token text not null unique,
  platform text not null default 'android' constraint pt_platform_check check (platform in ('android','ios')),
  updated_at timestamptz not null default now(),
  primary key (user_id, token)
);

-- ============ platform_config ============
create table public.platform_config (
  key text primary key,
  value jsonb not null,
  updated_at timestamptz not null default now()
);
