-- ============================================
-- FamilyPoints 数据库补丁
-- 给已有的 households 表添加 user_id 字段
-- ============================================

-- 1. 添加 user_id 字段
alter table public.households 
add column if not exists user_id uuid references auth.users(id) on delete cascade;

-- 2. 添加索引
create index if not exists idx_households_user_id on public.households(user_id);

-- 3. 重新设置 RLS 策略（如果之前已创建会报错，可以忽略）
do $$
begin
  if not exists (
    select 1 from pg_policies 
    where tablename = 'households' and policyname = 'Allow authenticated access'
  ) then
    create policy "Allow authenticated access" on public.households
      for all using (true) with check (true);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from pg_policies 
    where tablename = 'transactions' and policyname = 'Allow authenticated access'
  ) then
    create policy "Allow authenticated access" on public.transactions
      for all using (true) with check (true);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from pg_policies 
    where tablename = 'daily_stats' and policyname = 'Allow authenticated access'
  ) then
    create policy "Allow authenticated access" on public.daily_stats
      for all using (true) with check (true);
  end if;
end
$$;

-- 4. Realtime（如果之前已添加会报错，可以忽略）
alter publication supabase_realtime add table public.households;
alter publication supabase_realtime add table public.transactions;
alter publication supabase_realtime add table public.daily_stats;
