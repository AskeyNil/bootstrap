#!/usr/bin/env bash

set -Eeuo pipefail

readonly ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

output="$(
    BOOTSTRAP_DRY_RUN=1 \
    OPENRGB_SOURCE_FILE=/tmp/OpenRGB.AppImage \
    bash "${ROOT_DIR}/install.sh" --dry-run shell openrgb
)"

grep -Fq '[bootstrap] module: shell' <<<"${output}"
grep -Fq '[bootstrap] module: openrgb' <<<"${output}"
grep -Fq 'dry-run: no files will be downloaded or changed' <<<"${output}"
