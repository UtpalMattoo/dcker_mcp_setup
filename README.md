# dcker_mcp_setup

Project tree snapshot (source and docs only; generated artifacts like `.venv`, `.pytest_cache`, logs, and `__pycache__` are omitted):

```text
dcker_mcp_setup/
├── .devcontainer/
│   └── requirements.txt
├── context_data/
├── observability/
│   ├── alloy/
│   │   ├── config/
│   │   └── env/
│   ├── grafana/
│   │   ├── dashboards/
│   │   ├── env/
│   │   ├── provisioning/
│   │   └── rbac/
│   ├── docker-compose.observability.yml
│   ├── implementation_requirement_mapping.md
│   ├── local_path_variables.md
│   ├── log_sensitivity_assessment.md
│   ├── observability_guide.md
│   ├── secure_alloy_lgtm_observability_prompt.md
│   └── telemetry_contracts.md
├── services/
│   ├── ai_pipeline/
│   │   ├── embedding/
│   │   │   ├── providers/
│   │   │   │   ├── base.py
│   │   │   │   ├── openai_provider.py
│   │   │   │   └── sentence_transformers_provider.py
│   │   │   └── service.py
│   │   └── ingestion/
│   │       └── service.py
│   ├── main_starter_service/
│   │   ├── main_server.py
│   │   └── requirements.txt
│   ├── qdrant/
│   │   ├── preUpsert_embeddingCreation_.md
│   │   └── qdrant_service.py
│   ├── second-service-custom-mcp-work/
│   │   ├── python_custom_server.py
│   │   └── requirements.txt
│   ├── config.py
│   └── docker-compose.yml
├── startup-test/
│   ├── cleanup.sh
│   ├── README.md
│   ├── startup-and-test-lite.sh
│   └── startup-and-test.sh
├── tests/
│   ├── observability/
│   │   ├── contracts/
│   │   └── flow/
│   ├── unit/
│   │   ├── conftest.py
│   │   ├── test_cache_path_config.py
│   │   ├── test_config.py
│   │   ├── test_dimension_validation.py
│   │   ├── test_embedding_service.py
│   │   └── test_provider_factory.py
│   ├── test_qdrant_service.py
│   └── test_qdrant_service.sh
├── MICROVM_DEVCONTAINER_STEPS.md
├── pytest.ini
├── STARTUP_TEST.md
└── README.md
```

## Table of Contents

1. [Project Setup](#project-setup)
2. [Docker Setup](#docker-setup)
3. [Why This Exists](#why-this-exists)
4. [What's Included](#whats-included)
5. [Architecture](#architecture)
6. [Embedding Roadmap (Phases)](#embedding-roadmap-phases)
7. [Phase 1 Sequence Diagram](#phase-1-sequence-diagram)
8. [LGTM in This Project](#lgtm-in-this-project)
9. [Security](#security)
10. [Quick Start](#quick-start)
11. [Who This Is For](#who-this-is-for)
12. [Status](#status)

## Project Setup

Local environment for developing and testing AI-agent workflows. It isolates development, services, and observability.

This setup uses rootless Docker - Docker runs without full system-level (admin/root) privileges. If a container is compromised, it has fewer permissions and is less likely to affect the host machine.

## Docker Setup

This project uses a rootless Docker-in-Docker setup inside the Dev Container.

- The Dev Container runs its own Docker daemon instead of mounting the host Docker socket. This means Docker commands inside the container talk to an internal daemon, not directly to your host machine's Docker engine. Relevant diagrams: [Docker-isolation-setup.png](Docker-isolation-setup.png), [architecture_srtict_isolation.png](architecture_srtict_isolation.png).
- Service containers run from the Dev Container through that inner daemon. In practice, a service started from the Dev Container, is launched by this container's own Docker runtime. Relevant diagrams: [project_setup.png](project_setup.png), [Docker-isolation-setup.png](Docker-isolation-setup.png).
- The Dev Container joins the shared `mcp-net` network for service communication. This gives the inner Docker-managed services a predictable network path for talking to each other. Relevant diagrams: [mcp-net.png](mcp-net.png), [project_setup.png](project_setup.png).
- The host Docker socket remains disabled by default for stricter isolation. The Dev Container does not have direct control over the host Docker daemon if something goes wrong. Relevant diagrams: [architecture_srtict_isolation.png](architecture_srtict_isolation.png), [Docker-isolation-setup.png](Docker-isolation-setup.png).



Different views:



At a high level, the model is:

- Windows host -> WSL2 -> Dev Container -> inner Docker daemon -> project services


Simple Docker view:

```mermaid
graph TD
	Host[Windows Host] --> WSL[WSL2]
	WSL --> Dev[Dev Container]
	Dev --> DinD[Rootless Docker-in-Docker]
	DinD --> Services[Project Services]
	DinD --> Obs[Observability Stack]
```


Detailed runtime view:

```mermaid
graph TD
	subgraph Host[Windows Host]
		VSCode[VS Code]
		DockerDesktop[Docker Desktop]
	end

	subgraph WSL2[WSL2 MicroVM]
		subgraph DevContainer[Dev Container]
			Shell[Dev Shell / Agent Runtime]
			InnerDocker[Rootless Docker Daemon]
		end

		subgraph Services[services/docker-compose.yml]
			Qdrant[qdrant-db]
			Main[main_starter_service]
			Second[second-service-custom-mcp-work]
		end

		subgraph Observability[observability/docker-compose.observability.yml]
			Alloy[Grafana Alloy]
			LGTM[LGTM Stack]
			Grafana[Grafana]
			VizMarker[[Visualization happens here]]
		end
	end

	VSCode --> Shell
	DockerDesktop --> WSL2
	Shell -- docker compose / docker CLI --> InnerDocker
	InnerDocker -- creates/starts --> Qdrant
	InnerDocker -- creates/starts --> Main
	InnerDocker -- creates/starts --> Second
	InnerDocker -- creates/starts --> Alloy
	InnerDocker -- creates/starts --> LGTM
	InnerDocker -- creates/starts --> Grafana
	Main -- OTLP/logs --> Alloy
	Second -- OTLP/logs --> Alloy
	Qdrant -- metrics/logs --> Alloy
	Alloy -- forwards telemetry --> LGTM
	Grafana -- queries --> LGTM
	Grafana --> VizMarker
```

Connector legend: `creates/starts` means container lifecycle control by the inner Docker daemon. `OTLP/logs/metrics`, `forwards telemetry`, and `queries` are runtime data-flow links.

## Why This Exists

Separating services, tools, and telemetry run together to keep boundaries explicit:

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

- Search using Qdrant as the vector database for semantic search, embedding storage, and retrieval—needed for RAG‑style workflows.
- Containerized and modular, making it straightforward to plug in additional AI components or swap services without disrupting the rest of the stack.
- Observability set up through Grafana, Alloy, and LGTM, covering metrics, logs, and traces for AI‑related workloads.
- Agent‑service pattern structure: small, focused services handle specific responsibilities and can be composed into more complex behaviors.

## Embedding Roadmap (Phases)

Source: services/qdrant/preUpsert_embeddingCreation_.md

1. Phase 1 - Embedding foundation and configuration
- Status: implemented
- Provider abstraction, config validation, startup checks, normalized errors, and Qdrant safety checks.

2. Phase 2 - Document processing pipeline
- Status: planned
- Add readers (txt, md, pdf, eml, mbox), chunking, and metadata schema.

3. Phase 3 - Qdrant integration and persistence
- Status: partially implemented
- Expand collection lifecycle, persistence, and integration tests.

4. Phase 4 - CLI-based ingestion
- Status: planned
- Add CLI args, validation, and progress output.

5. Phase 5 - Gmail integration
- Status: planned
- Add OAuth ingestion, filters, metadata preservation, and incremental sync.

6. Phase 6 - Search API
- Status: planned
- Add /search, metadata filtering, and health endpoints.

7. Phase 7 - Frontend UI
- Status: planned
- Add upload flow, collection views, and semantic search UI.

8. Phase 8 - Production readiness
- Status: planned
- Add KPI metrics, async ingestion, embedding cache, security, and backup/restore.

## Phase 1 Sequence Diagram

This shows what happens in Phase 1 when text is converted into an embedding and saved.

```mermaid
sequenceDiagram
	participant App as App
	participant Config as Config File
	participant Health as Startup Checks
	participant Embed as Embedding Service
	participant Factory as Provider Factory
	participant Provider as Chosen Provider
	participant Ingest as Ingestion Service
	participant DB as Qdrant Database

	App->>Config: Load settings
	Config->>Config: Read provider + model
	Config->>Config: Read expected vector size
	Config->>Config: Validate provider + model + dimensions
	Config-->>App: Return valid config

	App->>Health: Run startup checks
	Health->>Health: Check local packages (if needed)
	Health->>Health: Check cache folder can be written
	Health-->>App: Ready or stop with error

	App->>Embed: Start embedding service
	Embed->>Factory: Build configured provider
	Factory->>Factory: No automatic fallback
	Factory->>Provider: Create selected provider
	Provider-->>Embed: Provider ready

	App->>Ingest: Send text to ingest
	Ingest->>Embed: Ask for embedding
	Embed->>Provider: Create vector from text
	Provider->>Provider: Retry transient OpenAI failures
	Provider-->>Embed: Return vector
	Embed->>Embed: Check vector size is correct
	Embed-->>Ingest: Return checked vector

	Ingest->>DB: Save vector + metadata
	DB->>DB: Create collection if missing
	DB->>DB: Check vector size before save
	DB-->>Ingest: Saved
	Ingest-->>App: Done

	Note over Provider,Embed: Provider failures are normalized as EmbeddingProviderError
```

1. The app reads settings (provider, model, and dimensions).
2. The app runs startup checks so problems are caught early.
3. The provider factory builds only the configured provider (no fallback).
4. The text is turned into a vector.
5. Transient OpenAI errors are retried.
6. The vector size is checked to avoid bad data.
7. The vector is saved in Qdrant.

If anything fails, the process stops with a clear error instead of silently continuing.

## LGTM in This Project

LGTM is the observability backend bundle used by this repo:

- Loki: stores and indexes logs
- Grafana: visualization and dashboards
- Tempo: distributed traces backend
- Mimir: metrics backend

In this setup, Grafana Alloy collects and forwards telemetry into the LGTM backends, and Grafana queries those backends to render dashboards.

Where visualization happens:

- Visualization happens in Grafana (the UI/dashboard layer)
- In the diagram, this is the `Grafana -- queries --> LGTM` connection
- In the repo, the visualization configuration is under `observability/grafana/`

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

## Who This Is For

- Developers exploring agent-service patterns
- Teams wanting safer setups (containerized) and observability
- Developers building/experimenting with a reproducible startup, testing, and telemetry behavior 

## Status

Sandbox with upgrade paths for stronger health checks, dashboards, and service-onboarding contracts.
