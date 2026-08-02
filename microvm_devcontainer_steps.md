# MicroVM AI Agent Dev Container Build Steps

This document captures exactly what is being built in the `.devcontainer` folder and how to use it.

## Table of Contents

1. [Folder Layout](#1-folder-layout)
2. [Canonical References](#2-canonical-references)
3. [Dev Container Configuration](#3-dev-container-configuration)
4. [Post-Create Setup Actions](#4-post-create-setup-actions)
5. [Not In Use (may change)](#5-not-in-use-now)
6. [Why This Is MicroVM-Optimized](#6-why-this-is-microvm-optimized)
7. [Isolation Model for MCP Servers](#7-isolation-model-for-mcp-servers)
8. [How to Use in VS Code](#8-how-to-use-in-vs-code)
9. [Reproducibility Notes](#9-reproducibility-notes)
10. [Testing the Qdrant Service](#10-testing-the-qdrant-service)

## 1. Folder Layout

High-level orientation tree:

```text
dcker_mcp_setup/
├── .devcontainer/
├── docs/
│   ├── runbooks/
│   └── observability/
├── microvm_devcontainer_steps.md
├── README.md
├── startup-test/
├── services/
├── observability/
└── tests/
```

This tree is intentionally short so it is less likely to drift over time.

## 2. Canonical References

Use these files as source of truth:

- Full project tree and top-level navigation: `README.md`
- Startup scenarios and skip/bypass behavior: `docs/runbooks/STARTUP_TEST.md`
- Script-first startup flow: `startup-test/README.md`

## 3. Dev Container Configuration

### Note on Dockerfile

This setup does not require a custom Dockerfile. The dev container uses a pre-existing image (`python:3.12`) specified in `devcontainer.json`. All configuration is handled via `devcontainer.json`, unless you need additional build-time customization.

Additional setup steps are performed by `setup.sh` and related scripts.

The active `devcontainer.json` behavior is:

- Uses official upstream Python image: `python:3.12`
- Enables rootless Docker-in-Docker
- Joins the `mcp-net` Docker network via `runArgs`
- Runs `.devcontainer/setup.sh` after container creation
- Forwards ports: `6333`, `5000`, `8000`

## 4. Post-Create Setup Actions

On first container creation, `.devcontainer/setup.sh` runs automatically via `postCreateCommand`.

Active steps:

1. `apt-get update`
2. `apt-get install -y curl git gnupg ca-certificates apt-transport-https build-essential pkg-config`
3. `pip install --upgrade pip`
4. `if [ -f .devcontainer/requirements.txt ]; then pip install -r .devcontainer/requirements.txt; fi`
5. Create the external Docker network `mcp-net` if it does not exist

## 5. Not In Use now

Status markers to prevent confusion:

- Not currently active: Node.js installation in `.devcontainer/setup.sh`
- Not currently active: Google Cloud CLI installation in `.devcontainer/setup.sh`
- Not currently active: forwarded ports `3000` and `8080` in `devcontainer.json`
- Drift risk: any detailed file tree in this document (use `README.md` for full tree)
- Drift risk: command examples that assume specific profiles or local networking defaults

If these features are re-enabled later, update this section first.

## 6. Why This Is MicroVM-Optimized

- Runs inside WSL2 microVM for strong isolation
- Enables Docker access from inside Dev Container using rootless Docker-in-Docker
- Keeps Python base image pure (`python:3.12`)
- Includes native build tooling to avoid missing compiler errors
- Supports isolated MCP runtime model

## 7. Isolation Model for MCP Servers

This setup intentionally does not run MCP servers inside the Dev Container.

Recommended pattern:

- Agent runtime: Dev Container
- MCP servers: Separate Docker containers

Run isolated MCP services with Docker Compose, for example:

```bash
cd /workspaces/dcker_mcp_setup/services
docker compose up -d qdrant-db
docker compose up -d second-service-custom-mcp-work
```

Current compose services in this project:

- `qdrant-db` - profile-gated inner Qdrant service (`inner-qdrant`)
- `main_starter_service` - startup container for main orchestrator work
- `second-service-custom-mcp-work` - custom MCP service container

## 8. How to Use in VS Code

1. Open the project in VS Code.
2. Run: **Dev Containers: Rebuild and Reopen in Container**.
3. Wait for post-create steps to complete.
4. Confirm toolchain:
   - `python --version`
   - `docker --version`

Workspace note:

- In this environment the project is mounted at `/workspaces/dcker_mcp_setup`.

## 9. Reproducibility Notes

- Keep all Python packages pinned in `requirements.txt`.
- Keep all tooling setup in `postCreateCommand`.
- Avoid manual ad-hoc installs to maintain reproducible rebuilds.

## 10. Testing the Qdrant Service

### Why We Run These Tests from the Dev Container Terminal

There are two deliberate design decisions behind the current workflow:

1. Python dependencies installed by `docker compose` in `main_starter_service` do not persist reliably across container recreation.
   - The service currently starts from `python:3.12` and runs `pip install -r requirements.txt` at runtime.
   - Those runtime-installed packages live in the container writable layer, so a recreated container starts fresh and must install again.

2. We do not run `pytest` as part of `main_starter_service` startup.
   - `pytest` is a one-shot process, not a long-running server.
   - Running it in startup command makes the container exit right after tests, which can cause restart-loop behavior depending on restart policy.

Because of this, the simplest and most stable approach is to run tests directly from the dev container terminal.

### Canonical Startup/Test Entry Point

Use the repo-root `startup-test/` folder as the canonical startup and test workflow:

- `startup-test/startup-and-test.sh` for full ordered startup + tests
- `startup-test/startup-and-test-lite.sh` for fast contract checks
- `startup-test/cleanup.sh` for teardown

Simple summary: the contract checks confirm observability setup files include required services and safety rules.
Technical definition: observability config contracts require expected compose wiring (`lgtm` + `alloy`, `OTEL_EXPORTER_OTLP_ENDPOINT=http://lgtm:4317`, external `observability` network, no `docker.sock`) and required Alloy redaction/import rules in `observability/alloy/config/*.river`.
Test type note: these are static file-content assertions, not runtime integration tests.

Recommended from WSL shell:

```bash
cd /workspaces/dcker_mcp_setup
bash startup-test/startup-and-test.sh
```

This centralizes ordering, health checks, and pytest execution as service count grows.

### Test Target

- Test file: `tests/test_qdrant_service.py`
- Test script: `tests/test_qdrant_service.sh`
- Test log: `tests/test_qdrant_service.log`

### Terminal Steps

1. Start Qdrant only:

```bash
cd /workspaces/dcker_mcp_setup/services
docker compose up -d qdrant-db
```

2. Confirm Qdrant is running:

```bash
docker ps --filter "name=qdrant-db"
```

3. Validate Qdrant API reachability on port `6333`:

```bash
curl http://localhost:6333/healthz
```

`6333` is the HTTP API port mapped by compose (`"6333:6333"`), so `localhost:6333` from the dev container terminal reaches Qdrant.

4. Run tests directly:

```bash
cd /workspaces/dcker_mcp_setup
QDRANT_HOST=localhost pytest tests/ -v
```

> Note: `pytest tests/ -v` discovers and runs all matching test files and test cases under the `tests/` folder, not just one file.
>
> Pytest discovery rules (default):
> - Test files: `test_*.py` or `*_test.py`
> - Test functions: `test_*`
> - Test classes: `Test*` (class name starts with `Test`)

`QDRANT_HOST=localhost` is intentional for terminal-based runs via the mapped host port.

Or use the project test script:

```bash
/workspaces/dcker_mcp_setup/tests/test_qdrant_service.sh
```

The script starts `qdrant-db`, checks the health endpoint, runs pytest, and writes all output to `tests/test_qdrant_service.log`.

### Future Improvement

If you add a custom Dockerfile for `main_starter_service` and bake dependencies into the image at build time, then running tests via `docker exec` becomes more predictable and startup is faster.
