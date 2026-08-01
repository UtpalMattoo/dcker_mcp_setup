from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
COMPOSE_PATH = ROOT / "observability" / "docker-compose.observability.yml"
PROVIDERS_PATH = (
    ROOT
    / "observability"
    / "grafana"
    / "provisioning"
    / "dashboards"
    / "dashboards.yml"
)


def test_compose_mounts_dashboards_outside_provisioning_tree() -> None:
    text = COMPOSE_PATH.read_text(encoding="utf-8")
    assert "./grafana/provisioning:/otel-lgtm/grafana/conf/provisioning:ro" in text


def test_dashboard_providers_read_from_runtime_dashboards_path() -> None:
    text = PROVIDERS_PATH.read_text(encoding="utf-8")
    assert "path: /otel-lgtm/grafana/conf/provisioning/dashboards/development" in text
    assert "path: /otel-lgtm/grafana/conf/provisioning/dashboards/restricted" in text
