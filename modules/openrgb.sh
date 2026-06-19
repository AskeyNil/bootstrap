#!/usr/bin/env bash

install_openrgb() {
    local args=()

    if is_macos; then
        log "openrgb module is skipped on macOS"
        return
    fi

    if [[ "${BOOTSTRAP_DRY_RUN}" == "1" ]]; then
        args+=(--dry-run)
    elif [[ "${OPENRGB_DOWNLOAD_ONLY:-0}" == "1" ]]; then
        args+=(--download-only)
    fi

    "${ROOT_DIR}/scripts/install-openrgb.sh" "${args[@]}"
}
