# ==============================================================================
# METADATA
# ==============================================================================
# FUNCTION: guard_direction
# PURPOSE: Prevent conflicting sync operations based on drift direction
#
# DEPENDENCIES:
#   - logger.sh (log, log_warn, log_err, log_debug)
# ==============================================================================

# -----------------------------------------------------------------------------
# INPUT / OUTPUT CONTRACT
# -----------------------------------------------------------------------------
# INPUT:
#   $1 - action: operation type (apply / export)
#   $2 - direction: drift direction (NONE, OPS_TO_RUNTIME, RUNTIME_TO_OPS, MIXED)
#   $@ - optional flags: --force
#
# OUTPUT:
#   stdout: log messages indicating guard status
#
# SIDE EFFECTS:
#   - May exit with code 1 if operation is blocked
#
# RETURNS:
#   0 on success (operation allowed)
#   1 on failure (operation blocked)
# -----------------------------------------------------------------------------

# ==============================================================================
# CONFIGURATION (provided)
# ==============================================================================
# --- assumed to be set by env.sh ---

# ==============================================================================
# IMPLEMENTATION
# ==============================================================================

guard_direction() {
    # ---------------------------------------------------------------------------
    # INPUT
    # ---------------------------------------------------------------------------

    # --- map positional arguments to named variables ---
    local action="$1"
    local direction="$2"
    shift 2

    # --- initialize flags ---
    local force_flag=false

     # --- parse flags from remaining arguments ---
    for arg in "$@"; do
        case "$arg" in
            --force)
                force_flag=true
                ;;
        esac
    done

    # ---------------------------------------------------------------------------
    # VALIDATION
    # ---------------------------------------------------------------------------

    # --- validate action parameter ---
    if [ -z "$action" ]; then
        log_err "guard_direction: action is required"
        return 1
    fi

    # --- validate direction parameter ---
    if [ -z "$direction" ]; then
        log_err "guard_direction: direction is required"
        return 1
    fi

    # --- check if force flag is enabled ---
    if [ "$force_flag" = true ]; then
        log_warn "$action → force enabled → skipping direction guard"
        return 0
    fi

    # ---------------------------------------------------------------------------
    # SETUP (none)
    # ---------------------------------------------------------------------------

    # ---------------------------------------------------------------------------
    # CORE
    # ---------------------------------------------------------------------------

    # --- check for mixed changes (always blocked) ---
    if [ "$direction" = "MIXED" ]; then
        log_err "$action blocked: mixed changes detected (MIXED)"
        log_err "hint: resolve manually or override with --force"
        exit 1
    fi

    # --- log no differences case ---
    if [ "$direction" = "NONE" ]; then
        log_debug "direction → no differences detected (NONE)"
        return 0
    fi

    # --- check action-specific direction conflicts ---
    case "$action:$direction" in
        apply:RUNTIME_TO_OPS)
            log_err "apply blocked: runtime has newer changes (RUNTIME_TO_OPS)"
            log_err "hint: use 'export' or override with --force"
            exit 1
            ;;

        export:OPS_TO_RUNTIME)
            log_err "export blocked: ops has newer changes (OPS_TO_RUNTIME)"
            log_err "hint: use 'apply' or override with --force"
            exit 1
            ;;

        *)
            ;;
    esac

    # ---------------------------------------------------------------------------
    # OUTPUT / RETURN
    # ---------------------------------------------------------------------------
    return 0
}
