export type ChatMessage = { role: "system" | "user" | "assistant"; content: string };

export type ModelCallOptions = {
  temperature?: number;
  maxTokens?: number;
};

function mustEnv(name: string): string {
  const v = Deno.env.get(name);
  if (!v) throw new Error(`missing env: ${name}`);
  return v;
}

function pickProvider(): "doubao" | "kimi" {
  const preferred = (Deno.env.get("DEFAULT_LLM") ?? "doubao").toLowerCase();
  if (preferred.includes("kimi")) return "kimi";
  return "doubao";
}

async function callKimi(messages: ChatMessage[], options: ModelCallOptions): Promise<string> {
  const apiKey = mustEnv("KIMI_API_KEY");
  const baseUrl = Deno.env.get("KIMI_BASE_URL") ?? "https://api.moonshot.cn/v1";
  const model = Deno.env.get("KIMI_MODEL") ?? "moonshot-v1-8k";

  const res = await fetch(`${baseUrl}/chat/completions`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model,
      messages,
      temperature: options.temperature ?? 0.4,
      max_tokens: options.maxTokens ?? 1024,
      stream: false,
    }),
  });

  if (!res.ok) {
    throw new Error(`MODEL_UNAVAILABLE: kimi ${res.status}`);
  }

  const payload = await res.json();
  return payload?.choices?.[0]?.message?.content ?? "";
}

async function callDoubao(messages: ChatMessage[], options: ModelCallOptions): Promise<string> {
  const apiKey = mustEnv("DOUBAO_API_KEY");
  const baseUrl = Deno.env.get("DOUBAO_BASE_URL") ?? "https://ark.cn-beijing.volces.com/api/v3";
  const model = Deno.env.get("DOUBAO_ENDPOINT_ID") ?? Deno.env.get("DOUBAO_MODEL") ?? "";

  if (!model) {
    throw new Error("missing env: DOUBAO_ENDPOINT_ID or DOUBAO_MODEL");
  }

  const res = await fetch(`${baseUrl}/chat/completions`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model,
      messages,
      temperature: options.temperature ?? 0.4,
      max_tokens: options.maxTokens ?? 1024,
      stream: false,
    }),
  });

  if (!res.ok) {
    throw new Error(`MODEL_UNAVAILABLE: doubao ${res.status}`);
  }

  const payload = await res.json();
  return payload?.choices?.[0]?.message?.content ?? "";
}

export async function callModelLive(messages: ChatMessage[], options: ModelCallOptions = {}): Promise<{ text: string; modelUsed: string }> {
  const provider = pickProvider();

  if (provider === "kimi") {
    const text = await callKimi(messages, options);
    return { text, modelUsed: Deno.env.get("KIMI_MODEL") ?? "kimi" };
  }

  const text = await callDoubao(messages, options);
  return { text, modelUsed: Deno.env.get("DOUBAO_ENDPOINT_ID") ?? Deno.env.get("DOUBAO_MODEL") ?? "doubao" };
}
