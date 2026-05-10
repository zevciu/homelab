# ==============================================================================
# METADATA
# ==============================================================================
# FUNCTION: seed_config
# PURPOSE: Create initial empty configuration files for a service
#
# DEPENDENCIES:
#   - logger.sh (log, log_warn, log_ok)
#   - run.sh (run)
#   - set_status.sh (set_status)
#   - create_files.sh (create_files)
# ==============================================================================

# -----------------------------------------------------------------------------
# INPUT / OUTPUT CONTRACT
# -----------------------------------------------------------------------------
# INPUT:
#   $1 - service: name of the service
#   $2 - ops_service_config_dir: path to the ops config directory
#   $@ - seed_files: list of file paths to create (relative to ops_service_config_dir)
#
# OUTPUT:
#   stdout: log messages indicating progress
#
# SIDE EFFECTS:
#   - Creates empty files in the ops config directory
#   - Sets status to "INIT"
#
# RETURNS:
#   0 on success
#   0 if config already exists (skipped)
# -----------------------------------------------------------------------------

# ==============================================================================
# CONFIGURATION (none)
# ==============================================================================

# ==============================================================================
# IMPLEMENTATION
# ==============================================================================

seed_config() {
    # ---------------------------------------------------------------------------
    # INPUT
    # ---------------------------------------------------------------------------

    # --- map positional arguments to named variables ---
    local service="$1"
    local ops_service_config_dir="$2"
    shift 2
    local seed_files=("$@")

    # ---------------------------------------------------------------------------
    # VALIDATION
    # ---------------------------------------------------------------------------

    # --- check if seed files already exist ---
    local all_exist=true

    for file in "${seed_files[@]}"; do
    	local path="$ops_service_config_dir/$file"
    	if [ ! -f "$path" ]; then
            all_exist=false
            break
    	fi
    done

    if [ "$all_exist" = true ]; then
    	log_warn "$service → seed skipped (files exist)"
    	return 0
    fi

    # ---------------------------------------------------------------------------
    # SETUP
    # ---------------------------------------------------------------------------

    # --- convert relative paths from input to absolute paths (required by create_files) ---
    local full_paths=()
    for file in "${seed_files[@]}"; do
        full_paths+=("$ops_service_config_dir/$file")
    done

    # ---------------------------------------------------------------------------
    # CORE
    # ---------------------------------------------------------------------------

    # --- log start ---
    log "$service → seeding config"

    # --- create seed files ---
    run create_files "${full_paths[@]}"

    # --- set initial status ---
    run set_status "$service" "$ops_service_config_dir" "INIT"

    # ---------------------------------------------------------------------------
    # OUTPUT / RETURN
    # ---------------------------------------------------------------------------
    return 0
}
