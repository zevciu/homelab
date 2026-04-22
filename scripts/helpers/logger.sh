# ==============================================================================
# METADATA
# ==============================================================================
# FUNCTION: write_log
# PURPOSE: Core logging function with level and color support
#
# DEPENDENCIES:
#   - None (self-contained)
# ==============================================================================

# -----------------------------------------------------------------------------
# INPUT / OUTPUT CONTRACT
# -----------------------------------------------------------------------------
# INPUT:
#   $LOG_DIR       - directory for log files (required env var)
#   $PROJECT_NAME  - name used for log file prefix (required env var)
#   $DEBUG         - 0 (default), 1 (debug logs), 2 (debug + trace) (optional)
#
# OUTPUT:
#   stdout: colored console output (stderr actually)
#   file: plain text log entries in $LOG_DIR/$PROJECT_NAME.log
#
# SIDE EFFECTS:
#   - Creates log directory if missing
#   - Appends to log file
#   - Prints colored output to stderr
#
# RETURNS:
#   0 on success
#   1 on failure (cannot create log directory)
# -----------------------------------------------------------------------------

# ==============================================================================
# CONFIGURATION
# ==============================================================================
: "${LOG_DIR:?LOG_DIR not set}"
: "${PROJECT_NAME:?PROJECT_NAME not set}"

# --- defaults ---
DEBUG=${DEBUG:-0}

# --- colors (console only) ---
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_CYAN='\033[0;36m'
COLOR_RESET='\033[0m'

SCRIPT_NAME=$(basename "$0" .sh)
LOG_FILE="$LOG_DIR/${PROJECT_NAME}.log"

mkdir -p "$LOG_DIR" || die "cannot create log directory: $LOG_DIR"

# ==============================================================================
# IMPLEMENTATION
# ==============================================================================

write_log() {
    # ---------------------------------------------------------------------------
    # INPUT
    # ---------------------------------------------------------------------------
    local level="$1"
    local message="$2"

    # ---------------------------------------------------------------------------
    # VALIDATION
    # ---------------------------------------------------------------------------
    [ -z "$level" ] && die "write_log: level is required"
    [ -z "$message" ] && die "write_log: message is required"

    # ---------------------------------------------------------------------------
    # SETUP
    # ---------------------------------------------------------------------------
    local color

    # ---------------------------------------------------------------------------
    # HELPERS (INTERNAL)
    # ---------------------------------------------------------------------------
    write_log__get_color() {
        case "$level" in
            INFO)  echo "$COLOR_CYAN" ;;
            OK)    echo "$COLOR_GREEN" ;;
            WARN)  echo "$COLOR_YELLOW" ;;
            ERR)   echo "$COLOR_RED" ;;
            DEBUG) echo "$COLOR_CYAN" ;;
            *)     echo "$COLOR_RESET" ;;
        esac
    }

    write_log__timestamp() {
        date "+%d-%m-%Y %H:%M:%S"
    }

    # ---------------------------------------------------------------------------
    # CORE
    # ---------------------------------------------------------------------------
    color=$(write_log__get_color)

    # --- console output with colors ---
    echo -e "$(write_log__timestamp) [${PROJECT_NAME}][${SCRIPT_NAME}] ${color}[${level}]${COLOR_RESET} $message" >&2

    # --- file output without colors ---
    echo "$(write_log__timestamp) [${PROJECT_NAME}][${SCRIPT_NAME}] [${level}] $message" >> "$LOG_FILE"
}

# -----------------------------------------------------------------------------
# OUTPUT / RETURN
# -----------------------------------------------------------------------------

log() 		{ write_log "INFO" "$1"; }
log_ok() 	{ write_log "OK" "$1"; }
log_warn() 	{ write_log "WARN" "$1"; }
log_err() 	{ write_log "ERR" "$1"; }

log_debug() {
 if [ "$DEBUG" -ge 1 ]; then
  write_log "DEBUG" "$1"
 fi
}

die() {
 log_err "$1"
 exit 1
}
