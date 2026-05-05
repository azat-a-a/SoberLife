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
- In Progress:
- Blockers:
- Decisions:
- Next:

## 2026-05-07 (Thursday)
- Done:
- In Progress:
- Blockers:
- Decisions:
- Next:

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

