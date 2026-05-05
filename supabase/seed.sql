-- SoberLife MVP seed data (development/stage only)

insert into public.users (
  id, apple_id, name, avatar_url, sobriety_start_date, daily_alcohol_cost
) values
  (
    '11111111-1111-1111-1111-111111111111',
    'apple-seed-user-1',
    'Seed User',
    null,
    now() - interval '14 days',
    850.00
  )
on conflict (apple_id) do nothing;

insert into public.sobriety_records (
  id, user_id, start_date, end_date, is_current
) values
  (
    '22222222-2222-2222-2222-222222222222',
    '11111111-1111-1111-1111-111111111111',
    now() - interval '14 days',
    null,
    true
  )
on conflict (id) do nothing;

insert into public.achievements (
  id, user_id, type, unlocked_at
) values
  (
    '33333333-3333-3333-3333-333333333333',
    '11111111-1111-1111-1111-111111111111',
    '7days',
    now() - interval '7 days'
  )
on conflict (user_id, type) do nothing;

insert into public.journal_entries (
  id, user_id, content, mood
) values
  (
    '44444444-4444-4444-4444-444444444444',
    '11111111-1111-1111-1111-111111111111',
    'Today was hard in the evening, but I made it through.',
    'struggling'
  ),
  (
    '44444444-4444-4444-4444-444444444445',
    '11111111-1111-1111-1111-111111111111',
    'Morning felt clearer than usual. Proud of progress.',
    'good'
  )
on conflict (id) do nothing;

insert into public.triggers (
  id, user_id, trigger_type, description, intensity
) values
  (
    '55555555-5555-5555-5555-555555555555',
    '11111111-1111-1111-1111-111111111111',
    'event',
    'After-work gathering with alcohol.',
    8
  )
on conflict (id) do nothing;

insert into public.ai_conversations (
  id, user_id, messages, conversation_type
) values
  (
    '66666666-6666-6666-6666-666666666666',
    '11111111-1111-1111-1111-111111111111',
    '[
      {"role":"user","content":"It is difficult tonight.","timestamp":"2026-05-05T18:00:00Z"},
      {"role":"assistant","content":"You are not alone. Let us do one breathing cycle together.","timestamp":"2026-05-05T18:00:06Z"}
    ]'::jsonb,
    'sos'
  )
on conflict (id) do nothing;
