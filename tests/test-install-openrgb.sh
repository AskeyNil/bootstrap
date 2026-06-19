#!/usr/bin/env bash

set -Eeuo pipefail

readonly ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly TEST_DIR="$(mktemp -d)"
trap 'rm -rf -- "${TEST_DIR}"' EXIT

mkdir -p "${TEST_DIR}/bin" "${TEST_DIR}/home"

cat >"${TEST_DIR}/bin/curl" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail

[[ "${FAIL_IF_CALLED:-0}" != "1" ]] || {
    printf 'curl must not be called during dry-run\n' >&2
    exit 99
}

destination=""
while (($#)); do
    if [[ "$1" == "--output" ]]; then
        destination="$2"
        shift 2
        continue
    fi
    shift
done

[[ -n "${destination}" ]]
cp /bin/true "${destination}"
chmod +x "${destination}"
EOF
chmod +x "${TEST_DIR}/bin/curl"

cat >"${TEST_DIR}/bin/sudo" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail

[[ "${FAIL_IF_CALLED:-0}" != "1" ]] || {
    printf 'sudo must not be called during dry-run\n' >&2
    exit 99
}

if [[ "${1:-}" == "--" ]]; then
    shift
fi
exec "$@"
EOF
chmod +x "${TEST_DIR}/bin/sudo"

cat >"${TEST_DIR}/bin/dpkg-query" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail

if [[ -n "${FAKE_FUSE_STATE:-}" ]]; then
    [[ -e "${FAKE_FUSE_STATE}" ]] && printf 'installed'
    exit 0
fi
exec /usr/bin/dpkg-query "$@"
EOF
chmod +x "${TEST_DIR}/bin/dpkg-query"

cat >"${TEST_DIR}/bin/apt-cache" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail

if [[ -n "${FAKE_FUSE_STATE:-}" ]]; then
    [[ "${1:-}" == "show" && "${2:-}" == "libfuse2t64" ]]
    exit
fi
exec /usr/bin/apt-cache "$@"
EOF
chmod +x "${TEST_DIR}/bin/apt-cache"

cat >"${TEST_DIR}/bin/apt-get" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail

if [[ -n "${FAKE_FUSE_STATE:-}" ]]; then
    [[ "${1:-}" == "install" && "${3:-}" == "libfuse2t64" ]]
    touch "${FAKE_FUSE_STATE}"
    exit
fi
exec /usr/bin/apt-get "$@"
EOF
chmod +x "${TEST_DIR}/bin/apt-get"

readonly INSTALL_ROOT="${TEST_DIR}/system/opt/apps/openrgb"
readonly BIN_PATH="${TEST_DIR}/system/usr/local/bin/openrgb"
readonly FUSE_STATE="${TEST_DIR}/libfuse-installed"

dry_run_output="$(
    PATH="${TEST_DIR}/bin:${PATH}" \
    FAIL_IF_CALLED=1 \
    OPENRGB_INSTALL_ROOT="${INSTALL_ROOT}" \
    OPENRGB_BIN_PATH="${BIN_PATH}" \
    /bin/bash "${ROOT_DIR}/install.sh" --dry-run openrgb
)"
grep -Fq 'dry-run: no files will be downloaded or changed' <<<"${dry_run_output}"
grep -Fq "${INSTALL_ROOT}/1.0rc2/OpenRGB.AppImage" <<<"${dry_run_output}"
grep -Fq 'sudo apt-get install --yes libfuse2t64 (or libfuse2)' <<<"${dry_run_output}"
[[ ! -e "${TEST_DIR}/system" ]]

HOME="${TEST_DIR}/home" \
PATH="${TEST_DIR}/bin:${PATH}" \
OPENRGB_SOURCE_FILE="/bin/true" \
bash "${ROOT_DIR}/scripts/install-openrgb.sh" --download-only

HOME="${TEST_DIR}/home" \
PATH="${TEST_DIR}/bin:${PATH}" \
OPENRGB_SOURCE_FILE="/bin/true" \
OPENRGB_INSTALL_ROOT="${INSTALL_ROOT}" \
OPENRGB_BIN_PATH="${BIN_PATH}" \
FAKE_FUSE_STATE="${FUSE_STATE}" \
bash "${ROOT_DIR}/scripts/install-openrgb.sh"

[[ -e "${FUSE_STATE}" ]]
[[ -x "${BIN_PATH}" ]]
[[ -x "${INSTALL_ROOT}/current/OpenRGB.AppImage" ]]
[[ "$(<"${INSTALL_ROOT}/VERSION")" == "1.0rc2" ]]
grep -Fq 'exec sudo --' "${BIN_PATH}"

printf 'install-openrgb tests passed\n'
