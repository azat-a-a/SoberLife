-- DB-02 MIG-0701 / MIG-0702: per-user notification preferences and SOS contact (cloud parity)

create table if not exists public.notification_preferences (
  user_id uuid primary key references public.users(id) on delete cascade,
  daily_enabled boolean not null default true,
  milestone_enabled boolean not null default true,
  reengagement_enabled boolean not null default true,
  daily_reminder_hour int not null default 10 check (daily_reminder_hour between 0 and 23),
  daily_reminder_minute int not null default 0 check (daily_reminder_minute between 0 and 59),
  quiet_hours_start int check (quiet_hours_start between 0 and 23),
  quiet_hours_end int check (quiet_hours_end between 0 and 23),
  updated_at timestamptz not null default now()
);

create table if not exists public.support_contacts (
  user_id uuid primary key references public.users(id) on delete cascade,
  trusted_name text,
  trusted_phone text,
  updated_at timestamptz not null default now()
);

create or replace function public.touch_row_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists notification_preferences_touch_updated_at on public.notification_preferences;
create trigger notification_preferences_touch_updated_at
  before update on public.notification_preferences
  for each row execute function public.touch_row_updated_at();

drop trigger if exists support_contacts_touch_updated_at on public.support_contacts;
create trigger support_contacts_touch_updated_at
  before update on public.support_contacts
  for each row execute function public.touch_row_updated_at();

alter table public.notification_preferences enable row level security;

drop policy if exists notification_preferences_select_own on public.notification_preferences;
create policy notification_preferences_select_own
  on public.notification_preferences
  for select
  using (user_id = auth.uid());

drop policy if exists notification_preferences_insert_own on public.notification_preferences;
create policy notification_preferences_insert_own
  on public.notification_preferences
  for insert
  with check (user_id = auth.uid());

drop policy if exists notification_preferences_update_own on public.notification_preferences;
create policy notification_preferences_update_own
  on public.notification_preferences
  for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists notification_preferences_delete_own on public.notification_preferences;
create policy notification_preferences_delete_own
  on public.notification_preferences
  for delete
  using (user_id = auth.uid());

alter table public.support_contacts enable row level security;

drop policy if exists support_contacts_select_own on public.support_contacts;
create policy support_contacts_select_own
  on public.support_contacts
  for select
  using (user_id = auth.uid());

drop policy if exists support_contacts_insert_own on public.support_contacts;
create policy support_contacts_insert_own
  on public.support_contacts
  for insert
  with check (user_id = auth.uid());

drop policy if exists support_contacts_update_own on public.support_contacts;
create policy support_contacts_update_own
  on public.support_contacts
  for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists support_contacts_delete_own on public.support_contacts;
create policy support_contacts_delete_own
  on public.support_contacts
  for delete
  using (user_id = auth.uid());
