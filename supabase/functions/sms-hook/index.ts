/**
 * Supabase Auth Hook: Send SMS
 * 替代 Twilio，使用阿里云短信服务发送验证码
 *
 * Supabase Auth Hook 会通过 HMAC-SHA256 签名验证请求
 * 签名在 x-webhook-signature header 中
 */

type AliyunSmsConfig = {
  accessKeyId: string;
  accessKeySecret: string;
  signName: string;
  templateCode: string;
};

type EdgeRuntimeLike = {
  waitUntil?: (promise: Promise<unknown>) => void;
};

type SmsSendResult =
  | {
      ok: true;
      bizId: string | null;
    }
  | {
      ok: false;
      status: number;
      payload: {
        error: {
          http_code: number;
          provider_code: string;
          message: string;
        };
      };
    };

function jsonResponse(status = 200, payload: Record<string, unknown> = {}): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function resolveAliyunConfig(): AliyunSmsConfig | null {
  const accessKeyId = Deno.env.get("ALIYUN_SMS_ACCESS_KEY_ID");
  const accessKeySecret = Deno.env.get("ALIYUN_SMS_ACCESS_KEY_SECRET");
  const signName = resolveSmsSignName(Deno.env.get("ALIYUN_SMS_SIGN_NAME"));
  const templateCode = Deno.env.get("ALIYUN_SMS_TEMPLATE_CODE");

  if (!accessKeyId || !accessKeySecret || !templateCode) {
    return null;
  }

  return {
    accessKeyId,
    accessKeySecret,
    signName,
    templateCode,
  };
}

export function resolveEdgeWaitUntil(runtime: unknown): ((promise: Promise<unknown>) => void) | null {
  if (!runtime || typeof runtime !== "object") return null;
  const candidate = (runtime as EdgeRuntimeLike).waitUntil;
  return typeof candidate === "function" ? candidate : null;
}

async function sendAliyunSms(
  config: AliyunSmsConfig,
  phone: string,
  otp: string,
  timeoutMs: number,
): Promise<SmsSendResult> {
  try {
    const params: Record<string, string> = {
      AccessKeyId: config.accessKeyId,
      Action: "SendSms",
      Format: "JSON",
      PhoneNumbers: phone,
      RegionId: "cn-hangzhou",
      SignName: config.signName,
      SignatureMethod: "HMAC-SHA1",
      SignatureNonce: crypto.randomUUID(),
      SignatureVersion: "1.0",
      TemplateCode: config.templateCode,
      TemplateParam: JSON.stringify({ code: otp }),
      Timestamp: new Date().toISOString().replace(/\.\d{3}Z$/, "Z"),
      Version: "2017-05-25",
    };

    const sortedKeys = Object.keys(params).sort();
    const canonicalQuery = sortedKeys
      .map((k) => `${encodeRFC3986(k)}=${encodeRFC3986(params[k])}`)
      .join("&");

    const stringToSign = `POST&${encodeRFC3986("/")}&${encodeRFC3986(canonicalQuery)}`;
    const signature = await hmacSha1(config.accessKeySecret + "&", stringToSign);
    params.Signature = signature;

    const body = Object.entries(params)
      .map(([k, v]) => `${encodeURIComponent(k)}=${encodeURIComponent(v)}`)
      .join("&");

    const response = await fetch("https://dysmsapi.aliyuncs.com/", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body,
      signal: AbortSignal.timeout(timeoutMs),
    });

    const rawText = await response.text();
    let result: Record<string, string> = {};
    try {
      result = JSON.parse(rawText);
    } catch {
      const hookError = buildAliyunHookError("ALIYUN_INVALID_RESPONSE", "SMS provider invalid response");
      return {
        ok: false,
        status: hookError.status,
        payload: hookError.payload,
      };
    }

    if (result.Code !== "OK") {
      const hookError = buildAliyunHookError(result.Code, result.Message);
      return {
        ok: false,
        status: hookError.status,
        payload: hookError.payload,
      };
    }

    return {
      ok: true,
      bizId: pickText(result.BizId) || null,
    };
  } catch (err) {
    if (err instanceof DOMException && err.name === "TimeoutError") {
      const timeoutPayload = {
        error: {
          http_code: 504,
          provider_code: "ALIYUN_TIMEOUT",
          message: "SMS provider timeout",
        },
      };
      return {
        ok: false,
        status: 504,
        payload: timeoutPayload,
      };
    }

    const hookError = buildAliyunHookError("ALIYUN_REQUEST_FAILED", (err as Error).message);
    return {
      ok: false,
      status: hookError.status,
      payload: hookError.payload,
    };
  }
}

export async function handleSmsHook(req: Request): Promise<Response> {
  // Auth Hook 只会 POST
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST",
        "Access-Control-Allow-Headers": "Content-Type, Authorization",
      },
    });
  }

  try {
    const payload = await req.json();
    console.log("SMS Hook received:", JSON.stringify(payload));

    const { phone, otp } = extractPhoneAndOtp(payload);

    if (!phone || !otp) {
      console.error("Missing phone or otp in payload");
      return jsonResponse(200, {});
    }

    const config = resolveAliyunConfig();
    if (!config) {
      console.error("Missing Aliyun SMS config");
      return jsonResponse(500, { error: { http_code: 500, message: "SMS service not configured" } });
    }

    const waitUntil = resolveEdgeWaitUntil((globalThis as Record<string, unknown>).EdgeRuntime);
    const asyncModeEnabled = pickText(Deno.env.get("SMS_HOOK_ASYNC_MODE")) === "1";
    const asyncTimeoutMs = Number.parseInt(pickText(Deno.env.get("SMS_HOOK_ASYNC_TIMEOUT_MS")) || "12000", 10);
    if (asyncModeEnabled) {
      const asyncTask = sendAliyunSms(
        config,
        phone,
        otp,
        Number.isFinite(asyncTimeoutMs) && asyncTimeoutMs > 0 ? asyncTimeoutMs : 12_000,
      )
        .then((sendResult) => {
          if (sendResult.ok) {
            console.log(`SMS sent to ${phone}, BizId: ${sendResult.bizId ?? "n/a"}`);
            return;
          }
          console.error("Aliyun SMS async error:", JSON.stringify(sendResult.payload));
        })
        .catch((error) => {
          console.error("Aliyun SMS async unexpected error:", error);
        });

      if (waitUntil) {
        waitUntil(asyncTask);
      } else {
        void asyncTask;
      }
      return jsonResponse(200, {});
    }

    const sendResult = await sendAliyunSms(config, phone, otp, 3_500);
    if (!sendResult.ok) {
      console.error("Aliyun SMS sync error:", JSON.stringify(sendResult.payload));
      return jsonResponse(sendResult.status, sendResult.payload);
    }

    console.log(`SMS sent to ${phone}, BizId: ${sendResult.bizId ?? "n/a"}`);
    return jsonResponse(200, {});
  } catch (err) {
    console.error("SMS Hook error:", err);
    return jsonResponse(500, { error: { http_code: 500, message: (err as Error).message } });
  }
}

if (import.meta.main) {
  Deno.serve(handleSmsHook);
}

export function normalizeChinaPhone(input?: string | null): string {
  const raw = (input ?? "").trim();
  return raw.replace(/^\+86/, "");
}

function pickText(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

function asRecord(value: unknown): Record<string, unknown> {
  if (value && typeof value === "object" && !Array.isArray(value)) {
    return value as Record<string, unknown>;
  }
  return {};
}

export function extractPhoneAndOtp(payload: unknown): { phone: string; otp: string } {
  const obj = asRecord(payload);
  const user = asRecord(obj.user);
  const sms = asRecord(obj.sms);

  const rawPhone = pickText(user.phone) || pickText(obj.phone) || pickText(sms.phone);
  const phone = normalizeChinaPhone(rawPhone);
  const otp =
    pickText(sms.otp) ||
    pickText(sms.token) ||
    pickText(obj.otp) ||
    pickText(obj.token) ||
    pickText(obj.code);

  return { phone, otp };
}

const FALLBACK_SIGN_NAME = "南京米斗教育科技";

export function resolveSmsSignName(envSignName?: string | null): string {
  const value = pickText(envSignName);
  return value || FALLBACK_SIGN_NAME;
}

export function shouldTreatAliyunErrorAsFatal(code?: string | null): boolean {
  const normalized = pickText(code);
  return Boolean(normalized && normalized !== "OK");
}

export function buildAliyunHookError(code?: string | null, message?: string | null): {
  status: number;
  payload: {
    error: {
      http_code: number;
      provider_code: string;
      message: string;
    };
  };
} {
  const providerCode = pickText(code) || "ALIYUN_UNKNOWN";
  const providerMessage = pickText(message) || "SMS send failed";
  const status = mapAliyunErrorStatus(providerCode);

  return {
    status,
    payload: {
      error: {
        http_code: status,
        provider_code: providerCode,
        message: providerMessage,
      },
    },
  };
}

function mapAliyunErrorStatus(code?: string | null): number {
  const normalized = pickText(code);
  if (normalized.includes("TIMEOUT")) {
    return 504;
  }
  if (normalized.includes("INVALID_RESPONSE")) {
    return 502;
  }
  if (normalized.includes("LIMIT") || normalized.includes("THROTTLE")) {
    return 429;
  }
  return 500;
}

// RFC 3986 编码
function encodeRFC3986(str: string): string {
  return encodeURIComponent(str)
    .replace(/!/g, "%21")
    .replace(/'/g, "%27")
    .replace(/\(/g, "%28")
    .replace(/\)/g, "%29")
    .replace(/\*/g, "%2A");
}

// HMAC-SHA1 签名（阿里云 API 用）
async function hmacSha1(key: string, data: string): Promise<string> {
  const encoder = new TextEncoder();
  const cryptoKey = await crypto.subtle.importKey(
    "raw",
    encoder.encode(key),
    { name: "HMAC", hash: "SHA-1" },
    false,
    ["sign"]
  );
  const sig = await crypto.subtle.sign("HMAC", cryptoKey, encoder.encode(data));
  return btoa(String.fromCharCode(...new Uint8Array(sig)));
}
