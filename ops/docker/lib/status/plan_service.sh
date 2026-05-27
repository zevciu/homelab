# ==============================================================================
# METADATA
# ==============================================================================
# FUNCTION: plan_service
# PURPOSE: Display the current state and drift analysis for a service
#
# DEPENDENCIES:
#   - logger.sh (log, log_ok, log_warn)
#   - get_status.sh (get_status)
#   - get_runtime_state.sh (get_runtime_state)
#   - get_health_state.sh (get_health_state)
#   - compare_dirs.sh (compare_dirs)
#   - get_drift_direction.sh (get_drift_direction)
# ==============================================================================

# -----------------------------------------------------------------------------
# INPUT / OUTPUT CONTRACT
# -----------------------------------------------------------------------------
# INPUT:
#   $1 - service: name of the service
#   $2 - source_dir: path to the ops config directory
#   $3 - target_dir: path to the runtime config directory
#
# OUTPUT:
#   stdout: formatted status report and hints
#
# SIDE EFFECTS:
#   - None (read-only analysis)
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

plan_service() {
    # ---------------------------------------------------------------------------
    # INPUT
    # ---------------------------------------------------------------------------
    local service="$1"
    local source_dir="$2"
    local target_dir="$3"

    # ---------------------------------------------------------------------------
    # VALIDATION (none)
    # ---------------------------------------------------------------------------

    # ---------------------------------------------------------------------------
    # SETUP
    # ---------------------------------------------------------------------------
    local declared_status
    declared_status="$(get_status "$service" "$source_dir" "$target_dir")"

    local runtime_state
    runtime_state="$(get_runtime_state)"

    local health_state
    health_state="$(get_health_state)"

    local direction
    direction="$(get_drift_direction "$source_dir" "$target_dir")"

    # ---------------------------------------------------------------------------
    # CORE
    # ---------------------------------------------------------------------------

    # --- handle early states ---
    case "$declared_status" in
        EMPTY)
            echo
            log "$service:"
            log "  config status: EMPTY"
            log "  config state: NOT INITIALIZED"
            log "  hint: bootstrap/seed or supply config"
            return 0
            ;;
        INIT)
            echo
            log "$service:"
            log "  config status: INIT"
            log "  config state: NOT DEPLOYED"
            log "  hint: edit config → apply"
            return 0
            ;;
    esac

    # --- determine if stale ---
    local is_stale=false
    [ "$direction" != "NONE" ] && is_stale=true

    local display_status="$declared_status"
    [ "$is_stale" = true ] && display_status="$declared_status (STALE)"

    # --- log general status ---
    echo
    log "$service:"
    log "  runtime: $runtime_state"
    log "  condition: $health_state"
    log "  config status: $display_status"

    # --- check if in sync ---
    if [ "$is_stale" = false ]; then
        log_ok "    config state: IN SYNC ✅"
        return 0
    fi

    log_warn "  config state: DRIFT DETECTED"
    log_warn "  direction: $direction"

    # --- display categorized diff details ---
    local diff_output
    diff_output="$(compare_dirs "$source_dir" "$target_dir" --categories)"

    if [ -n "$diff_output" ]; then
        echo "$diff_output" | while IFS= read -r line; do
            if [[ "$line" == "["* ]]; then
                local section="${line#[}"
                section="${section%]}"
                log "  ${section,,}:"
            elif [ -n "$line" ]; then
                log "    - $line"
            fi
        done
    fi

    # --- provide action hints ---
    case "$declared_status:$direction" in
        APPLIED:OPS_TO_RUNTIME)
            log "  hint: apply → push changes"
            ;;
        APPLIED:RUNTIME_TO_OPS)
            log "  hint: export $service → runtime modified"
            ;;
        EXPORTED:OPS_TO_RUNTIME)
            log "  hint: apply → ops changed after export"
            ;;
        EXPORTED:RUNTIME_TO_OPS)
            log "  hint: export (again)"
            ;;
        *:MIXED)
            log "  hint: conflict! manual review required"
            ;;
        *)
            log "  hint: review state"
            ;;
    esac

    # ---------------------------------------------------------------------------
    # OUTPUT / RETURN
    # ---------------------------------------------------------------------------
    return 0
}
