#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/common.sh"

load_versions
require_cmd git

"${SCRIPT_DIR}/fetch-upstream.sh" >/dev/null

mkdir -p "$(dirname -- "${CONTEXT_DIR}")"
rm -rf "${CONTEXT_DIR}"
mkdir -p "${CONTEXT_DIR}"
cp -a "${SOURCE_DIR}/." "${CONTEXT_DIR}/"
cp "${REPO_ROOT}/docker/upstream.dockerignore" "${CONTEXT_DIR}/.dockerignore"

shopt -s nullglob
for patch in "${REPO_ROOT}"/patches/*.patch; do
  git -C "${CONTEXT_DIR}" apply --3way "${patch}"
done

printf '%s\n' "${CONTEXT_DIR}"
