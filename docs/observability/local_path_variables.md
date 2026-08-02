# Local Path Variables

Use this file as a quick reference for host log paths.
These variables are optional.
Set them when you want Alloy to read local machine logs.

## Variables

- VSCODE_LOGS_DIR
- COPILOT_EXTENSION_LOGS_DIR
- QDRANT_HOST_LOGS_DIR

## Typical Windows defaults

- VSCODE_LOGS_DIR: %APPDATA%/Code/logs
- COPILOT_EXTENSION_LOGS_DIR: %APPDATA%/Code/User/globalStorage/GitHub.copilot
- QDRANT_HOST_LOGS_DIR: %APPDATA%/Qdrant/logs

## Notes

- These paths are mounted read-only into Alloy.
- If not set, compose uses built-in defaults.
- Copilot logs can be nested by workspace.
- Host Qdrant logs appear only if Qdrant writes to that folder.

## Startup reminder

Use startup-test/startup-and-test.sh to run startup checks.
For the full run/verify checklist, use telemetry_contracts.md.
