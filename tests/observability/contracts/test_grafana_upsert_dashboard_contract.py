from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
DASHBOARD_PATH = (
    ROOT
    / "observability"
    / "grafana"
    / "provisioning"
    / "dashboards"
    / "development"
    / "qdrant-upsert-observability.json"
)


def _dashboard_text() -> str:
    return DASHBOARD_PATH.read_text(encoding="utf-8")


def test_upsert_dashboard_exists() -> None:
    assert DASHBOARD_PATH.exists()


def test_upsert_dashboard_has_required_panels() -> None:
    text = _dashboard_text()
    assert '"title": "Qdrant Upsert Observability"' in text
    assert '"title": "Upserts (success, selected range)"' in text
    assert '"title": "Upserts / minute"' in text
    assert '"title": "Upsert errors / minute"' in text
    assert '"title": "Upsert latency p95 (ms)"' in text
    assert '"title": "Upsert latency avg (ms)"' in text
    assert '"title": "Recent upsert events"' in text


def test_upsert_dashboard_queries_use_structured_upsert_signal() -> None:
    text = _dashboard_text()
    assert "qdrant_upsert_event" in text
    assert "upsert_latency_ms" in text
    assert "upsert_status" in text
