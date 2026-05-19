# Reusable Prompt: Secure Alloy + LGTM Observability Architecture

## Context

Design a practical observability architecture using:

* Grafana Alloy
* Grafana LGTM

The architecture should prioritize:

* explicit telemetry contracts
   Why: Clear contracts let you check telemetry in a reliable way and avoid hidden assumptions.
   Detail: List needed endpoints, labels, and data formats for each service.
   Operational impact: If telemetry is missing, you can catch it early in tests.
* reduced infrastructure privileges
   Why: Fewer permissions reduce damage if the collector is set up wrong or gets compromised.
   Detail: Allow Alloy to read only what it needs through known endpoints and read-only mounts.
   Operational impact: Reviews are simpler because Alloy cannot control other containers.
* separation between workloads and observability
   Why: Keeping stacks separate makes failures easier to contain and ownership clearer.
   Detail: Run app services and observability as separate compose projects with one shared network.
   Operational impact: You can update observability tools without interrupting app services.
* OTLP-first telemetry collection
   Why: OTLP gives one common way to send logs, metrics, and traces.
   Detail: Using OTLP everywhere avoids custom exporter differences between services.
   Operational impact: Changing backends later is easier because app instrumentation stays the same.
* modular configuration structure
   Why: Smaller config files are easier to read, debug, and maintain.
   Detail: Split river files by signal and source, like logs, metrics, traces, and service-specific parts.
   Operational impact: Small changes are safer and faster to troubleshoot.

Local path placeholders are defined in `observability/LOCAL_PATH_VARIABLES.md`, which is kept out of version control.

The environment already contains multiple Docker Compose files and a separated observability stack.

---

## Goal

Create a complete observability setup where:

1. Alloy acts as the isolated telemetry collection layer.
2. LGTM acts as the backend for logs, metrics, traces, and dashboards.
3. Telemetry is collected from:

   * VS Code logs
   * GitHub Copilot extension logs
   * application containers
   * Qdrant
   * future services added later
4. Telemetry collection works without Docker socket access.
5. Services explicitly expose telemetry instead of relying on Docker auto-discovery.

---

# Existing Project Structure

```text
<REPO_ROOT>/
├── MICROVM_DEVCONTAINER_STEPS.md
├── context_data/
├── services/
│   ├── docker-compose.yml
│   ├── main_starter_service/
│   ├── qdrant/
│   └── second-service-custom-mcp-work/
├── tests/
└── observability/
    ├── docker-compose.observability.yml
    ├── alloy/
    │   ├── config/
    │   │   ├── alloy.river
    │   │   ├── logs-vscode.river
    │   │   ├── logs-copilot.river
    │   │   ├── logs-docker.river
    │   │   ├── metrics-qdrant.river
    │   │   └── traces-otlp.river
    │   └── env/
    │       └── alloy.env
    └── grafana/
        ├── provisioning/
        │   ├── datasources/
        │   │   └── datasources.yml
        │   └── dashboards/
        │       └── dashboards.yml
        ├── dashboards/
        │   ├── qdrant-overview.json
        │   ├── docker-overview.json
        │   └── app-telemetry.json
        └── env/
            └── grafana.env
```

---

# Architectural Expectations

The setup should follow a contract-driven observability model.

Do not assume Alloy can inspect Docker infrastructure directly.

Services should explicitly expose telemetry using:

* OTLP push
* Prometheus scrape endpoints
* explicitly mounted log files

Avoid infrastructure auto-discovery patterns that depend on:

```text
/var/run/docker.sock
```

The design should treat Alloy as:

* a telemetry gateway
* a telemetry processor
* a routing layer

not as a privileged infrastructure discovery component.

---

# Security Constraints

The architecture must follow these constraints:

1. Use two main containers:

   * `grafana/otel-lgtm`
   * `grafana/alloy`

2. Do not mount Docker socket into Alloy.

   Specifically, avoid:

```text
/var/run/docker.sock
```

3. Alloy should only receive telemetry through:

   * OTLP
   * Prometheus scraping
   * explicitly mounted log paths

4. Alloy forwards telemetry to LGTM using:

   * OTLP gRPC (`4317`)
   * OTLP HTTP (`4318`)

5. The network layout should preserve workload isolation and prevent Alloy from accessing Docker daemon APIs.

---

# Log Security and Access Control Requirements

**These requirements are MANDATORY before implementation.**

## 1. Log Sensitivity Assessment

Conduct a sensitivity audit of all collected logs:

* VS Code logs: identify telemetry types and potential sensitive data exposure
* Copilot logs: identify prompts, responses, and interaction traces
* application service logs: identify internal details and user data
* Qdrant logs: identify query patterns and operational details

Document findings in a telemetry audit checklist.

## 2. Mandatory Log Redaction in Alloy Pipelines

Before forwarding any logs to LGTM:

* Define regex patterns for automatic redaction (API key formats, JWT patterns, tokens, credentials, PII)
* Add redaction/replacement stages in each Alloy log pipeline (`logs-*.river` files)
* Redaction MUST occur before data reaches Loki
* Maintain a redaction patterns reference document for ongoing updates

Example sensitive patterns to redact:
* `api[_-]?key["\s:=]*([A-Za-z0-9\-._~+/]+=*)`
* `(authorization|auth)["\s:=]*Bearer\s+[A-Za-z0-9\-._~+/]+=*`
* `password["\s:=]*[^\s"]+`
* `(token|secret)["\s:=]*[^\s"]+`

## 3. Grafana Access Control (RBAC)

Configure Grafana RBAC so that:

* Only authorized users can view logs containing sensitive data
* Separate dashboard/datasource permissions for production logs vs development logs
* Audit logging enabled for sensitive data access
* Environment-specific access restrictions

## 4. CI Environment Portability

Add environment flags to disable local log collection in CI:

* `ENABLE_VSCODE_LOGS=false` disables VS Code log tailing
* `ENABLE_COPILOT_LOGS=false` disables Copilot extension log tailing
* Default: `true` for local development, `false` for CI/production

---

# Required Telemetry Sources

## 1. VS Code Logs

Windows path:

```text
<VSCODE_LOGS_DIR>
```

Include:

* file tailing using mounted paths
* optional OTLP forwarding approach
* Windows mount considerations
* troubleshooting for path issues

---

## 2. GitHub Copilot Extension Logs

Windows path pattern:

```text
<COPILOT_EXTENSION_LOGS_DIR>
```

Include:

* how to locate `workspace-id`
* safe ingestion methods
* file tailing strategy
* optional preprocessing or filtering

---

## 3. Docker/Application Telemetry Without docker.sock

Do not use Docker API discovery.

Allowed telemetry patterns:

* OTLP push from applications
* Prometheus scrape endpoints
* explicitly mounted logs
* structured stdout logging

Avoid:

* Docker daemon introspection
* container auto-discovery
* mounting Docker internal log directories
* recreating Docker discovery manually

Explain what Alloy can and cannot do without Docker socket access.

---

## 4. Qdrant Telemetry

Include:

* Prometheus metrics scraping
* logs ingestion
* OTLP traces if supported
* recommended labels and naming conventions

---

## 5. Future Services Placeholder

Add a reusable onboarding section for future services containing:

| Field           | Description                           |
| --------------- | ------------------------------------- |
| Service name    | Logical service identifier            |
| Telemetry types | logs, metrics, traces, profiles       |
| Export method   | OTLP, scrape, file tail               |
| Required ports  | metrics/traces endpoints              |
| Labels          | OTEL labels and attributes            |
| Security notes  | mount restrictions and exposure rules |

---

# Existing Compose Structure

The environment already contains:

```text
services/docker-compose.yml
observability/docker-compose.observability.yml
```

Explain:

* how Docker Compose startup order works
* what `depends_on` actually guarantees
* why healthchecks are still necessary
* how separate compose projects communicate
* how to use shared external networks

---

# Required Output

Generate all of the following.

---

## 1. Architecture Walkthrough

Include:

* telemetry flow from services → Alloy → LGTM
* trust boundaries
* blast-radius discussion
* explanation of explicit telemetry contracts
* explanation of why observability becomes "passive" without Docker socket access

---

## 2. Docker Compose Design

Provide:

* secure Compose examples
* shared external network setup
* Alloy + LGTM networking
* exposed ports
* healthchecks
* OTEL environment variable reuse patterns

Include examples for:

```yaml
OTEL_EXPORTER_OTLP_ENDPOINT
OTEL_SERVICE_NAME
OTEL_RESOURCE_ATTRIBUTES
```

---

## 3. Alloy Configuration

Provide modular Alloy configuration examples for:

* OTLP receiver (gRPC + HTTP)
* Prometheus scraping
* log pipelines with mandatory redaction stages
* VS Code logs with automatic redaction
* Copilot logs with automatic redaction
* Qdrant metrics
* traces pipeline
* exporters to LGTM

**MANDATORY for log pipelines:** Include regex-based `loki.process` or equivalent filtering stages that apply redaction patterns defined in the "Log Security and Access Control Requirements" section before forwarding to Loki. Demonstrate how to redact API keys, tokens, credentials, and PII.

Keep the configuration split across multiple `.river` files.

---

## 4. Telemetry Standards

Define recommended telemetry conventions for all services.

Include standards for:

| Signal         | Recommended Standard |
| -------------- | -------------------- |
| Metrics        | `/metrics`           |
| Traces         | OTLP gRPC            |
| Logs           | structured stdout    |
| Service naming | `OTEL_SERVICE_NAME`  |
| OTLP endpoint  | `http://alloy:4317`  |

Explain why standardized telemetry matters once Docker auto-discovery is removed.

---

## 5. Application Instrumentation Guidance

Show how services should publish telemetry.

Include:

* OTLP examples
* Prometheus examples
* structured logging examples
* retry guidance
* buffering considerations
* startup timing considerations

Explain why Alloy cannot process telemetry that services never expose.

---

## 6. Validation and Troubleshooting

Provide:

* commands to send test telemetry
* commands to verify Alloy pipelines
* Grafana verification steps
* **commands to validate that redaction filters are working (verify sensitive patterns are NOT present in ingested logs)**
* troubleshooting examples for:

  * missing telemetry
  * broken Windows mounts
  * incorrect endpoints
  * failed scrapes
  * OTLP connection failures
  * label inconsistencies
  * **redaction filter failures (patterns not redacting as expected)**

---

## 7. Telemetry Matrix

Create a table with:

| Source | Transport | Telemetry Type | Security Notes | Limitations |
| ------ | --------- | -------------- | -------------- | ----------- |

Include:

* VS Code
* Copilot
* Qdrant
* application services
* future services

---

# Important Concepts to Explain

Include clear explanations for:

1. Why removing Docker socket access improves isolation.
2. Why Docker socket access is highly privileged.
3. What Alloy loses without Docker socket access:

   * container auto-discovery
   * metadata inspection
   * dynamic port discovery
   * automatic log collection
4. What still works without Docker socket access:

   * OTLP push
   * Prometheus scraping
   * explicit log mounts
5. The shift from:

   * discovery-driven observability
   * to contract-driven observability

---

# Recommended Improvements

Include suggestions for:

* shared external Docker networks
* telemetry standards documentation (optional future addition, for example a contracts folder if adopted)
* centralized OTEL environment templates
* healthchecks
* sampling/rate limiting
* retention policies
* future profile collection support

Note: sensitive log redaction and Grafana RBAC are MANDATORY, not optional — they are fully specified in the "Log Security and Access Control Requirements" section above.

---

# Output Style

The response should:

* use practical engineering language
* avoid marketing language and hype
* clearly separate required vs optional components
* explain tradeoffs directly
* keep examples runnable and concrete
* avoid assuming Kubernetes unless explicitly comparing architectures
* explain operational implications, not just configuration syntax
