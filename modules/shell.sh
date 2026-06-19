#!/usr/bin/env bash

install_shell() {
    local config_root="${ROOT_DIR}/config/zsh"
    local sheldon_target="${XDG_CONFIG_HOME:-${HOME}/.config}/sheldon/plugins.toml"
    local zsh_path

    ensure_dir "$(dirname -- "${sheldon_target}")"
    link_with_backup "${config_root}/zshrc" "${HOME}/.zshrc" "~/.zshrc"
    link_with_backup "${config_root}/plugins.toml" "${sheldon_target}" "sheldon/plugins.toml"

    if [[ "${BOOTSTRAP_DRY_RUN}" == "1" ]]; then
        log "dry-run: sheldon lock"
        log "dry-run: set default shell to zsh"
        return
    fi

    if have sheldon; then
        sheldon lock
    else
        log "sheldon not installed yet; run module 'cli' before 'shell' or rerun bootstrap"
    fi

    if ! have zsh; then
        log "zsh is not installed yet; run module 'base' before 'shell'"
        return
    fi

    zsh_path="$(command -v zsh)"
    if [[ "${SHELL:-}" == "${zsh_path}" ]]; then
        log "default shell already zsh"
        return
    fi

    if ! grep -qxF "${zsh_path}" /etc/shells 2>/dev/null; then
        if [[ "${BOOTSTRAP_DRY_RUN}" == "1" ]]; then
            log "dry-run: add ${zsh_path} to /etc/shells"
        else
            printf '%s\n' "${zsh_path}" | sudo tee -a /etc/shells >/dev/null
        fi
    fi

    if chsh -s "${zsh_path}"; then
        log "default shell changed to zsh"
    else
        log "failed to change default shell automatically; run manually: chsh -s ${zsh_path}"
    fi
}
