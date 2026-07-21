# Secure Observability with Alloy + LGTM

*A practical tutorial for building an observability architecture without Docker socket access*

---

# Table of Contents

1. [Introduction](#1-introduction)
2. [Architecture Overview](#2-architecture-overview)
3. [Architectural Model](#3-architectural-model)
4. [Project Layout](#4-project-layout)
5. [How the Docker Compose Files Work](#5-how-the-docker-compose-files-work)
6. [Security and Capability Model](#6-security-and-capability-model)
7. [Telemetry Contracts](#7-telemetry-contracts)
8. [Recommended OTEL Environment Variables](#8-recommended-otel-environment-variables)
9. [How Services Should Send Telemetry](#9-how-services-should-send-telemetry)
10. [Recommended Networking Setup](#10-recommended-networking-setup)
11. [Recommended Improvements](#11-recommended-improvements)
12. [Final Takeaway](#12-final-takeaway)

---

# 1. Introduction

This tutorial explains how to build an observability setup using:

* Grafana Alloy
* Grafana LGTM

The setup collects:

* logs
* metrics
* traces

from application services without giving the telemetry collector direct access to the Docker daemon.

Instead of relying on Docker auto-discovery, services explicitly publish telemetry to Alloy.

The architecture focuses on:

* explicit telemetry configuration
* reduced collector privileges
* separation between workloads and observability infrastructure

---

# 2. Architecture Overview

At a high level, the architecture looks like this:

```text
Applications / Services
        ↓
 OTLP / Metrics / Logs
        ↓
      Alloy
        ↓
      LGTM
   ├── Loki
   ├── Tempo
   ├── Mimir
   └── Grafana
```

Component responsibilities:

| Component | Responsibility                          |
| --------- | --------------------------------------- |
| Services  | Generate telemetry                      |
| Alloy     | Collect, process, and forward telemetry |
| LGTM      | Store telemetry                         |
| Grafana   | Visualization and dashboards            |

---

# 3. Architectural Model

Traditional observability setups often allow telemetry collectors to inspect Docker directly through:

```text
/var/run/docker.sock
```

That allows automatic:

* container discovery
* metadata collection
* port inspection
* log collection

This setup intentionally avoids Docker socket access.

Instead, services explicitly publish telemetry to Alloy using:

* OTLP
* Prometheus endpoints
* mounted log files

The architecture changes from:

```text
Collector discovers infrastructure automatically
```

to:

```text
Infrastructure explicitly publishes telemetry
```

This creates a contract-driven observability model where services define the telemetry they expose and Alloy processes only explicitly available telemetry.

---

# 4. Project Layout

```text
<REPO_ROOT>/
├── STARTUP_TEST.md
├── startup-test/
├── services/
├── observability/
├── tests/
└── context_data/
```

---

## services/

Contains:

* application containers
* MCP services
* Qdrant
* business logic

Example:

```text
services/
├── docker-compose.yml
├── main_starter_service/
├── qdrant/
└── second-service-custom-mcp-work/
```

---

## observability/

Contains:

* Alloy
* LGTM
* Grafana provisioning

Example:

```text
observability/
├── docker-compose.observability.yml
├── alloy/
└── grafana/
```

---

## Alloy Configuration Structure

```text
alloy/config/
├── runtime.river
├── alloy.river
├── logs-vscode.river
├── logs-copilot.river
├── logs-docker.river
├── metrics-qdrant.river
└── traces-otlp.river
```

`runtime.river` is the current compose entrypoint loaded by Alloy at container startup.

This structure separates telemetry pipelines by signal type instead of combining everything into one configuration file.

Benefits include:

* clearer organization
* easier maintenance
* simpler debugging

---

# 5. How the Docker Compose Files Work

Current setup:

```text
services/docker-compose.yml
observability/docker-compose.observability.yml
```

These are separate Docker Compose projects unless explicitly merged.

---

## Running Separately

Example:

```bash
docker compose -f services/docker-compose.yml up -d

docker compose -f observability/docker-compose.observability.yml up -d
```

Operational shortcut (recommended):

```bash
bash startup-test/startup-and-test.sh
```

The script applies ordered startup, readiness checks, and pytest execution across services and observability.

Execution flow:

1. The application stack starts
2. Docker creates networks and volumes
3. Application containers launch
4. The observability stack starts separately

---

## Important Note About depends_on

`depends_on` controls startup order only.

It does not guarantee that:

* Alloy is ready
* OTLP endpoints are accepting traffic
* Grafana finished initializing
* Qdrant metrics are available

Production setups commonly add:

* healthchecks
* retry logic
* startup delays
* exporter retries

In this repository, those concerns are operationalized in `startup-test/startup-and-test.sh`.

---

# 6. Security and Capability Model

Without Docker socket access, Alloy cannot:

* auto-discover containers
* inspect Docker metadata
* dynamically discover ports
* automatically collect container logs
* inspect runtime container state

However, Alloy can still:

* receive OTLP telemetry
* scrape Prometheus endpoints
* tail explicitly mounted logs
* process and enrich telemetry
* forward telemetry to LGTM

This changes Alloy from an infrastructure-inspecting component into a telemetry receiver and processor.

---

# 7. Telemetry Contracts

Since Alloy does not inspect Docker directly, each service must explicitly define the telemetry it exposes.

---

## Each Service Should Define

| Requirement      | Example                |
| ---------------- | ---------------------- |
| Metrics endpoint | `/metrics`             |
| Trace exporter   | OTLP                   |
| Log location     | `/app/logs/*.log`      |
| Service name     | `main-starter-service` |
| OTLP endpoint    | `http://alloy:4317`    |

Alloy can only process telemetry that services expose explicitly.

---

## Recommended Standards

| Signal        | Recommended Standard |
| ------------- | -------------------- |
| Metrics       | `/metrics`           |
| Traces        | OTLP gRPC            |
| Logs          | Structured stdout    |
| Service name  | `OTEL_SERVICE_NAME`  |
| OTLP endpoint | `http://alloy:4317`  |

---

## Service Responsibilities

Services are responsible for:

* generating telemetry
* exposing telemetry
* naming telemetry consistently

---

## Alloy Responsibilities

Alloy is responsible for:

* receiving telemetry
* scraping known endpoints
* tailing mounted logs
* processing/enriching telemetry
* forwarding telemetry to LGTM

---

# 8. Recommended OTEL Environment Variables

Shared defaults:

```yaml
x-otel-common: &otel-common
  OTEL_EXPORTER_OTLP_ENDPOINT: http://alloy:4317
  OTEL_EXPORTER_OTLP_PROTOCOL: grpc
  OTEL_TRACES_EXPORTER: otlp
  OTEL_METRICS_EXPORTER: otlp
  OTEL_LOGS_EXPORTER: otlp
```

Example usage:

```yaml
environment:
  <<: *otel-common
  OTEL_SERVICE_NAME: main-starter-service
```

This creates consistent telemetry behavior across services.

---

# 9. How Services Should Send Telemetry

Three common approaches work well.

---

## Option 1 — OTLP Push

Applications export directly to Alloy.

Example:

```yaml
environment:
  OTEL_EXPORTER_OTLP_ENDPOINT: http://alloy:4317
```

Characteristics:

* no Docker socket access
* no host mounts required
* compatible with Kubernetes-style deployments

---

## Option 2 — Prometheus Scraping

Applications expose:

```text
/metrics
```

Alloy scrapes the endpoint.

Commonly used for:

* Qdrant
* infrastructure metrics
* runtime metrics

---

## Option 3 — Explicit File Tailing

Example:

```yaml
volumes:
  - ./logs:/app/logs:ro
```

Alloy tails:

```text
/app/logs/*.log
```

This approach uses explicit read-only mounts.

---

# 10. Recommended Networking Setup

A shared external Docker network simplifies communication between stacks.

---

## Step 1 — Create the Network

```bash
docker network create observability
```

---

## Step 2 — Attach Both Compose Projects

Example:

```yaml
networks:
  observability:
    external: true
```

Benefits:

* services can reach Alloy
* Alloy can reach LGTM
* compose stacks remain separated

Host exposure policy for local and single-host development:

* publish observability ports on localhost only (`127.0.0.1`)
* keep container-to-container communication on the Docker `observability` network
* do not rely on host-wide `0.0.0.0` port publishing unless explicitly required

---

# 11. Recommended Improvements

---

## Add Telemetry Contracts Documentation

Suggested future structure (optional addition, not required in the current setup):

```text
observability/contracts/
├── telemetry-env.md
├── otlp-standards.md
├── service-labeling.md
└── ports-and-endpoints.md
```

This documents telemetry conventions and expectations.

Note: This directory is a recommendation for future hardening and documentation clarity. It may not exist in the current repository layout yet.

---

## Add Healthchecks

Especially for:

* Alloy
* LGTM
* Qdrant

This improves startup coordination.

---

## Standardize Labels

Example:

```yaml
OTEL_RESOURCE_ATTRIBUTES: env=dev,stack=sandbox
```

Useful for:

* filtering
* dashboards
* querying
* service grouping

---

# 12. Final Takeaway

This architecture separates:

* application workloads
* telemetry collection
* telemetry storage

while avoiding direct Docker daemon access from the telemetry collector.

The main architectural change is:

---

## Traditional Model

```text
Collector discovers infrastructure automatically
```

---

## Explicit Telemetry Model

```text
Infrastructure explicitly publishes telemetry
```

This is why:

* Docker socket access is removed
* telemetry contracts become important
* services explicitly expose logs, metrics, and traces
