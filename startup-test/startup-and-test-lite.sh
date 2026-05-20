#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

log() {
  echo ""
  echo "==> $*"
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

main() {
  require_cmd python

  log "Repository root: ${REPO_ROOT}"
  log "Running fast observability contract checks"
  cd "$REPO_ROOT"
  python -m pytest tests/observability/contracts -v

  log "Lite check completed"
}

main
