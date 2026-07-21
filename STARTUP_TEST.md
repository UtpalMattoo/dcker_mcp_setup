# Startup Test Entry Point

Use the startup-test folder for canonical startup order, test execution, and teardown.

Simple summary: the contract checks confirm observability setup files include required services and safety rules.
Technical definition: observability config contracts require expected compose wiring (`lgtm` + `alloy`, `OTEL_EXPORTER_OTLP_ENDPOINT=http://lgtm:4317`, localhost-only published observability ports, external `observability` network, no `docker.sock`) and required Alloy redaction/import rules in `observability/alloy/config/*.river`.
Test type note: these are static file-content assertions, not runtime integration tests.

- Full ordered startup and tests: [startup-test/startup-and-test.sh](startup-test/startup-and-test.sh)
- Fast contracts-only checks: [startup-test/startup-and-test-lite.sh](startup-test/startup-and-test-lite.sh)
- Teardown helper: [startup-test/cleanup.sh](startup-test/cleanup.sh)
- Runbook and rationale: [startup-test/README.md](startup-test/README.md)

From repository root:

```bash
bash startup-test/startup-and-test.sh
```

## YAML File Types and Execution Order

Not all `.yml` files are executed directly.

### 1) Compose entrypoints (you run these)

- `services/docker-compose.yml`: workload/services stack
- `observability/docker-compose.observability.yml`: observability stack (LGTM, Alloy, Grafana init)

These are started in order by `startup-test/startup-and-test.sh`:

1. services stack first
2. observability stack second

### 2) Grafana provisioning YAML (read by Grafana at startup)

- `observability/grafana/provisioning/datasources/datasources.yml`
- `observability/grafana/provisioning/dashboards/dashboards.yml`

These are mounted into the Grafana container by `observability/docker-compose.observability.yml` and loaded automatically by Grafana. You do not run them manually.

### 3) Context/example compose files

- `context_data/Python/DSA-Python/docker-compose.yml`

This is not part of the canonical startup path used by `startup-test/startup-and-test.sh`.

## Bypass and Skip Scenarios

Policy summary:

- Skip flags and runtime self-skips are useful for local troubleshooting.
- For CI/release confidence, run without skip flags and investigate unexpected skips.
- For detailed rationale and strategy, see [startup-test/README.md](startup-test/README.md), section "Test Strategy: Contract vs Flow and Skip Policy".

### 1) Explicit test bypass controls (CLI flags)

These options intentionally skip parts of the suite.

- Scenario 1.1: Skip service tests

```bash
bash startup-test/startup-and-test.sh --skip-service-tests
```

- Scenario 1.2: Skip all observability tests (contracts + flow)

```bash
bash startup-test/startup-and-test.sh --skip-observability-tests
```

- Scenario 1.3: Skip observability flow tests only

```bash
bash startup-test/startup-and-test.sh --skip-flow-tests
```

### 2) Conditional flow-test self-skips (runtime conditions)

Flow tests may self-skip when dependencies are unreachable.

- Scenario 2.1: Normal full run (no intentional skip)

```bash
bash startup-test/startup-and-test.sh
```

- Scenario 2.2: Force Alloy-unreachable condition for flow tests

```bash
ALLOY_STATUS_URL=http://localhost:1/-/ready \
	bash startup-test/startup-and-test.sh
```

- Scenario 2.3: Force Grafana/Loki query-unreachable condition for flow tests

```bash
GRAFANA_URL=http://localhost:3999 \
	bash startup-test/startup-and-test.sh
```