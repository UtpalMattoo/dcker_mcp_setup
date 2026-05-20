#!/usr/bin/env bash
set -euo pipefail

PRUNE_NETWORKS=false

for arg in "$@"; do
  case "$arg" in
    --prune-networks) PRUNE_NETWORKS=true ;;
    -h|--help)
      cat <<'EOF'
Usage: startup-test/cleanup.sh [options]

Options:
  --prune-networks  Attempt to remove mcp-net and observability after compose down
  -h, --help        Show help
EOF
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 2
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SERVICES_COMPOSE="${REPO_ROOT}/services/docker-compose.yml"
OBS_COMPOSE="${REPO_ROOT}/observability/docker-compose.observability.yml"

log() {
  echo ""
  echo "==> $*"
}

try_remove_network() {
  local name="$1"
  if docker network inspect "$name" >/dev/null 2>&1; then
    if docker network rm "$name" >/dev/null 2>&1; then
      echo "Removed network: $name"
    else
      echo "Could not remove network (still in use or protected): $name"
    fi
  fi
}

main() {
  log "Stopping observability compose stack"
  docker compose -f "$OBS_COMPOSE" down --remove-orphans || true

  log "Stopping services compose stack"
  docker compose -f "$SERVICES_COMPOSE" down --remove-orphans || true

  if [[ "$PRUNE_NETWORKS" == true ]]; then
    log "Pruning external networks requested"
    try_remove_network "observability"
    try_remove_network "mcp-net"
  fi

  log "Cleanup completed"
}

cd "$REPO_ROOT"
main
