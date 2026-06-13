export function messageTextFromUpdate(update) {
  return update?.message?.text ?? update?.edited_message?.text ?? "";
}

export function telegramUserIdFromUpdate(update) {
  return update?.message?.from?.id ?? update?.edited_message?.from?.id;
}

export function chatIdFromUpdate(update) {
  return update?.message?.chat?.id ?? update?.edited_message?.chat?.id;
}

export async function handleTelegramUpdate({ update, config, telegram, conversation }) {
  const chatId = chatIdFromUpdate(update);
  const userId = telegramUserIdFromUpdate(update);
  const text = messageTextFromUpdate(update).trim();

  if (!chatId || !userId || !text) return { status: "ignored" };

  if (userId !== config.allowlistedTelegramUserId) {
    await telegram.sendMessage(chatId, "Unauthorized.");
    return { status: "rejected" };
  }

  const answer = await conversation.reply(text);
  await telegram.sendMessage(chatId, answer);
  return { status: "answered", answer };
}
