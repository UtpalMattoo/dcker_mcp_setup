# Project Layout

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
