-- ============================================
-- EDGELOG PRO — SUPABASE SCHEMA
-- Run this in: Supabase Dashboard > SQL Editor
-- ============================================

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- ============================================
-- PROFILES
-- ============================================
create table if not exists profiles (
  id uuid references auth.users on delete cascade primary key,
  email text,
  full_name text,
  account_balance numeric(12,2) default 100.00,
  starting_balance numeric(12,2) default 100.00,
  risk_per_trade numeric(5,2) default 1.00,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table profiles enable row level security;
create policy "Users can view own profile" on profiles for select using (auth.uid() = id);
create policy "Users can update own profile" on profiles for update using (auth.uid() = id);
create policy "Users can insert own profile" on profiles for insert with check (auth.uid() = id);

-- ============================================
-- STRATEGIES
-- ============================================
create table if not exists strategies (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references auth.users on delete cascade not null,
  name text not null,
  description text,
  rules jsonb default '[]'::jsonb,
  timeframes text[] default '{}',
  pairs text[] default '{}',
  active boolean default true,
  created_at timestamptz default now()
);

alter table strategies enable row level security;
create policy "Users can manage own strategies" on strategies for all using (auth.uid() = user_id);

-- ============================================
-- TRADES
-- ============================================
create table if not exists trades (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references auth.users on delete cascade not null,
  trade_id text not null,
  strategy_id uuid references strategies on delete set null,
  strategy_name text,
  pair text not null,
  direction text check (direction in ('BUY', 'SELL')) not null,
  entry_price numeric(12,5) not null,
  sl_price numeric(12,5),
  tp_price numeric(12,5),
  lot_size numeric(10,2) not null default 0.01,
  entry_time timestamptz not null,
  exit_time timestamptz,
  exit_price numeric(12,5),
  pnl numeric(12,2),
  pips numeric(10,1),
  status text check (status in ('OPEN', 'CLOSED', 'CANCELLED')) default 'OPEN',
  outcome text check (outcome in ('WIN', 'LOSS', 'BREAKEVEN')),
  discipline_score integer check (discipline_score >= 0 and discipline_score <= 100),
  discipline_notes text,
  setup_notes text,
  rule_violations text[] default '{}',
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(user_id, trade_id)
);

alter table trades enable row level security;
create policy "Users can manage own trades" on trades for all using (auth.uid() = user_id);

-- ============================================
-- SCREENSHOTS
-- ============================================
create table if not exists screenshots (
  id uuid default uuid_generate_v4() primary key,
  trade_id uuid references trades on delete cascade not null,
  user_id uuid references auth.users on delete cascade not null,
  url text not null,
  type text check (type in ('analysis', 'confirmation', 'entry', 'outcome')) not null,
  timeframe text,
  ai_extracted boolean default false,
  created_at timestamptz default now()
);

alter table screenshots enable row level security;
create policy "Users can manage own screenshots" on screenshots for all using (auth.uid() = user_id);

-- ============================================
-- PROTOCOL STATE
-- ============================================
create table if not exists protocol_state (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references auth.users on delete cascade unique not null,
  daily_loss numeric(12,2) default 0,
  daily_trades integer default 0,
  weekly_loss numeric(12,2) default 0,
  last_reset_date timestamptz default now(),
  locked_until timestamptz,
  lock_reason text,
  updated_at timestamptz default now()
);

alter table protocol_state enable row level security;
create policy "Users can manage own protocol" on protocol_state for all using (auth.uid() = user_id);

-- ============================================
-- AUTO-CREATE PROFILE + PROTOCOL ON SIGNUP
-- ============================================
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, full_name)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1))
  )
  on conflict (id) do nothing;

  insert into public.protocol_state (user_id)
  values (new.id)
  on conflict (user_id) do nothing;

  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ============================================
-- STORAGE BUCKET (run if not created via UI)
-- ============================================
-- insert into storage.buckets (id, name, public) values ('screenshots', 'screenshots', true)
-- on conflict (id) do nothing;

-- create policy "Public screenshot access" on storage.objects for select using (bucket_id = 'screenshots');
-- create policy "Authenticated users can upload" on storage.objects for insert with check (bucket_id = 'screenshots' and auth.role() = 'authenticated');
-- create policy "Users can delete own screenshots" on storage.objects for delete using (bucket_id = 'screenshots' and auth.uid()::text = (storage.foldername(name))[1]);
