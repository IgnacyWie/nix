export class TelegramClient {
  constructor({ token, fetchImpl = fetch }) {
    this.token = token;
    this.fetch = fetchImpl;
    this.baseUrl = `https://api.telegram.org/bot${token}`;
  }

  async call(method, payload) {
    const response = await this.fetch(`${this.baseUrl}/${method}`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify(payload),
    });
    const body = await response.json();
    if (!response.ok || !body.ok) {
      throw new Error(`Telegram ${method} failed: ${body.description ?? response.status}`);
    }
    return body.result;
  }

  getUpdates({ offset, timeout = 50 }) {
    return this.call("getUpdates", { offset, timeout, allowed_updates: ["message", "edited_message"] });
  }

  sendMessage(chatId, text) {
    return this.call("sendMessage", { chat_id: chatId, text });
  }
}
