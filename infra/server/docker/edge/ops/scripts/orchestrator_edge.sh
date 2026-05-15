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

SERVICES=("nginx")
BOOTSTRAP_COMPOSE="$PROJECT_DIR/docker-compose.bootstrap.yml"
DOCKER_COMPOSE="$PROJECT_DIR/docker-compose.yml"

TARGET_DIR_nginx="$PROJECT_DIR/nginx"

BOOTSTRAP_MAP_nginx=(
  "nginx.conf:/etc/nginx/nginx.conf"
  "conf.d/default.conf:/etc/nginx/conf.d/default.conf"
  "html/index.html:/usr/share/nginx/html/index.html"
)

DIRS_nginx=(
  "conf.d"
  "html"
  "certs"
)

INIT_FLOW_nginx=(
  "setup:DIRS"
  "bootstrap:BOOTSTRAP_MAP"
)

# -----------------------------------------------------------------------------
# CORE
# -----------------------------------------------------------------------------

cli_engine "$@"
