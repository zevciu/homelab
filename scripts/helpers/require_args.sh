# ==============================================================================
# METADATA
# ==============================================================================
# FUNCTION: require_args
# PURPOSE: Validate that a command has the required number of arguments
#
# DEPENDENCIES:
#   - logger.sh (log_err)
# ==============================================================================

# -----------------------------------------------------------------------------
# INPUT / OUTPUT CONTRACT
# -----------------------------------------------------------------------------
# INPUT:
#   $1 - expected: minimum number of arguments required
#   $2 - actual: number of arguments provided
#   $3 - cmd: name of the command being validated
#   $4 - usage_fn: optional function name to display usage on error
#
# OUTPUT:
#   stdout: none
#
# SIDE EFFECTS:
#   - Logs error message if validation fails
#   - Calls usage function if provided
#   - Exits with code 1 if validation fails
#
# RETURNS:
#   0 on success (arguments sufficient)
#   1 on failure (arguments insufficient)
# -----------------------------------------------------------------------------

# ==============================================================================
# CONFIGURATION (none)
# ==============================================================================

# ==============================================================================
# IMPLEMENTATION
# ==============================================================================

require_args() {
    # ---------------------------------------------------------------------------
    # INPUT
    # ---------------------------------------------------------------------------
    local expected="$1"
    local actual="$2"
    local cmd="$3"
    local usage_fn="${4:-}"

    # ---------------------------------------------------------------------------
    # VALIDATION (none)
    # ---------------------------------------------------------------------------

    # ---------------------------------------------------------------------------
    # SETUP (none)
    # ---------------------------------------------------------------------------

    # ---------------------------------------------------------------------------
    # CORE
    # ---------------------------------------------------------------------------

    # --- check argument count ---
    if [ "$actual" -lt "$expected" ]; then
        log_err "command '$cmd' requires $expected argument(s)"

        # --- display usage if function provided ---
        if [ -n "$usage_fn" ] && declare -f "$usage_fn" >/dev/null; then
            "$usage_fn"
        fi

        exit 1
    fi

    # ---------------------------------------------------------------------------
    # OUTPUT / RETURN
    # ---------------------------------------------------------------------------
    return 0
}
