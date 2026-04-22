# ==============================================================================
# METADATA
# ==============================================================================
# FUNCTION: destroy_environment
# PURPOSE: Remove Docker containers, volumes, and configuration files for specific services
#
# DEPENDENCIES:
#   - logger.sh (log, log_ok, log_err, die)
#   - get_status.sh (get_status)
#   - set_status.sh (set_status)
#   - run.sh (run)
#   - confirm_action.sh (confirm_action)
#   - get_runtime_state.sh (get_runtime_state)
# ==============================================================================

# -----------------------------------------------------------------------------
# INPUT / OUTPUT CONTRACT
# -----------------------------------------------------------------------------
# INPUT:
#   $1 - target: service name OR "--all" (REQUIRED)
#   $@ - flags: --runtime, --ops (AT LEAST ONE REQUIRED)
#   $SERVICES: array of all service names (required env var)
#   $PROJECT_OPS_ROOT: path to ops config root (required env var)
#   $PROJECT_RUNTIME_ROOT: path to runtime root (required env var)
#
# OUTPUT:
#   stdout: log messages indicating progress
#
# SIDE EFFECTS:
#   - Removes runtime directories
#   - Removes ops directories
#   - Updates status files
#
# RETURNS:
#   0 on success
#   1 on failure (missing arguments, invalid flags, aborted confirmation)
# -----------------------------------------------------------------------------

# ==============================================================================
# CONFIGURATION
# ==============================================================================
# All required env vars assumed to be provided by env.sh

# ==============================================================================
# IMPLEMENTATION
# ==============================================================================

destroy_environment() {
    # ---------------------------------------------------------------------------
    # INPUT
    # ---------------------------------------------------------------------------

    # --- initialize flags and target ---
    local runtime_flag=false
    local ops_flag=false
    local target=""

    # --- parse arguments ---
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --runtime) runtime_flag=true ;;
            --ops) ops_flag=true ;;
            --all) target="all" ;;
            *)
                if [ -z "$target" ]; then
                    target="$1"
                else
                    die "too many arguments: expected <service|--all> followed by flags"
                fi
                ;;
        esac
        shift
    done

    # ---------------------------------------------------------------------------
    # VALIDATION
    # ---------------------------------------------------------------------------

    # --- validate target is provided ---
    if [ -z "$target" ]; then
        die "destroy requires <service|--all>"
    fi

    # --- validate at least one deletion mode is selected ---
    if [ "$runtime_flag" = false ] && [ "$ops_flag" = false ]; then
        die "destroy requires at least one of: --runtime or --ops"
    fi

    # --- warn if containers are running ---
    local runtime_state
    runtime_state="$(get_runtime_state)"

    if [ "$runtime_state" = "running" ]; then
        log_warn "containers are running"
        log "consider running: $SCRIPT_NAME stop"
    fi

    # ---------------------------------------------------------------------------
    # HELPERS (INTERNAL)
    # ---------------------------------------------------------------------------

    # --- resolve target list based on input ---
    get_targets() {
        if [ "$target" = "all" ]; then
            echo "${SERVICES[@]}"
        else
            echo "$target"
        fi
    }

    # ---------------------------------------------------------------------------
    # SETUP (none)
    # ---------------------------------------------------------------------------

    # ---------------------------------------------------------------------------
    # CORE
    # ---------------------------------------------------------------------------

    # --- handle runtime destruction ---
    if [ "$runtime_flag" = true ]; then
        log "destroy → target: runtime config ($target)"

    	confirm_action "are you sure you want to delete runtime data?"

    	for service in $(get_targets); do
    		local ops_dir="$PROJECT_OPS_ROOT/$service"
        	local runtime_dir="$PROJECT_RUNTIME_ROOT/$service"

        	if [ -d "$runtime_dir" ]; then
        		log "removing $service runtime config dir: $runtime_dir"
                	run rm -rf "$runtime_dir"
                	log_ok "destroy completed → runtime config removed ($service)"

                	# --- update status based on new state ---
                	local new_status
                	new_status=$(get_status "$service" "$ops_dir" "$runtime_dir")
                	run set_status "$service" "$ops_dir" "$new_status"
		else
                	log_err "destroy failed → runtime config not found ($service)"
        	fi
    	done
    fi

    # --- handle ops destruction ---
    if [ "$ops_flag" = true ]; then
        log "destroy → target: ops config ($target)"

        confirm_action "are you sure you want to delete ops data?"

        for service in $(get_targets); do
                local ops_dir="$PROJECT_OPS_ROOT/$service"
                local runtime_dir="$PROJECT_RUNTIME_ROOT/$service"

                if [ -d "$ops_dir" ]; then
                    log "removing $service ops config dir: $ops_dir"
                    run rm -rf "$ops_dir"
                    log_ok "destroy completed → ops config removed ($service)"
                else
                    log_err "destroy failed → ops config not found ($service)"
                fi
        done
    fi

    # ---------------------------------------------------------------------------
    # OUTPUT / RETURN
    # ---------------------------------------------------------------------------
    return 0
}
