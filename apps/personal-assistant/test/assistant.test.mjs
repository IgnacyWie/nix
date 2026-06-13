import assert from "node:assert/strict";
import test from "node:test";

import { handleTelegramUpdate } from "../src/assistant.mjs";
import { validateConfig } from "../src/config.mjs";

const validEnv = {
  TELEGRAM_BOT_TOKEN: "telegram-token",
  ASSISTANT_ALLOWLISTED_TELEGRAM_USER_ID: "42",
  ASSISTANT_DURABLE_STATE_DIR: "/tmp/personal-assistant-test",
  PI_MODEL_PROVIDER: "anthropic",
  PI_MODEL_ID: "claude-sonnet-4-20250514",
};

test("startup validation reports missing Assistant Secret Projection values", () => {
  assert.throws(
    () => validateConfig({}),
    /TELEGRAM_BOT_TOKEN, ASSISTANT_ALLOWLISTED_TELEGRAM_USER_ID, ASSISTANT_DURABLE_STATE_DIR, PI_MODEL_PROVIDER, PI_MODEL_ID/,
  );
});

test("unauthorized Telegram users are rejected without invoking conversation", async () => {
  const sent = [];
  const result = await handleTelegramUpdate({
    config: validateConfig(validEnv),
    update: { update_id: 1, message: { text: "hello", from: { id: 7 }, chat: { id: 100 } } },
    telegram: { sendMessage: async (chatId, text) => sent.push({ chatId, text }) },
    conversation: { reply: async () => assert.fail("conversation should not be called") },
  });

  assert.deepEqual(result, { status: "rejected" });
  assert.deepEqual(sent, [{ chatId: 100, text: "Unauthorized." }]);
});

test("allowlisted Telegram user receives hosted-model conversation reply", async () => {
  const sent = [];
  const result = await handleTelegramUpdate({
    config: validateConfig(validEnv),
    update: { update_id: 2, message: { text: "say hi", from: { id: 42 }, chat: { id: 100 } } },
    telegram: { sendMessage: async (chatId, text) => sent.push({ chatId, text }) },
    conversation: { reply: async (message) => `model reply to ${message}` },
  });

  assert.deepEqual(result, { status: "answered", answer: "model reply to say hi" });
  assert.deepEqual(sent, [{ chatId: 100, text: "model reply to say hi" }]);
});
