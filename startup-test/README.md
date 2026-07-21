# Startup-Test Runbook

This folder provides the canonical WSL bash entrypoints for startup sequencing and test execution.

## Files

- `startup-and-test.sh`: Full startup and test path (services + observability + flow tests)
- `startup-and-test-lite.sh`: Fast path for observability contract checks only
- `cleanup.sh`: Compose teardown helper with optional network pruning

Simple summary: these checks make sure the observability setup files include the expected services and safety rules.
Technical definition: observability config contracts require expected compose wiring (`lgtm` + `alloy`, `OTEL_EXPORTER_OTLP_ENDPOINT=http://lgtm:4317`, localhost-only published observability ports, external `observability` network, no `docker.sock`) and required Alloy redaction/import rules in `observability/alloy/config/*.river`.
Test type note: these are static file-content assertions, not runtime integration tests.

## Why this order

The full script follows this order:

1. Ensure external Docker networks exist (`mcp-net`, `observability`)
2. Ensure host-level persistent Qdrant is running and wait for `http://localhost:6333/healthz`
3. Run service tests (`tests/test_qdrant_service.py`) with `QDRANT_HOST=host.docker.internal` (use `localhost` only when running tests directly on host)
4. Start observability stack (`observability/docker-compose.observability.yml`)
5. Wait for Grafana and Alloy health endpoints
6. Run observability contract tests
7. Run observability flow tests

Rationale:

- Networks are external in compose, so they must already exist.
- Service tests require a live Qdrant endpoint and fail fast on core dependency issues.
- Observability flow tests are integration checks against live Alloy/Grafana/Loki endpoints, so the observability stack must be up and healthy first.
- Contract tests run quickly and validate config invariants before deeper flow checks.

## Test Strategy: Contract vs Flow and Skip Policy

Why both test types exist:

- Contract tests are fast, deterministic checks that validate expected config structure and safety invariants.
- Flow tests are runtime integration checks that validate end-to-end behavior across live components.

Why skip controls exist:

- Explicit skip flags are for local troubleshooting speed and targeted debugging.
- Conditional self-skips in flow tests prevent unrelated hard-fail noise when required live dependencies are unavailable.

Policy recommendation:

- Local development: skip flags are allowed when debugging specific layers.
- CI/release gate: run without skip flags and treat unexpected skips in critical flow tests as a quality signal.
- Always review skipped test counts in run output before treating a run as full coverage.

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

For detailed bypass and conditional self-skip scenarios with concrete invocation examples,
see [STARTUP_TEST.md](../STARTUP_TEST.md), section "Bypass and Skip Scenarios".
