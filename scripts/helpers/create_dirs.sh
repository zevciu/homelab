#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# METADATA
# ==============================================================================
# FUNCTION: create_dirs
# PURPOSE: Create directory structure
#
# DEPENDENCIES:
#   - logger.sh (log, log_ok, log_debug, die)
# ==============================================================================

# -----------------------------------------------------------------------------
# INPUT / OUTPUT CONTRACT
# -----------------------------------------------------------------------------
# INPUT:
#   $@ - list of absolute paths to directories to create
#
# OUTPUT:
#   stdout: log messages indicating created directories
#
# SIDE EFFECTS:
#   - Creates directories on the filesystem
#
# RETURNS:
#   0 on success
#   1 on failure (path exists as a file, permission denied)
# -----------------------------------------------------------------------------

# ==============================================================================
# CONFIGURATION (none)
# ==============================================================================

# ==============================================================================
# IMPLEMENTATION
# ==============================================================================

create_dirs() {
    # ---------------------------------------------------------------------------
    # INPUT (none)
    # ---------------------------------------------------------------------------

    # ---------------------------------------------------------------------------
    # VALIDATION
    # ---------------------------------------------------------------------------

    # --- ensure at least one argument is provided ---
    if [ $# -eq 0 ]; then
        die "create_dirs: requires at least one directory path"
    fi

    # --- validate that existing paths are directories (not files) ---
    for dir in "$@"; do
        if [ -e "$dir" ] && [ ! -d "$dir" ]; then
            die "create_dirs: path exists but is not a directory: $dir"
        fi
    done

    # ---------------------------------------------------------------------------
    # SETUP (none)
    # ---------------------------------------------------------------------------

    # ---------------------------------------------------------------------------
    # CORE
    # ---------------------------------------------------------------------------

    # --- create directories ---
    for dir in "$@"; do
        local dir_name
        dir_name=$(basename "$dir")

        if [ -d "$dir" ]; then
            # --- already exists, just log ---
            log_debug "directory exists: $dir_name ($dir)"
        else
            # --- create directory and parents ---
            mkdir -p "$dir" \
                || die "create_dirs: failed to create directory: $dir"

            log_ok "created directory: $dir_name"
            log_debug "created directory: $dir"
        fi
    done

    # ---------------------------------------------------------------------------
    # OUTPUT / RETURN
    # ---------------------------------------------------------------------------
    return 0
}
