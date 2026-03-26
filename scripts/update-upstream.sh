#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/common.sh"

load_versions
require_cmd git
require_cmd curl
require_cmd jq
require_cmd sha256sum

LATEST_TAG="$(git ls-remote --tags "${OPENCLAW_UPSTREAM_REPO}" | awk -F/ '/refs\/tags\/v[0-9]/{print $3}' | grep -v '\^{}' | sort -V | tail -n 1)"

if [[ -z "${LATEST_TAG}" ]]; then
  echo "unable to detect latest upstream tag" >&2
  exit 1
fi

if [[ "${LATEST_TAG}" == "${OPENCLAW_VERSION}" ]]; then
  echo "already on latest upstream tag: ${OPENCLAW_VERSION}"
  exit 0
fi

ARCHIVE_URL="https://codeload.github.com/openclaw/openclaw/tar.gz/refs/tags/${LATEST_TAG}"
TMP_ARCHIVE="$(mktemp)"
trap 'rm -f "${TMP_ARCHIVE}"' EXIT

curl -fsSL -o "${TMP_ARCHIVE}" "${ARCHIVE_URL}"
NEW_SHA256="$(sha256sum "${TMP_ARCHIVE}" | awk '{print $1}')"
NEW_PACKAGE_MANAGER="$(curl -fsSL "https://raw.githubusercontent.com/openclaw/openclaw/${LATEST_TAG}/package.json" | jq -r '.packageManager')"

sed -i \
  -e "s#^OPENCLAW_VERSION=.*#OPENCLAW_VERSION=${LATEST_TAG}#" \
  -e "s#^OPENCLAW_SOURCE_ARCHIVE_URL=.*#OPENCLAW_SOURCE_ARCHIVE_URL=${ARCHIVE_URL}#" \
  -e "s#^OPENCLAW_SOURCE_SHA256=.*#OPENCLAW_SOURCE_SHA256=${NEW_SHA256}#" \
  -e "s#^OPENCLAW_PACKAGE_MANAGER=.*#OPENCLAW_PACKAGE_MANAGER=${NEW_PACKAGE_MANAGER}#" \
  "${VERSIONS_FILE}"

printf 'updated %s to %s\n' "${VERSIONS_FILE}" "${LATEST_TAG}"

