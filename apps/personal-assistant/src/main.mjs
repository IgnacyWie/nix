#!/usr/bin/env node
import { handleTelegramUpdate } from "./assistant.mjs";
import { loadConfig } from "./config.mjs";
import { PiHostedConversation } from "./pi-conversation.mjs";
import { DurableState } from "./state.mjs";
import { TelegramClient } from "./telegram.mjs";

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

export async function run({ config = loadConfig(), telegram, conversation, state } = {}) {
  state ??= new DurableState(config.durableStateDir);
  state.ensure();
  telegram ??= new TelegramClient({ token: config.telegramBotToken });
  conversation ??= new PiHostedConversation(config);

  let offset = state.readOffset();
  console.error(`Personal Assistant Agent starting; durableStateDir=${config.durableStateDir}`);

  for (;;) {
    try {
      const updates = await telegram.getUpdates({ offset, timeout: 50 });
      for (const update of updates) {
        await handleTelegramUpdate({ update, config, telegram, conversation });
        offset = update.update_id + 1;
        state.writeOffset(offset);
      }
    } catch (error) {
      console.error(`Personal Assistant Agent polling error: ${error.stack ?? error.message}`);
      await sleep(5000);
    }
  }
}

if (import.meta.url === `file://${process.argv[1]}`) {
  run().catch((error) => {
    console.error(error.stack ?? error.message);
    process.exit(1);
  });
}
