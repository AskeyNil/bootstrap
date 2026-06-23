#!/usr/bin/env bash

# Pinned versions for reproducibility. Override via env (e.g. SHELDON_VERSION=0.7.0).
# Note: zoxide and atuin installers always fetch latest; their version variables
# are reserved for when installers support pinning.
readonly SHELDON_VERSION="${SHELDON_VERSION:-0.8.5}"
readonly STARSHIP_VERSION="${STARSHIP_VERSION:-v1.25.1}"

install_sheldon() {
    if have sheldon; then log "sheldon already installed"; return; fi
    require_command curl
    log "installing sheldon ${SHELDON_VERSION}"
    if [[ "${BOOTSTRAP_DRY_RUN}" == "1" ]]; then
        log "dry-run: install sheldon ${SHELDON_VERSION} to ~/.local/bin"
        return
    fi
    curl -fsSL --proto '=https' https://rossmacarthur.github.io/install/crate.sh |
        bash -s -- --repo rossmacarthur/sheldon --tag "${SHELDON_VERSION}" --to "${HOME}/.local/bin"
}

install_starship() {
    if have starship; then log "starship already installed"; return; fi
    require_command curl
    log "installing starship ${STARSHIP_VERSION}"
    if [[ "${BOOTSTRAP_DRY_RUN}" == "1" ]]; then
        log "dry-run: curl https://starship.rs/install.sh | sh -s -- -y -v ${STARSHIP_VERSION}"
        return
    fi
    curl -fsSL --proto '=https' https://starship.rs/install.sh | sh -s -- -y -v "${STARSHIP_VERSION}"
}

install_zoxide() {
    if have zoxide; then log "zoxide already installed"; return; fi
    require_command curl
    log "installing zoxide (latest; installer does not support version pinning)"
    if [[ "${BOOTSTRAP_DRY_RUN}" == "1" ]]; then
        log "dry-run: curl zoxide install.sh | sh"
        return
    fi
    curl -fsSL --proto '=https' https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
}

install_atuin() {
    if have atuin; then log "atuin already installed"; return; fi
    require_command curl
    log "installing atuin (latest; installer does not support version pinning)"
    if [[ "${BOOTSTRAP_DRY_RUN}" == "1" ]]; then
        log "dry-run: curl atuin install.sh | bash"
        return
    fi
    bash <(curl -fsSL --proto '=https' https://raw.githubusercontent.com/atuinsh/atuin/main/install.sh)
}

install_cli() {
    install_sheldon
    install_starship
    install_zoxide
    install_atuin
}
