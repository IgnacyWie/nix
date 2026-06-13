# Local AI Service Stack

The `local-ai` stack is a Tier 2 Local AI Service Stack for the `eta` Home
Server. In this slice it runs Open WebUI for browser-based local chat. OMLX is
not containerized here; it remains the host-managed Local Model Runtime and is
reached through the standard local OpenAI-compatible API boundary.

## Service Definition

Run this stack on `eta` through the Service Control Command:

```sh
eta-service inspect local-ai
eta-service local-ai config
eta-service local-ai up
eta-service local-ai logs --tail=100
```

Open WebUI is routed through the Traefik Ingress Layer at:

```text
https://ai.mac.wie.dev
```

The stack joins the existing `proxy-network` network used by Traefik.

## Durable Service State

Open WebUI app configuration, users, and chat state live under the Service Data
Root:

```text
~/Services/data/local-ai/open-webui
```

This is useful Durable Service State, but the Local AI Service Stack remains
Tier 2 and is not a v1 recovery blocker.

## Required Environment

Copy the committed example and keep the real file local to `eta`:

```sh
cd ~/nix/services/eta/local-ai
cp .env.example .env
chmod 600 .env
```

Required contract:

- `OPEN_WEBUI_HOST=ai.mac.wie.dev` keeps the browser UI behind Traefik.
- `OPEN_WEBUI_AUTH=true` requires Open WebUI application authentication.
- `OPEN_WEBUI_ENABLE_SIGNUP=false` keeps public signup disabled after the owner
  account exists.
- `OMLX_OPENAI_API_BASE_URL=http://host.docker.internal:8000/v1` points Open
  WebUI at host-managed OMLX through the Docker host bridge.
- `OMLX_OPENAI_API_KEY=omlx-local-no-key` is a non-secret placeholder because
  OMLX has no API key in v1.

Never commit `.env`, chat exports, API tokens, or prompt/document content.

## Manual Verification

1. Confirm OMLX is healthy on the host:

   ```sh
   curl -fsS http://127.0.0.1:8000/health
   curl -fsS http://127.0.0.1:8000/v1/models
   ```

2. Start the stack:

   ```sh
   eta-service local-ai up
   ```

3. Open `https://ai.mac.wie.dev` through the Home Server Access Model.
4. Authenticate with the owner/admin Open WebUI account.
5. Send one short prompt and confirm it reaches OMLX.
6. Restart the Service Stack and verify the account and chat state persist under
   `~/Services/data/local-ai/open-webui`.
