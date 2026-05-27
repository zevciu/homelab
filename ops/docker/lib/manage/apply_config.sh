# ==============================================================================
# METADATA
# ==============================================================================
# FUNCTION: apply_config
# PURPOSE: Apply configuration files from ops directory to runtime directory
#
# DEPENDENCIES:
#   - logger.sh (log, log_ok, die)
#   - status.sh (get_status, set_status)
#   - backup_config.sh (backup_config)
#   - confirm_action.sh (confirm_action)
#   - auto_detect.sh (detect_changes)
#   - run.sh (run)
# ==============================================================================

# -----------------------------------------------------------------------------
# INPUT / OUTPUT CONTRACT
# -----------------------------------------------------------------------------
# INPUT:
#   $1 - service: name of the service
#   $2 - ops_service_config_dir: source directory (ops)
#   $3 - runtime_service_config_dir: target directory (runtime)
#   $@ - flags: --full, --auto, --force, or specific files
#
# OUTPUT:
#   stdout: log messages indicating progress
#
# SIDE EFFECTS:
#   - Copies files from ops to runtime
#   - Creates backup if needed
#   - Updates .status file to "APPLIED"
#
# RETURNS:
#   0 on success
#   1 on failure (missing dirs, invalid flags, aborted confirmation)
# -----------------------------------------------------------------------------

# ==============================================================================
# CONFIGURATION (none)
# ==============================================================================

# ==============================================================================
# IMPLEMENTATION
# ==============================================================================

apply_config() {
    # ---------------------------------------------------------------------------
    # INPUT
    # ---------------------------------------------------------------------------

    # --- map positional arguments to named variables ---
    local service="$1"
    local ops_service_config_dir="$2"
    local runtime_service_config_dir="$3"
    shift 3

    # --- initialize flags and arrays ---
    local force_flag=false
    local full_flag=false
    local auto_flag=false
    local selected_files=()

    # --- parse arguments ---
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --force) force_flag=true ;;
            --full) full_flag=true ;;
            --auto) auto_flag=true ;;
            --*) die "$service → unknown flag: $1 (use --full, --auto, --force)" ;;
            *) selected_files+=("$1") ;;
        esac
        shift
    done


    # ---------------------------------------------------------------------------
    # VALIDATION
    # ---------------------------------------------------------------------------

    # --- validate source directory exists ---
    [ ! -d "$ops_service_config_dir" ] && die "aborting apply ($service) → ops config dir missing"

    # --- ensure target directory exists ---
    mkdir -p "$runtime_service_config_dir"

    # --- validate mode selection ---
    local mode_count=0
    [ "$full_flag" = true ] && mode_count=$((mode_count + 1))
    [ "$auto_flag" = true ] && mode_count=$((mode_count + 1))
    [ "${#selected_files[@]}" -gt 0 ] && mode_count=$((mode_count + 1))

    [ "$mode_count" -eq 0 ] && die "$service → must specify one of: --full | --auto | <files...>"
    [ "$mode_count" -gt 1 ] && die "$service → cannot combine modes (--full | --auto | files)"

    # ---------------------------------------------------------------------------
    # SETUP
    # ---------------------------------------------------------------------------

    # --- define context variables ---
    local source_dir="$ops_service_config_dir"
    local target_dir="$runtime_service_config_dir"
    local status
    status=$(get_status "$service" "$source_dir" "$target_dir")

    # ---------------------------------------------------------------------------
    # CORE
    # ---------------------------------------------------------------------------

    # --- detect files to process ---
    if [ "$full_flag" = true ]; then
        mapfile -t selected_files < <(
            find "$source_dir" -type f \
            ! -name ".status" \
            ! -path "*/.backup/*" \
            | sed "s|^$source_dir/||"
        )
    elif [ "$auto_flag" = true ]; then
        mapfile -t selected_files < <(compare_dirs "$source_dir" "$target_dir" --list | sort -u)
    fi

    # --- check if any files were selected ---
    if [ "${#selected_files[@]}" -eq 0 ]; then
        log "$service → no changes detected"
        return 0
    fi

    # --- log selected files ---
    log "$service → files to process: ${#selected_files[@]}"
    for f in "${selected_files[@]}"; do
        log "  - $f"
    done

    # --- confirm action ---
    if ! confirm_action "$service → Apply ${#selected_files[@]} files?"; then
        return 0
    fi

    # --- execute backup if needed ---
    case "$status" in
        INIT|EMPTY)
            log "$service → status=$status, skipping backup"
            ;;
        *)
            backup_config "$service" "$target_dir"
            ;;
    esac

    # --- copy files ---
    for file in "${selected_files[@]}"; do
        local src="$source_dir/$file"
        local dst="$target_dir/$file"

        log "$service → applying: $file"

        run mkdir -p "$(dirname "$dst")"
        run rsync -av "$src" "$dst"
    done

    # --- finalize ---
    log_ok "$service → apply complete"
    run set_status "$service" "$source_dir" "APPLIED"

    # ---------------------------------------------------------------------------
    # OUTPUT / RETURN
    # ---------------------------------------------------------------------------
    return 0
}
