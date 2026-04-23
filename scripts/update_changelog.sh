#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# METADATA
# ==============================================================================
# FUNCTION: update_changelog
# PURPOSE: Automated updater for CHANGELOG.md based on git commits
#
# DEPENDENCIES:
#   - None (self-contained, uses standard git/bash tools)
# ==============================================================================

# -----------------------------------------------------------------------------
# INPUT / OUTPUT CONTRACT
# -----------------------------------------------------------------------------
# INPUT:
#   $@ - command-line arguments (--version, --date, --dry-run, --help)
#   Environment: GIT_DIR (must be a valid git repository)
#
# OUTPUT:
#   stdout: Progress messages, preview (if dry-run), or success confirmation
#
# SIDE EFFECTS:
#   - Modifies CHANGELOG.md
#   - Modifies METADATA.json (if exists)
#
# RETURNS:
#   0 on success
#   1 on failure (invalid arguments, not a git repo, no commits)
# -----------------------------------------------------------------------------

# ==============================================================================
# CONFIGURATION
# ==============================================================================

REPO_DIR="$(git rev-parse --show-toplevel)"

CHANGELOG_FILE="$REPO_DIR/CHANGELOG.md"
VERSION_FILE="$REPO_DIR/METADATA.json"
DEFAULT_VERSION="1.0.0"

# ==============================================================================
# IMPLEMENTATION
# ==============================================================================

update_changelog() {
    # ---------------------------------------------------------------------------
    # INPUT
    # ---------------------------------------------------------------------------
    # --- parse command-line arguments ---
    local dry_run=false
    local version=""
    local date=""

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
    local current_version
    local next_version
    local release_date

    # ---------------------------------------------------------------------------
    # HELPERS (INTERNAL)
    # ---------------------------------------------------------------------------

    update_changelog__show_usage() {
        cat <<EOF
Usage: $0 [OPTIONS]

Options:
  --version VERSION    Set version number (default: auto-increment)
  --date DATE          Set release date (default: today)
  --dry-run            Show what would change without modifying files
  --help               Show this help message

Examples:
  $0                          # Auto-detect version and date
  $0 --version 1.4.0          # Set specific version
  $0 --date 2026-03-20        # Set specific date
  $0 --dry-run                # Preview changes
EOF
    }

    update_changelog__get_current_version() {
        # --- extract latest version from CHANGELOG.md ---
        if grep -q "^\[Unreleased\]" "$CHANGELOG_FILE" 2>/dev/null; then
            # --- get version from previous section ---
            grep -E "^## \[[0-9]+\.[0-9]+\.[0-9]+\]" "$CHANGELOG_FILE" | head -1 | \
                sed 's/## \[\([0-9.]*\)\]/\1/'
        else
            echo "$DEFAULT_VERSION"
        fi
    }

    update_changelog__increment_version() {
        # --- increment patch version ---
        local current="$1"
        local major minor patch
        IFS='.' read -r major minor patch <<< "$current"
        echo "${major}.${minor}.$((patch + 1))"
    }

    update_changelog__parse_commits() {
        # --- get commits since last tag or all commits ---
        local since_tag="${1:-}"
        local commits=""

        if [ -n "$since_tag" ]; then
            commits=$(git log --pretty=format:"%s" "${since_tag}..HEAD" 2>/dev/null || true)
        else
            commits=$(git log --pretty=format:"%s" HEAD 2>/dev/null || true)
        fi

        echo "$commits"
    }

    update_changelog__categorize_commits() {
        # --- categorize commits by type (feat, fix, change, etc.) ---
        local commits="$1"
        local added="" changed="" fixed="" security="" removed=""

        while IFS= read -r line || [[ -n "$line" ]]; do
    		[ -z "$line" ] && continue

    		# --- extract type (prefix before colon) ---
    		local type=""
    		local msg="$line"

    		if [[ "$line" == *:* ]]; then
        	    type="${line%%:*}"
        	    msg="${line#*: }"
    		fi

    		# --- normalize type (capitalize first letter) ---
    		local tag=""
    		if [ -n "$type" ]; then
        	    tag="[$(echo "$type" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')] "
    		fi

    		# --- strip existing tags like [Docs], [Feat] ---
                local msg_clean="$msg"
	        msg_clean="$(echo "$msg" | sed 's/^\[[^]]*\] //')"
                msg_clean="${msg_clean,,}"

    		# --- classify by meaning ---
    		if [[ "$msg_clean" =~ (add|create|introduce|implement|init|initial) ]]; then
        	    added="${added}- ${tag}${msg}"$'\n'

    		elif [[ "$msg_clean" =~ (update|change|modify|refactor|improve) ]]; then
        	    changed="${changed}- ${tag}${msg}"$'\n'

    		elif [[ "$msg_clean" =~ (fix|resolve|bugfix|patch|correct) ]]; then
        	    fixed="${fixed}- ${tag}${msg}"$'\n'

    		elif [[ "$msg_clean" =~ (remove|delete|drop|cleanup) ]]; then
        	    removed="${removed}- ${tag}${msg}"$'\n'

    		elif [[ "$msg_clean" =~ (security) ]]; then
        	    security="${security}- ${tag}${msg}"$'\n'

    		else
        	    # fallback
        	    added="${added}- ${tag}${msg}"$'\n'
    		fi

	done <<< "$commits"

        echo "ADDED:$added"
        echo "CHANGED:$changed"
        echo "FIXED:$fixed"
        echo "SECURITY:$security"
        echo "REMOVED:$removed"
    }

    update_changelog__update_changelog_file() {
        # --- build and write new CHANGELOG.md content ---
        local version="$1"
        local date="$2"
        local categorized="$3"
        local dry_run="$4"

        # --- extract sections from categorized commits ---
        local added changed fixed security removed
        added=$(echo "$categorized" | awk '
    		/^ADDED:/ {flag=1; sub(/^ADDED:/,""); print; next}
    		/^CHANGED:/ {flag=0}
    		flag
	')
        changed=$(echo "$categorized" | awk '
    		/^CHANGED:/ {flag=1; sub(/^CHANGED:/,""); print; next}
    		/^FIXED:/ {flag=0}
    		flag
	')
        fixed=$(echo "$categorized" | awk '
    		/^FIXED:/ {flag=1; sub(/^FIXED:/,""); print; next}
    		/^SECURITY:/ {flag=0}
    		flag
	')
        security=$(echo "$categorized" | awk '
    		/^SECURITY:/ {flag=1; sub(/^SECURITY:/,""); print; next}
    		/^REMOVED:/ {flag=0}
    		flag
	')
        removed=$(echo "$categorized" | awk '
    		/^REMOVED:/ {flag=1; sub(/^REMOVED:/,""); print; next}
    		flag
	')

        # --- create temporary file ---
        local temp_file
        temp_file=$(mktemp)

        # --- build new release section ---
        {
            echo "# Changelog"
            echo ""
            echo "All notable changes to this project will be documented in this file."
            echo ""
            echo "The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),"
            echo "and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)."
            echo ""
            echo "## [Unreleased]"
            echo ""

            # --- copy unreleased content (if any) ---
            if grep -q "^\[Unreleased\]" "$CHANGELOG_FILE"; then
                awk '/^\[Unreleased\]/,/^## \[/ { if (!/^## \[/ || NR==FNR) print }' \
                    "$CHANGELOG_FILE" "$CHANGELOG_FILE" | tail -n +2
            fi

            echo "---"
            echo ""
            echo "## [$version] - $date"
            echo ""

            # --- add sections if they have content ---
            if [ -n "$added" ]; then
                echo "### Added"
                echo "$added"
                echo ""
            fi

            if [ -n "$changed" ]; then
                echo "### Changed"
                echo "$changed"
                echo ""
            fi

            if [ -n "$fixed" ]; then
                echo "### Fixed"
                echo "$fixed"
                echo ""
            fi

            if [ -n "$security" ]; then
                echo "### Security"
                echo "$security"
                echo ""
            fi

            if [ -n "$removed" ]; then
                echo "### Removed"
                echo "$removed"
                echo ""
            fi

            # --- copy remaining old changelog ---
            if grep -q "^## \[" "$CHANGELOG_FILE"; then
                awk '/^## \[/ { if (found) exit; found=1 } found' "$CHANGELOG_FILE" | tail -n +2
            fi

            echo ""
            echo "---"
            echo ""
            echo "## [Links]"
            echo "- [Architecture Decision Records](docs/adr/)"
            echo "- [Documentation](docs/)"

        } > "$temp_file"

        # --- write or preview changes ---
        if [ "$dry_run" = "true" ]; then
            echo "[DRY RUN] Would update CHANGELOG.md with:"
            echo "  Version: $version"
            echo "  Date: $date"
            echo ""
            echo "Preview:"
            cat "$temp_file"
            rm "$temp_file"
        else
            mv "$temp_file" "$CHANGELOG_FILE"
            echo "[OK] Updated $CHANGELOG_FILE"
            echo "  Version: $version"
            echo "  Date: $date"
        fi
    }

    update_changelog__update_metadata() {
        # --- update METADATA.json with new version and date ---
        local version="$1"
        local date="$2"
        local dry_run="$3"

        if [ ! -f "$VERSION_FILE" ]; then
            echo "[WARN] $VERSION_FILE not found, skipping metadata update"
            return
        fi

        if [ "$dry_run" = "true" ]; then
            echo "[DRY RUN] Would update $VERSION_FILE with version: $version"
        else
            # --- simple JSON update (assumes basic structure) ---
            sed -i "s/\"version\": \"[^\"]*\"/\"version\": \"$version\"/" "$VERSION_FILE"
            sed -i "s/\"last_updated\": \"[^\"]*\"/\"last_updated\": \"$date\"/" "$VERSION_FILE"
            echo "[OK] Updated $VERSION_FILE"
        fi
    }

    # ---------------------------------------------------------------------------
    # CORE
    # ---------------------------------------------------------------------------

    # --- parse arguments ---
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --version)
                version="$2"
                shift 2
                ;;
            --date)
                date="$2"
                shift 2
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            --help)
                update_changelog__show_usage
                exit 0
                ;;
            *)
                echo "[ERROR] Unknown option: $1"
                update_changelog__show_usage
                exit 1
                ;;
        esac
    done

    # --- set defaults ---
    [ -z "$version" ] && version=$(update_changelog__increment_version "$(update_changelog__get_current_version)")
    [ -z "$date" ] && date=$(date +%Y-%m-%d)

    # --- get and categorize commits ---
    local commits
    commits=$(update_changelog__parse_commits)
    if [ -z "$commits" ]; then
        echo "[WARN] No commits found to process"
        exit 0
    fi

    local categorized
    categorized=$(update_changelog__categorize_commits "$commits")

    # --- update files ---
    update_changelog__update_changelog_file "$version" "$date" "$categorized" "$dry_run"
    update_changelog__update_metadata "$version" "$date" "$dry_run"

    # --- final instructions ---
    if [ "$dry_run" != "true" ]; then
        echo ""
        echo "Next steps:"
        echo "  1. Review: git diff $CHANGELOG_FILE"
        echo "  2. Commit: git add $CHANGELOG_FILE && git commit -m \"chore: update CHANGELOG for v$version\""
        echo "  3. Tag: git tag v$version"
    fi

    # ---------------------------------------------------------------------------
    # OUTPUT / RETURN / FINALIZE
    # ---------------------------------------------------------------------------
    return 0
}

# ==============================================================================
# ENTRYPOINT
# ==============================================================================

# --- execute main function if script is run directly (not sourced) ---

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    update_changelog "$@"
fi
