#!/usr/bin/env bash
set -euo pipefail

IMAGE_REF="${1:-}"
if [[ -z "${IMAGE_REF}" ]]; then
  echo "usage: $0 <image-ref>" >&2
  exit 1
fi

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "required command not found: $1" >&2
    exit 1
  fi
}

require_cmd docker
require_cmd curl

HOST_PORT="${HOST_PORT:-18789}"
CONTAINER_NAME="openclaw-smoke-$$"

cleanup() {
  docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true
}
trap cleanup EXIT

docker run -d \
  --name "${CONTAINER_NAME}" \
  -p "127.0.0.1:${HOST_PORT}:18789" \
  "${IMAGE_REF}" \
  sh -lc 'node openclaw.mjs config set gateway.controlUi.enabled false >/dev/null && exec node openclaw.mjs gateway --allow-unconfigured --bind lan' >/dev/null

for _ in $(seq 1 30); do
  if curl -fsS "http://127.0.0.1:${HOST_PORT}/healthz" >/dev/null; then
    break
  fi
  sleep 2
done

curl -fsS "http://127.0.0.1:${HOST_PORT}/healthz" >/dev/null
curl -fsS "http://127.0.0.1:${HOST_PORT}/readyz" >/dev/null
docker exec "${CONTAINER_NAME}" sh -lc 'test "$(id -u)" = "1000"'
docker exec "${CONTAINER_NAME}" sh -lc 'test -d /home/node/.openclaw && test -w /home/node/.openclaw'
docker exec "${CONTAINER_NAME}" sh -lc 'test -d /home/node/.openclaw/workspace && test -w /home/node/.openclaw/workspace'
