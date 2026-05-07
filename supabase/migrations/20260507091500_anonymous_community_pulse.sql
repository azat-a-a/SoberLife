-- COMMUNITY-01: Anonymous Community Pulse
-- Goal: allow users to feel part of a community while staying anonymous.
-- Data model stores only anonymous device-scoped check-ins and exposes aggregates via RPC.

create table if not exists public.community_checkins (
  anon_id uuid not null,
  day date not null,
  created_at timestamptz not null default now(),
  primary key (anon_id, day)
);

alter table public.community_checkins enable row level security;

-- No direct select/insert/update policies: table is write/read only via SECURITY DEFINER RPC.

create or replace function public.community_checkin()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  anon uuid;
begin
  -- Must be authenticated (keeps abuse lower; still anonymous to other users).
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  anon := gen_random_uuid();
  begin
    -- If client passes an anon_id via request.jwt.claims it can be used later,
    -- but for MVP we keep server-generated anon to avoid correlating across devices.
    null;
  end;

  insert into public.community_checkins (anon_id, day)
  values (anon, (now() at time zone 'utc')::date)
  on conflict do nothing;
end;
$$;

-- Aggregated pulse for last N days, no individual rows returned.
create or replace function public.community_pulse_last7()
returns table(day date, checkins bigint)
language sql
security definer
set search_path = public
as $$
  select c.day, count(*)::bigint as checkins
  from public.community_checkins c
  where c.day >= ((now() at time zone 'utc')::date - 6)
  group by c.day
  order by c.day asc;
$$;

revoke all on table public.community_checkins from anon, authenticated;
revoke all on function public.community_checkin() from anon, authenticated;
revoke all on function public.community_pulse_last7() from anon, authenticated;

grant execute on function public.community_checkin() to authenticated;
grant execute on function public.community_pulse_last7() to authenticated;

