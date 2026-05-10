#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# METADATA
# ==============================================================================
# FUNCTION: create_files
# PURPOSE: Create empty files while ensuring parent directories exist
#
# DEPENDENCIES:
#   - logger.sh (log, log_ok, log_warn, log_debug, die)
# ==============================================================================

# -----------------------------------------------------------------------------
# INPUT / OUTPUT CONTRACT
# -----------------------------------------------------------------------------
# INPUT:
#   $@ - list of absolute paths to files to create
#
# OUTPUT:
#   stdout: log messages indicating created/existing files
#
# SIDE EFFECTS:
#   - Creates files and directories on the filesystem
#
# RETURNS:
#   0 on success
#   1 on failure (path exists as a directory, permission denied)
# -----------------------------------------------------------------------------

# ==============================================================================
# CONFIGURATION (none)
# ==============================================================================

# ==============================================================================
# IMPLEMENTATION
# ==============================================================================

create_files() {
    # ---------------------------------------------------------------------------
    # INPUT (none)
    # ---------------------------------------------------------------------------

    # ---------------------------------------------------------------------------
    # VALIDATION
    # ---------------------------------------------------------------------------

    # --- validate at least one argument ---
    if [ $# -eq 0 ]; then
        die "create_files: requires at least one file path"
    fi

    # --- ensure paths are not directories ---
    for file in "$@"; do
        if [ -d "$file" ]; then
            die "create_files: path exists but is a directory: $file"
        fi
    done

    # ---------------------------------------------------------------------------
    # SETUP (none)
    # ---------------------------------------------------------------------------

    # ---------------------------------------------------------------------------
    # CORE
    # ---------------------------------------------------------------------------

    # --- create files ---
    for file in "$@"; do

        local file_name
        file_name=$(basename "$file")

        local parent_dir
        parent_dir=$(dirname "$file")

        # --- ensure parent directory exists ---
        mkdir -p "$parent_dir" \
            || die "create_files: failed to create parent directory: $parent_dir"

        if [ -f "$file" ]; then
            if [ ! -s "$file" ]; then
                log_warn "file exists but is empty: $file_name"
                log_debug "file is located at $file"
            else
                log_debug "file exists: $file"
            fi
        else
            touch "$file" \
                || die "create_files: failed to create file: $file"

            log_ok "created file: $file_name"
            log_debug "created file: $file"
        fi
    done

    # ---------------------------------------------------------------------------
    # OUTPUT / RETURN
    # ---------------------------------------------------------------------------
    return 0
}
