# Telemetry Contracts: Service Exports and Observability Guarantees

**Purpose:** Define explicit telemetry exports that each service guarantees to provide, enabling observability without Docker socket introspection.

**Status:** STEP 4 of observability implementation — defines the contract between services and Alloy collector.

---

## 1. Contract Definition Model

Each service explicitly declares:
- **Service name** (`OTEL_SERVICE_NAME`)
- **Telemetry types** (logs, metrics, traces, profiles)
- **Export methods** (OTLP gRPC, HTTP, Prometheus scrape, file tail)
- **Required ports** and endpoints
- **Resource attributes** for correlation
- **Security notes** (mounts, network access, secrets)

---

## 2. Service Telemetry Contracts

### 2.1 Qdrant Database Service

**Container:** `qdrant-db`

**Service Name:** `qdrant-db`

**Exported Telemetry:**

| Type | Method | Endpoint | Port | Format | Required |
|------|--------|----------|------|--------|----------|
| Metrics | Prometheus scrape | `http://qdrant-db:6333/metrics` | 6333 | Prometheus text | YES |
| Logs | stdout/stderr | Container logs | - | plaintext | YES |
| Traces | None | - | - | - | NO (future) |

**Environment Variables:**
```bash
OTEL_SERVICE_NAME=qdrant-db
OTEL_RESOURCE_ATTRIBUTES=service.name=qdrant-db,service.version=latest,deployment.environment=local
```

**Alloy Collection:**
```
# Prometheus metrics scrape
prometheus.scrape "qdrant_metrics" {
  targets = [{
    __address__           = "qdrant-db:6333",
    __metrics_path__      = "/metrics",
    job                   = "qdrant",
  }]
  scrape_interval = "30s"
}

# Logs via file tail from mounted container logs
loki.source.file "qdrant_logs" {
  targets = [{
    __path__ = "/mnt/service-logs/qdrant/*.log",
    service_name = "qdrant-db",
  }]
}
```

**Network Access:** `observability` network

**Security Notes:**
- Metrics endpoint is public (no auth)
- Logs are read-only mounted
- No credentials needed

**Testing Checklist:**
- [ ] Qdrant service starts and exposes metrics on port 6333
- [ ] `http://qdrant-db:6333/metrics` returns Prometheus-formatted metrics
- [ ] Metrics include `qdrant_*` prefix (e.g., `qdrant_searches_total`)
- [ ] Container logs are captured and forwarded to Loki
- [ ] Redaction filters do not interfere with metric labels

---

### 2.2 Main Starter Service

**Container:** `main_starter_service`

**Service Name:** `main_starter_service`

**Exported Telemetry:**

| Type | Method | Endpoint | Port | Format | Required |
|------|--------|----------|------|--------|----------|
| Traces | OTLP gRPC | `http://alloy:4317` | 4317 | OTLP Protobuf | YES |
| Logs | stdout/stderr | Container logs | - | structured JSON | YES |
| Metrics | Prometheus scrape | `http://main_starter_service:8000/metrics` | 8000 | Prometheus text | NO (future) |

**Environment Variables:**
```bash
OTEL_EXPORTER_OTLP_ENDPOINT=http://alloy:4317
OTEL_SERVICE_NAME=main_starter_service
OTEL_RESOURCE_ATTRIBUTES=service.name=main_starter_service,service.version=1.0
OTEL_EXPORTER_OTLP_INSECURE=true
PYTHONUNBUFFERED=1
```

**Alloy Collection:**
```
# OTLP traces via gRPC
otlp.receiver "default" {
  protocols {
    grpc {
      endpoint = "0.0.0.0:4317"
    }
  }
}

# Logs via file tail from mounted logs
loki.source.file "app_logs" {
  targets = [{
    __path__ = "/mnt/service-logs/main_starter_service/*.log",
    service_name = "main_starter_service",
  }]
}
```

**Network Access:** `observability` network

**Security Notes:**
- OTLP endpoint must be reachable on `alloy:4317`
- Logs should be structured JSON for proper parsing
- Ensure PYTHONUNBUFFERED=1 for real-time log streaming

**Implementation Requirement:**
- Service must import OpenTelemetry Python SDK
- Initialize tracer provider pointing to `OTEL_EXPORTER_OTLP_ENDPOINT`
- Emit structured logs to stdout with proper redaction

**Testing Checklist:**
- [ ] Service starts and resolves `alloy` hostname
- [ ] Service successfully exports traces to OTLP endpoint
- [ ] Traces appear in Grafana Tempo within 5 seconds
- [ ] Logs are captured in real-time
- [ ] Service name and resource attributes are preserved in Grafana
- [ ] Redaction filters successfully mask credentials in logs

---

### 2.3 Second Service (Custom MCP Work)

**Container:** `second-service-custom-mcp-work`

**Service Name:** `second-service-custom-mcp-work`

**Exported Telemetry:**

| Type | Method | Endpoint | Port | Format | Required |
|------|--------|----------|------|--------|----------|
| Traces | OTLP gRPC | `http://alloy:4317` | 4317 | OTLP Protobuf | YES |
| Logs | stdout/stderr | Container logs | - | structured JSON | YES |
| Metrics | Custom HTTP | `http://second-service-custom-mcp-work:9001/metrics` | 9001 | Prometheus text | NO (future) |

**Environment Variables:**
```bash
OTEL_EXPORTER_OTLP_ENDPOINT=http://alloy:4317
OTEL_SERVICE_NAME=second-service-custom-mcp-work
OTEL_RESOURCE_ATTRIBUTES=service.name=second-service-custom-mcp-work,service.version=1.0
OTEL_EXPORTER_OTLP_INSECURE=true
PYTHONUNBUFFERED=1
```

**Alloy Collection:**
```
# OTLP traces via gRPC (shared receiver)
otlp.receiver "default" {
  # Already defined in traces-otlp.river
}

# Logs via file tail from mounted logs
loki.source.file "mcp_logs" {
  targets = [{
    __path__ = "/mnt/service-logs/second-service-custom-mcp-work/*.log",
    service_name = "second-service-custom-mcp-work",
  }]
}
```

**Network Access:** `observability` network

**Security Notes:**
- OTLP endpoint must be reachable on `alloy:4317`
- Custom MCP protocol logs should be structured
- Ensure PYTHONUNBUFFERED=1 for real-time log streaming

**Implementation Requirement:**
- Service must import OpenTelemetry Python SDK
- Initialize tracer provider pointing to `OTEL_EXPORTER_OTLP_ENDPOINT`
- Emit structured logs to stdout with proper redaction
- MCP-specific telemetry should include MCP operation type as span attribute

**Testing Checklist:**
- [ ] Service starts and resolves `alloy` hostname
- [ ] Service successfully exports traces to OTLP endpoint
- [ ] MCP operations are traced as spans
- [ ] Traces appear in Grafana Tempo within 5 seconds
- [ ] Logs are captured in real-time with MCP context
- [ ] Redaction filters successfully mask secrets in MCP payload logs

---

## 3. Future Service Onboarding Template

When adding new services, use this contract template:

```markdown
### X.Y New Service Name

**Container:** `service-name`

**Service Name:** `service-name`

**Exported Telemetry:**

| Type | Method | Endpoint | Port | Format | Required |
|------|--------|----------|------|--------|----------|
| Traces | OTLP gRPC | `http://alloy:4317` | 4317 | OTLP Protobuf | YES |
| Logs | stdout/stderr | Container logs | - | structured JSON | YES |
| Metrics | Prometheus scrape | `http://service-name:PORT/metrics` | PORT | Prometheus text | NO |

**Environment Variables:**
```bash
OTEL_EXPORTER_OTLP_ENDPOINT=http://alloy:4317
OTEL_SERVICE_NAME=service-name
OTEL_RESOURCE_ATTRIBUTES=service.name=service-name,service.version=1.0
PYTHONUNBUFFERED=1
```

**Alloy Collection:**
[Include River configuration snippets for this service]

**Network Access:** `observability` network

**Security Notes:**
[Document any special security considerations]

**Implementation Requirement:**
[List what the service must do to comply with the contract]

**Testing Checklist:**
- [ ] Service starts successfully
- [ ] Service exports telemetry
- [ ] Telemetry appears in LGTM within expected timeframe
- [ ] Redaction filters work correctly
```

---

## 4. Cross-Service Correlation

Services should emit correlated traces using W3C Trace Context headers:

```python
# Python example using OpenTelemetry
from opentelemetry.propagate import inject
from opentelemetry.propagators.w3c_trace_context import W3CTraceContextPropagator

headers = {}
inject(headers)  # Adds traceparent and tracestate headers
# Use headers in HTTP requests to other services
```

This enables Grafana Tempo to correlate traces across service boundaries.

---

## 5. Validation Strategy

**For each service telemetry contract:**

1. **Startup validation:**
   - Service resolves `alloy` hostname
   - Service successfully connects to OTLP endpoint
   - Logs are emitted to stdout immediately

2. **Runtime validation:**
   - Emit synthetic requests/traces
   - Query Grafana Tempo for traces (should appear within 5s)
   - Query Grafana Loki for logs
   - Verify service name and resource attributes
   - Verify redaction filters are working (sensitive data absent)

3. **Failure scenarios:**
   - OTLP endpoint unreachable: service should log error but continue
   - Network latency: traces should buffer and resend
   - Log redaction regex errors: should not drop logs, log warning

---

## 6. Contract Versioning

When contracts change (e.g., new telemetry types added):

1. Update this file with new version
2. Tag with service version (e.g., `main_starter_service v2.0`)
3. Document breaking changes
4. Update Alloy River config correspondingly
5. Update tests to validate new contract

---

## 7. Service-to-Alloy Networking

**Network Name:** `observability` (external Docker bridge)

**DNS Resolution:**
- Services can reach Alloy via `http://alloy:4317` or `http://alloy:4318`
- Alloy resolves service names (e.g., `qdrant-db:6333`)

**Port Mapping:**
| Service | Internal Port | Network | Exposure |
|---------|---------------|---------|----------|
| alloy | 4317, 4318 | observability | OTLP receiver |
| qdrant-db | 6333 | observability | Metrics/API |
| main_starter_service | - | observability | OTLP sender |
| second-service-custom-mcp-work | - | observability | OTLP sender |

