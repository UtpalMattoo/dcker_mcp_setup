# Telemetry Contracts (Current Runtime)

This is the main operational contract for observability.
If you need one place to check behavior, use this file first.
Keep it aligned with running code and compose files.

## Runtime anchors

Use these files as the runtime truth:

- observability/alloy/config/runtime.river
- observability/docker-compose.observability.yml
- startup-test/startup-and-test.sh
- tests/observability/flow/test_alloy_lgtm_health_flow.py

If this document and those files differ, follow those files.

## Quick picture

- Services send traces to Alloy on port 4317.
- Alloy reads service logs from mounted files.
- Alloy pushes logs to Loki and traces to LGTM.
- Grafana reads data from provisioned datasources.

In plain terms:

- Services emit telemetry.
- Alloy routes it.
- LGTM stores it.
- Grafana shows it.

## Service contracts

### Qdrant (host-level)

- Role: vector database.
- Metrics source: host.docker.internal:6333.
- Metric job label: qdrant.
- Logs source: host log mount at /mnt/qdrant-host-logs.
- Traces: not emitted by Qdrant in current setup.

### main_starter_service

- Role: app service.
- Trace export target: http://alloy:4317.
- Log file path inside observability mount: /mnt/service-logs/main_starter_service/app.log.
- Expected service label in Loki: main_starter_service.

### second-service-custom-mcp-work

- Role: second app service.
- Trace export target: http://alloy:4317.
- Log file path inside observability mount: /mnt/service-logs/second-service-custom-mcp-work/app.log.
- Expected service label in Loki: second-service-custom-mcp-work.

## Alloy runtime details

Current runtime is a single flat file:

- observability/alloy/config/runtime.river

This is important:

- runtime.river is the active entrypoint.
- Reference files in observability/alloy/config are not imported at runtime.

Current runtime includes:

- otelcol.receiver.otlp for traces.
- loki.source.file for app log files.
- loki.process with JSON parse and labels.
- loki.write to http://lgtm:3100/loki/api/v1/push.
- prometheus.scrape for Qdrant metrics.

## Labels and log contract used by flow test

The flow test writes a token to this file:

- observability/runtime-logs/main_starter_service/app.log

The flow test queries Loki with this label:

- service="main_starter_service"

See:

- tests/observability/flow/test_alloy_lgtm_health_flow.py

## Grafana provisioning contract

Grafana provisioning is mounted from:

- ./grafana/provisioning:/otel-lgtm/grafana/conf/provisioning:ro

Provisioning path used by env:

- GF_PATHS_PROVISIONING=/otel-lgtm/grafana/conf/provisioning

See:

- observability/docker-compose.observability.yml
- observability/grafana/env/grafana.env

## Startup and credentials contract

Canonical startup flow:

- startup-test/startup-and-test.sh

That script:

- ensures required networks exist.
- checks Qdrant health first.
- starts observability stack.
- waits for Grafana and Alloy health.
- runs observability contract tests.
- runs observability flow tests.

For Grafana test auth:

- script exports GRAFANA_ADMIN_USER and GRAFANA_ADMIN_PASSWORD.
- defaults are change_me and change_me_strong if not overridden.

## Health endpoints

- Qdrant: http://localhost:6333/healthz
- Grafana: http://localhost:3000/api/health
- Alloy status API: http://localhost:12345/api/v1/status
- Alloy ready endpoint used by flow tests: http://localhost:12345/-/ready

## What this contract is for

Use this contract when you:

- onboard a new service.
- debug missing logs or traces.
- update labels used in Loki queries.
- change Grafana provisioning.

## Canonical operations checklist

This is the only checklist you should follow for observability updates.
Other docs should link here instead of duplicating these steps.

1. Confirm service labels and log paths in observability/alloy/config/runtime.river.
2. Confirm compose mounts and env settings in observability/docker-compose.observability.yml.
3. Confirm Grafana provisioning path and datasources in observability/grafana/env/grafana.env.
4. Run canonical startup: bash startup-test/startup-and-test.sh.
5. Verify health endpoints for Qdrant, Grafana, and Alloy.
6. Run contract tests and flow tests.
7. For log policy changes, run redaction validation from log_sensitivity_assessment.md.
8. Update this contract if labels, paths, endpoints, or auth assumptions changed.

