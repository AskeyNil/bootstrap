#!/usr/bin/env bash

install_rust() {
    if have rustc; then
        log "rust already installed"
        return
    fi

    require_command curl

    log "installing Rust stable via rsproxy.cn"
    if [[ "${BOOTSTRAP_DRY_RUN}" == "1" ]]; then
        log "dry-run: curl https://rsproxy.cn/rustup-init.sh | sh -s -- -y --default-toolchain stable"
        return
    fi

    export RUSTUP_DIST_SERVER="https://rsproxy.cn"
    export RUSTUP_UPDATE_ROOT="https://rsproxy.cn/rustup"
    curl --proto '=https' --tlsv1.2 -sSf https://rsproxy.cn/rustup-init.sh |
        sh -s -- -y --default-toolchain stable

    # shellcheck source=/dev/null
    [[ -f "${HOME}/.cargo/env" ]] && source "${HOME}/.cargo/env"
}
