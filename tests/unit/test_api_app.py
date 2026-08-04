from __future__ import annotations

from types import SimpleNamespace

from fastapi.testclient import TestClient

import services.api.app as api_app


client = TestClient(api_app.app)


def test_get_providers_returns_catalog():
    response = client.get("/providers")
    assert response.status_code == 200
    payload = response.json()
    assert "providers" in payload
    assert "precomputed" in payload["providers"]


def test_validate_reports_missing_openai_key(monkeypatch):
    monkeypatch.delenv("OPENAI_API_KEY", raising=False)
    response = client.post(
        "/validate",
        json={"provider": "openai", "model": "text-embedding-3-small", "dimensions": 1536},
    )
    assert response.status_code == 200
    payload = response.json()
    assert payload["status"] == "error"
    assert "OPENAI_API_KEY" in payload["missing_keys"]


def test_ingest_uses_existing_services_with_monkeypatched_dependencies(monkeypatch):
    class FakeEmbeddingService:
        def __init__(self, config):
            self.config = config

        def embed_text(self, text):
            assert text == "hello"
            return [0.1] * 384

    class FakeQdrant:
        def __init__(self, host, port, collection, dim):
            self.collection = collection

        def upsert(self, vector, payload, point_id):
            assert len(vector) == 384
            assert payload["source"] == "unit"

    monkeypatch.setattr(api_app, "EmbeddingService", FakeEmbeddingService)
    monkeypatch.setattr(api_app, "QdrantHelper", FakeQdrant)

    response = client.post(
        "/ingest",
        json={
            "text": "hello",
            "payload": {"source": "unit"},
            "point_id": 123,
            "provider": "sentence_transformers",
            "model": "all-MiniLM-L6-v2",
            "collection": "embeddings_384",
        },
    )
    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "success"
    assert body["vector_id"] == 123


def test_search_returns_hits(monkeypatch):
    class FakeEmbeddingService:
        def __init__(self, config):
            self.config = config

        def embed_text(self, text):
            return [0.1] * 384

    class FakeQdrant:
        def __init__(self, host, port, collection, dim):
            self.collection = collection

        def search(self, query_vector, limit):
            return [SimpleNamespace(id=1, score=0.99, payload={"text": "match"})]

    monkeypatch.setattr(api_app, "EmbeddingService", FakeEmbeddingService)
    monkeypatch.setattr(api_app, "QdrantHelper", FakeQdrant)

    response = client.post(
        "/search",
        json={
            "query": "find",
            "top_k": 5,
            "provider": "sentence_transformers",
            "model": "all-MiniLM-L6-v2",
            "collection": "embeddings_384",
        },
    )
    assert response.status_code == 200
    data = response.json()
    assert data["items"][0]["id"] == 1


def test_precomputed_ingest_endpoint_uses_runner(monkeypatch):
    class FakeQdrant:
        def __init__(self, host, port, collection, dim):
            self.collection = collection

    class FakeResult:
        def to_dict(self):
            return {
                "inserted": 10,
                "scanned": 10,
                "skipped": 0,
                "collection": "embeddings_1536",
                "dimensions": 1536,
                "dataset_name": "Qdrant/dbpedia-entities-openai3-text-embedding-3-small-1536-100K",
                "split": "train",
                "dry_run": False,
                "first_point_id": 100000,
                "last_point_id": 100009,
            }

    monkeypatch.setattr(api_app, "QdrantHelper", FakeQdrant)
    monkeypatch.setattr(api_app, "ingest_precomputed_dataset", lambda **kwargs: FakeResult())

    response = client.post(
        "/ingest/precomputed",
        json={
            "model": "Qdrant/dbpedia-entities-openai3-text-embedding-3-small-1536-100K",
            "dataset_name": "Qdrant/dbpedia-entities-openai3-text-embedding-3-small-1536-100K",
            "split": "train",
            "limit": 10,
            "dry_run": False,
            "start_id": 100000,
            "collection": "embeddings_1536",
        },
    )
    assert response.status_code == 200
    payload = response.json()
    assert payload["status"] == "success"
    assert payload["inserted"] == 10
