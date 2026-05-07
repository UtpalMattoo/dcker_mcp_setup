# MicroVM AI Agent Dev Container Build Steps

This document captures exactly what is being built in the `.devcontainer` folder and how to use it.

## Table of Contents

1. [Folder Layout](#1-folder-layout)
2. [Dev Container Configuration](#2-dev-container-configuration)
3. [Post-Create Setup Actions](#3-post-create-setup-actions)
4. [Google Cloud Support](#4-google-cloud-support)
5. [Why This Is MicroVM-Optimized](#5-why-this-is-microvm-optimized)
6. [Isolation Model for MCP Servers](#6-isolation-model-for-mcp-servers)
7. [How to Use in VS Code](#7-how-to-use-in-vs-code)
8. [Reproducibility Notes](#8-reproducibility-notes)
9. [Testing the Qdrant Service](#9-testing-the-qdrant-service)

## 1. Folder Layout

Expected files:

- `.devcontainer/devcontainer.json`
- `.devcontainer/requirements.txt`
- `.devcontainer/setup.sh`
- `MICROVM_DEVCONTAINER_STEPS.md`
- `services/docker-compose.yml`
- `tests/test_qdrant_service.py`
- `tests/test_qdrant_service.sh`

Project layout:

```text
dcker_mcp_setup/
|-- .devcontainer/
|   |-- devcontainer-lock.json
|   |-- devcontainer.json
|   |-- requirements.txt
|   `-- setup.sh
|-- .gitignore
|-- .vscode/
|   `-- settings.json
|-- MICROVM_DEVCONTAINER_STEPS.md
|-- services/
|   |-- docker-compose.yml
|   |-- main_starter_service/
|   |   |-- main_server.py
|   |   `-- requirements.txt
|   |-- qdrant/
|   |   |-- __init__.py
|   |   `-- qdrant_service.py
|   `-- second-service-custom-mcp-work/
|       `-- python_custom_server.py
`-- tests/
   |-- test_qdrant_service.log
   |-- test_qdrant_service.py
   `-- test_qdrant_service.sh
```


## 2. Dev Container Configuration

### Note on Dockerfile

This setup does not require a custom Dockerfile. The dev container uses a pre-existing image (e.g., python:3.12) specified in devcontainer.json. All configuration is handled via devcontainer.json, so a Dockerfile is unnecessary unless further customization is needed.

Additional setup steps are performed by setup.sh and other scripts referenced in devcontainer.json or this documentation. These scripts build on top of the pre-existing image to install required tools and dependencies.

The `devcontainer.json` is configured to:

- Use official upstream Python image: `python:3.12`
- Install Node.js 20 inside the container
- Install Google Cloud CLI inside the container
- Install build tools needed for Python and Node package compilation
- Enable rootless Docker-in-Docker so Docker CLI usage works inside the Dev Container without depending on the host Docker socket by default
- Forward common debugging ports: `3000`, `5000`, `8000`, `8080`
- Join the `mcp-net` Docker network via `runArgs`
- Run `.devcontainer/setup.sh` after container creation

## 3. Post-Create Setup Actions

On first container creation, `.devcontainer/setup.sh` runs automatically via `postCreateCommand`. This script performs the following steps:

1. `apt-get update`
2. `apt-get install -y curl git gnupg ca-certificates apt-transport-https build-essential pkg-config`
3. `curl -fsSL https://deb.nodesource.com/setup_20.x | bash -` (NodeJS setup)
4. Add the Google Cloud SDK apt repository and signing key
5. `apt-get update`
6. `apt-get install -y nodejs google-cloud-cli`
7. `pip install --upgrade pip`
8. `if [ -f .devcontainer/requirements.txt ]; then pip install -r .devcontainer/requirements.txt; fi`
9. Create the external Docker network `mcp-net` (if it does not already exist)
   - This network is required by `docker-compose.yml` for inter-container communication

## 4. Google Cloud Support

The environment now includes:

- `google-cloud-cli` for `gcloud`, `gsutil`, and ADC login flows
- Python client libraries for common services:
   - Cloud Storage
   - Secret Manager
   - BigQuery
   - Vertex AI
- Google authentication library support for Application Default Credentials

Typical auth flow inside the container:

```bash
gcloud auth login
gcloud auth application-default login
```

## 5. Why This Is MicroVM-Optimized

- Runs inside WSL2 microVM for strong isolation
- Enables Docker access from inside Dev Container using rootless Docker-in-Docker
- Keeps Python base image pure (`python:3.12`)
- Adds Node only inside Dev Container (not on host)
- Includes native build tooling to avoid missing compiler errors
- Supports isolated MCP runtime model

## 6. Isolation Model for MCP Servers

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

- `qdrant-db` - pre-built Qdrant vector database service
- `main_starter_service` - startup container for installing Python dependencies used by the main orchestrator work
- `second-service-custom-mcp-work` - placeholder custom MCP service container

## 7. How to Use in VS Code

1. Open the project in VS Code.
2. Run: **Dev Containers: Rebuild and Reopen in Container**.
3. Wait for post-create steps to complete.
4. Confirm toolchain:
   - `python --version`
   - `node --version`
   - `docker --version`
   - `gcloud --version`

Workspace note:

- In this environment the project is mounted at `/workspaces/dcker_mcp_setup`.

## 8. Reproducibility Notes

- Keep all Python packages pinned in `requirements.txt`.
- Keep all tooling setup in `postCreateCommand`.
- Avoid manual ad-hoc installs to maintain reproducible rebuilds.

## 9. Testing the Qdrant Service

### Why We Run These Tests from the Dev Container Terminal

There are two deliberate design decisions behind the current workflow:

1. Python dependencies installed by `docker compose` in `main_starter_service` do not persist reliably across container recreation.
   - The service currently starts from `python:3.12` and runs `pip install -r requirements.txt` at runtime.
   - Those runtime-installed packages live in the container writable layer, so a recreated container starts fresh and must install again.

2. We do not run `pytest` as part of `main_starter_service` startup.
   - `pytest` is a one-shot process, not a long-running server.
   - Running it in startup command makes the container exit right after tests, which can cause restart-loop behavior depending on restart policy.

Because of this, the simplest and most stable approach is to run tests directly from the dev container terminal.

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

`QDRANT_HOST=localhost` is intentional for terminal-based runs via the mapped host port.

Or use the project test script:

```bash
/workspaces/dcker_mcp_setup/tests/test_qdrant_service.sh
```

The script starts `qdrant-db`, checks the health endpoint, runs pytest, and writes all output to `tests/test_qdrant_service.log`.

### Future Improvement

If you add a custom Dockerfile for `main_starter_service` and bake dependencies into the image at build time, then running tests via `docker exec` becomes more predictable and startup is faster.
