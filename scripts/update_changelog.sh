#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# METADATA
# ==============================================================================
# FUNCTION: update_changelog
# PURPOSE: Automated updater for CHANGELOG.md based on git commits since last tag.
#          Parses commits using format: type(scope)[section]: message
#          Generates Markdown with proper grouping (Added, Changed, Fixed, etc.)
#
# DEPENDENCIES:
#   - git (must be available in PATH)
#   - awk (GNU awk recommended for regex support)
# ==============================================================================

# -----------------------------------------------------------------------------
# INPUT / OUTPUT CONTRACT
# -----------------------------------------------------------------------------
# INPUT:
#   $@ - command-line arguments (--version, --date, --dry-run, --preview-full, --help)
#   Environment: GIT_DIR (must be a valid git repository)
#
# OUTPUT:
#   stdout: Progress messages, preview (if dry-run/preview-full), or success confirmation
#
# SIDE EFFECTS:
#   - Modifies CHANGELOG.md (unless --dry-run or --preview-full is used)
#
# RETURNS:
#   0 on success
#   1 on failure (invalid arguments, not a git repo, no commits)
# -----------------------------------------------------------------------------

# ==============================================================================
# CONFIGURATION
# ==============================================================================

# --- global constants ---
REPO_DIR="$(git rev-parse --show-toplevel)"
CHANGELOG_FILE="$REPO_DIR/docs/CHANGELOG.md"
DEFAULT_VERSION="1.0.0"
COMMIT_SEPARATOR="---COMMIT_BLOCK---"

# ==============================================================================
# IMPLEMENTATION
# ==============================================================================

update_changelog() {
    # ---------------------------------------------------------------------------
    # INPUT
    # ---------------------------------------------------------------------------

    # --- parse command-line arguments ---
    local dry_run=false
    local preview_full=false
    local version=""
    local date=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --version) version="$2"; shift 2 ;;
            --date) date="$2"; shift 2 ;;
            --dry-run) dry_run=true; shift ;;
            --preview-full) preview_full=true; shift ;;
            --help) update_changelog__show_usage; exit 0 ;;
            *) echo "[ERROR] Unknown option: $1"; update_changelog__show_usage; exit 1 ;;
        esac
    done

    # ---------------------------------------------------------------------------
    # VALIDATION
    # ---------------------------------------------------------------------------
    # --- ensure we are in a git repository ---
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "[ERROR] Not a git repository"
        exit 1
    fi

    # ---------------------------------------------------------------------------
    # SETUP
    # ---------------------------------------------------------------------------
    local last_tag
    local commits
    local new_entry

    # --- get last tag ---
    last_tag=$(update_changelog__get_last_tag)

    # --- get commits since last tag ---
    commits=$(update_changelog__get_commits_since_tag "$last_tag")

    if [ -z "$commits" ]; then
        echo "[WARN] No commits found since last tag ($last_tag) or no tags exist."
        exit 0
    fi

    # --- determine version and date ---
    if [ -z "$version" ]; then
        if [ -n "$last_tag" ]; then
            local clean_tag="${last_tag#v}"
            version=$(update_changelog__increment_version "$clean_tag")
        else
            version="$DEFAULT_VERSION"
        fi
    fi

    if [ -z "$date" ]; then
        date=$(date +%Y-%m-%d)
    fi

    echo "[INFO] Generating version: $version for date: $date"
    [ -n "$last_tag" ] && echo "[INFO] Since last tag: $last_tag"

    # --- generate new changelog entry ---
    new_entry=$(update_changelog__generate_markdown "$version" "$date" "$commits")

    # ---------------------------------------------------------------------------
    # CORE
    # ---------------------------------------------------------------------------

    # --- handle preview modes ---
    if [ "$preview_full" = "true" ]; then
        echo "[PREVIEW FULL] Full CHANGELOG.md content after update:"
        echo "=========================================="
        update_changelog__build_full_preview "$new_entry" "$CHANGELOG_FILE"
        echo "=========================================="
        exit 0
    fi

    if [ "$dry_run" = "true" ]; then
        echo "[DRY RUN] Preview of new section only:"
        echo "----------------------------------------"
        echo "$new_entry"
        echo "----------------------------------------"
        exit 0
    fi

    # --- update the actual file ---
    if [ ! -f "$CHANGELOG_FILE" ]; then
        # Create new file
        {
            echo "# Changelog"
            echo ""
            echo "All notable changes to this project will be documented in this file."
            echo ""
            echo "The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),"
            echo "and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)."
            echo ""
            echo "$new_entry"
        } > "$CHANGELOG_FILE"
        echo "[OK] Created $CHANGELOG_FILE"
    else
        # Insert new entry into existing file
        local temp_file
        temp_file=$(mktemp)

        update_changelog__insert_entry "$new_entry" "$CHANGELOG_FILE" > "$temp_file"
        mv "$temp_file" "$CHANGELOG_FILE"
        echo "[OK] Updated $CHANGELOG_FILE (version $version)"
    fi

    # ---------------------------------------------------------------------------
    # OUTPUT / RETURN / FINALIZE
    # ---------------------------------------------------------------------------
    echo ""
    echo "Next steps:"
    echo "  1. Review: git diff $CHANGELOG_FILE"
    echo "  2. Commit: git add $CHANGELOG_FILE && git commit -m \"chore: update CHANGELOG for v$version\""
    echo "  3. Tag: git tag v$version"

    return 0
}

# -----------------------------------------------------------------------------
# HELPERS (INTERNAL)
# -----------------------------------------------------------------------------

update_changelog__show_usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Options:
  --version VERSION    Set version number (default: auto-increment from last tag)
  --date DATE          Set release date (default: today YYYY-MM-DD)
  --dry-run            Show preview of new section only (without history)
  --preview-full       Show preview of entire file (new section + history)
  --help               Show this help message

Examples:
  $0                          # Update file with auto-detected version/date
  $0 --version 2.0.0          # Set specific version
  $0 --date 2026-04-29        # Set specific date
  $0 --dry-run                # Preview new section
  $0 --preview-full           # Preview full file
EOF
}

update_changelog__get_last_tag() {
    git describe --tags --abbrev=0 2>/dev/null || echo ""
}

update_changelog__get_commits_since_tag() {
    local last_tag="$1"
    if [ -n "$last_tag" ]; then
        git log --pretty=format:"%H${COMMIT_SEPARATOR}%B${COMMIT_SEPARATOR}" "${last_tag}..HEAD" 2>/dev/null || true
    else
        git log --pretty=format:"%H${COMMIT_SEPARATOR}%B${COMMIT_SEPARATOR}" HEAD 2>/dev/null || true
    fi
}

update_changelog__increment_version() {
    local current="$1"
    local major minor patch
    IFS='.' read -r major minor patch <<< "$current"
    echo "${major}.${minor}.$((patch + 1))"
}

# --- generates Markdown for the new version using AWK ---
update_changelog__generate_markdown() {
    local version="$1"
    local date="$2"
    local commits_raw="$3"

    echo "$commits_raw" | awk -v version="$version" -v date="$date" '
    BEGIN {
        RS = "'"$COMMIT_SEPARATOR"'"
        FS = "\n"
        
        sections["Added"] = ""
        sections["Changed"] = ""
        sections["Fixed"] = ""
        sections["Security"] = ""
        sections["Removed"] = ""
        
        order[1] = "Added"
        order[2] = "Changed"
        order[3] = "Fixed"
        order[4] = "Security"
        order[5] = "Removed"
    }

    function title_case(str) {
        return toupper(substr(str, 1, 1)) tolower(substr(str, 2))
    }

    function get_section(sec) {
        if (sec ~ /^[Aa]dd/) return "Added"
        if (sec ~ /^[Cc]hange/) return "Changed"
        if (sec ~ /^[Ff]ix/) return "Fixed"
        if (sec ~ /^[Ss]ec/) return "Security"
        if (sec ~ /^[Rr]em/) return "Removed"
        return "Changed"
    }

    {
        if (NF == 0) next
        
        subject = $1
        
        body = ""
        for (i = 2; i <= NF; i++) {
            if ($i != "") {
                body = body $i "\n"
            }
        }
        
        # --- regex: type(scope)[section]: message ---
        if (match(subject, /^([a-zA-Z]+)(\([^)]+\))?(\[[a-zA-Z]+\])?: (.*)$/, arr)) {
            type = arr[1]
	    scope = arr[2]
            section_raw = arr[3]
            message = arr[4]
            
            gsub(/\[|\]/, "", section_raw)
            
            type_label = title_case(type)
            section_name = get_section(section_raw)
            
            # --- build main line scope if present
            if (scope != "") {
                # --- remove parentheses ---
                gsub(/\(|\)/, "", scope)
                main_line = "- [" type_label "] (" scope ") " message
            } else {
                main_line = "- [" type_label "] " message
            }
            
            body_lines = ""
            n = split(body, body_arr, "\n")
            for (i = 1; i <= n; i++) {
                line = body_arr[i]
                if (line == "") continue
                
                if (match(line, /^[[:space:]]*- /)) {
                    body_lines = body_lines "  " line "\n"
                }
            }
            
            sections[section_name] = sections[section_name] main_line "\n"
            if (body_lines != "") {
                sections[section_name] = sections[section_name] body_lines "\n"
            }
        }
    }

    END {
        print "## [" version "] - " date
        print ""
        
        for (i = 1; i <= 5; i++) {
            sec = order[i]
            if (sections[sec] != "") {
                print "### " sec
                gsub(/\n+$/, "", sections[sec])
                print sections[sec]
                print ""
            }
        }
    }
    '
}

# --- builds the full preview (new entry + existing history) ---
update_changelog__build_full_preview() {
    local new_entry="$1"
    local existing_file="$2"
    
    if [ ! -f "$existing_file" ]; then
        {
            echo "# Changelog"
            echo ""
            echo "All notable changes to this project will be documented in this file."
            echo ""
            echo "The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),"
            echo "and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)."
            echo ""
            echo "$new_entry"
        }
        return
    fi
    
    update_changelog__insert_entry "$new_entry" "$existing_file"
}

# --- inserts the new entry into the file content (used by both preview and update) ---
update_changelog__insert_entry() {
    local new_entry="$1"
    local source_file="$2"
    
    local header_done=false
    local inserted=false
    
    {
        while IFS= read -r line || [ -n "$line" ]; do
            echo "$line"
            
            if [ "$line" = "# Changelog" ]; then
                header_done=true
                continue
            fi
            
            if [ "$header_done" = "true" ] && [ "$inserted" = "false" ]; then
                if [[ "$line" =~ ^##\ \[ ]]; then
                    echo "$new_entry"
                    inserted=true
                fi
            fi
        done < "$source_file"
        
        if [ "$header_done" = "true" ] && [ "$inserted" = "false" ]; then
            echo "$new_entry"
        fi
        
    }
}

# ==============================================================================
# ENTRYPOINT
# ==============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    update_changelog "$@"
fi
