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
