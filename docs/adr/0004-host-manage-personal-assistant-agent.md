# Host-manage the Personal Assistant Agent on eta

`eta` will run the Personal Assistant Agent as a host-managed macOS service rather than as a Docker Compose Service Stack. This intentionally follows the same exception pattern as OMLX: native macOS integration matters more than container uniformity, because the assistant needs Things local app automation while still presenting Telegram as its primary interaction surface.

The assistant runs as a primary-user launchd agent because its v1 task integration reads, creates, and deletes Things tasks through AppleScript. Things automation requires macOS user-session behavior and manual Automation/TCC permission grants that do not fit cleanly inside a container or system daemon.

The bootstrap slice keeps the assistant app under `apps/personal-assistant/` and runs it from the checked-out repository with Node. Its untracked `.env` is the Assistant Secret Projection: it contains the Telegram token, allowlisted Telegram user id, durable-state directory, hosted Pi model selection, and any runtime hosted-model API key projection needed by launchd. The committed `.env.example`, `.gitignore`, and gitleaks rules define the expected shape while preventing secrets from becoming repository state.

The v1 launch path intentionally disables Pi tools for general conversation. Telegram messages from the allowlisted user are answered through the configured hosted Pi model using only the message context; messages from other Telegram users receive an authorization rejection and do not reach the model.
