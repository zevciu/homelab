# ==============================================================================
# METADATA
# ==============================================================================
# FUNCTION: backup_config
# PURPOSE: Create a timestamped backup of the runtime configuration directory
#
# DEPENDENCIES:
#   - logger.sh (log, log_ok)
#   - run.sh (run)
# ==============================================================================

# -----------------------------------------------------------------------------
# INPUT / OUTPUT CONTRACT
# -----------------------------------------------------------------------------
# INPUT:
#   $1 - service: name of the service
#   $2 - target_dir: path to the directory to backup
#
# OUTPUT:
#   stdout: log messages indicating progress
#
# SIDE EFFECTS:
#   - Creates a backup directory
#   - Copies files using rsync
#
# RETURNS:
#   0 on success
# -----------------------------------------------------------------------------

# ==============================================================================
# CONFIGURATION (none)
# ==============================================================================

# ==============================================================================
# IMPLEMENTATION
# ==============================================================================

backup_config() {
    # ---------------------------------------------------------------------------
    # INPUT
    # ---------------------------------------------------------------------------

    # --- map positional arguments to named variables ---
    local service="$1"
    local target_dir="$2"

    # ---------------------------------------------------------------------------
    # VALIDATION (none)
    # ---------------------------------------------------------------------------

    # ---------------------------------------------------------------------------
    # SETUP
    # ---------------------------------------------------------------------------

    # --- generate backup directory path with timestamp ---
    local backup_dir="$target_dir/.backup/$(date +%Y%m%d_%H%M%S)"

    # --- create backup directory ---
    run mkdir -p "$backup_dir"

    # ---------------------------------------------------------------------------
    # CORE
    # ---------------------------------------------------------------------------

    # --- log start ---
    log "$service → backup start"

    # --- copy files excluding backup and status files ---
    run rsync -a \
        --exclude=".backup" \
        --exclude=".status" \
        "$target_dir/" "$backup_dir/"

    # --- log success ---
    log_ok "$service → backup saved: $backup_dir"

    # ---------------------------------------------------------------------------
    # OUTPUT / RETURN
    # ---------------------------------------------------------------------------
    return 0
}
