// deno-lint-ignore-file no-explicit-any
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

type ChatMessage = {
  role: "system" | "user" | "assistant";
  content: string;
  timestamp?: string;
};

type RequestBody = {
  user_id?: string;
  conversation_type?: "chat" | "sos" | "daily" | "analysis";
  messages?: ChatMessage[];
  context?: Record<string, unknown>;
  messages_json?: string;
  context_json?: string;
};

function parseMessages(body: RequestBody): ChatMessage[] {
  if (Array.isArray(body.messages)) return body.messages;
  if (typeof body.messages_json === "string") {
    try {
      const parsed = JSON.parse(body.messages_json);
      if (Array.isArray(parsed)) return parsed;
    } catch {
      return [];
    }
  }
  return [];
}

function parseContext(body: RequestBody): Record<string, unknown> {
  if (body.context && typeof body.context === "object") return body.context;
  if (typeof body.context_json === "string") {
    try {
      const parsed = JSON.parse(body.context_json);
      if (parsed && typeof parsed === "object") return parsed;
    } catch {
      return {};
    }
  }
  return {};
}

function safeLogMetadata(body: RequestBody, messages: ChatMessage[]) {
  console.log(
    JSON.stringify({
      event: "deepseek-chat-request",
      user_id: body.user_id ?? "unknown",
      conversation_type: body.conversation_type ?? "chat",
      message_count: messages.length,
      total_chars: messages.reduce((acc, m) => acc + (m.content?.length ?? 0), 0),
    }),
  );
}

async function fetchWithRetry(
  url: string,
  init: RequestInit,
  retries = 2,
): Promise<Response> {
  let attempt = 0;
  let lastError: unknown = null;

  while (attempt <= retries) {
    try {
      const response = await fetch(url, init);
      if (response.status === 429 || response.status >= 500) {
        if (attempt === retries) return response;
        const backoffMs = 300 * Math.pow(2, attempt);
        await new Promise((resolve) => setTimeout(resolve, backoffMs));
        attempt += 1;
        continue;
      }
      return response;
    } catch (error) {
      lastError = error;
      if (attempt === retries) throw error;
      const backoffMs = 300 * Math.pow(2, attempt);
      await new Promise((resolve) => setTimeout(resolve, backoffMs));
      attempt += 1;
    }
  }

  throw lastError ?? new Error("Unknown retry failure");
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const deepseekApiKey = Deno.env.get("DEEPSEEK_API_KEY");
  if (!deepseekApiKey) {
    return new Response(JSON.stringify({ error: "DeepSeek key is not configured" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  try {
    const body = (await req.json()) as RequestBody;
    const messages = parseMessages(body);
    const context = parseContext(body);
    safeLogMetadata(body, messages);

    const systemPrompt =
      "You are a caring, empathetic sobriety support assistant for adults working on alcohol use. " +
      "Never shame, blame, or moralize. Use warm, plain language. Normalize difficulty and praise help-seeking. " +
      "Keep replies concise. Offer 1–3 practical next steps (breathing, water, movement, contacting someone safe). " +
      "If the user expresses imminent self-harm, wanting to die, or plans to hurt someone, do not try to solve the crisis alone: " +
      "urge them to contact local emergency services or a crisis line immediately and keep your message brief and supportive. " +
      "You are not a clinician; encourage professional care when appropriate without sounding dismissive.";

    const sosAddendum = body.conversation_type === "sos"
      ? " This is an SOS/craving moment: prioritize grounding, safety, and connection over analysis."
      : "";

    const deepseekMessages = [
      { role: "system", content: systemPrompt + sosAddendum },
      { role: "system", content: `User context: ${JSON.stringify(context)}` },
      ...messages.map((m) => ({ role: m.role, content: m.content })),
    ];

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort("timeout"), 12_000);

    const response = await fetchWithRetry(
      "https://api.deepseek.com/chat/completions",
      {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${deepseekApiKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model: "deepseek-chat",
          messages: deepseekMessages,
          temperature: 0.4,
          max_tokens: 400,
        }),
        signal: controller.signal,
      },
      2,
    );
    clearTimeout(timeoutId);

    if (!response.ok) {
      const text = await response.text();
      console.error("deepseek-error", response.status, text.slice(0, 500));
      return new Response(JSON.stringify({ error: "DeepSeek request failed" }), {
        status: 502,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const payload = await response.json();
    const reply = payload?.choices?.[0]?.message?.content;
    if (!reply || typeof reply !== "string") {
      return new Response(JSON.stringify({ error: "Invalid DeepSeek response" }), {
        status: 502,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const suggestedActions = body.conversation_type === "sos"
      ? [
        "Ten slow breaths: in 4, hold 2, out 6",
        "Sip water and pause for one minute",
        "Text or call one person who feels safe",
      ]
      : [];

    const riskFlags = body.conversation_type === "sos" ? ["craving"] : [];

    return new Response(
      JSON.stringify({
        reply,
        suggested_actions_json: JSON.stringify(suggestedActions),
        risk_flags_json: JSON.stringify(riskFlags),
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (error) {
    console.error("deepseek-chat-fatal", error);
    return new Response(JSON.stringify({ error: "Unhandled server error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
