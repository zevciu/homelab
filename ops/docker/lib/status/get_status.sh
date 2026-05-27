# ==============================================================================
# METADATA
# ==============================================================================
# FUNCTION: get_status
# PURPOSE: Get the current status of a service
#
# DEPENDENCIES:
#   - None (uses standard bash commands)
# ==============================================================================

# -----------------------------------------------------------------------------
# INPUT / OUTPUT CONTRACT
# -----------------------------------------------------------------------------
# INPUT:
#   $1 - service: name of the service
#   $2 - ops_service_config_dir: path to the ops config directory
#   $3 - runtime_service_config_dir: path to the runtime config directory
#
# OUTPUT:
#   stdout: status string (EMPTY, INIT, BROKEN, or value from .status file)
#
# SIDE EFFECTS:
#   - None (read-only)
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

get_status() {
    # ---------------------------------------------------------------------------
    # INPUT
    # ---------------------------------------------------------------------------

    # --- map positional arguments to named variables ---
    local service="$1"
    local ops_service_config_dir="$2"
    local runtime_service_config_dir="$3"

    # ---------------------------------------------------------------------------
    # VALIDATION (none)
    # ---------------------------------------------------------------------------

    # ---------------------------------------------------------------------------
    # SETUP
    # ---------------------------------------------------------------------------

    # --- define status file path ---
    local status_file="$ops_service_config_dir/.status"

    # ---------------------------------------------------------------------------
    # CORE (none)
    # ---------------------------------------------------------------------------

    # ---------------------------------------------------------------------------
    # OUTPUT / RETURN
    # ---------------------------------------------------------------------------

    # --- check if both directories are missing ---
    if [ ! -d "$ops_service_config_dir" ] && [ ! -d "$runtime_service_config_dir" ]; then
        echo "EMPTY"
        return 0
    fi

    # --- check if ops exists but runtime is missing ---
    if [ -d "$ops_service_config_dir" ] && [ ! -d "$runtime_service_config_dir" ]; then
        echo "INIT"
        return 0
    fi

    # --- check if ops is missing but runtime exists ---
    if [ ! -d "$ops_service_config_dir" ] && [ -d "$runtime_service_config_dir" ]; then
        echo "BROKEN"
        return 0
    fi

    # --- read status from file if it exists ---
    if [ -f "$status_file" ]; then
        cat "$status_file"
        return 0
    fi

    # ---------------------------------------------------------------------------
    # FALLBACK
    # ---------------------------------------------------------------------------
    echo "UNKNOWN"
    return 0
}
