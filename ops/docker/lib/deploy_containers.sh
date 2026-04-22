# ==============================================================================
# METADATA
# ==============================================================================
# FUNCTION: deploy_containers
# PURPOSE: Deploy Docker containers after validating service status
#
# DEPENDENCIES:
#   - logger.sh (log, log_ok, die)
#   - get_status.sh (get_status)
#   - get_runtime_state.sh (get_runtime_state)
#   - run.sh (run)
# ==============================================================================

# -----------------------------------------------------------------------------
# INPUT / OUTPUT CONTRACT
# -----------------------------------------------------------------------------
# INPUT:
#   $SERVICES: array of service names (required env var)
#   $PROJECT_OPS_ROOT: path to ops config root (required env var)
#   $PROJECT_RUNTIME_ROOT: path to runtime root (required env var)
#   $DOCKER_COMPOSE: path to docker-compose.yml (required env var)
#
# OUTPUT:
#   stdout: log messages indicating progress
#
# SIDE EFFECTS:
#   - Starts Docker containers
#
# RETURNS:
#   0 on success
#   1 on failure (invalid status, containers already running)
# -----------------------------------------------------------------------------

# ==============================================================================
# CONFIGURATION (provided)
# ==============================================================================
# --- assumed to be set by env.sh ---

# ==============================================================================
# IMPLEMENTATION
# ==============================================================================

deploy_containers() {
    # ---------------------------------------------------------------------------
    # INPUT (provided)
    # ---------------------------------------------------------------------------
    # --- assumed to be set by orchestrator_*.sh ---

    # ---------------------------------------------------------------------------
    # VALIDATION
    # ---------------------------------------------------------------------------

    # --- validate required environment variables ---
    if [ -z "${SERVICES[*]:-}" ]; then
        die "deploy_cmd: SERVICES array is not set"
    fi

    # --- log start ---
    log "deploy → checking services..."

    # --- validate status for each service ---
    for service in "${SERVICES[@]}"; do
        local ops_service_config_dir="$PROJECT_OPS_ROOT/$service"
        local runtime_service_config_dir="$PROJECT_RUNTIME_ROOT/$service"

        local status
        status=$(get_status "$service" "$ops_service_config_dir" "$runtime_service_config_dir")

        case "$status" in
            APPLIED|EXPORTED)
                log "$service → OK ($status)"
                ;;
            *)
                die "$service → invalid status: $status (required: APPLIED|EXPORTED)"
                ;;
        esac
    done

    # --- check if containers are already running ---
    local runtime_state
    runtime_state=$(get_runtime_state)

    if [ "$runtime_state" = "running" ]; then
        die "containers already running → aborting deploy"
    fi

    # ---------------------------------------------------------------------------
    # SETUP (none)
    # ---------------------------------------------------------------------------

    # ---------------------------------------------------------------------------
    # CORE
    # ---------------------------------------------------------------------------

    # --- start containers ---
    log "starting containers..."
    run docker compose -f "$DOCKER_COMPOSE" up -d

    # --- log success ---
    log_ok "deploy completed"

    # ---------------------------------------------------------------------------
    # OUTPUT / RETURN
    # ---------------------------------------------------------------------------
    return 0
}
