# ==============================================================================
# METADATA
# ==============================================================================
# FUNCTION: get_health_state
# PURPOSE: Check the health status of running containers
#
# DEPENDENCIES:
#   - get_runtime_state()
#   - None (uses docker inspect)
# ==============================================================================

# -----------------------------------------------------------------------------
# INPUT / OUTPUT CONTRACT
# -----------------------------------------------------------------------------
# INPUT:
#   $DOCKER_COMPOSE: path to docker-compose.yml (required env var)
#
# OUTPUT:
#   stdout: "healthy", "unhealthy", "starting", or "N/A"
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

get_health_state() {
    # ---------------------------------------------------------------------------
    # INPUT (none)
    # ---------------------------------------------------------------------------

    # ---------------------------------------------------------------------------
    # VALIDATION (none)
    # ---------------------------------------------------------------------------

    # ---------------------------------------------------------------------------
    # SETUP
    # ---------------------------------------------------------------------------

    # --- get runtime state ---
    local runtime_state
    runtime_state="$(get_runtime_state)"

    # --- define variables for health checks ---
    local container_ids
    local has_starting=false
    local has_unhealthy=false

    # ---------------------------------------------------------------------------
    # CORE
    # ---------------------------------------------------------------------------

    # --- check if containers are running ---
    if [ "$runtime_state" != "running" ]; then
        echo "N/A"
        return 0
    fi

    # --- get container IDs ---
    container_ids=$(docker compose -f "$DOCKER_COMPOSE" ps -q 2>/dev/null || true)

    # --- iterate through containers to check health ---
    for cid in $container_ids; do
        local health
        health=$(docker inspect --format='{{.State.Health.Status}}' "$cid" 2>/dev/null || echo "unknown")

        case "$health" in
            unhealthy)
                has_unhealthy=true
                ;;
            starting)
                has_starting=true
                ;;
        esac
    done

    # ---------------------------------------------------------------------------
    # OUTPUT / RETURN
    # ---------------------------------------------------------------------------

    # --- determine overall health state ---
    if [ "$has_unhealthy" = true ]; then
        echo "unhealthy"
    elif [ "$has_starting" = true ]; then
        echo "starting"
    else
        echo "healthy"
    fi

    return 0
}
