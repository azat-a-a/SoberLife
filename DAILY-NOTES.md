# Daily Notes

Use this file for short daily execution logs.

Template:
```md
## YYYY-MM-DD (Day)
- Done:
- In Progress:
- Blockers:
- Decisions:
- Next:
```

---

## 2026-05-05 (Tuesday)
- Done:
  - **DATA-SYNC-01:** синк онбординга и honesty/relapse в Supabase (`SobrietySupabaseSync`, `SobrietyCloudSync`, `ensure_user_profile` перед PATCH, JWT через `SessionState`, баннер ошибки на табах).
  - **RELI-01:** явная обработка `401` и офлайна на критическом пути (`SessionState.handleUnauthorizedSession`, доработки `AIChatState` / `SobrietyCloudSync` / ensure profile, офлайн-копия в SOS), тест на разлогин.
  - **REL-02:** таймлайн трезвых периодов на Stats (`SobrietyPeriodSummary`, `SobrietyJourney.periodSummaries`), скролл на экране Stats, тесты порядка периодов и сохранения майлстоунов после рецидива без дублей.
  - Репозиторий: коммиты запушены на `origin/main` (в т.ч. `feat(REL-02): …`).
- In Progress:
  - Нет.
- Blockers:
  - Ранее: PR в `main` невозможен, пока на GitHub не существует ветка `main` / не выбрана как default; сейчас `main` на remote есть, default обновлён (см. процесс в чате).
- Decisions:
  - См. `DECISIONS.md` — D-010 … D-012 (слой Core vs AppShell, 401, таймлайн периодов).
- Next:
  - **PUSH-02** (тихие часы и настройки уведомлений) или **IOS-APP-01** (Xcode target / TestFlight), по приоритету продукта.

## 2026-05-06 (Wednesday)
- Done:
  - **DB-02:** паритет облака для профиля/прогресса (миграции `notification_preferences`, `support_contacts`; `UserSettingsCloudSync` / `AchievementsCloudSync`; гидратация таймлайна из `sobriety_records`; майлстоуны как `achievements`) — см. `MIGRATION-PLAN-S07.md`, задача в `TASKS.md`.
  - **Пакет Sprint 05–06:** метаданные App Store (`APP-STORE-METADATA-S05.md`), переключатель языка в профиле (**I18N-02**), усиление TestFlight (**REL-01**), закрытый бета-гейт (**BETA-01**), баг-бёрндаун (**BUG-01**), расширенный языковой пакет (**I18N-03**, `I18N-COVERAGE-S06.md`), аналитика baseline (**DATA-01**, `ANALYTICS.md`), регрессия **QA-02** / смоук **QA-01**.
- In Progress:
  - Нет (к вечеру дня — перенос фокуса на полевую проверку DB-02 и документы Sprint 07).
- Blockers:
  - Нет.
- Decisions:
  - **D-014** (email/password Supabase) — см. `DECISIONS.md`.
- Next:
  - Полевой выкат и чеклист **OPS-DB02-ROLLOUT**; прогон **QA-SYNC-S07**; **I18N-REVIEW-S07**.

## 2026-05-07 (Thursday)
- Done:
  - **OPS-01 / Gate 0:** `OPS-DB02-ROLLOUT.md` закрыт полностью (staging + production, матрица клиента, completion record; P0/P1 по синку не зафиксированы).
  - **S07-01:** `QA-SYNC-S07.md` + `QA-SYNC-S07-RESULTS.md` — полный проход, статус Passed; `I18N-REVIEW-S07.md` — Completed, блокеров нет (опциональный native pass по `I18N-COVERAGE-S06.md`).
  - **Документация:** обновлены `LAUNCH-CHECKLIST.md` (строка DB-02), `SPRINT-07.md` (прогресс), `TASKS.md` (OPS-01, S07-01 → Done); коммит на `main`: `docs: close DB-02 rollout, sync QA, and Sprint 07 sign-offs` (`d8db6b5`).
- In Progress:
  - Нет.
- Blockers:
  - Нет.
- Decisions:
  - **D-015** (аналитика logging-only до Sprint 08); **D-016** — приём закрытия Gate 0 + QA-03 + I18N-04 Sprint 07 — см. `DECISIONS.md`.
- Next:
  - Pre-Beta по `LAUNCH-CHECKLIST.md`; фокус Sprint 08 (запуск vs глубина); решение по вендору аналитики (**D-008**) после постановки приватности/App Store.

## 2026-05-08 (Friday)
- Done:
- In Progress:
- Blockers:
- Decisions:
- Next:

## 2026-05-09 (Saturday)
- Done:
- In Progress:
- Blockers:
- Decisions:
- Next:

## 2026-05-10 (Sunday)
- Done:
- In Progress:
- Blockers:
- Decisions:
- Next:

## 2026-05-11 (Monday)
- Done:
- In Progress:
- Blockers:
- Decisions:
- Next:

## 2026-05-12 (Tuesday)
- Done:
- In Progress:
- Blockers:
- Decisions:
- Next:

## 2026-05-13 (Wednesday)
- Done:
- In Progress:
- Blockers:
- Decisions:
- Next:

## 2026-05-14 (Thursday)
- Done:
- In Progress:
- Blockers:
- Decisions:
- Next:

## 2026-05-15 (Friday)
- Done:
- In Progress:
- Blockers:
- Decisions:
- Next:

## 2026-05-16 (Saturday)
- Done:
- In Progress:
- Blockers:
- Decisions:
- Next:

## 2026-05-17 (Sunday)
- Done:
- In Progress:
- Blockers:
- Decisions:
- Next:

## 2026-05-18 (Monday)
- Done:
- In Progress:
- Blockers:
- Decisions:
- Next:

## 2026-05-19 (Tuesday)
- Done:
- In Progress:
- Blockers:
- Decisions:
- Next:

