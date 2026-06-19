#!/usr/bin/env bash

set -Eeuo pipefail

readonly ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly TEST_DIR="$(mktemp -d)"
trap 'rm -rf -- "${TEST_DIR}"' EXIT

mkdir -p "${TEST_DIR}/bin" "${TEST_DIR}/archive/bootstrap-custom"
cp -R \
    "${ROOT_DIR}/install.sh" \
    "${ROOT_DIR}/lib" \
    "${ROOT_DIR}/modules" \
    "${ROOT_DIR}/scripts" \
    "${ROOT_DIR}/config" \
    "${TEST_DIR}/archive/bootstrap-custom/"

tar -czf "${TEST_DIR}/bootstrap.tar.gz" -C "${TEST_DIR}/archive" bootstrap-custom
cp "${ROOT_DIR}/install.sh" "${TEST_DIR}/standalone-install.sh"

cat >"${TEST_DIR}/bin/curl" <<EOF
#!/usr/bin/env bash
set -Eeuo pipefail
cat "${TEST_DIR}/bootstrap.tar.gz"
EOF
chmod +x "${TEST_DIR}/bin/curl"

output="$(
    PATH="${TEST_DIR}/bin:${PATH}" \
    BOOTSTRAP_REPO_ARCHIVE="https://example.invalid/bootstrap.tar.gz" \
    BOOTSTRAP_HOME="${TEST_DIR}/home/.local/share/bootstrap" \
    bash "${TEST_DIR}/standalone-install.sh" --dry-run openrgb
)"

grep -Fq '[bootstrap] downloading full repository archive' <<<"${output}"
grep -Fq '[bootstrap] module: openrgb' <<<"${output}"
grep -Fq 'dry-run: no files will be downloaded or changed' <<<"${output}"
[[ ! -e "${TEST_DIR}/home/.local/share/bootstrap" ]]

help_output="$(
    PATH="${TEST_DIR}/bin:${PATH}" \
    BOOTSTRAP_REPO_ARCHIVE="https://example.invalid/bootstrap.tar.gz" \
    BOOTSTRAP_HOME="${TEST_DIR}/home/.local/share/bootstrap" \
    bash "${TEST_DIR}/standalone-install.sh" --help
)"

grep -Fq 'Usage: ./install.sh' <<<"${help_output}"
[[ ! -e "${TEST_DIR}/home/.local/share/bootstrap" ]]
