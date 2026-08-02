# Observability Guide (Current Runtime)

This guide explains how observability works in this repository today.
Use this for daily operations.

Typical flow is simple.
You start the stack, run one script, and then check dashboards.
If a test fails, use the contract doc to trace labels, paths, and endpoints.

## What this stack is

- Alloy collects telemetry.
- LGTM stores telemetry.
- Grafana shows dashboards.

Telemetry types:

- logs
- metrics
- traces

## Core design

- Services and observability run as separate compose projects.
- Services push traces to Alloy.
- Alloy reads log files from read-only mounts.
- Alloy scrapes Qdrant metrics.
- Alloy forwards data to LGTM.

## Security model

- Docker socket is not mounted into Alloy.
- Alloy only sees what you expose.
- Exposed paths are read-only where possible.
- Observability ports are localhost-only in compose.

## Where to check first

Use these files when in doubt:

- observability/alloy/config/runtime.river
- observability/docker-compose.observability.yml
- startup-test/startup-and-test.sh
- tests/observability/flow/test_alloy_lgtm_health_flow.py
- telemetry_contracts.md

## Startup path

Recommended path:

- bash startup-test/startup-and-test.sh

For the exact operational steps, use the canonical checklist in telemetry_contracts.md.

## Health endpoints

- Qdrant: http://localhost:6333/healthz
- Grafana: http://localhost:3000/api/health
- Alloy status: http://localhost:12345/api/v1/status
- Alloy ready endpoint used by flow tests: http://localhost:12345/-/ready

## Logs and labels used by flow tests

Flow test writes to:

- observability/runtime-logs/main_starter_service/app.log

Flow test looks for Loki label:

- service="main_starter_service"

## Grafana provisioning

Provisioning is mounted to:

- /otel-lgtm/grafana/conf/provisioning

Configured by:

- observability/grafana/env/grafana.env
- observability/docker-compose.observability.yml

## Troubleshooting

Use one workflow for all issues.
Follow the canonical operations checklist in telemetry_contracts.md.
It is the only checklist that should drive run/verify/update actions.

## Related docs

- telemetry_contracts.md
- ../../startup-test/README.md
- ../runbooks/STARTUP_TEST.md
