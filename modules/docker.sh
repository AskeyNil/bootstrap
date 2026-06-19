#!/usr/bin/env bash

install_docker() {
    if is_macos; then
        log "docker module is skipped on macOS; install Docker Desktop manually if needed"
        return
    fi

    if is_deb_installed docker-ce; then
        log "docker already installed"
        return
    fi

    require_command curl

    log "installing Docker CE"
    if [[ "${BOOTSTRAP_DRY_RUN}" == "1" ]]; then
        log "dry-run: DOWNLOAD_URL=https://mirrors.tuna.tsinghua.edu.cn/docker-ce curl https://get.docker.com | sh"
        log "dry-run: sudo systemctl enable --now docker"
        log "dry-run: sudo usermod -aG docker ${USER}"
        return
    fi

    export DOWNLOAD_URL="https://mirrors.tuna.tsinghua.edu.cn/docker-ce"
    curl -fsSL https://get.docker.com | sh
    sudo systemctl enable --now docker

    if ! id -nG "${USER}" | grep -qw docker; then
        sudo usermod -aG docker "${USER}"
        log "added ${USER} to docker group; log out and back in to use docker without sudo"
    fi
}
