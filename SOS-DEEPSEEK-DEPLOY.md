# SOS assistant (DeepSeek on Firebase Functions)

The SOS chat invokes the **`sosDeepseekChat`** callable (`functions/index.js`). The DeepSeek API key lives only in Firebase Secret Manager (`DEEPSEEK_API_KEY`).

System prompt and localization rules live in **`functions/sosPrompt.js`**.

## One-time deploy

Requires **Blaze** for Cloud Functions.

```bash
cd functions && npm install && cd ..
firebase functions:secrets:set DEEPSEEK_API_KEY
firebase deploy --only functions
firebase deploy --only hosting
```

Use your DeepSeek keys from https://platform.deepseek.com .

## Region alignment

Callable is deployed to **`europe-west1`** (see `functions/index.js`). The web app reads `firebaseFunctionsRegion` from **`public/firebase-config.js`**; keep them identical.

## Если в чате «Помощник недоступен» или generic-ошибка

1. **Откройте консоль браузера** (Safari/WebKit: Develop → Show Web Inspector → Console). При ошибке там будет строка **`[SOS sosDeepseekChat]`** с `code` и `message`.

2. **`functions/not-found`** — приложение дергает не тот регион, или функцию не деплоили. Выровняйте `region` и `firebaseFunctionsRegion`, затем:
   ```bash
   firebase deploy --only functions
   firebase deploy --only hosting
   ```

3. **`failed-precondition` / missing API key** — не задан секрет или не перезадеплоили после `secrets:set`:
   ```bash
   firebase functions:secrets:set DEEPSEEK_API_KEY
   firebase deploy --only functions
   ```

4. В чате теперь может появиться текст с **`DeepSeek 401`** — ключ неверный; **`402`** — баланс/квота; **`429`** — лимиты, повторите позже.

5. Функции требуют **Blaze** и аккаунт **DeepSeek** с рабочим API key.
