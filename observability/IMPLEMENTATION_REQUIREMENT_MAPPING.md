# Observability Implementation Requirement Mapping

Source prompt: [Secure Alloy + LGTM Observability Prompt.md](Secure Alloy + LGTM Observability Prompt.md)

Purpose: map requirements from Secure Alloy + LGTM prompt to exact repository changes applied in this implementation pass.

Date: 2026-05-19

## Legend
- Implemented: requirement was directly implemented in code/config.
- Partial: some parts implemented, some pending.
- Not implemented: documented in prompt but not yet changed in this pass.

## 1) Explicit telemetry contracts
Status: Implemented (runtime wiring) / Partial (contract docs unchanged)

Changes made:
- Added OTEL runtime variables for services and explicit OTLP endpoint/protocol.
  - File: services/docker-compose.yml
  - Change: added OTEL_EXPORTER_OTLP_ENDPOINT, OTEL_EXPORTER_OTLP_PROTOCOL, OTEL_TRACES_EXPORTER, OTEL_METRICS_EXPORTER, OTEL_LOGS_EXPORTER, OTEL_EXPORTER_OTLP_INSECURE, OTEL_SERVICE_NAME, OTEL_RESOURCE_ATTRIBUTES.
- Added service log contract via explicit file path env variable.
  - File: services/docker-compose.yml
  - Change: added SERVICE_LOG_FILE for each Python service.

## 2) OTLP-first telemetry collection
Status: Implemented

Changes made:
- Instrumented main starter service to initialize OpenTelemetry tracer provider and OTLP gRPC exporter.
  - File: services/main_starter_service/main_server.py
  - Change: configure_tracing() with OTLPSpanExporter(endpoint from OTEL_EXPORTER_OTLP_ENDPOINT, insecure=True), BatchSpanProcessor, startup/qdrant spans.
- Instrumented second service similarly.
  - File: services/second-service-custom-mcp-work/python_custom_server.py
  - Change: configure_tracing() and placeholder MCP span attribute (mcp.operation=placeholder).
- Added Python OTEL packages used by both services.
  - File: .devcontainer/requirements.txt
  - Change: added opentelemetry-api, opentelemetry-sdk, opentelemetry-exporter-otlp-proto-grpc.

## 3) Structured service logs and explicit file tailing
Status: Implemented

Changes made:
- Added structured JSON logging in both Python services and dual sink (stdout + file).
  - Files:
    - services/main_starter_service/main_server.py
    - services/second-service-custom-mcp-work/python_custom_server.py
  - Change: JsonFormatter + file handler writing to SERVICE_LOG_FILE.
- Added host-to-container mounts for service log directories.
  - File: services/docker-compose.yml
  - Change: mounted ../observability/runtime-logs/main_starter_service and ../observability/runtime-logs/second-service-custom-mcp-work.
- Added collector mount to read service logs.
  - File: observability/docker-compose.observability.yml
  - Change: mounted ./runtime-logs:/mnt/service-logs:ro into alloy.
- Updated Alloy file targets to match per-service subdirectories.
  - File: observability/alloy/config/logs-docker.river
  - Change: /mnt/service-logs/*/*.log glob for app logs and /mnt/service-logs/qdrant/*.log for qdrant pipeline.
- Added runtime log directories in repo.
  - Paths:
    - observability/runtime-logs/.gitkeep
    - observability/runtime-logs/main_starter_service/.gitkeep
    - observability/runtime-logs/second-service-custom-mcp-work/.gitkeep
    - observability/runtime-logs/qdrant/.gitkeep

## 4) Service lifecycle/startup behavior
Status: Implemented

Changes made:
- Fixed main service command so container does not exit after dependency install.
  - File: services/docker-compose.yml
  - Change: command changed from pip-only to "pip install -r requirements.txt && python main_server.py".
- Applied same run pattern to second service.
  - File: services/docker-compose.yml
  - Change: command changed to install + run python_custom_server.py.

## 5) Reduced collector privileges (no docker.sock, explicit mounts)
Status: Implemented (maintained)

Changes verified/maintained:
- No docker.sock mount added to alloy.
  - File: observability/docker-compose.observability.yml
  - Change in this pass: only explicit runtime-logs read-only mount was added.
- Collection path remains contract-driven: OTLP push + Prometheus scrape + explicit log mounts.
  - Files:
    - observability/alloy/config/traces-otlp.river
    - observability/alloy/config/metrics-qdrant.river
    - observability/alloy/config/logs-docker.river

## 6) Separation of workloads and observability stacks
Status: Implemented (already present, preserved)

Changes verified/maintained:
- Service and observability compose files remain separate and communicate through shared external network.
  - Files:
    - services/docker-compose.yml
    - observability/docker-compose.observability.yml

## 7) Mandatory log redaction before Loki
Status: Already present, preserved (no new redaction patterns added in this pass)

Changes verified/maintained:
- Existing redaction stages in Alloy pipelines for API keys, auth tokens, passwords, and paths remain in place.
  - Files:
    - observability/alloy/config/logs-docker.river
    - observability/alloy/config/logs-vscode.river
    - observability/alloy/config/logs-copilot.river

## 8) CI portability flags for local log collection
Status: Already present, preserved

Changes verified/maintained:
- Existing flags remain in alloy env and compose.
  - Files:
    - observability/alloy/env/alloy.env
    - observability/docker-compose.observability.yml
  - Flags: ENABLE_VSCODE_LOGS, ENABLE_COPILOT_LOGS, ENABLE_SERVICE_LOGS, ENABLE_QDRANT_LOGS.

## 9) Grafana RBAC and sensitive-access segregation
Status: Implemented (practical baseline) / Partial (datasource-level restrictions depend on Grafana edition/features)

Changes made:
- Added Grafana runtime controls relevant to access and audit visibility.
  - File: observability/grafana/env/grafana.env
  - Change: router logging enabled, explore disabled, editors cannot administer users.
- Added RBAC bootstrap automation using Grafana HTTP API.
  - File: observability/grafana/rbac/bootstrap-rbac.sh
  - Change: creates teams (obs-dev, obs-restricted), optional users, folder permissions, and membership mapping.
- Added RBAC bootstrap init service and Grafana provisioning mounts.
  - File: observability/docker-compose.observability.yml
  - Change: mounts grafana provisioning and RBAC script; adds grafana-rbac-init one-shot service.

Limitations:
- Fine-grained datasource permissions can require Grafana Enterprise features.
- This implementation enforces folder/team separation and audit-friendly logging in OSS-compatible workflow.

## 10) Validation executed during implementation
Status: Implemented (basic config validation)

Checks executed:
- File diagnostics: no errors reported in edited files.
- Compose render checks succeeded:
  - services compose config rendered successfully.
  - observability compose config rendered successfully.
- Note: Docker emitted a warning that the version field in observability/docker-compose.observability.yml is obsolete.

## Quick file list changed in this implementation pass
- .devcontainer/requirements.txt
- services/docker-compose.yml
- services/main_starter_service/main_server.py
- services/second-service-custom-mcp-work/python_custom_server.py
- observability/docker-compose.observability.yml
- observability/alloy/config/logs-docker.river
- observability/grafana/provisioning/datasources/datasources.yml
- observability/grafana/provisioning/dashboards/dashboards.yml
- observability/grafana/env/grafana.env
- observability/grafana/rbac/bootstrap-rbac.sh
- observability/grafana/dashboards/development/.gitkeep
- observability/grafana/dashboards/restricted/.gitkeep
- observability/Secure Alloy + LGTM Observability Prompt.md
- observability/runtime-logs/.gitkeep
- observability/runtime-logs/main_starter_service/.gitkeep
- observability/runtime-logs/second-service-custom-mcp-work/.gitkeep
- observability/runtime-logs/qdrant/.gitkeep
