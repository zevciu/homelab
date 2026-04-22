# ==============================================================================
# METADATA
# ==============================================================================
# FUNCTION: set_status
# PURPOSE: Set the status of a service in the ops configuration directory
#
# DEPENDENCIES:
#   - logger.sh (log_ok, die)
# ==============================================================================

# -----------------------------------------------------------------------------
# INPUT / OUTPUT CONTRACT
# -----------------------------------------------------------------------------
# INPUT:
#   $1 - service: name of the service
#   $2 - ops_service_config_dir: path to the ops config directory
#   $3 - status: status value (BROKEN, EMPTY, INIT, READY, APPLIED, EXPORTED)
#
# OUTPUT:
#   stdout: none
#
# SIDE EFFECTS:
#   - Writes status to .status file
#   - Logs success message
#
# RETURNS:
#   0 on success
#   1 on failure (invalid status)
# -----------------------------------------------------------------------------

# ==============================================================================
# CONFIGURATION (none)
# ==============================================================================

# ==============================================================================
# IMPLEMENTATION
# ==============================================================================

set_status() {
    # ---------------------------------------------------------------------------
    # INPUT
    # ---------------------------------------------------------------------------

    # --- map positional arguments to named variables ---
    local service="$1"
    local ops_service_config_dir="$2"
    local status="$3"

    # ---------------------------------------------------------------------------
    # VALIDATION
    # ---------------------------------------------------------------------------

    # --- validate status value ---
    case "$status" in
        BROKEN|EMPTY|INIT|READY|APPLIED|EXPORTED)
            ;;
        *)
            die "$service → unknown status: $status"
            ;;
    esac

    # ---------------------------------------------------------------------------
    # SETUP
    # ---------------------------------------------------------------------------

    # --- define status file path ---
    local status_file="$ops_service_config_dir/.status"

    # ---------------------------------------------------------------------------
    # CORE
    # ---------------------------------------------------------------------------

    # --- write status to file ---
    echo "$status" > "$status_file"

    # --- log success ---
    log_ok "$service → status set: $status"

    # ---------------------------------------------------------------------------
    # OUTPUT / RETURN
    # ---------------------------------------------------------------------------
    return 0
}
