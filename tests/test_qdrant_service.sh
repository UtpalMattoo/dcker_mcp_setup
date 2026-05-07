#!/usr/bin/env bash
set -euo pipefail

# Resolve repository root from this script location.
# Script path: tests/ (top-level, one level below repo root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
LOG_FILE="${SCRIPT_DIR}/test_qdrant_service.log"
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"

# Redirect all stdout and stderr to the log file from this point on
exec >> "${LOG_FILE}" 2>&1

echo ""
echo "[${TIMESTAMP}]"
echo "script: ${SCRIPT_DIR}/test_qdrant_service.sh"

echo "[1/4] Starting qdrant-db service"
docker compose -f "${REPO_ROOT}/services/docker-compose.yml" up -d qdrant-db

echo "[2/4] Verifying qdrant-db container status"
docker ps --filter "name=qdrant-db"

echo "[3/4] Checking Qdrant health endpoint on port 6333"
curl -i http://localhost:6333/healthz | head -n 5

echo "[4/4] Running Qdrant service tests"
cd "${REPO_ROOT}"
set +e
QDRANT_HOST=localhost /usr/local/bin/python -m pytest tests/ -v
PYTEST_EXIT=$?
set -e

if [ ${PYTEST_EXIT} -eq 0 ]; then
    STATUS="PASS"
else
    STATUS="FAIL"
fi

echo "status: ${STATUS}"
echo "exit_code: ${PYTEST_EXIT}"

exit ${PYTEST_EXIT}