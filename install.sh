#!/usr/bin/env bash

set -Eeuo pipefail

readonly ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
: "${BOOTSTRAP_REPO_ARCHIVE:=https://github.com/AskeyNil/bootstrap/archive/refs/heads/main.tar.gz}"
: "${BOOTSTRAP_HOME:=${XDG_DATA_HOME:-${HOME}/.local/share}/bootstrap}"

bootstrap_self() {
    [[ -r "${ROOT_DIR}/lib/common.sh" &&
       -r "${ROOT_DIR}/lib/apt.sh" &&
       -r "${ROOT_DIR}/lib/brew.sh" &&
       -d "${ROOT_DIR}/modules" ]] && return

    command -v curl >/dev/null 2>&1 || {
        printf '[bootstrap] error: curl is required for one-line install\n' >&2
        exit 1
    }
    command -v tar >/dev/null 2>&1 || {
        printf '[bootstrap] error: tar is required for one-line install\n' >&2
        exit 1
    }
    command -v mktemp >/dev/null 2>&1 || {
        printf '[bootstrap] error: mktemp is required for one-line install\n' >&2
        exit 1
    }

    local temp_dir
    local archive_root
    local persist=1
    local arg
    temp_dir="$(mktemp -d)"
    trap 'rm -rf -- "${temp_dir}"' EXIT

    printf '[bootstrap] downloading full repository archive\n'
    curl -fsSL "${BOOTSTRAP_REPO_ARCHIVE}" | tar -xz -C "${temp_dir}"

    archive_root="$(find "${temp_dir}" -mindepth 1 -maxdepth 1 -type d -print -quit)"
    [[ -n "${archive_root}" && -x "${archive_root}/install.sh" ]] || {
        printf '[bootstrap] error: downloaded archive does not contain install.sh\n' >&2
        exit 1
    }

    for arg in "$@"; do
        case "${arg}" in
            --dry-run | --download-only | -h | --help)
                persist=0
                ;;
        esac
    done

    if [[ "${persist}" == "0" ]]; then
        bash "${archive_root}/install.sh" "$@"
        exit $?
    fi

    case "${BOOTSTRAP_HOME}" in
        "" | "/" | "${HOME}")
            printf '[bootstrap] error: unsafe BOOTSTRAP_HOME: %s\n' "${BOOTSTRAP_HOME}" >&2
            exit 1
            ;;
    esac

    printf '[bootstrap] installing repository files to %s\n' "${BOOTSTRAP_HOME}"
    rm -rf -- "${BOOTSTRAP_HOME}.tmp"
    mkdir -p -- "$(dirname -- "${BOOTSTRAP_HOME}")"
    cp -R -- "${archive_root}" "${BOOTSTRAP_HOME}.tmp"
    rm -rf -- "${BOOTSTRAP_HOME}"
    mv -- "${BOOTSTRAP_HOME}.tmp" "${BOOTSTRAP_HOME}"

    exec bash "${BOOTSTRAP_HOME}/install.sh" "$@"
}

bootstrap_self "$@"

# shellcheck source=lib/common.sh
source "${ROOT_DIR}/lib/common.sh"
# shellcheck source=lib/apt.sh
source "${ROOT_DIR}/lib/apt.sh"
# shellcheck source=lib/brew.sh
source "${ROOT_DIR}/lib/brew.sh"

usage() {
    cat <<EOF
Usage: ./install.sh [--dry-run] [--download-only] [module...]

Modules:
  base      Ubuntu/macOS base packages
  shell     zsh config, Sheldon plugins, default shell
  rust      rustup stable via rsproxy.cn
  cli       sheldon, starship, zoxide, atuin
  docker    Docker CE via docker install script (Ubuntu only)
  openrgb   OpenRGB AppImage installer (Ubuntu only)

Default modules:
  Ubuntu: base rust cli shell docker openrgb
  macOS:  base rust cli shell

Options:
  --dry-run        Show actions without changing the system
  --download-only  Validate OpenRGB download/local AppImage only
EOF
}

main() {
    local modules=()
    local arg

    for arg in "$@"; do
        case "${arg}" in
            --dry-run)
                BOOTSTRAP_DRY_RUN=1
                ;;
            --download-only)
                OPENRGB_DOWNLOAD_ONLY=1
                modules=(openrgb)
                ;;
            -h | --help)
                usage
                exit 0
                ;;
            base | shell | rust | cli | docker | openrgb)
                modules+=("${arg}")
                ;;
            *)
                die "unknown argument: ${arg}"
                ;;
        esac
    done

    detect_os
    setup_proxy_from_env

    if ((${#modules[@]} == 0)); then
        if is_macos; then
            modules=(base rust cli shell)
        else
            modules=(base rust cli shell docker openrgb)
        fi
    fi

    local module
    for module in "${modules[@]}"; do
        log "module: ${module}"
        # shellcheck source=/dev/null
        source "${ROOT_DIR}/modules/${module}.sh"
        "install_${module}"
    done

    log "bootstrap complete"
}

main "$@"
