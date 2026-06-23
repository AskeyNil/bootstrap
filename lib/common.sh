#!/usr/bin/env bash

: "${BOOTSTRAP_DRY_RUN:=0}"
: "${BOOTSTRAP_PREFIX:=bootstrap}"
: "${BOOTSTRAP_OS:=}"

log() {
    printf '[%s] %s\n' "${BOOTSTRAP_PREFIX}" "$*"
}

die() {
    printf '[%s] error: %s\n' "${BOOTSTRAP_PREFIX}" "$*" >&2
    exit 1
}

have() {
    command -v "$1" >/dev/null 2>&1
}

require_command() {
    have "$1" || die "required command not found: $1"
}

run() {
    if [[ "${BOOTSTRAP_DRY_RUN}" == "1" ]]; then
        printf '[%s] dry-run: ' "${BOOTSTRAP_PREFIX}"
        printf '%q ' "$@"
        printf '\n'
        return
    fi

    "$@"
}

sudo_run() {
    run sudo "$@"
}

detect_os() {
    case "${BOOTSTRAP_OS}" in
        ubuntu | macos)
            log "detected OS: ${BOOTSTRAP_OS}"
            return
            ;;
        "")
            ;;
        *)
            die "invalid BOOTSTRAP_OS override: ${BOOTSTRAP_OS}"
            ;;
    esac

    case "$(uname -s)" in
        Linux)
            [[ -r /etc/os-release ]] || die "cannot read /etc/os-release"
            # shellcheck disable=SC1091
            source /etc/os-release
            [[ "${ID:-}" == "ubuntu" ]] ||
                die "Linux support is limited to Ubuntu, found: ${PRETTY_NAME:-unknown}"
            BOOTSTRAP_OS="ubuntu"
            ;;
        Darwin)
            BOOTSTRAP_OS="macos"
            ;;
        *)
            die "unsupported operating system: $(uname -s)"
            ;;
    esac

    log "detected OS: ${BOOTSTRAP_OS}"
}

is_ubuntu() {
    [[ "${BOOTSTRAP_OS}" == "ubuntu" ]]
}

is_macos() {
    [[ "${BOOTSTRAP_OS}" == "macos" ]]
}

ensure_dir() {
    local dir="$1"
    if [[ "${BOOTSTRAP_DRY_RUN}" == "1" ]]; then
        log "dry-run: mkdir -p ${dir}"
        return
    fi
    mkdir -p "${dir}"
}

link_with_backup() {
    local source="$1"
    local target="$2"
    local label="${3:-${target}}"
    local backup

    [[ -e "${source}" ]] || die "missing source file: ${source}"

    if [[ -L "${target}" && "$(readlink "${target}")" == "${source}" ]]; then
        log "${label} already linked"
        return
    fi

    if [[ -e "${target}" || -L "${target}" ]]; then
        backup="${target}.bak.$(date +%Y%m%d-%H%M%S)"
        run mv -- "${target}" "${backup}"
        log "backed up ${label}: ${backup}"
    fi

    run ln -sfn -- "${source}" "${target}"
    log "linked ${label}"
}
