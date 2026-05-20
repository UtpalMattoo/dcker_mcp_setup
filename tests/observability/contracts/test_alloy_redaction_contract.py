from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
ALLOY_CONFIG_DIR = ROOT / "observability" / "alloy" / "config"


def _read(name: str) -> str:
    return (ALLOY_CONFIG_DIR / name).read_text(encoding="utf-8")


def test_docker_logs_have_redaction_stages() -> None:
    text = _read("logs-docker.river")
    assert "loki.process \"app_redaction\"" in text
    assert "stage.regex" in text
    assert "<REDACTED_API_KEY>" in text
    assert "<REDACTED_DB_PASSWORD>" in text
    assert "<REDACTED_TOKEN>" in text
    assert "<PATH_REDACTED>" in text


def test_vscode_logs_have_path_redaction() -> None:
    text = _read("logs-vscode.river")
    assert "loki.process \"vscode_redaction\"" in text
    assert "stage.regex" in text
    assert "<PATH_REDACTED>" in text


def test_copilot_logs_have_high_sensitivity_redaction() -> None:
    text = _read("logs-copilot.river")
    assert "loki.process \"copilot_redaction\"" in text
    assert "<REDACTED_OPENAI_KEY>" in text
    assert "<REDACTED_GITHUB_TOKEN>" in text
    assert "<REDACTED_TOKEN>" in text
    assert "<REDACTED_SESSION>" in text
    assert "sensitivity = \"high\"" in text


def test_root_alloy_imports_log_modules() -> None:
    text = _read("alloy.river")
    assert "filename = \"/etc/alloy/logs-vscode.river\"" in text
    assert "filename = \"/etc/alloy/logs-copilot.river\"" in text
    assert "filename = \"/etc/alloy/logs-docker.river\"" in text
