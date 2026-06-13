import fs from "node:fs";
import path from "node:path";

const REQUIRED = [
  "TELEGRAM_BOT_TOKEN",
  "ASSISTANT_ALLOWLISTED_TELEGRAM_USER_ID",
  "ASSISTANT_DURABLE_STATE_DIR",
  "PI_MODEL_PROVIDER",
  "PI_MODEL_ID",
];

export function loadEnvFile(filePath) {
  if (!fs.existsSync(filePath)) return {};

  const result = {};
  for (const line of fs.readFileSync(filePath, "utf8").split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) continue;
    const match = trimmed.match(/^([A-Za-z_][A-Za-z0-9_]*)=(.*)$/);
    if (!match) continue;
    const [, key, rawValue] = match;
    result[key] = rawValue.replace(/^['"]|['"]$/g, "");
  }
  return result;
}

export function validateConfig(env) {
  const missing = REQUIRED.filter((key) => !String(env[key] ?? "").trim());
  if (missing.length > 0) {
    throw new Error(`Personal Assistant Agent missing required configuration: ${missing.join(", ")}`);
  }

  const allowlistedTelegramUserId = Number(env.ASSISTANT_ALLOWLISTED_TELEGRAM_USER_ID);
  if (!Number.isSafeInteger(allowlistedTelegramUserId) || allowlistedTelegramUserId <= 0) {
    throw new Error("Personal Assistant Agent configuration invalid: ASSISTANT_ALLOWLISTED_TELEGRAM_USER_ID must be a positive integer");
  }

  const durableStateDir = path.resolve(env.ASSISTANT_DURABLE_STATE_DIR);
  return {
    telegramBotToken: env.TELEGRAM_BOT_TOKEN,
    allowlistedTelegramUserId,
    durableStateDir,
    piModelProvider: env.PI_MODEL_PROVIDER,
    piModelId: env.PI_MODEL_ID,
    piThinkingLevel: env.PI_THINKING_LEVEL || "off",
  };
}

export function loadConfig({ env = process.env, envFile = path.join(process.cwd(), ".env") } = {}) {
  return validateConfig({ ...env, ...loadEnvFile(envFile) });
}
