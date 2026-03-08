import { strict as assert } from "node:assert";

import {
  buildAliyunHookError,
  extractPhoneAndOtp,
  normalizeChinaPhone,
  resolveEdgeWaitUntil,
  resolveSmsSignName,
  shouldTreatAliyunErrorAsFatal,
} from "./index.ts";

Deno.test("normalizeChinaPhone strips +86 prefix", () => {
  assert.equal(normalizeChinaPhone("+8613800138000"), "13800138000");
  assert.equal(normalizeChinaPhone("13800138000"), "13800138000");
});

Deno.test("extractPhoneAndOtp supports supabase sms hook payload", () => {
  const parsed = extractPhoneAndOtp({
    user: { phone: "+8613800138000" },
    sms: { otp: "123456" },
  });

  assert.equal(parsed.phone, "13800138000");
  assert.equal(parsed.otp, "123456");
});

Deno.test("extractPhoneAndOtp supports token fallback fields", () => {
  const parsed = extractPhoneAndOtp({
    phone: "+8613800138000",
    sms: { token: "654321" },
  });

  assert.equal(parsed.phone, "13800138000");
  assert.equal(parsed.otp, "654321");
});

Deno.test("resolveSmsSignName prefers configured env value", () => {
  assert.equal(resolveSmsSignName("阿里云签名"), "阿里云签名");
});

Deno.test("aliyun rate-limit errors are fatal for auth hook", () => {
  assert.equal(shouldTreatAliyunErrorAsFatal("isv.BUSINESS_LIMIT_CONTROL"), true);
});

Deno.test("buildAliyunHookError maps limit code to 429 and keeps message", () => {
  const result = buildAliyunHookError("isv.BUSINESS_LIMIT_CONTROL", "too many requests");

  assert.equal(result.status, 429);
  assert.equal(result.payload.error.http_code, 429);
  assert.equal(result.payload.error.provider_code, "isv.BUSINESS_LIMIT_CONTROL");
  assert.equal(result.payload.error.message, "too many requests");
});

Deno.test("resolveEdgeWaitUntil returns callable when runtime provides waitUntil", () => {
  let called = false;
  const waitUntil = resolveEdgeWaitUntil({
    waitUntil: (_promise: Promise<unknown>) => {
      called = true;
    },
  });

  assert.equal(typeof waitUntil, "function");
  waitUntil?.(Promise.resolve());
  assert.equal(called, true);
});
