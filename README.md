# dcker_mcp_setup

```text
dcker_mcp_setup/
├── .devcontainer/
│   └── requirements.txt
├── services/
│   ├── docker-compose.yml
│   ├── main_starter_service/
│   │   └── main_server.py
│   ├── qdrant/
│   │   └── qdrant_service.py
│   └── second-service-custom-mcp-work/
│       └── python_custom_server.py
├── observability/
│   ├── docker-compose.observability.yml
│   ├── OBSERVABILITY_GUIDE.md
│   ├── TELEMETRY_CONTRACTS.md
│   ├── LOG_SENSITIVITY_ASSESSMENT.md
│   ├── IMPLEMENTATION_REQUIREMENT_MAPPING.md
│   ├── alloy/
│   │   └── config/
│   ├── grafana/
│   │   └── provisioning/
│   └── runtime-logs/
├── startup-test/
│   ├── startup-and-test.sh
│   ├── startup-and-test-lite.sh
│   ├── cleanup.sh
│   └── README.md
├── tests/
│   ├── test_qdrant_service.py
│   └── observability/
│       ├── contracts/
│       └── flow/
├── MICROVM_DEVCONTAINER_STEPS.md
├── STARTUP_TEST.md
└── README.md
```

## Table of Contents

1. [Project Setup](#project-setup)
2. [Why This Exists](#why-this-exists)
3. [What's Included](#whats-included)
4. [Architecture](#architecture)
5. [Security](#security)
6. [Quick Start](#quick-start)
7. [Who This Is For](#who-this-is-for)
8. [Status](#status)

## Project Setup

A reproducible local environment for developing and testing AI-agent workflows. It isolates development, services, and observability so each layer stays predictable and easy to reason about.

## Why This Exists

Local stacks often become messy when services, tools, and telemetry run together. This setup keeps boundaries explicit:

- Development happens in a Dev Container inside WSL2
- Service containers run separately on controlled shared networks
- Observability runs as its own stack (Alloy + LGTM)
- Telemetry is contract-driven, not auto-scraped or privileged

## What's Included

- Local service stack with Qdrant and Python service placeholders
- Observability stack for logs, metrics, and traces
- Startup scripts enforcing deterministic bring-up order
- Contract and flow tests for services and telemetry wiring
- Documentation covering security, telemetry contracts, and runbooks

## Architecture

Services emit telemetry -> Alloy processes it -> LGTM stores and visualizes it.

## Security

- No Docker socket exposure to Alloy
- Only explicit telemetry endpoints and mounts
- Sensitive log redaction before Loki ingestion
- Access-separated Grafana dashboards and log visibility

## Quick Start

1. Rebuild and reopen in the Dev Container (VS Code).
2. Use startup script in startup-test.
3. Validate service health, then observability health.
4. Confirm logs, metrics, and traces in Grafana.

## Users

- Developers exploring agent-service patterns
- Teams wanting safer local observability defaults
- Developers building/experimenting with a reproducible startup, testing, and telemetry behavior 

## Status

A working sandbox with clear upgrade paths for stronger health checks, richer dashboards, and additional service-onboarding contracts.
