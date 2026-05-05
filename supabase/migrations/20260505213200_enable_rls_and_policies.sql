-- SEC-01: Enable RLS and ownership policies
-- Note: policies assume app user identity is represented by auth.uid()

-- USERS
alter table public.users enable row level security;

drop policy if exists users_select_own on public.users;
create policy users_select_own
  on public.users
  for select
  using (id = auth.uid());

drop policy if exists users_insert_own on public.users;
create policy users_insert_own
  on public.users
  for insert
  with check (id = auth.uid());

drop policy if exists users_update_own on public.users;
create policy users_update_own
  on public.users
  for update
  using (id = auth.uid())
  with check (id = auth.uid());

drop policy if exists users_delete_own on public.users;
create policy users_delete_own
  on public.users
  for delete
  using (id = auth.uid());

-- SOBRIETY RECORDS
alter table public.sobriety_records enable row level security;

drop policy if exists sobriety_records_select_own on public.sobriety_records;
create policy sobriety_records_select_own
  on public.sobriety_records
  for select
  using (user_id = auth.uid());

drop policy if exists sobriety_records_insert_own on public.sobriety_records;
create policy sobriety_records_insert_own
  on public.sobriety_records
  for insert
  with check (user_id = auth.uid());

drop policy if exists sobriety_records_update_own on public.sobriety_records;
create policy sobriety_records_update_own
  on public.sobriety_records
  for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists sobriety_records_delete_own on public.sobriety_records;
create policy sobriety_records_delete_own
  on public.sobriety_records
  for delete
  using (user_id = auth.uid());

-- ACHIEVEMENTS
alter table public.achievements enable row level security;

drop policy if exists achievements_select_own on public.achievements;
create policy achievements_select_own
  on public.achievements
  for select
  using (user_id = auth.uid());

drop policy if exists achievements_insert_own on public.achievements;
create policy achievements_insert_own
  on public.achievements
  for insert
  with check (user_id = auth.uid());

drop policy if exists achievements_update_own on public.achievements;
create policy achievements_update_own
  on public.achievements
  for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists achievements_delete_own on public.achievements;
create policy achievements_delete_own
  on public.achievements
  for delete
  using (user_id = auth.uid());

-- JOURNAL ENTRIES
alter table public.journal_entries enable row level security;

drop policy if exists journal_entries_select_own on public.journal_entries;
create policy journal_entries_select_own
  on public.journal_entries
  for select
  using (user_id = auth.uid());

drop policy if exists journal_entries_insert_own on public.journal_entries;
create policy journal_entries_insert_own
  on public.journal_entries
  for insert
  with check (user_id = auth.uid());

drop policy if exists journal_entries_update_own on public.journal_entries;
create policy journal_entries_update_own
  on public.journal_entries
  for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists journal_entries_delete_own on public.journal_entries;
create policy journal_entries_delete_own
  on public.journal_entries
  for delete
  using (user_id = auth.uid());

-- TRIGGERS
alter table public.triggers enable row level security;

drop policy if exists triggers_select_own on public.triggers;
create policy triggers_select_own
  on public.triggers
  for select
  using (user_id = auth.uid());

drop policy if exists triggers_insert_own on public.triggers;
create policy triggers_insert_own
  on public.triggers
  for insert
  with check (user_id = auth.uid());

drop policy if exists triggers_update_own on public.triggers;
create policy triggers_update_own
  on public.triggers
  for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists triggers_delete_own on public.triggers;
create policy triggers_delete_own
  on public.triggers
  for delete
  using (user_id = auth.uid());

-- AI CONVERSATIONS
alter table public.ai_conversations enable row level security;

drop policy if exists ai_conversations_select_own on public.ai_conversations;
create policy ai_conversations_select_own
  on public.ai_conversations
  for select
  using (user_id = auth.uid());

drop policy if exists ai_conversations_insert_own on public.ai_conversations;
create policy ai_conversations_insert_own
  on public.ai_conversations
  for insert
  with check (user_id = auth.uid());

drop policy if exists ai_conversations_update_own on public.ai_conversations;
create policy ai_conversations_update_own
  on public.ai_conversations
  for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists ai_conversations_delete_own on public.ai_conversations;
create policy ai_conversations_delete_own
  on public.ai_conversations
  for delete
  using (user_id = auth.uid());

-- FRIENDSHIPS
alter table public.friendships enable row level security;

drop policy if exists friendships_select_related on public.friendships;
create policy friendships_select_related
  on public.friendships
  for select
  using (user_id = auth.uid() or friend_id = auth.uid());

drop policy if exists friendships_insert_owner on public.friendships;
create policy friendships_insert_owner
  on public.friendships
  for insert
  with check (user_id = auth.uid());

drop policy if exists friendships_update_owner on public.friendships;
create policy friendships_update_owner
  on public.friendships
  for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists friendships_delete_owner on public.friendships;
create policy friendships_delete_owner
  on public.friendships
  for delete
  using (user_id = auth.uid());
