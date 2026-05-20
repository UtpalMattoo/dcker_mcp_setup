# Startup-Test Runbook

This folder provides the canonical WSL bash entrypoints for startup sequencing and test execution.

## Files

- `startup-and-test.sh`: Full startup and test path (services + observability + flow tests)
- `startup-and-test-lite.sh`: Fast path for observability contract checks only
- `cleanup.sh`: Compose teardown helper with optional network pruning

## Why this order

The full script follows this order:

1. Ensure external Docker networks exist (`mcp-net`, `observability`)
2. Start `qdrant-db` and wait for `http://localhost:6333/healthz`
3. Run service tests (`tests/test_qdrant_service.py`) with `QDRANT_HOST=localhost`
4. Start observability stack (`observability/docker-compose.observability.yml`)
5. Wait for Grafana and Alloy health endpoints
6. Run observability contract tests
7. Run observability flow tests

Rationale:

- Networks are external in compose, so they must already exist.
- Service tests require a live Qdrant endpoint and fail fast on core dependency issues.
- Observability flow tests are integration checks against live Alloy/Grafana/Loki endpoints, so the observability stack must be up and healthy first.
- Contract tests run quickly and validate config invariants before deeper flow checks.

## Prerequisites

- WSL/devcontainer bash shell
- `docker` + `docker compose`
- `python` with `pytest`
- `curl`

Optional environment source:

- `../.env.local` for `GRAFANA_ADMIN_USER` and `GRAFANA_ADMIN_PASSWORD`

## Usage

From repository root:

```bash
bash startup-test/startup-and-test.sh
```

Fast checks:

```bash
bash startup-test/startup-and-test-lite.sh
```

Cleanup:

```bash
bash startup-test/cleanup.sh
```

Cleanup plus network prune attempt:

```bash
bash startup-test/cleanup.sh --prune-networks
```

## Full script options

```text
--skip-service-tests
--skip-observability-tests
--skip-flow-tests
```
