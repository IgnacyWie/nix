# Local AI Service Stack

The `local-ai` stack is a Tier 2 Local AI Service Stack for the `eta` Home
Server. It runs Open WebUI for browser-based local chat and Paperless-AI for
AI-assisted Paperless metadata workflows. OMLX is not containerized here; it
remains the host-managed Local Model Runtime and is reached through the standard
local OpenAI-compatible API boundary.

Paperless remains the Tier 1 Paperless Service Stack. Paperless-AI consumes
Paperless through its API and may write AI-written document metadata, but adding
Paperless-AI here does not promote Local AI to Tier 1 and does not make Local AI
a v1 recovery blocker.

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

Paperless-AI has a useful setup/manual-processing UI and is routed through
Traefik at:

```text
https://paperless-ai.mac.wie.dev
```

The stack joins the existing `proxy-network` network used by Traefik.

## Durable Service State

Open WebUI app configuration, users, and chat state live under the Service Data
Root:

```text
~/Services/data/local-ai/open-webui
```

Paperless-AI app configuration, login state, processing history, and optional
RAG data live under:

```text
~/Services/data/local-ai/paperless-ai
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

Open WebUI contract:

- `OPEN_WEBUI_HOST=ai.mac.wie.dev` keeps the browser UI behind Traefik.
- `OPEN_WEBUI_AUTH=true` requires Open WebUI application authentication.
- `OPEN_WEBUI_ENABLE_SIGNUP=false` keeps public signup disabled after the owner
  account exists. For first bootstrap on empty Open WebUI state, temporarily set
  this to `true`, create the owner/admin account, then set it back to `false`
  and restart the stack.
- `OMLX_OPENAI_API_BASE_URL=http://host.docker.internal:8000/v1` points Open
  WebUI at host-managed OMLX through the Docker host bridge.
- `OMLX_OPENAI_API_KEY=omlx-local-no-key` is a non-secret placeholder because
  OMLX has no API key in v1.

Paperless-AI contract:

- `PAPERLESS_AI_HOST=paperless-ai.mac.wie.dev` routes the Paperless-AI UI through
  Traefik.
- `PAPERLESS_AI_PAPERLESS_API_URL=http://paperless-webserver-1:8000/api` points
  at the Tier 1 Paperless Service Stack over the shared `proxy-network` Docker
  network. `https://documents.mac.wie.dev/api` also works when Traefik is
  healthy, but the internal URL avoids an unnecessary Ingress Layer round trip.
- `PAPERLESS_AI_PAPERLESS_USERNAME` and `PAPERLESS_AI_PAPERLESS_API_TOKEN` must
  be a dedicated Paperless user/token for Paperless-AI, stored in the Secret
  Store and projected only into the untracked `.env` on `eta`.
- `PAPERLESS_AI_PROVIDER=custom`, `OMLX_OPENAI_API_BASE_URL`,
  `OMLX_OPENAI_API_KEY`, and `PAPERLESS_AI_OMLX_MODEL` wire Paperless-AI to the
  host-managed OMLX OpenAI-compatible API through `host.docker.internal`.
- `PAPERLESS_AI_API_KEY` and `PAPERLESS_AI_JWT_SECRET` must be replaced with long
  random values. Paperless-AI supports login/JWT sessions after initial setup
  and API-key authentication for API calls.
- If the Paperless-AI setup UI writes settings to
  `~/Services/data/local-ai/paperless-ai/.env`, copy the Paperless and custom AI
  values back into this stack `.env` using the `PAPERLESS_AI_*` names above, then
  recreate the container. Compose environment values override Paperless-AI's
  persisted `/app/data/.env` values.
- `PAPERLESS_AI_ADD_AI_PROCESSED_TAG=yes` and
  `PAPERLESS_AI_PROCESSED_TAG_NAME=ai-written-metadata` visibly mark
  AI-written document metadata for later audits.
- `PAPERLESS_AI_RAG_SERVICE_ENABLED=false` keeps the optional RAG path disabled
  until intentionally enabled; metadata assistance does not require it.

Never commit `.env`, chat exports, API tokens, Paperless credentials, or
prompt/document content.

## Manual Verification

1. Confirm OMLX is healthy on the host:

   ```sh
   curl -fsS http://127.0.0.1:8000/health
   curl -fsS http://127.0.0.1:8000/v1/models
   ```

2. Create or recover the dedicated Paperless-AI Paperless user and API token in
   the Paperless UI. Store it in the Secret Store and put it in `.env` on `eta`.
3. Start the stack:

   ```sh
   eta-service local-ai up
   ```

4. If this is a fresh Open WebUI data directory, temporarily allow first-account
   creation:

   ```sh
   perl -0pi -e 's/OPEN_WEBUI_ENABLE_SIGNUP=false/OPEN_WEBUI_ENABLE_SIGNUP=true/' .env
   eta-service local-ai up
   ```

5. Open `https://ai.mac.wie.dev` through the Home Server Access Model and create
   the owner/admin account.
6. Disable further Open WebUI signup and restart:

   ```sh
   perl -0pi -e 's/OPEN_WEBUI_ENABLE_SIGNUP=true/OPEN_WEBUI_ENABLE_SIGNUP=false/' .env
   eta-service local-ai up
   ```

7. Authenticate with the owner/admin Open WebUI account.
8. Send one short prompt and confirm it reaches OMLX.
9. Open `https://paperless-ai.mac.wie.dev` through the Home Server Access Model,
   complete Paperless-AI setup if prompted, and confirm its login flow is active.
10. Confirm Paperless-AI can read a Paperless document through the dedicated
    token at `http://paperless-webserver-1:8000/api` and can reach OMLX through
    the custom OpenAI-compatible provider. If
    logs show Paperless `401` responses after changing `.env`, recreate the
    container rather than only restarting it:

    ```sh
    eta-service local-ai up --force-recreate paperless-ai
    ```
11. If allowing a metadata write, verify the resulting AI-written metadata is
    marked with `ai-written-metadata` or another configured audit tag.
12. Restart the Service Stack and verify Open WebUI state persists under
    `~/Services/data/local-ai/open-webui` and Paperless-AI state persists under
    `~/Services/data/local-ai/paperless-ai`.
