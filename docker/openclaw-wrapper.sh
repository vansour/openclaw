#!/bin/sh
set -eu

OPENCLAW_HOME="${HOME:-/home/node}"
export HOME="${OPENCLAW_HOME}"
export USER="${USER:-node}"
export LOGNAME="${LOGNAME:-node}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-${OPENCLAW_HOME}/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-${OPENCLAW_HOME}/.cache}"
export OPENCLAW_STATE_DIR="${OPENCLAW_STATE_DIR:-${OPENCLAW_HOME}/.openclaw}"
export OPENCLAW_CONFIG_PATH="${OPENCLAW_CONFIG_PATH:-${OPENCLAW_STATE_DIR}/openclaw.json}"

if [ "$(id -u)" -eq 0 ]; then
  NODE_UID="$(id -u node)"
  NODE_GID="$(id -g node)"
  exec setpriv --reuid "${NODE_UID}" --regid "${NODE_GID}" --init-groups \
    node /app/openclaw.mjs "$@"
fi

exec node /app/openclaw.mjs "$@"
