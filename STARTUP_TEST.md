# Startup Test Entry Point

Use the startup-test folder for canonical startup order, test execution, and teardown.

- Full ordered startup and tests: [startup-test/startup-and-test.sh](startup-test/startup-and-test.sh)
- Fast contracts-only checks: [startup-test/startup-and-test-lite.sh](startup-test/startup-and-test-lite.sh)
- Teardown helper: [startup-test/cleanup.sh](startup-test/cleanup.sh)
- Runbook and rationale: [startup-test/README.md](startup-test/README.md)

From repository root:

```bash
bash startup-test/startup-and-test.sh
```