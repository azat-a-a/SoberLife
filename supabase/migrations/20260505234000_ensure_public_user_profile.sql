-- Keep public.users in sync with auth.users for FK targets (ai_conversations, etc.)

create or replace function public.handle_auth_user_insert()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.users (id, apple_id, name, created_at)
  values (
    NEW.id,
    coalesce(
      NEW.raw_user_meta_data->>'sub',
      NEW.raw_user_meta_data->>'provider_id',
      NEW.id::text
    ),
    coalesce(
      NEW.raw_user_meta_data->>'full_name',
      NEW.raw_user_meta_data->>'name'
    ),
    now()
  )
  on conflict (id) do nothing;
  return NEW;
end;
$$;

drop trigger if exists soberlife_on_auth_user_created on auth.users;
create trigger soberlife_on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_auth_user_insert();

-- Idempotent: safe to call after every sign-in (backfill if trigger missed older accounts)
create or replace function public.ensure_user_profile()
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  au record;
begin
  select id, raw_user_meta_data, email into au from auth.users where id = auth.uid();
  if not found then
    return;
  end if;

  insert into public.users (id, apple_id, name, created_at)
  values (
    au.id,
    coalesce(
      au.raw_user_meta_data->>'sub',
      au.raw_user_meta_data->>'provider_id',
      au.email,
      au.id::text
    ),
    coalesce(
      au.raw_user_meta_data->>'full_name',
      au.raw_user_meta_data->>'name'
    ),
    now()
  )
  on conflict (id) do update set
    name = coalesce(excluded.name, public.users.name);
end;
$$;

grant execute on function public.ensure_user_profile() to authenticated;
