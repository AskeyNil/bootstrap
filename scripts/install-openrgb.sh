#!/usr/bin/env bash

set -Eeuo pipefail

# Pinned to the latest published release validated for this bootstrap setup.
readonly OPENRGB_VERSION="${OPENRGB_VERSION:-1.0rc2}"
readonly OPENRGB_BUILD="${OPENRGB_BUILD:-0fca93e}"
readonly OPENRGB_ARCH="${OPENRGB_ARCH:-x86_64}"
readonly OPENRGB_FILE="OpenRGB_${OPENRGB_VERSION}_${OPENRGB_ARCH}_${OPENRGB_BUILD}.AppImage"
readonly OPENRGB_URL="${OPENRGB_URL:-https://codeberg.org/OpenRGB/OpenRGB/releases/download/release_candidate_${OPENRGB_VERSION}/${OPENRGB_FILE}}"
readonly OPENRGB_SHA256="${OPENRGB_SHA256:-}"
readonly OPENRGB_SOURCE_FILE="${OPENRGB_SOURCE_FILE:-}"
readonly INSTALL_ROOT="${OPENRGB_INSTALL_ROOT:-/opt/apps/openrgb}"
readonly BIN_PATH="${OPENRGB_BIN_PATH:-/usr/local/bin/openrgb}"

log() {
    printf '[bootstrap:openrgb] %s\n' "$*"
}

die() {
    printf '[bootstrap:openrgb] error: %s\n' "$*" >&2
    exit 1
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

check_platform() {
    [[ "$(uname -s)" == "Linux" ]] || die "this installer only supports Linux"
    [[ "$(uname -m)" == "${OPENRGB_ARCH}" ]] ||
        die "expected architecture ${OPENRGB_ARCH}, found $(uname -m)"
}

print_dry_run() {
    local version_dir="${INSTALL_ROOT}/${OPENRGB_VERSION}"
    local source

    if [[ -n "${OPENRGB_SOURCE_FILE}" ]]; then
        source="local file ${OPENRGB_SOURCE_FILE}"
    else
        source="URL ${OPENRGB_URL}"
    fi

    log "dry-run: no files will be downloaded or changed"
    printf '%s\n' \
        "  version:       ${OPENRGB_VERSION}" \
        "  architecture:  ${OPENRGB_ARCH}" \
        "  source:        ${source}" \
        "  AppImage:      ${version_dir}/OpenRGB.AppImage" \
        "  current link:  ${INSTALL_ROOT}/current -> ${version_dir}" \
        "  version file:  ${INSTALL_ROOT}/VERSION" \
        "  command:       ${BIN_PATH}" \
        "  dependency:    sudo apt-get install --yes libfuse2t64 (or libfuse2)" \
        "  runtime:       ${BIN_PATH} launches the AppImage through sudo"
}

is_package_installed() {
    [[ "$(dpkg-query -W -f='${db:Status-Status}' "$1" 2>/dev/null || true)" == "installed" ]]
}

find_fuse_package() {
    local package

    for package in libfuse2t64 libfuse2; do
        if apt-cache show "${package}" >/dev/null 2>&1; then
            printf '%s\n' "${package}"
            return
        fi
    done

    return 1
}

ensure_fuse_dependency() {
    local package

    for package in libfuse2t64 libfuse2; do
        if is_package_installed "${package}"; then
            log "AppImage dependency already installed: ${package}"
            return
        fi
    done

    package="$(find_fuse_package || true)"
    if [[ -z "${package}" ]]; then
        log "refreshing apt package metadata"
        sudo apt-get update
        package="$(find_fuse_package || true)"
    fi

    [[ -n "${package}" ]] ||
        die "neither libfuse2t64 nor libfuse2 is available from the configured apt repositories"

    log "installing AppImage dependency: ${package}"
    sudo apt-get install --yes "${package}"
    is_package_installed "${package}" ||
        die "apt completed but ${package} is not installed"
}

download_appimage() {
    local destination="$1"

    if [[ -n "${OPENRGB_SOURCE_FILE}" ]]; then
        [[ -r "${OPENRGB_SOURCE_FILE}" ]] ||
            die "local AppImage is not readable: ${OPENRGB_SOURCE_FILE}"
        log "using local AppImage: ${OPENRGB_SOURCE_FILE}"
        cp -- "${OPENRGB_SOURCE_FILE}" "${destination}"
        return
    fi

    log "downloading OpenRGB ${OPENRGB_VERSION}"
    if ! curl \
        --silent \
        --show-error \
        --fail \
        --location \
        --http1.1 \
        --proto '=https' \
        --retry 2 \
        --retry-all-errors \
        --connect-timeout 15 \
        --max-time 900 \
        --output "${destination}" \
        "${OPENRGB_URL}"; then
        diagnose_download_failure
    fi
}

diagnose_download_failure() {
    local address

    if command -v getent >/dev/null 2>&1; then
        while read -r address _; do
            case "${address}" in
                198.18.* | 198.19.*)
                    die "Codeberg resolved to proxy Fake-IP ${address}, but TLS forwarding failed.
Start or repair the proxy/TUN service, export HTTPS_PROXY for this shell, or install from a local file:
OPENRGB_SOURCE_FILE=/path/to/${OPENRGB_FILE} ./install.sh"
                    ;;
            esac
        done < <(getent ahostsv4 codeberg.org 2>/dev/null || true)
    fi

    die "download failed: ${OPENRGB_URL}
Check access to codeberg.org, configure HTTPS_PROXY if required, or use:
OPENRGB_SOURCE_FILE=/path/to/${OPENRGB_FILE} ./install.sh"
}

verify_appimage() {
    local appimage="$1"

    [[ -s "${appimage}" ]] || die "downloaded file is empty"

    if [[ -n "${OPENRGB_SHA256}" ]]; then
        printf '%s  %s\n' "${OPENRGB_SHA256}" "${appimage}" |
            sha256sum --check --status ||
            die "SHA-256 verification failed"
    fi

    # An AppImage is an ELF executable. This rejects HTML error pages and other
    # common bad downloads even when no upstream checksum is available.
    [[ "$(LC_ALL=C head -c 4 "${appimage}" | od -An -tx1 | tr -d ' \n')" == "7f454c46" ]] ||
        die "download is not a valid ELF/AppImage file"

    chmod 0755 "${appimage}"
    "${appimage}" --appimage-version >/dev/null 2>&1 ||
        die "downloaded executable did not identify itself as an AppImage"
}

install_appimage() {
    local source="$1"
    local version_dir="${INSTALL_ROOT}/${OPENRGB_VERSION}"
    local destination="${version_dir}/OpenRGB.AppImage"
    local staging_dir wrapper

    staging_dir="$(mktemp -d)"
    wrapper="${staging_dir}/openrgb"

    cat >"${wrapper}" <<EOF
#!/usr/bin/env bash
set -Eeuo pipefail

readonly OPENRGB_APPIMAGE="${INSTALL_ROOT}/current/OpenRGB.AppImage"

if ((EUID == 0)); then
    exec "\${OPENRGB_APPIMAGE}" "\$@"
fi

exec sudo -- "\${OPENRGB_APPIMAGE}" "\$@"
EOF

    sudo install -d -m 0755 \
        "${version_dir}" \
        "$(dirname -- "${BIN_PATH}")"
    sudo install -m 0755 "${source}" "${destination}"
    sudo ln -sfn "${version_dir}" "${INSTALL_ROOT}/current"
    sudo install -m 0755 "${wrapper}" "${BIN_PATH}"
    printf '%s\n' "${OPENRGB_VERSION}" | sudo tee "${INSTALL_ROOT}/VERSION" >/dev/null

    rm -rf -- "${staging_dir}"
}

is_installed() {
    [[ -x "${BIN_PATH}" ]] &&
        [[ -x "${INSTALL_ROOT}/current/OpenRGB.AppImage" ]] &&
        [[ -r "${INSTALL_ROOT}/VERSION" ]] &&
        [[ "$(<"${INSTALL_ROOT}/VERSION")" == "${OPENRGB_VERSION}" ]]
}

main() {
    local mode="install"
    case "${1:-}" in
        "") ;;
        --download-only) mode="download-only" ;;
        --dry-run) mode="dry-run" ;;
        *) die "usage: $0 [--download-only | --dry-run]" ;;
    esac

    check_platform

    if [[ "${mode}" == "dry-run" ]]; then
        print_dry_run
        exit 0
    fi

    require_command curl
    require_command cp
    require_command dpkg-query
    require_command head
    require_command install
    require_command od
    require_command sha256sum
    require_command sudo
    require_command tr

    if [[ "${mode}" == "install" ]]; then
        require_command apt-cache
        require_command apt-get
        ensure_fuse_dependency

        if is_installed; then
            log "OpenRGB ${OPENRGB_VERSION} is already installed"
            exit 0
        fi
    fi

    local temp_dir appimage
    temp_dir="$(mktemp -d)"
    trap 'rm -rf -- "${temp_dir:-}"' EXIT
    appimage="${temp_dir}/${OPENRGB_FILE}"

    download_appimage "${appimage}"
    verify_appimage "${appimage}"

    if [[ "${mode}" == "download-only" ]]; then
        log "download and AppImage validation succeeded"
        exit 0
    fi

    install_appimage "${appimage}"
    is_installed || die "installation verification failed"

    log "OpenRGB ${OPENRGB_VERSION} installed system-wide at ${INSTALL_ROOT}"
    log "run 'openrgb'; the launcher will request sudo access"
}

main "$@"
