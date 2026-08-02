# Observability Implementation Mapping (Historical)

Reference note:

- This file is a historical snapshot.
- It is for audit and change tracking.
- It is not the day-to-day runbook.

Need current behavior instead?
Use these files:

- ../observability/telemetry_contracts.md
- ../observability/observability_guide.md
- ../../startup-test/README.md
- ../../startup-test/startup-and-test.sh

## Snapshot summary

Date of this mapping: 2026-05-19.

Work captured in this snapshot:

1. OTEL env wiring was added for services.
2. Python services were instrumented for OTLP traces.
3. Structured JSON logging was added.
4. Runtime log mounts were added for Alloy.
5. Compose separation was preserved.
6. Redaction and CI flags were preserved.
7. RBAC bootstrap support was added for Grafana.

## Important caveat

Some details in this historical mapping may differ from current runtime files.
Always verify against active config files before making changes.
