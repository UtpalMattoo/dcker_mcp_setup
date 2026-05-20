from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
COMPOSE_PATH = ROOT / "observability" / "docker-compose.observability.yml"


def _compose_text() -> str:
    return COMPOSE_PATH.read_text(encoding="utf-8")


def test_compose_declares_lgtm_and_alloy_services() -> None:
    text = _compose_text()
    assert "lgtm:" in text
    assert "alloy:" in text
    assert "image: grafana/otel-lgtm:latest" in text
    assert "image: grafana/alloy:latest" in text


def test_alloy_forwards_to_lgtm() -> None:
    text = _compose_text()
    assert "OTEL_EXPORTER_OTLP_ENDPOINT=http://lgtm:4317" in text


def test_alloy_does_not_mount_docker_socket() -> None:
    text = _compose_text()
    assert "docker.sock" not in text


def test_shared_observability_network_is_external() -> None:
    text = _compose_text()
    assert "networks:" in text
    assert "observability:" in text
    assert "external: true" in text
