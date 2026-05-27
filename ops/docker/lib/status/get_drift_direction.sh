# ==============================================================================
# METADATA
# ==============================================================================
# FUNCTION: get_drift_direction
# PURPOSE: Determine the direction of config drift
#
# DEPENDENCIES:
#   - compare_dirs.sh (compare_dirs)
#   - logger.sh (log_debug)
# ==============================================================================

# -----------------------------------------------------------------------------
# INPUT / OUTPUT CONTRACT
# -----------------------------------------------------------------------------
# INPUT:
#   $1 - source_dir: path to the source directory (OPS)
#   $2 - target_dir: path to the target directory (RUNTIME)
#
# OUTPUT:
#   stdout: Direction string (NONE, OPS_TO_RUNTIME, RUNTIME_TO_OPS, MIXED)
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

get_drift_direction() {
    # ---------------------------------------------------------------------------
    # INPUT
    # ---------------------------------------------------------------------------

    # --- map positional arguments to named variables ---
    local source_dir="$1"
    local target_dir="$2"

    # ---------------------------------------------------------------------------
    # VALIDATION (none)
    # ---------------------------------------------------------------------------

    # ---------------------------------------------------------------------------
    # SETUP
    # ---------------------------------------------------------------------------

    # --- initialize counters for diff types ---
    local modified_count=0
    local only_source_count=0
    local only_target_count=0

    local ops_newer=false
    local runtime_newer=false

    # --- array to store modified files for timestamp check ---
    local modified_files=()

    # ---------------------------------------------------------------------------
    # CORE
    # ---------------------------------------------------------------------------

    # --- gather and parse diff details ---
    while IFS= read -r line; do
        local type="${line%%:*}"
        local file="${line#*:}"

        case "$type" in
            MODIFIED)
                ((modified_count++)) || true
                modified_files+=("$file")
                ;;
            ONLY_SOURCE)
                ((only_source_count++)) || true
                ;;
            ONLY_TARGET)
                ((only_target_count++)) || true
                ;;
        esac
    done < <(compare_dirs "$source_dir" "$target_dir")

    # --- compare timestamps of modified files ---
    for file in "${modified_files[@]}"; do
        local src="$source_dir/$file"
        local tgt="$target_dir/$file"

        [ ! -f "$src" ] && continue
        [ ! -f "$tgt" ] && continue

        if [ "$src" -nt "$tgt" ]; then
            ops_newer=true
        elif [ "$tgt" -nt "$src" ]; then
            runtime_newer=true
        fi
    done

    # --- determine direction based on counts and timestamps ---
    local result="MIXED" # Default fallback

    if [ "$modified_count" -eq 0 ] \
       && [ "$only_source_count" -eq 0 ] \
       && [ "$only_target_count" -eq 0 ]; then
        log_debug "get_drift_direction: no changes → NONE"
        result="NONE"

    elif [ "$only_source_count" -gt 0 ] \
         && [ "$only_target_count" -eq 0 ] \
         && [ "$modified_count" -eq 0 ]; then
        log_debug "get_drift_direction: only in SOURCE → OPS_TO_RUNTIME"
        result="OPS_TO_RUNTIME"

    elif [ "$only_target_count" -gt 0 ] \
         && [ "$only_source_count" -eq 0 ] \
         && [ "$modified_count" -eq 0 ]; then
        log_debug "get_drift_direction: only in TARGET → RUNTIME_TO_OPS"
        result="RUNTIME_TO_OPS"

    elif [ "$only_source_count" -gt 0 ] \
         && [ "$only_target_count" -gt 0 ]; then
        log_debug "get_drift_direction: both have different files → MIXED"
        result="MIXED"

    elif [ "$ops_newer" = true ] && [ "$runtime_newer" = false ]; then
        log_debug "get_drift_direction: ops has newer files → OPS_TO_RUNTIME"
        result="OPS_TO_RUNTIME"

    elif [ "$runtime_newer" = true ] && [ "$ops_newer" = false ]; then
        log_debug "get_drift_direction: runtime has newer files → RUNTIME_TO_OPS"
        result="RUNTIME_TO_OPS"

    elif [ "$ops_newer" = true ] && [ "$runtime_newer" = true ]; then
        log_debug "get_drift_direction: both have newer files → MIXED"
        result="MIXED"
    fi

    # ---------------------------------------------------------------------------
    # OUTPUT / RETURN
    # ---------------------------------------------------------------------------
    echo "$result"
    return 0
}
