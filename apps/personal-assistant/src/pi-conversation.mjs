export class PiHostedConversation {
  constructor(config) {
    this.config = config;
  }

  async reply(message) {
    const [{ getModel }, sdk] = await Promise.all([
      import("@earendil-works/pi-ai"),
      import("@earendil-works/pi-coding-agent"),
    ]);
    const { AuthStorage, createAgentSession, ModelRegistry, SessionManager, SettingsManager } = sdk;

    const authStorage = AuthStorage.create();
    const modelRegistry = ModelRegistry.create(authStorage);
    const model = modelRegistry.find(this.config.piModelProvider, this.config.piModelId)
      ?? getModel(this.config.piModelProvider, this.config.piModelId);
    if (!model) {
      throw new Error(`Configured Pi model not found: ${this.config.piModelProvider}/${this.config.piModelId}`);
    }

    const chunks = [];
    const { session } = await createAgentSession({
      cwd: process.cwd(),
      model,
      thinkingLevel: this.config.piThinkingLevel,
      authStorage,
      modelRegistry,
      tools: [],
      sessionManager: SessionManager.inMemory(process.cwd()),
      settingsManager: SettingsManager.inMemory({ compaction: { enabled: false } }),
    });

    try {
      session.subscribe((event) => {
        if (event.type === "message_update" && event.assistantMessageEvent.type === "text_delta") {
          chunks.push(event.assistantMessageEvent.delta);
        }
      });
      await session.prompt(`Answer as a concise personal assistant. Use only this message context; do not access external data.\n\nUser: ${message}`);
      return chunks.join("").trim() || "I do not have a response.";
    } finally {
      session.dispose();
    }
  }
}
