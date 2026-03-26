# vansour/openclaw

This repository maintains a downstream Docker packaging workflow for OpenClaw.

It does not track the full upstream Git history. Instead, it pins a tested upstream release, downloads the source archive, applies any local patches, and builds a reproducible gateway image.

Because this repository targets a headless deployment, the example runtime flow disables `gateway.controlUi.enabled` before starting the gateway on a non-loopback bind.

## Scope

- Maintain a long-lived OpenClaw runtime image.
- Pin upstream releases and base-image digests.
- Keep local changes minimal and auditable.
- Publish a gateway-oriented image rather than a customized web distribution.

## Current baseline

- Upstream release: `v2026.3.24`
- Base builder image: `node:25-trixie`
- Base runtime image: `node:25-trixie-slim`
- Package manager: `pnpm@10.32.1`

## Layout

- `versions/openclaw.env`: upstream and image pins
- `docker/Dockerfile`: downstream runtime image build
- `docker/compose.example.yml`: minimal runtime example
- `docker/openclaw.example.json5`: sample headless gateway config with `vansour-openai` plus Telegram
- `docker/.env.example`: credentials template for local compose runs
- `scripts/fetch-upstream.sh`: download and verify upstream source archive
- `scripts/prepare-context.sh`: expand source and apply local patches
- `scripts/smoke-test.sh`: health and permission smoke checks

## Build

```bash
make build
```

This will:

1. Download the pinned upstream OpenClaw source archive.
2. Verify its SHA-256 checksum.
3. Prepare a clean Docker build context under `.cache/contexts/`.
4. Build the image with the pinned `node:25-trixie` images.

## vansour-openai + Telegram template

Use [openclaw.example.json5](/root/github/openclaw/docker/openclaw.example.json5) as the base config when you want:

- your `https://newapi.vansour.net/v1` OpenAI-compatible endpoint
- forced `openai-responses` mode
- Telegram bot ingress via long polling

Key points:

- Set `models.providers.<id>.baseUrl` to your endpoint URL.
- Set `models.providers.<id>.apiKey` from an environment variable or SecretRef.
- Force `models.providers.<id>.api = "openai-responses"`.
- Set each model entry to `api: "openai-responses"` as well.
- Point `agents.defaults.model.primary` at `provider/model`.

This repository's example is already wired for:

- provider id: `vansour-openai`
- base URL: `https://newapi.vansour.net/v1`
- model id: `gpt-5.4`
- env vars: `VANSOUR_OPENAI_API_KEY` and `TELEGRAM_BOT_TOKEN`
- Telegram DM policy: `pairing`
- Telegram groups: allowed, but require mention by default

The Compose example already includes:

- `VANSOUR_OPENAI_API_KEY`
- `TELEGRAM_BOT_TOKEN`
- `OPENCLAW_CONFIG_PATH=/home/node/.openclaw/openclaw.json`
- `OPENCLAW_STATE_DIR=/home/node/.openclaw`
- host bind mounts under `./data/config` and `./data/workspace`
- first-start bootstrap from the template baked into the image
- startup as `root` only long enough to fix bind-mount permissions, then drop back to `node`
- explicit `HOME=/home/node` plus XDG env so runtime state does not leak into `/root/.openclaw`

Recommended runtime flow:

1. Copy [docker/.env.example](/root/github/openclaw/docker/.env.example) to a real `.env` file near your compose run and fill both tokens.
2. Start the stack with Compose. On first start, the image copies its baked-in template to `./data/config/openclaw.json`.
3. If you need to customize limits or policies, edit `./data/config/openclaw.json` after the first boot.
4. On first Telegram DM, approve pairing with `openclaw pairing list telegram` and `openclaw pairing approve telegram <CODE>`.

Before first boot, you can lay out the deployment directory like this:

```text
.
├── compose.yaml
└── data
    ├── config
    │   └── workspace
    └── workspace
```

After the first boot, OpenClaw writes `data/config/openclaw.json` automatically.

The extra `data/config/workspace` directory is expected when you bind-mount both `./data/config` to `/home/node/.openclaw` and `./data/workspace` to `/home/node/.openclaw/workspace`.

## Smoke test

```bash
make smoke
```

The smoke test expects an already-built local image matching `IMAGE_REF`. It disables Control UI before starting the gateway so the non-loopback bind is valid in a headless deployment.

## Publish

```bash
make publish
```

By default this pushes `ghcr.io/vansour/openclaw:${OPENCLAW_VERSION}-${OPENCLAW_IMAGE_REVISION}` for `linux/amd64,linux/arm64`.

## Upgrade flow

```bash
./scripts/update-upstream.sh
make build
make smoke
```

When the upstream version changes, review `versions/openclaw.env`, refresh any local patches, and only then publish a new image revision.
