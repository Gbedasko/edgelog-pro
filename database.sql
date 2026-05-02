-- ═══════════════════════════════════════════════
-- EdgeLog Pro — Database Schema
-- Run this in Supabase SQL Editor
-- https://supabase.com/dashboard/project/tjefloldgvrvqpdilaxv/sql/new
-- ═══════════════════════════════════════════════

-- Profiles
create table if not exists profiles (
  id uuid references auth.users on delete cascade primary key,
  name text,
  account_size decimal(12,2),
  timezone text default 'Africa/Lagos',
  trading_window_start time default '07:00:00',
  trading_window_end time default '18:00:00',
  created_at timestamptz default now()
);

-- Strategies
create table if not exists strategies (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users on delete cascade not null,
  name text not null,
  timeframes text[] default '{}',
  confluences jsonb default '[]',
  rules jsonb default '{}',
  is_default boolean default false,
  created_at timestamptz default now()
);

-- Trades
create table if not exists trades (
  id text primary key,
  user_id uuid references auth.users on delete cascade not null,
  strategy_id uuid references strategies(id) on delete set null,
  strategy_name text,
  pair text not null,
  direction text check (direction in ('BUY','SELL')),
  entry_price decimal(10,5),
  stop_loss decimal(10,5),
  take_profit decimal(10,5),
  close_price decimal(10,5),
  lot_size decimal(8,4),
  rr_ratio decimal(6,2),
  r_result decimal(6,2),
  pnl_dollar decimal(10,2),
  outcome text check (outcome in ('win','loss','breakeven','open','manual_close')) default 'open',
  trade_date date,
  entry_time time,
  close_date date,
  close_time time,
  session text,
  bias text,
  timeframes_used text[] default '{}',
  confluence_score integer,
  discipline_score integer,
  ai_verdict text,
  is_rule_violation boolean default false,
  violation_reasons text[] default '{}',
  mistake_tags text[] default '{}',
  notes text,
  within_trading_window boolean,
  sl_moved boolean default false,
  tp_changed boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Screenshots
create table if not exists screenshots (
  id uuid primary key default gen_random_uuid(),
  trade_id text references trades(id) on delete cascade,
  user_id uuid references auth.users on delete cascade not null,
  type text check (type in ('analysis','confirm','entry','outcome')) not null,
  timeframe text,
  storage_url text not null,
  ai_extracted jsonb,
  confidence text check (confidence in ('HIGH','MEDIUM','LOW')),
  created_at timestamptz default now()
);

-- Audit log (immutable — never delete or update rows)
create table if not exists audit_log (
  id uuid primary key default gen_random_uuid(),
  trade_id text,
  user_id uuid references auth.users not null,
  action text not null,
  field_name text,
  old_value text,
  new_value text,
  reason text,
  ai_approved boolean,
  created_at timestamptz default now()
);

-- Protocol state
create table if not exists protocol_state (
  user_id uuid references auth.users primary key,
  streak integer default 0,
  compliant integer default 0,
  violations integer default 0,
  resets integer default 0,
  updated_at timestamptz default now()
);

-- ═══ Enable Row Level Security ═══
alter table profiles enable row level security;
alter table strategies enable row level security;
alter table trades enable row level security;
alter table screenshots enable row level security;
alter table audit_log enable row level security;
alter table protocol_state enable row level security;

-- ═══ RLS Policies ═══
create policy "profiles_own" on profiles for all using (auth.uid() = id);
create policy "strategies_own" on strategies for all using (auth.uid() = user_id);
create policy "trades_own" on trades for all using (auth.uid() = user_id);
create policy "screenshots_own" on screenshots for all using (auth.uid() = user_id);
create policy "audit_log_own" on audit_log for all using (auth.uid() = user_id);
create policy "protocol_own" on protocol_state for all using (auth.uid() = user_id);

-- ═══ Indexes for performance ═══
create index if not exists idx_trades_user on trades(user_id);
create index if not exists idx_trades_date on trades(trade_date desc);
create index if not exists idx_screenshots_trade on screenshots(trade_id);
create index if not exists idx_audit_trade on audit_log(trade_id);
