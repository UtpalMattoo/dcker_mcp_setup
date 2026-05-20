import json
import os
import time
import urllib.parse
import urllib.error
import urllib.request
import uuid
from pathlib import Path

import pytest


ALLOY_STATUS_URL = os.getenv("ALLOY_STATUS_URL", "http://localhost:12345/api/v1/status")
LGTM_HEALTH_URL = os.getenv("LGTM_HEALTH_URL", "http://localhost:3000/api/health")
GRAFANA_URL = os.getenv("GRAFANA_URL", "http://localhost:3000")
GRAFANA_USER = os.getenv("GRAFANA_USER", "admin")
GRAFANA_PASSWORD = os.getenv("GRAFANA_PASSWORD", "admin")
LOKI_DATASOURCE_UID = os.getenv("LOKI_DATASOURCE_UID", "loki-dev")

ROOT = Path(__file__).resolve().parents[3]
FLOW_LOG_PATH = ROOT / "observability" / "runtime-logs" / "main_starter_service" / "flow_test.log"


def _get_json(url: str, timeout: float = 3.0) -> dict:
    request = urllib.request.Request(url, method="GET")
    with urllib.request.urlopen(request, timeout=timeout) as response:
        body = response.read().decode("utf-8")
    return json.loads(body)


def _grafana_loki_query_range(expr: str, start_ns: int, end_ns: int, timeout: float = 5.0) -> dict:
    query = urllib.parse.urlencode(
        {
            "query": expr,
            "start": str(start_ns),
            "end": str(end_ns),
            "limit": "200",
            "direction": "backward",
        }
    )
    url = (
        f"{GRAFANA_URL}/api/datasources/proxy/uid/{LOKI_DATASOURCE_UID}"
        f"/loki/api/v1/query_range?{query}"
    )
    password_mgr = urllib.request.HTTPPasswordMgrWithDefaultRealm()
    password_mgr.add_password(None, GRAFANA_URL, GRAFANA_USER, GRAFANA_PASSWORD)
    auth_handler = urllib.request.HTTPBasicAuthHandler(password_mgr)
    opener = urllib.request.build_opener(auth_handler)
    request = urllib.request.Request(url, method="GET")
    with opener.open(request, timeout=timeout) as response:
        body = response.read().decode("utf-8")
    return json.loads(body)


def _extract_loki_lines(payload: dict) -> list[str]:
    results = payload.get("data", {}).get("result", [])
    lines: list[str] = []
    for stream in results:
        for value in stream.get("values", []):
            if len(value) >= 2:
                lines.append(value[1])
    return lines


@pytest.mark.flow
def test_alloy_status_endpoint() -> None:
    try:
        payload = _get_json(ALLOY_STATUS_URL)
    except (urllib.error.URLError, TimeoutError):
        pytest.skip("Alloy is not reachable. Start observability stack to run flow tests.")

    assert isinstance(payload, dict)
    # Alloy status payload shape can vary by version; keep contract minimal and stable.
    assert len(payload) > 0


@pytest.mark.flow
def test_lgtm_grafana_health_endpoint() -> None:
    try:
        payload = _get_json(LGTM_HEALTH_URL)
    except (urllib.error.URLError, TimeoutError):
        pytest.skip("LGTM is not reachable. Start observability stack to run flow tests.")

    assert isinstance(payload, dict)
    assert payload.get("database") == "ok"


@pytest.mark.flow
def test_runtime_log_reaches_loki_via_alloy() -> None:
    try:
        _get_json(ALLOY_STATUS_URL)
        _get_json(LGTM_HEALTH_URL)
    except (urllib.error.URLError, TimeoutError):
        pytest.skip("Alloy or LGTM is not reachable. Start observability stack to run flow tests.")

    token = f"flow-token-{uuid.uuid4()}"
    FLOW_LOG_PATH.parent.mkdir(parents=True, exist_ok=True)
    with FLOW_LOG_PATH.open("a", encoding="utf-8") as handle:
        handle.write(f"INFO observability flow ingestion check {token}\n")

    # Poll Loki via Grafana proxy to allow for file tailing and pipeline propagation.
    start_ns = int((time.time() - 60) * 1_000_000_000)
    deadline = time.time() + 35
    saw_token = False
    last_error = None

    while time.time() < deadline:
        end_ns = int(time.time() * 1_000_000_000)
        expr = f'{{service="application"}} |= "{token}"'
        try:
            payload = _grafana_loki_query_range(expr, start_ns=start_ns, end_ns=end_ns)
            lines = _extract_loki_lines(payload)
            if any(token in line for line in lines):
                saw_token = True
                break
        except urllib.error.URLError as exc:
            last_error = str(exc)
            break
        except urllib.error.HTTPError as exc:
            last_error = f"HTTP {exc.code}"
            break

        time.sleep(2)

    if last_error is not None:
        pytest.skip(
            "Grafana/Loki query API not reachable with current config. "
            "Ensure stack is running and credentials are set via GRAFANA_USER/GRAFANA_PASSWORD. "
            f"Last error: {last_error}"
        )

    assert saw_token, "Synthetic runtime log did not appear in Loki through Alloy within timeout"
