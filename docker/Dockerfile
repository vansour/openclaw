# syntax=docker/dockerfile:1.7

ARG OPENCLAW_NODE_IMAGE=node:24-trixie
ARG OPENCLAW_NODE_SLIM_IMAGE=node:24-trixie-slim
ARG OPENCLAW_DOCKER_APT_UPGRADE=1
ARG OPENCLAW_PACKAGE_MANAGER=pnpm@10.32.1

FROM ${OPENCLAW_NODE_IMAGE} AS build

ARG OPENCLAW_PACKAGE_MANAGER

RUN set -eux; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends curl ca-certificates; \
    for attempt in 1 2 3 4 5; do \
      if curl --retry 5 --retry-all-errors --retry-delay 2 -fsSL https://bun.sh/install | bash; then \
        break; \
      fi; \
      if [ "$attempt" -eq 5 ]; then \
        exit 1; \
      fi; \
      sleep $((attempt * 2)); \
    done

ENV PATH="/root/.bun/bin:${PATH}"

RUN npm install -g "${OPENCLAW_PACKAGE_MANAGER}"

WORKDIR /app

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml .npmrc ./
COPY ui/package.json ./ui/package.json
COPY patches ./patches
COPY extensions ./extensions

RUN --mount=type=cache,id=openclaw-pnpm-store,target=/root/.local/share/pnpm/store,sharing=locked \
    NODE_OPTIONS=--max-old-space-size=2048 pnpm install --frozen-lockfile

COPY . .

RUN for dir in /app/extensions /app/.agent /app/.agents; do \
      if [ -d "$dir" ]; then \
        find "$dir" -type d -exec chmod 755 {} +; \
        find "$dir" -type f -exec chmod 644 {} +; \
      fi; \
    done

RUN pnpm canvas:a2ui:bundle || \
    (echo "A2UI bundle unavailable; generating stub" && \
     mkdir -p src/canvas-host/a2ui && \
     echo "/* A2UI bundle unavailable in this build */" > src/canvas-host/a2ui/a2ui.bundle.js && \
     echo "stub" > src/canvas-host/a2ui/.bundle.hash && \
     rm -rf vendor/a2ui apps/shared/OpenClawKit/Tools/CanvasA2UI)

RUN pnpm build:docker

ARG OPENCLAW_BUILD_UI=1
ENV OPENCLAW_PREFER_PNPM=1
RUN if [ "${OPENCLAW_BUILD_UI}" = "1" ]; then \
      pnpm ui:build; \
    else \
      echo "Skipping ui:build at downstream request"; \
    fi

FROM build AS runtime-assets
RUN CI=true pnpm prune --prod && \
    find dist -type f \( -name '*.d.ts' -o -name '*.d.mts' -o -name '*.d.cts' -o -name '*.map' \) -delete

FROM ${OPENCLAW_NODE_SLIM_IMAGE} AS runtime

ARG OPENCLAW_DOCKER_APT_UPGRADE=1
ARG OPENCLAW_DOCKER_APT_PACKAGES=""
ARG OPENCLAW_INSTALL_BROWSER=0
ARG OPENCLAW_INSTALL_DOCKER_CLI=0
ARG OPENCLAW_DOCKER_GPG_FINGERPRINT=9DC858229FC7DD38854AE2D88D81803C0EBFCD88
ARG OPENCLAW_PACKAGE_MANAGER

LABEL org.opencontainers.image.source="https://github.com/vansour/openclaw" \
  org.opencontainers.image.url="https://github.com/vansour/openclaw" \
  org.opencontainers.image.documentation="https://github.com/vansour/openclaw" \
  org.opencontainers.image.licenses="MIT" \
  org.opencontainers.image.title="OpenClaw Runtime" \
  org.opencontainers.image.description="Downstream OpenClaw gateway image maintained by vansour"

WORKDIR /app

RUN --mount=type=cache,id=openclaw-trixie-apt-cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,id=openclaw-trixie-apt-lists,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    if [ "${OPENCLAW_DOCKER_APT_UPGRADE}" != "0" ]; then \
      DEBIAN_FRONTEND=noninteractive apt-get upgrade -y --no-install-recommends; \
    fi && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      procps hostname curl git lsof openssl

RUN if [ -n "${OPENCLAW_DOCKER_APT_PACKAGES}" ]; then \
      apt-get update && \
      DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ${OPENCLAW_DOCKER_APT_PACKAGES}; \
    fi

COPY --from=runtime-assets --chown=node:node /app/dist ./dist
COPY --from=runtime-assets --chown=node:node /app/node_modules ./node_modules
COPY --from=runtime-assets --chown=node:node /app/package.json .
COPY --from=runtime-assets --chown=node:node /app/openclaw.mjs .
COPY --from=runtime-assets --chown=node:node /app/extensions ./extensions
COPY --from=runtime-assets --chown=node:node /app/skills ./skills
COPY --from=runtime-assets --chown=node:node /app/docs ./docs
COPY --from=runtime-assets --chown=node:node /app/.downstream/openclaw.example.json5 ./examples/openclaw.example.json5

ENV OPENCLAW_BUNDLED_PLUGINS_DIR=/app/extensions
ENV NODE_ENV=production

RUN install -d -o node -g node /home/node/.openclaw /home/node/.openclaw/workspace /home/node/.cache/ms-playwright && \
    npm install -g "${OPENCLAW_PACKAGE_MANAGER}" && \
    ln -sf /app/openclaw.mjs /usr/local/bin/openclaw && \
    chmod 755 /app/openclaw.mjs

RUN if [ "${OPENCLAW_INSTALL_BROWSER}" = "1" ]; then \
      apt-get update && \
      DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends xvfb && \
      PLAYWRIGHT_BROWSERS_PATH=/home/node/.cache/ms-playwright \
      node /app/node_modules/playwright-core/cli.js install --with-deps chromium && \
      chown -R node:node /home/node/.cache/ms-playwright; \
    fi

RUN if [ "${OPENCLAW_INSTALL_DOCKER_CLI}" = "1" ]; then \
      apt-get update && \
      DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ca-certificates curl gnupg && \
      install -m 0755 -d /etc/apt/keyrings && \
      curl -fsSL https://download.docker.com/linux/debian/gpg -o /tmp/docker.gpg.asc && \
      expected_fingerprint="$(printf '%s' "${OPENCLAW_DOCKER_GPG_FINGERPRINT}" | tr '[:lower:]' '[:upper:]' | tr -d '[:space:]')" && \
      actual_fingerprint="$(gpg --batch --show-keys --with-colons /tmp/docker.gpg.asc | awk -F: '$1 == "fpr" { print toupper($10); exit }')" && \
      if [ -z "${actual_fingerprint}" ] || [ "${actual_fingerprint}" != "${expected_fingerprint}" ]; then \
        echo "docker apt key fingerprint mismatch" >&2; \
        exit 1; \
      fi && \
      gpg --dearmor -o /etc/apt/keyrings/docker.gpg /tmp/docker.gpg.asc && \
      rm -f /tmp/docker.gpg.asc && \
      chmod a+r /etc/apt/keyrings/docker.gpg && \
      printf 'deb [arch=%s signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian trixie stable\n' \
        "$(dpkg --print-architecture)" > /etc/apt/sources.list.d/docker.list && \
      apt-get update && \
      DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends docker-ce-cli docker-compose-plugin; \
    fi

USER node

EXPOSE 18789

HEALTHCHECK --interval=3m --timeout=10s --start-period=15s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1:18789/healthz').then((r)=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

CMD ["node", "openclaw.mjs", "gateway", "--allow-unconfigured"]
