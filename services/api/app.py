from __future__ import annotations

import os
import time
from contextlib import contextmanager
from datetime import datetime, timezone
from uuid import uuid4

import requests
from fastapi import FastAPI, HTTPException, Query

from services.ai_pipeline.embedding.service import EmbeddingService
from services.ai_pipeline.ingestion.precomputed_ingest import ingest_precomputed_dataset
from services.ai_pipeline.ingestion.service import IngestionService
from services.api.schemas import (
    DeleteResponse,
    DependencyHealthResponse,
    HealthResponse,
    IngestRequest,
    IngestResponse,
    PrecomputedIngestRequest,
    PrecomputedIngestResponse,
    ProvidersResponse,
    SearchItem,
    SearchRequest,
    SearchResponse,
    StatsResponse,
    ValidateRequest,
    ValidateResponse,
)
from services.config import (
    ConfigError,
    EmbeddingConfig,
    PROVIDER_MODEL_DIMENSIONS,
    load_embedding_config,
)
from services.qdrant.qdrant_service import QdrantHelper

app = FastAPI(title="Embedding + Qdrant API", version="0.1.0")


@contextmanager
def _temporary_env(overrides: dict[str, str | None]):
    previous = {key: os.environ.get(key) for key in overrides}
    try:
        for key, value in overrides.items():
            if value is None:
                os.environ.pop(key, None)
            else:
                os.environ[key] = value
        yield
    finally:
        for key, value in previous.items():
            if value is None:
                os.environ.pop(key, None)
            else:
                os.environ[key] = value


def _resolve_dimensions(provider: str, model: str) -> int:
    provider_key = provider.strip().lower()
    try:
        return PROVIDER_MODEL_DIMENSIONS[provider_key][model]
    except KeyError as exc:
        raise ConfigError(
            f"Unsupported model '{model}' for provider '{provider_key}'"
        ) from exc


def _build_embedding_config(provider: str, model: str) -> EmbeddingConfig:
    provider_key = provider.strip().lower()
    dimensions = _resolve_dimensions(provider_key, model)
    openai_api_key = os.getenv("OPENAI_API_KEY")
    if provider_key == "openai" and not openai_api_key:
        raise ConfigError("OPENAI_API_KEY is required when EMBEDDING_PROVIDER=openai")

    return EmbeddingConfig(
        provider=provider_key,
        model=model,
        dimensions=dimensions,
        openai_api_key=openai_api_key,
        hf_cache_dir=os.getenv("HF_HOME", "/cache/huggingface"),
        hf_dataset_name=os.getenv("HF_DATASET_NAME", "Qdrant/dbpedia-entities-openai3-text-embedding-3-small-1536-100K"),
        hf_dataset_split=os.getenv("HF_DATASET_SPLIT", "train"),
    )


def _default_collection(dimensions: int) -> str:
    return os.getenv("QDRANT_COLLECTION", f"embeddings_{dimensions}")


def _build_qdrant(collection: str, dimensions: int) -> QdrantHelper:
    return QdrantHelper(
        host=os.getenv("QDRANT_HOST", "localhost"),
        port=int(os.getenv("QDRANT_PORT", "6333")),
        collection=collection,
        dim=dimensions,
    )


@app.get("/providers", response_model=ProvidersResponse)
def get_providers() -> ProvidersResponse:
    return ProvidersResponse(providers=PROVIDER_MODEL_DIMENSIONS)


@app.post("/validate", response_model=ValidateResponse)
def validate_config(payload: ValidateRequest) -> ValidateResponse:
    provider = payload.provider.strip().lower()
    missing_keys: list[str] = []

    if provider == "openai" and not os.getenv("OPENAI_API_KEY"):
        missing_keys.append("OPENAI_API_KEY")

    env_overrides = {
        "EMBEDDING_PROVIDER": provider,
        "EMBEDDING_MODEL": payload.model,
        "EMBEDDING_DIMENSIONS": str(payload.dimensions) if payload.dimensions else None,
    }

    try:
        with _temporary_env(env_overrides):
            load_embedding_config(validate_runtime=True)
    except ConfigError as exc:
        return ValidateResponse(
            status="error",
            message=str(exc),
            missing_keys=missing_keys,
        )

    return ValidateResponse(status="ok", message="Configuration is valid", missing_keys=missing_keys)


@app.post("/ingest", response_model=IngestResponse)
def ingest_text(payload: IngestRequest) -> IngestResponse:
    try:
        config = _build_embedding_config(payload.provider, payload.model)
        collection = payload.collection or _default_collection(config.dimensions)
        qdrant = _build_qdrant(collection=collection, dimensions=config.dimensions)
        ingestion = IngestionService(
            embedding_service=EmbeddingService(config=config),
            qdrant_service=qdrant,
        )

        point_id = payload.point_id if payload.point_id is not None else str(uuid4())
        result = ingestion.ingest_text(payload.text, payload.payload, point_id)
        return IngestResponse(
            vector_id=result.point_id,
            dimensions=result.dimensions,
            status="success",
            collection=collection,
        )
    except (ConfigError, ValueError) as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"Ingestion failed: {exc}") from exc


@app.post("/search", response_model=SearchResponse)
def search_vectors(payload: SearchRequest) -> SearchResponse:
    try:
        config = _build_embedding_config(payload.provider, payload.model)
        collection = payload.collection or _default_collection(config.dimensions)
        qdrant = _build_qdrant(collection=collection, dimensions=config.dimensions)
        embedder = EmbeddingService(config=config)
        query_vector = embedder.embed_text(payload.query)
        hits = qdrant.search(query_vector=query_vector, limit=payload.top_k)

        return SearchResponse(
            collection=collection,
            items=[
                SearchItem(
                    id=hit.id,
                    score=float(hit.score),
                    payload=hit.payload,
                )
                for hit in hits
            ],
        )
    except (ConfigError, ValueError) as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"Search failed: {exc}") from exc


@app.delete("/vectors/{vector_id}", response_model=DeleteResponse)
def delete_vector(
    vector_id: str,
    collection: str = Query(default=os.getenv("QDRANT_COLLECTION", "embeddings_384")),
    dimensions: int = Query(default=384),
) -> DeleteResponse:
    try:
        qdrant = _build_qdrant(collection=collection, dimensions=dimensions)
        parsed_id: int | str = int(vector_id) if vector_id.isdigit() else vector_id
        qdrant.delete_document(parsed_id)
        return DeleteResponse(deleted=True, id=parsed_id, collection=collection)
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"Delete failed: {exc}") from exc


@app.get("/stats", response_model=StatsResponse)
def collection_stats(
    collection: str = Query(default=os.getenv("QDRANT_COLLECTION", "embeddings_384")),
    dimensions: int = Query(default=384),
) -> StatsResponse:
    try:
        qdrant = _build_qdrant(collection=collection, dimensions=dimensions)
        stats = qdrant.collection_stats()
        return StatsResponse(**stats)
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"Stats failed: {exc}") from exc


@app.get("/health", response_model=HealthResponse)
def app_health() -> HealthResponse:
    return HealthResponse(status="healthy", timestamp=datetime.now(timezone.utc))


@app.get("/health/qdrant", response_model=DependencyHealthResponse)
def qdrant_health() -> DependencyHealthResponse:
    started = time.perf_counter()
    try:
        qdrant = _build_qdrant(collection=os.getenv("QDRANT_COLLECTION", "embeddings_384"), dimensions=384)
        qdrant.client.get_collections()
        latency_ms = round((time.perf_counter() - started) * 1000, 3)
        return DependencyHealthResponse(status="healthy", latency_ms=latency_ms)
    except Exception as exc:
        return DependencyHealthResponse(status="unhealthy", message=str(exc))


def _http_health(url: str) -> DependencyHealthResponse:
    started = time.perf_counter()
    try:
        response = requests.get(url, timeout=5)
        latency_ms = round((time.perf_counter() - started) * 1000, 3)
        if response.ok:
            return DependencyHealthResponse(status="healthy", url=url, latency_ms=latency_ms)
        return DependencyHealthResponse(
            status="unhealthy",
            url=url,
            latency_ms=latency_ms,
            message=f"HTTP {response.status_code}",
        )
    except Exception as exc:
        return DependencyHealthResponse(status="unhealthy", url=url, message=str(exc))


@app.get("/health/grafana", response_model=DependencyHealthResponse)
def grafana_health() -> DependencyHealthResponse:
    return _http_health(os.getenv("GRAFANA_HEALTH_URL", "http://localhost:3000/api/health"))


@app.get("/health/alloy", response_model=DependencyHealthResponse)
def alloy_health() -> DependencyHealthResponse:
    return _http_health(os.getenv("ALLOY_STATUS_URL", "http://localhost:12345/-/ready"))


@app.post("/ingest/precomputed", response_model=PrecomputedIngestResponse)
def ingest_precomputed(payload: PrecomputedIngestRequest) -> PrecomputedIngestResponse:
    provider_key = "precomputed"
    if payload.model not in PROVIDER_MODEL_DIMENSIONS[provider_key]:
        supported = ", ".join(sorted(PROVIDER_MODEL_DIMENSIONS[provider_key]))
        raise HTTPException(
            status_code=422,
            detail=f"Unsupported precomputed model '{payload.model}'. Supported: {supported}",
        )

    dimensions = PROVIDER_MODEL_DIMENSIONS[provider_key][payload.model]
    collection = payload.collection or _default_collection(dimensions)

    try:
        qdrant = _build_qdrant(collection=collection, dimensions=dimensions)
        result = ingest_precomputed_dataset(
            qdrant_service=qdrant,
            dataset_name=payload.dataset_name,
            split=payload.split,
            expected_dimensions=dimensions,
            limit=payload.limit,
            dry_run=payload.dry_run,
            start_id=payload.start_id,
            model_key=payload.model,
            streaming=payload.streaming,
        )
        return PrecomputedIngestResponse(status="success", **result.to_dict())
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"Precomputed ingestion failed: {exc}") from exc
