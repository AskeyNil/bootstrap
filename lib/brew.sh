#!/usr/bin/env bash

_activate_brew() {
    if [[ -x /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        return 0
    fi
    if [[ -x /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
        return 0
    fi
    return 1
}

ensure_brew() {
    have brew && return 0
    _activate_brew && return 0

    log "installing Homebrew"
    if [[ "${BOOTSTRAP_DRY_RUN}" == "1" ]]; then
        log "dry-run: NONINTERACTIVE=1 /bin/bash -c \"\$(curl -fsSL --proto '=https' https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        return
    fi

    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL --proto '=https' https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    _activate_brew
    require_command brew
}

brew_install_missing() {
    local package
    local missing=()

    ensure_brew

    for package in "$@"; do
        if have brew && brew list "${package}" >/dev/null 2>&1; then
            log "brew package already installed: ${package}"
        else
            missing+=("${package}")
        fi
    done

    ((${#missing[@]} > 0)) || return 0

    log "installing brew packages: ${missing[*]}"
    run brew install "${missing[@]}"
}
