#!/usr/bin/env bash

set -Eeuo pipefail

readonly ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

output="$(
    BOOTSTRAP_OS=macos \
    bash "${ROOT_DIR}/install.sh" --dry-run
)"

grep -Fq '[bootstrap] detected OS: macos' <<<"${output}"
grep -Fq '[bootstrap] module: base' <<<"${output}"
grep -Fq '[bootstrap] installing brew packages:' <<<"${output}"
grep -Fq '[bootstrap] module: shell' <<<"${output}"
! grep -Fq '[bootstrap] module: docker' <<<"${output}"
! grep -Fq '[bootstrap] module: openrgb' <<<"${output}"

explicit_output="$(
    BOOTSTRAP_OS=macos \
    bash "${ROOT_DIR}/install.sh" --dry-run docker openrgb
)"

grep -Fq 'docker module is skipped on macOS' <<<"${explicit_output}"
grep -Fq 'openrgb module is skipped on macOS' <<<"${explicit_output}"
