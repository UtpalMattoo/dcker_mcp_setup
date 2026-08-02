# Reusable Design Prompt: Secure Alloy + LGTM

Reference note:

- This is a design prompt.
- It helps plan or regenerate an implementation.
- It is not the canonical operations runbook.

When you need runtime truth, use:

- ../observability/telemetry_contracts.md
- ../observability/observability_guide.md
- ../../startup-test/startup-and-test.sh

## Prompt goal

Design an observability setup that:

1. uses Grafana Alloy and LGTM
2. avoids Docker socket access
3. uses explicit telemetry contracts
4. keeps services and observability as separate stacks
5. supports logs, metrics, and traces

## Security requirements

- Do not mount /var/run/docker.sock into Alloy.
- Use read-only log mounts when possible.
- Redact sensitive data before Loki.
- Keep observability ports localhost-only unless there is a strong reason.

## Telemetry requirements

- Traces via OTLP.
- Metrics via Prometheus scrape.
- Logs via explicit file paths.
- Consistent service labels for querying.

## Output expected from this prompt

1. Architecture overview in simple language.
2. Compose design with clear trust boundaries.
3. Runtime config plan for Alloy.
4. Redaction and access-control plan.
5. Validation plan with health checks and flow tests.

## Keep in sync

When you use this prompt to produce changes, compare the output against:

- ../../observability/alloy/config/runtime.river
- ../../observability/docker-compose.observability.yml
- ../../tests/observability/flow/test_alloy_lgtm_health_flow.py
