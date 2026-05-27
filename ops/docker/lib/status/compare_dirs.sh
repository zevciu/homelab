# ==============================================================================
# METADATA
# ==============================================================================
# FUNCTION: compare_dirs
# PURPOSE: Compare two directories and output differences in various formats
#
# MODES:
#   Default (no flags): Outputs "TYPE:FILENAME" (e.g., "MODIFIED:file.txt")
#   --list: Outputs flat list of filenames (MODIFIED + ONLY_SOURCE)
#   --categories: Outputs grouped list with headers
#
# DEPENDENCIES:
#   - logger.sh (log_debug)
# ==============================================================================

# -----------------------------------------------------------------------------
# INPUT / OUTPUT CONTRACT
# -----------------------------------------------------------------------------
# INPUT:
#   $1 - source_dir: path to the source directory
#   $2 - target_dir: path to the target directory
#   $@ - optional flags: --list, --categories
#
# OUTPUT:
#   stdout: Formatted diff output based on mode
#
# SIDE EFFECTS:
#   - None (read-only comparison)
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

compare_dirs() {
    # ---------------------------------------------------------------------------
    # INPUT
    # ---------------------------------------------------------------------------

    # --- map positional arguments to named variables ---
    local source_dir=""
    local target_dir=""
    local mode="detailed" # Options: detailed, list, categories

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --list)
                mode="list"
                shift
                ;;
            --categories)
                mode="categories"
                shift
                ;;
            -*)
                log_err "unknown option: $1"
                return 1
                ;;
            *)
                if [ -z "$source_dir" ]; then
                    source_dir="$1"
                elif [ -z "$target_dir" ]; then
                    target_dir="$1"
                else
                    log_err "too many arguments"
                    return 1
                fi
                shift
                ;;
        esac
    done

    # ---------------------------------------------------------------------------
    # VALIDATION
    # ---------------------------------------------------------------------------

    # --- validate required arguments ---
    if [ -z "$source_dir" ] || [ -z "$target_dir" ]; then
        log_err "compare_dirs → source_dir and target_dir are required"
        return 1
    fi

    # --- validate directories exist ---
    if [ ! -d "$source_dir" ]; then
        log_debug "compare_dirs → source dir is missing"
        return 0
    fi

    if [ ! -d "$target_dir" ]; then
        log_debug "compare_dirs → target dir is missing"
        return 0
    fi

    # ---------------------------------------------------------------------------
    # SETUP
    # ---------------------------------------------------------------------------

    # --- initialize arrays to store results for categorization ---
    local modified_files=()
    local only_source_files=()
    local only_target_files=()

    # ---------------------------------------------------------------------------
    # HELPERS (INTERNAL)
    # ---------------------------------------------------------------------------

    # --- parse "Only in <dir>: <item>" line into relative path ---
    # Handles format: "Only in /path/to/base/subdir: filename"
    # Returns: "subdir/filename"
    parse_only_in_line() {
    	local line="$1"
    	local base_dir="$2"

    	local rest="${line#Only in }"
    	local dir_part="${rest%%: *}"
    	local file_part="${rest#*: }"

    	local rel_dir="${dir_part#$base_dir}"
    	rel_dir="${rel_dir#/}"

    	if [ -z "$rel_dir" ]; then
        	echo "$file_part"
    	else
        	echo "$rel_dir/$file_part"
    	fi
    }

    expand_to_files() {
        local path="$1"
        local base_dir="$2"
        local full_path="$base_dir/$path"

        if [ -d "$full_path" ]; then
            # --- it's a directory: find all files inside and print relative paths ---
            find "$full_path" -type f | sed "s|^$base_dir/||"
        else
            # --- it's a file: just echo the path ---
            echo "$path"
        fi
    }

    # ---------------------------------------------------------------------------
    # CORE
    # ---------------------------------------------------------------------------

    # --- parse diff output and collect results ---
    while IFS= read -r line; do
        local file=""
        local type=""

        # --- handle modified files ---
        if [[ "$line" == Files* ]]; then
            file=$(echo "$line" | awk '{print $2}' | sed "s|$source_dir/||")
            [[ "$file" == ".status" || "$file" == .backup/* ]] && continue
            type="MODIFIED"
            modified_files+=("$file")

        # --- handle files only in source ---
        elif [[ "$line" == Only\ in\ "$source_dir"* ]]; then
            file=$(parse_only_in_line "$line" "$source_dir")
            [[ "$file" == ".status" || "$file" == .backup/* ]] && continue
            type="ONLY_SOURCE"
            only_source_files+=("$file")

        # --- handle files only in target ---
        elif [[ "$line" == Only\ in\ "$target_dir"* ]]; then
            file=$(parse_only_in_line "$line" "$target_dir")
            [[ "$file" == ".status" || "$file" == .backup/* ]] && continue
            type="ONLY_TARGET"
            only_target_files+=("$file")
        fi
    done < <(
        diff -qr "$source_dir" "$target_dir" \
            --exclude=".status" \
            --exclude=".backup"
    )

    # --- output based on mode ---
    if [ "$mode" = "list" ]; then
        {
            if [ ${#modified_files[@]} -gt 0 ]; then
                for f in "${modified_files[@]}"; do
                    expand_to_files "$f" "$source_dir"
                done
            fi

            if [ ${#only_source_files[@]} -gt 0 ]; then
                for f in "${only_source_files[@]}"; do
                    expand_to_files "$f" "$source_dir"
                done
            fi
        } | sort -u

    elif [ "$mode" = "categories" ]; then
        if [ ${#modified_files[@]} -gt 0 ]; then
            echo "[MODIFIED]"
            printf '%s\n' "${modified_files[@]}"
            echo ""
        fi

        if [ ${#only_source_files[@]} -gt 0 ]; then
            echo "[ONLY_SOURCE]"
            printf '%s\n' "${only_source_files[@]}"
            echo ""
        fi

        if [ ${#only_target_files[@]} -gt 0 ]; then
            echo "[ONLY_TARGET]"
            printf '%s\n' "${only_target_files[@]}"
            echo ""
        fi

    else
        # Default: TYPE:FILE
        {
            for f in "${modified_files[@]}"; do echo "MODIFIED:$f"; done 2>/dev/null || true
            for f in "${only_source_files[@]}"; do echo "ONLY_SOURCE:$f"; done 2>/dev/null || true
            for f in "${only_target_files[@]}"; do echo "ONLY_TARGET:$f"; done 2>/dev/null || true
        }
    fi

    # ---------------------------------------------------------------------------
    # OUTPUT / RETURN
    # ---------------------------------------------------------------------------
    return 0
}
