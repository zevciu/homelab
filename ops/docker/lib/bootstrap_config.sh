# ==============================================================================
# METADATA
# ==============================================================================
# FUNCTION: bootstrap_config
# PURPOSE: Initialize service configuration by copying from a temporary container
#
# DEPENDENCIES:
#   - logger.sh (log, log_ok, log_warn, die)
#   - run.sh (run)
#   - set_status.sh (set_status)
# ==============================================================================

# -----------------------------------------------------------------------------
# INPUT / OUTPUT CONTRACT
# -----------------------------------------------------------------------------
# INPUT:
#   $1 - service: name of the service
#   $2 - ops_service_config_dir: path to the ops config directory
#   $3 - compose_file: path to docker-compose file
#   $@ - files_map: list of "dst:src" mappings (destination:source in container)
#
# OUTPUT:
#   stdout: log messages indicating progress
#
# SIDE EFFECTS:
#   - Starts a temporary container
#   - Copies configuration files from container to ops directory
#   - Stops the container
#   - Sets status to "INIT"
#
# RETURNS:
#   0 on success
#   0 if config already exists (skipped)
#   1 on failure (container unhealthy, copy failed)
# -----------------------------------------------------------------------------

# ==============================================================================
# CONFIGURATION (none)
# ==============================================================================

# ==============================================================================
# IMPLEMENTATION
# ==============================================================================

bootstrap_config() {
    # ---------------------------------------------------------------------------
    # INPUT
    # ---------------------------------------------------------------------------

    # --- map positional arguments to named variables ---
    local service="$1"
    local ops_service_config_dir="$2"
    local compose_file="$3"
    shift 3
    local files_map=("$@")

    # ---------------------------------------------------------------------------
    # VALIDATION
    # ---------------------------------------------------------------------------

    # --- check if config already exists ---
    if [ -d "$ops_service_config_dir" ] && [ "$(ls -A "$ops_service_config_dir" 2>/dev/null)" ]; then
        log_warn "$service → bootstrap skipped (config exists)"
        return 0
    fi

    # ---------------------------------------------------------------------------
    # HELPERS (INTERNAL)
    # ---------------------------------------------------------------------------

    # --- wait for container to become healthy ---
    wait_for_container() {
        local container="$1"
        local max_attempts=30
        local attempt=0

        while [ $attempt -lt $max_attempts ]; do
            local health
            health="$(docker inspect -f '{{.State.Health.Status}}' "$container" 2>/dev/null || true)"

            if [ "$health" = "healthy" ]; then
                log_ok "container healthy"
                return 0
            fi

            sleep 1
            ((attempt++)) || true
        done

        die "container not healthy after $max_attempts attempts"
    }

    # --- copy configuration files from container ---
    copy_configs() {
        local container="$1"
        local target_dir="$2"
        shift 2
        local entries=("$@")

        run mkdir -p "$target_dir"

        for entry in "${entries[@]}"; do
            local dst="${entry%%:*}"
            local src="${entry##*:}"

            if run docker cp "$container:$src" "$target_dir/$dst"; then
                log_ok "copied: $dst"
	    else
		log_warn "copy procedure encountered fatal error"
		stop_containers
    		die "copy failed: $dst"
	    fi
        done
    }

    # ---------------------------------------------------------------------------
    # SETUP (none)
    # ---------------------------------------------------------------------------

    # ---------------------------------------------------------------------------
    # CORE
    # ---------------------------------------------------------------------------

    # --- log start ---
    log "$service → bootstrap start"

    # --- start container ---
    docker compose -f "$compose_file" up -d

    # --- get container ID ---
    local container
    container="$(docker compose -f "$compose_file" ps -q "$service")"

    if [ -z "$container" ]; then
        docker compose -f "$compose_file" down
        die "failed to start container for service: $service"
    fi

    # --- wait for health ---
    wait_for_container "$container"

    # --- copy files ---
    copy_configs "$container" "$ops_service_config_dir" "${files_map[@]}"

    # --- stop container ---
    docker compose -f "$compose_file" down

    # --- set status ---
    run set_status "$service" "$ops_service_config_dir" "INIT"

    # ---------------------------------------------------------------------------
    # OUTPUT / RETURN
    # ---------------------------------------------------------------------------
    return 0
}
