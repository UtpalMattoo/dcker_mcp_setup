#!/usr/bin/env bash

# Startup and integration test runner
#
# 1) Explicit test bypass controls (CLI flags)
#    These options intentionally skip parts of the suite.
#
#    Scenario 1.1: Skip service tests
#      bash startup-test/startup-and-test.sh --skip-service-tests
#
#    Scenario 1.2: Skip all observability tests (contracts + flow)
#      bash startup-test/startup-and-test.sh --skip-observability-tests
#
#    Scenario 1.3: Skip observability flow tests only
#      bash startup-test/startup-and-test.sh --skip-flow-tests
#
# 2) Conditional flow-test self-skips (runtime conditions)
#    Flow tests may self-skip when dependencies are unreachable.
#
#    Scenario 2.1: Normal full run (no intentional skip)
#      bash startup-test/startup-and-test.sh
#
#    Scenario 2.2: Force Alloy-unreachable condition for flow tests
#      ALLOY_STATUS_URL=http://localhost:1/-/ready \
#        bash startup-test/startup-and-test.sh
#
#    Scenario 2.3: Force Grafana/Loki query-unreachable condition for flow tests
#      GRAFANA_URL=http://localhost:3999 \
#        bash startup-test/startup-and-test.sh

set -euo pipefail

SKIP_SERVICE_TESTS=false
SKIP_OBSERVABILITY_TESTS=false
SKIP_FLOW_TESTS=false

for arg in "$@"; do
  case "$arg" in
    --skip-service-tests) SKIP_SERVICE_TESTS=true ;;
    --skip-observability-tests) SKIP_OBSERVABILITY_TESTS=true ;;
    --skip-flow-tests) SKIP_FLOW_TESTS=true ;;
    -h|--help)
      cat <<'EOF'
Usage: startup-test/startup-and-test.sh [options]

Options:
  --skip-service-tests         Skip tests/test_qdrant_service.py
  --skip-observability-tests   Skip all observability pytest runs
  --skip-flow-tests            Skip tests/observability/flow runs
  -h, --help                   Show help
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
ENV_LOCAL="${REPO_ROOT}/.env.local"
LOG_FILE="${SCRIPT_DIR}/startup-and-test.log"

exec > >(tee -a "$LOG_FILE") 2> >(tee -a "$LOG_FILE" >&2)

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

ensure_network() {
  local name="$1"
  if docker network inspect "$name" >/dev/null 2>&1; then
    echo "Network exists: $name"
  else
    echo "Creating docker network: $name"
    docker network create "$name" >/dev/null
  fi
}

load_env_file() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    return 0
  fi

  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%$'\r'}"
    [[ -z "$line" ]] && continue
    [[ "$line" == \#* ]] && continue
    if [[ "$line" == *=* ]]; then
      local key="${line%%=*}"
      local value="${line#*=}"
      key="${key//[[:space:]]/}"
      export "$key=$value"
    fi
  done < "$file"
}

wait_for_http() {
  local url="$1"
  local timeout_sec="$2"
  local sleep_sec=2
  local started="$(date +%s)"

  while true; do
    if curl -fsS "$url" >/dev/null 2>&1; then
      return 0
    fi

    local now
    now="$(date +%s)"
    if (( now - started >= timeout_sec )); then
      return 1
    fi

    sleep "$sleep_sec"
  done
}

run_pytest() {
  local label="$1"
  shift
  log "$label"
  python -m pytest "$@"
}

main() {
  require_cmd docker
  require_cmd python
  require_cmd curl

  log "Repository root: ${REPO_ROOT}"

  log "Loading optional local environment from .env.local"
  load_env_file "$ENV_LOCAL"

  : "${GRAFANA_ADMIN_USER:=change_me}"
  : "${GRAFANA_ADMIN_PASSWORD:=change_me_strong}"
  export GRAFANA_ADMIN_USER GRAFANA_ADMIN_PASSWORD

  log "Ensuring required external docker networks"
  ensure_network "mcp-net"
  ensure_network "observability"

  log "Starting qdrant-db"
  docker compose -f "$SERVICES_COMPOSE" up -d qdrant-db

  log "Waiting for Qdrant health endpoint"
  if ! wait_for_http "http://localhost:6333/healthz" 90; then
    echo "Qdrant health check timed out" >&2
    exit 1
  fi

  if [[ "$SKIP_SERVICE_TESTS" == false ]]; then
    QDRANT_HOST=localhost run_pytest "Running service tests" tests/test_qdrant_service.py -v
  else
    log "Skipping service tests"
  fi

  log "Starting observability stack"
  docker compose -f "$OBS_COMPOSE" up -d

  log "Waiting for Grafana health endpoint"
  if ! wait_for_http "http://localhost:3000/api/health" 150; then
    echo "Grafana health check timed out" >&2
    exit 1
  fi

  log "Waiting for Alloy status endpoint"
  if ! wait_for_http "http://localhost:12345/api/v1/status" 120; then
    echo "Alloy status check timed out" >&2
    exit 1
  fi

  if [[ "$SKIP_OBSERVABILITY_TESTS" == false ]]; then
    run_pytest "Running observability contract tests" tests/observability/contracts -v

    if [[ "$SKIP_FLOW_TESTS" == false ]]; then
      GRAFANA_USER="$GRAFANA_ADMIN_USER" GRAFANA_PASSWORD="$GRAFANA_ADMIN_PASSWORD" \
        run_pytest "Running observability flow tests" tests/observability/flow -m flow -v
    else
      log "Skipping observability flow tests"
    fi
  else
    log "Skipping observability pytest suite"
  fi

  log "Startup and test sequence completed"
}

cd "$REPO_ROOT"
main
