-- ============================================
-- FamilyPoints Supabase Schema (完整版)
-- 家庭积分成长系统 V3.0 数据库设计
-- ============================================

-- ============================================
-- 1. households 表（家庭账户）
-- ============================================
create table if not exists public.households (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz default now(),
  user_id uuid references auth.users(id) on delete cascade,
  name text not null default '我们家',
  balance bigint not null default 0,
  child_name text not null default '小明',
  daily_earn_limit int not null default 30,
  weekday_spend_limit int not null default 20,
  interest_rate numeric(3,2) not null default 0.02,
  last_interest_date text
);

create index if not exists idx_households_user_id on public.households(user_id);

-- ============================================
-- 2. transactions 表（积分流水）
-- ============================================
create table if not exists public.transactions (
  id bigint primary key generated always as identity,
  household_id uuid not null references public.households(id) on delete cascade,
  created_at timestamptz default now(),
  category text not null check (category in ('earn', 'spend')),
  action text not null,
  points int not null,
  balance_after bigint not null,
  note text
);

create index if not exists idx_transactions_household_id on public.transactions(household_id);
create index if not exists idx_transactions_created_at on public.transactions(created_at desc);

-- ============================================
-- 3. daily_stats 表（每日统计）
-- ============================================
create table if not exists public.daily_stats (
  id bigint primary key generated always as identity,
  household_id uuid not null references public.households(id) on delete cascade,
  date text not null,
  earned_today int not null default 0,
  spent_today int not null default 0,
  make_bed_count int default 0,
  swim_count int default 0,
  reading_count int default 0,
  exercise_count int default 0,
  piano_count int default 0,
  early_sleep_count int default 0,
  chores_sweep_count int default 0,
  chores_mop_count int default 0,
  chores_dishes_count int default 0,
  chores_trash_count int default 0,
  chores_wipe_count int default 0,
  snack_count int default 0,
  late_sleep_count int default 0,
  unique(household_id, date)
);

create index if not exists idx_daily_stats_household_date on public.daily_stats(household_id, date);

-- ============================================
-- 4. Row Level Security (RLS)
-- ============================================
-- 注意：当前策略为宽松策略，所有认证用户可读写所有数据
-- 正式上线建议改为按 user_id 隔离：
--   using (auth.uid() = user_id) with check (auth.uid() = user_id)

alter table public.households enable row level security;
alter table public.transactions enable row level security;
alter table public.daily_stats enable row level security;

-- 清理旧策略（如果存在）
drop policy if exists "Allow authenticated access" on public.households;
drop policy if exists "Allow authenticated access" on public.transactions;
drop policy if exists "Allow authenticated access" on public.daily_stats;

-- 创建策略
create policy "Allow authenticated access" on public.households
  for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

create policy "Allow authenticated access" on public.transactions
  for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

create policy "Allow authenticated access" on public.daily_stats
  for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

-- ============================================
-- 5. Realtime 订阅
-- ============================================
-- 确保 publication 存在
drop publication if exists supabase_realtime;
create publication supabase_realtime;

-- 添加表到 publication
alter publication supabase_realtime add table public.households;
alter publication supabase_realtime add table public.transactions;
alter publication supabase_realtime add table public.daily_stats;

-- ============================================
-- 6. 测试数据（可选）
-- ============================================
-- 注册后会自动创建家庭，不需要手动插入
-- 如果需要手动测试，先在 Auth 里创建用户，然后：
-- INSERT INTO public.households (user_id, name, child_name, balance) 
-- VALUES ('你的用户UUID', '我们家', '小明', 0);
