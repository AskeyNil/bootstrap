#!/usr/bin/env bash

: "${PROXY_URL:=}"

setup_proxy_from_env() {
    if [[ -z "${PROXY_URL}" ]]; then
        if [[ -n "${http_proxy:-}" ]]; then
            PROXY_URL="${http_proxy}"
        elif [[ -n "${HTTP_PROXY:-}" ]]; then
            PROXY_URL="${HTTP_PROXY}"
        elif [[ -n "${PROXY_HOST:-}" && -n "${PROXY_PORT:-}" ]]; then
            PROXY_URL="http://${PROXY_HOST}:${PROXY_PORT}"
        fi
    fi

    [[ -n "${PROXY_URL}" ]] || return 0

    export http_proxy="${PROXY_URL}"
    export https_proxy="${PROXY_URL}"
    export HTTP_PROXY="${PROXY_URL}"
    export HTTPS_PROXY="${PROXY_URL}"
    export ALL_PROXY="${PROXY_URL}"
    export no_proxy="localhost,127.0.0.1"
    export NO_PROXY="${no_proxy}"
    log "using proxy: ${PROXY_URL}"
}

apt_get() {
    local command=(apt-get "$@")

    if [[ -n "${PROXY_URL}" ]]; then
        command=(
            apt-get
            -o "Acquire::http::Proxy=${PROXY_URL}"
            -o "Acquire::https::Proxy=${PROXY_URL}"
            "$@"
        )
    fi

    sudo_run env DEBIAN_FRONTEND=noninteractive "${command[@]}"
}

is_deb_installed() {
    [[ "$(dpkg-query -W -f='${db:Status-Status}' "$1" 2>/dev/null || true)" == "installed" ]]
}

apt_install_missing() {
    local package
    local missing=()

    require_command dpkg-query
    require_command apt-get

    for package in "$@"; do
        if is_deb_installed "${package}"; then
            log "apt package already installed: ${package}"
        else
            missing+=("${package}")
        fi
    done

    ((${#missing[@]} > 0)) || return 0

    log "installing apt packages: ${missing[*]}"
    apt_get update -qq
    apt_get install --yes "${missing[@]}"
}
