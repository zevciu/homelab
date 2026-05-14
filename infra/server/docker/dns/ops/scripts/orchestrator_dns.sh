#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# CONFIGURATION
# ==============================================================================

# --- paths ---
REPO_DIR="$(git rev-parse --show-toplevel)"

# --- dependencies ---
source "$REPO_DIR/ops/docker/config/env.sh"

# ==============================================================================
# IMPLEMENTATION
# ==============================================================================

# -----------------------------------------------------------------------------
# SETUP
# -----------------------------------------------------------------------------

SERVICES=("unbound" "pihole")
BOOTSTRAP_COMPOSE="$PROJECT_DIR/docker-compose.bootstrap.yml"
DOCKER_COMPOSE="$PROJECT_DIR/docker-compose.yml"

# --- unbound ---
TARGET_DIR_unbound="$PROJECT_DIR/unbound"

BOOTSTRAP_MAP_unbound=(
  "unbound.conf:/opt/unbound/etc/unbound/unbound.conf"
  "a-records.conf:/opt/unbound/etc/unbound/a-records.conf"
  "srv-records.conf:/opt/unbound/etc/unbound/srv-records.conf"
  "forward-records.conf:/opt/unbound/etc/unbound/forward-records.conf"
)

SEED_FILES_unbound=(
  "root.hints"
)

INIT_FLOW_unbound=(
  "bootstrap:BOOTSTRAP_MAP"
  "seed:SEED_FILES"
)

# --- pihole ---
# No additional config prior to container deployment is required. All is handled by the Compose file.

# -----------------------------------------------------------------------------
# CORE
# -----------------------------------------------------------------------------

cli_engine "$@"
