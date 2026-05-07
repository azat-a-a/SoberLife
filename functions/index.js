const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { SOS_ASSISTANT_SYSTEM_PROMPT, buildLocaleInstruction } = require("./sosPrompt");

const deepseekApiKey = defineSecret("DEEPSEEK_API_KEY");

const DEEPSEEK_URL = "https://api.deepseek.com/v1/chat/completions";
const MAX_DIALOG_MESSAGES = 36;
const MAX_CONTENT_LENGTH = 8000;

/**
 * Authenticated SOS chat → DeepSeek (server-side key only).
 * data: { messages: {role: 'user'|'assistant', content: string}[], locale?: string }
 */
exports.sosDeepseekChat = onCall(
  {
    region: "europe-west1",
    secrets: [deepseekApiKey],
    timeoutSeconds: 120,
    memory: "512MiB"
  },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Sign in required for SOS chat.");
    }

    const { messages, locale = "en" } = request.data || {};
    if (!Array.isArray(messages) || messages.length === 0) {
      throw new HttpsError("invalid-argument", "messages array required.");
    }

    const trimmed = messages
      .filter((m) => m && (m.role === "user" || m.role === "assistant") && typeof m.content === "string")
      .map((m) => ({
        role: m.role,
        content: m.content.slice(0, MAX_CONTENT_LENGTH)
      }))
      .slice(-MAX_DIALOG_MESSAGES);

    if (!trimmed.some((m) => m.role === "user")) {
      throw new HttpsError("invalid-argument", "At least one user message is required.");
    }

    const systemContent = `${SOS_ASSISTANT_SYSTEM_PROMPT}\n\n### Language\n${buildLocaleInstruction(String(locale).slice(0, 24))}`;

    const apiMessages = [{ role: "system", content: systemContent }, ...trimmed];

    const apiKey = deepseekApiKey.value();
    if (!apiKey) {
      throw new HttpsError("failed-precondition", "Assistant is not configured (missing API key).");
    }

    let res;
    try {
      res = await fetch(DEEPSEEK_URL, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${apiKey}`
        },
        body: JSON.stringify({
          model: "deepseek-chat",
          messages: apiMessages,
          temperature: 0.65,
          max_tokens: 900
        })
      });
    } catch {
      throw new HttpsError("unavailable", "Network error calling DeepSeek.");
    }

    if (!res.ok) {
      const errText = await res.text().catch(() => "");
      let snippet = "";
      try {
        const parsed = JSON.parse(errText);
        snippet = parsed.error?.message || parsed.message || "";
      } catch (_) {
        snippet = errText.slice(0, 240);
      }
      console.error("DeepSeek HTTP error", res.status, errText.slice(0, 800));

      let hint = "";
      switch (res.status) {
        case 401:
          hint =
            "DeepSeek 401: invalid API key. Set secret: firebase functions:secrets:set DEEPSEEK_API_KEY then firebase deploy --only functions.";
          break;
        case 402:
          hint = "DeepSeek 402: billing or quota. Check account at platform.deepseek.com.";
          break;
        case 403:
          hint = "DeepSeek 403: access denied. Check API key and platform status.";
          break;
        case 429:
          hint = "DeepSeek 429: rate limited. Retry in one minute.";
          break;
        default:
          hint = snippet || `HTTP ${res.status}`;
      }
      throw new HttpsError("unavailable", `Assistant unavailable — ${hint}`.slice(0, 800));
    }

    /** @type {{ choices?: { message?: { content?: string } }[] }} */
    let data;
    try {
      data = await res.json();
    } catch {
      throw new HttpsError("internal", "Invalid response from DeepSeek.");
    }

    const reply = data?.choices?.[0]?.message?.content?.trim();
    if (!reply) {
      console.error("DeepSeek empty choices", JSON.stringify(data).slice(0, 1500));
      throw new HttpsError("internal", "Empty assistant reply from model.");
    }

    return { reply };
  }
);
