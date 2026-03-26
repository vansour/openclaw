#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/common.sh"

load_versions
require_cmd curl
require_cmd sha256sum
require_cmd tar

mkdir -p "${ARCHIVE_DIR}" "$(dirname -- "${SOURCE_DIR}")"

if [[ ! -f "${ARCHIVE_PATH}" ]]; then
  curl -fsSL -o "${ARCHIVE_PATH}" "${OPENCLAW_SOURCE_ARCHIVE_URL}"
fi

ACTUAL_SHA256="$(sha256sum "${ARCHIVE_PATH}" | awk '{print $1}')"
if [[ "${ACTUAL_SHA256}" != "${OPENCLAW_SOURCE_SHA256}" ]]; then
  echo "source sha256 mismatch" >&2
  echo "expected: ${OPENCLAW_SOURCE_SHA256}" >&2
  echo "actual:   ${ACTUAL_SHA256}" >&2
  exit 1
fi

TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "${TMP_ROOT}"' EXIT

tar -xzf "${ARCHIVE_PATH}" -C "${TMP_ROOT}"
TOP_DIR="$(find "${TMP_ROOT}" -mindepth 1 -maxdepth 1 -type d | head -n 1)"

if [[ -z "${TOP_DIR}" ]]; then
  echo "unable to locate extracted upstream directory" >&2
  exit 1
fi

rm -rf "${SOURCE_DIR}"
mv "${TOP_DIR}" "${SOURCE_DIR}"

printf '%s\n' "${SOURCE_DIR}"

