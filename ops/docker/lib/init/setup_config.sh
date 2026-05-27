# ==============================================================================
# METADATA
# ==============================================================================
# FUNCTION: setup_config
# PURPOSE: Create directory structure for a service
#
# DEPENDENCIES:
#   - logger.sh (log, log_ok, log_warn, die)
#   - create_dirs.sh (create_dirs)
#   - set_status.sh (set_status)
# ==============================================================================

# -----------------------------------------------------------------------------
# INPUT / OUTPUT CONTRACT
# -----------------------------------------------------------------------------
# INPUT:
#   $1 - service: name of the service
#   $2 - ops_service_config_dir: path to the ops config directory
#   $3 - runtime_service_config_dir: path to the runtime config directory
#   $@ - dirs_list: list of names of directories to create
#
# OUTPUT:
#   stdout: log messages indicating created directories
#
# SIDE EFFECTS:
#   - Creates directories on the filesystem
#   - Sets status to "INIT"
#
# RETURNS:
#   0 on success
#   0 if directories already exist (skipped)
#   1 on failure (permission denied, invalid path)
# -----------------------------------------------------------------------------

# ==============================================================================
# IMPLEMENTATION
# ==============================================================================

setup_config() {
    # ---------------------------------------------------------------------------
    # INPUT
    # ---------------------------------------------------------------------------

    local service="$1"
    local ops_service_config_dir="$2"
    local runtime_service_config_dir="$3"
    shift 3
    local dirs_list=("$@")

    # ---------------------------------------------------------------------------
    # VALIDATION
    # ---------------------------------------------------------------------------

    # --- check if dirs list is not empty ---
    if [ ${#dirs_list[@]} -eq 0 ]; then
        log_warn "$service → no directories defined for setup (skipped)"
        return 0
    fi

    # --- check if all directories already exist ---
    local all_exist=true

    for item in "${dirs_list[@]}"; do
        local ops_path="$ops_service_config_dir/$item"
        local runtime_path="$runtime_service_config_dir/$item"

        if [ ! -d "$ops_path" ] || [ ! -d "$runtime_path" ]; then
            all_exist=false
            break
        fi
    done

    if [ "$all_exist" = true ]; then
        log_warn "$service → setup skipped (filesystem already exists)"
	return 0
    fi

    # ---------------------------------------------------------------------------
    # SETUP
    # ---------------------------------------------------------------------------

    # --- build paths ---
    local ops_paths=()
    for item in "${dirs_list[@]}"; do
        ops_paths+=("$ops_service_config_dir/$item")
    done

    local runtime_paths=()
    for item in "${dirs_list[@]}"; do
        runtime_paths+=("$runtime_service_config_dir/$item")
    done

    # ---------------------------------------------------------------------------
    # CORE
    # ---------------------------------------------------------------------------

    # --- log start ---
    log "$service → setup start"

    # --- create OPS directory structure ---
    log "$service → creating directory structure (OPS)"
    run create_dirs "${ops_paths[@]}"

    # --- create RUNTIME directory structure ---
    log "$service → creating directory structure (RUNTIME)"
    run create_dirs "${runtime_paths[@]}"

    # --- set initial status ---
    run set_status "$service" "$ops_service_config_dir" "INIT"

    # ---------------------------------------------------------------------------
    # OUTPUT / RETURN
    # ---------------------------------------------------------------------------
    log_ok "$service → setup complete (filesystem ready)"
    return 0
}

