#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
VERSIONS_FILE="${REPO_ROOT}/versions/openclaw.env"

load_versions() {
  if [[ ! -f "${VERSIONS_FILE}" ]]; then
    echo "missing versions file: ${VERSIONS_FILE}" >&2
    exit 1
  fi

  set -a
  # shellcheck disable=SC1090
  . "${VERSIONS_FILE}"
  set +a

  CACHE_DIR="${REPO_ROOT}/.cache"
  ARCHIVE_DIR="${CACHE_DIR}/archives"
  SOURCE_DIR="${CACHE_DIR}/sources/openclaw-${OPENCLAW_VERSION}"
  CONTEXT_DIR="${CACHE_DIR}/contexts/openclaw-${OPENCLAW_VERSION}"
  ARCHIVE_PATH="${ARCHIVE_DIR}/openclaw-${OPENCLAW_VERSION}.tar.gz"
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "required command not found: $1" >&2
    exit 1
  fi
}

