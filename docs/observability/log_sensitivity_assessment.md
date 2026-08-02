# Log Sensitivity and Redaction (Current Policy)

This file explains what log data is sensitive.
It also explains what must be redacted before logs reach Loki.

## Risk levels by source

### VS Code logs

- Risk: medium.
- Why: can expose local paths and project structure.
- Rule: redact absolute paths.

### Copilot logs

- Risk: critical.
- Why: can contain prompts, code, tokens, and secrets.
- Rule: keep disabled by default in non-dev.
- Rule: redact tokens and keys when enabled.

### App service logs

- Risk: medium.
- Why: may include payloads, credentials, and stack details.
- Rule: redact credentials and sensitive values.

### Qdrant logs

- Risk: low to medium.
- Why: mostly operational, but can expose query patterns.
- Rule: redact secrets if present.

## Mandatory redaction outcomes

Before sending logs to Loki:

- API keys must be masked.
- bearer tokens must be masked.
- passwords and secrets must be masked.
- local absolute paths must be masked.

Common replacement markers:

- <REDACTED_API_KEY>
- <REDACTED_TOKEN>
- <REDACTED_PASSWORD>
- <PATH_REDACTED>

## Runtime control flags

Use these flags in observability compose/env:

- ENABLE_VSCODE_LOGS
- ENABLE_COPILOT_LOGS
- ENABLE_SERVICE_LOGS
- ENABLE_QDRANT_LOGS
- REDACTION_MODE

Recommended defaults:

- local dev: service and Qdrant logs on
- local dev: Copilot logs off unless needed
- CI: editor logs off unless test requires them

## Access control guidance

- Sensitive logs should have restricted access.
- General app logs can be broader.
- Keep Grafana access scoped by role/team.

## Validation checklist

Use the canonical operations checklist in telemetry_contracts.md.

For redaction-specific validation, run these checks:

1. emit test lines with fake secrets
2. verify masked output in Loki
3. verify no raw secrets appear
4. verify expected labels still exist after redaction

## Incident response if secrets leak

1. rotate affected secrets immediately
2. limit access to related dashboards
3. review recent log queries
4. patch redaction patterns
5. rerun validation tests
