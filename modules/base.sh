#!/usr/bin/env bash

install_base() {
    if is_macos; then
        brew_install_missing zsh git curl fzf eza
        return
    fi

    apt_install_missing \
        zsh \
        git \
        curl \
        fzf \
        eza \
        build-essential \
        ca-certificates
}
