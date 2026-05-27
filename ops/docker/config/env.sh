#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# METADATA
# ==============================================================================
# FILE: env.sh
# TYPE: CONFIG
# PURPOSE: Define global paths, variables, and source dependencies for the project
#
# DEPENDENCIES:
#   - scripts/helpers/logger.sh
#   - scripts/helpers/global_flags.sh
#   - scripts/helpers/create_files.sh
#   - ops/docker/lib/*.sh
# ==============================================================================

# -----------------------------------------------------------------------------
# CONFIGURATION
# -----------------------------------------------------------------------------

# --- paths ---
REPO_DIR="$(git rev-parse --show-toplevel)"
SCRIPTS_DIR="$REPO_DIR/scripts"
HELPERS_DIR="$SCRIPTS_DIR/helpers"

GLOBAL_OPS_DIR="$REPO_DIR/ops"
GLOBAL_OPS_DOCKER_DIR="$GLOBAL_OPS_DIR/docker"
GLOBAL_OPS_DOCKER_LIB_DIR="$GLOBAL_OPS_DOCKER_DIR/lib"

LOCAL_OPS_DIR="$(cd "$(dirname "${BASH_SOURCE[1]}")/.." && pwd)"
LOCAL_OPS_CONFIG="$LOCAL_OPS_DIR/config"
LOG_DIR="$LOCAL_OPS_DIR/logs"

PROJECT_DIR="$(cd "$LOCAL_OPS_DIR/.." && pwd)"
PROJECT_RUNTIME_ROOT="$PROJECT_DIR"
PROJECT_OPS_ROOT="$LOCAL_OPS_CONFIG"
PROJECT_NAME="$(basename "$PROJECT_DIR")"

# --- defaults ---
DEBUG=${DEBUG:-0}

# --- exports ---
export SCRIPTS_DIR
export HELPERS_DIR
export GLOBAL_OPS_DIR
export GLOBAL_OPS_DOCKER_DIR
export GLOBAL_OPS_DOCKER_LIB_DIR
export LOCAL_OPS_DIR
export LOCAL_OPS_CONFIG
export LOG_DIR
export PROJECT_DIR
export PROJECT_RUNTIME_ROOT
export PROJECT_OPS_ROOT
export PROJECT_NAME
export DEBUG

# --- dependencies ---
source "$HELPERS_DIR/logger.sh"
source "$HELPERS_DIR/require_args.sh"
source "$HELPERS_DIR/run.sh"
source "$HELPERS_DIR/confirm_action.sh"
source "$HELPERS_DIR/global_flags.sh"
source "$HELPERS_DIR/create_files.sh"
source "$HELPERS_DIR/create_dirs.sh"

source "$GLOBAL_OPS_DOCKER_LIB_DIR/status/set_status.sh"
source "$GLOBAL_OPS_DOCKER_LIB_DIR/status/get_status.sh"
source "$GLOBAL_OPS_DOCKER_LIB_DIR/status/get_runtime_state.sh"
source "$GLOBAL_OPS_DOCKER_LIB_DIR/status/get_health_state.sh"
source "$GLOBAL_OPS_DOCKER_LIB_DIR/init/setup_config.sh"
source "$GLOBAL_OPS_DOCKER_LIB_DIR/init/bootstrap_config.sh"
source "$GLOBAL_OPS_DOCKER_LIB_DIR/init/seed_config.sh"
source "$GLOBAL_OPS_DOCKER_LIB_DIR/manage/apply_config.sh"
source "$GLOBAL_OPS_DOCKER_LIB_DIR/manage/apply_permissions.sh"
source "$GLOBAL_OPS_DOCKER_LIB_DIR/status/compare_dirs.sh"
source "$GLOBAL_OPS_DOCKER_LIB_DIR/status/get_drift_direction.sh"
source "$GLOBAL_OPS_DOCKER_LIB_DIR/manage/backup_config.sh"
source "$GLOBAL_OPS_DOCKER_LIB_DIR/manage/export_from_runtime.sh"
source "$GLOBAL_OPS_DOCKER_LIB_DIR/status/guard_direction.sh"
source "$GLOBAL_OPS_DOCKER_LIB_DIR/manage/stop_containers.sh"
source "$GLOBAL_OPS_DOCKER_LIB_DIR/manage/destroy_environment.sh"
source "$GLOBAL_OPS_DOCKER_LIB_DIR/manage/deploy_containers.sh"
source "$GLOBAL_OPS_DOCKER_LIB_DIR/manage/plan_service.sh"
source "$GLOBAL_OPS_DOCKER_LIB_DIR/cli.sh"

# --- debug ---
# Enable trace mode if DEBUG >= 2
if [ "$DEBUG" -ge 2 ]; then
    set -x
fi
