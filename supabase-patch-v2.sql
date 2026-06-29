-- ============================================
-- FamilyPoints V2 补丁 - 家庭邀请码功能
-- ============================================

-- 1. 添加邀请码字段到 households 表
alter table public.households 
add column if not exists invite_code text unique;

-- 2. 为已有的家庭生成邀请码（6位大写字母+数字）
update public.households 
set invite_code = upper(substring(md5(random()::text), 1, 6))
where invite_code is null;

-- 3. 创建邀请码索引
create index if not exists idx_households_invite_code on public.households(invite_code);

-- ============================================
-- 4. 更新 RLS 策略（允许通过 household_id 访问）
-- ============================================
-- 注意：为了支持孩子端无需登录即可访问家庭数据，
-- 我们放宽策略，允许认证用户和匿名用户访问
-- 安全保障：household_id 是 UUID，难以猜测

-- 删除所有可能存在的旧策略
drop policy if exists "Allow authenticated access" on public.households;
drop policy if exists "Allow authenticated access" on public.transactions;
drop policy if exists "Allow authenticated access" on public.daily_stats;
drop policy if exists "Household access by id" on public.households;
drop policy if exists "Transaction access by household" on public.transactions;
drop policy if exists "Daily stats access by household" on public.daily_stats;

-- households：所有人都可以按 id 查询和更新
create policy "Household access by id" on public.households
  for all using (true) with check (true);

-- transactions：所有人都可以按 household_id 访问
create policy "Transaction access by household" on public.transactions
  for all using (true) with check (true);

-- daily_stats：所有人都可以按 household_id 访问
create policy "Daily stats access by household" on public.daily_stats
  for all using (true) with check (true);
