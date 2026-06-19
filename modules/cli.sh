#!/usr/bin/env bash

install_sheldon() {
    if have sheldon; then log "sheldon already installed"; return; fi
    require_command curl
    log "installing sheldon"
    if [[ "${BOOTSTRAP_DRY_RUN}" == "1" ]]; then
        log "dry-run: install sheldon to ~/.local/bin"
        return
    fi
    curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh |
        bash -s -- --repo rossmacarthur/sheldon --to "${HOME}/.local/bin"
}

install_starship() {
    if have starship; then log "starship already installed"; return; fi
    require_command curl
    log "installing starship"
    if [[ "${BOOTSTRAP_DRY_RUN}" == "1" ]]; then
        log "dry-run: curl https://starship.rs/install.sh | sh -s -- -y"
        return
    fi
    curl -fsSL https://starship.rs/install.sh | sh -s -- -y
}

install_zoxide() {
    if have zoxide; then log "zoxide already installed"; return; fi
    require_command curl
    log "installing zoxide"
    if [[ "${BOOTSTRAP_DRY_RUN}" == "1" ]]; then
        log "dry-run: curl zoxide install.sh | sh"
        return
    fi
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
}

install_atuin() {
    if have atuin; then log "atuin already installed"; return; fi
    require_command curl
    log "installing atuin"
    if [[ "${BOOTSTRAP_DRY_RUN}" == "1" ]]; then
        log "dry-run: curl atuin install.sh | bash"
        return
    fi
    bash <(curl -fsSL https://raw.githubusercontent.com/ellie/atuin/main/install.sh)
}

install_cli() {
    install_sheldon
    install_starship
    install_zoxide
    install_atuin
}
