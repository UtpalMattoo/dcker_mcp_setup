from __future__ import annotations

from datetime import datetime
from typing import Any

from pydantic import BaseModel, Field


class ProvidersResponse(BaseModel):
    providers: dict[str, dict[str, int]]


class ValidateRequest(BaseModel):
    provider: str
    model: str
    dimensions: int | None = None


class ValidateResponse(BaseModel):
    status: str
    message: str
    missing_keys: list[str] = Field(default_factory=list)


class IngestRequest(BaseModel):
    text: str
    payload: dict[str, Any] = Field(default_factory=dict)
    point_id: int | str | None = None
    provider: str
    model: str
    collection: str | None = None


class IngestResponse(BaseModel):
    vector_id: int | str
    dimensions: int
    status: str
    collection: str


class SearchRequest(BaseModel):
    query: str
    top_k: int = 5
    provider: str
    model: str
    collection: str | None = None


class SearchItem(BaseModel):
    id: int | str
    score: float
    payload: dict[str, Any] | None = None


class SearchResponse(BaseModel):
    collection: str
    items: list[SearchItem]


class DeleteResponse(BaseModel):
    deleted: bool
    id: int | str
    collection: str


class StatsResponse(BaseModel):
    collection: str
    vector_size: int
    points_count: int | None
    indexed_vectors_count: int | None
    status: str


class HealthResponse(BaseModel):
    status: str
    timestamp: datetime


class DependencyHealthResponse(BaseModel):
    status: str
    url: str | None = None
    latency_ms: float | None = None
    message: str | None = None


class PrecomputedIngestRequest(BaseModel):
    model: str = "Qdrant/dbpedia-entities-openai3-text-embedding-3-small-1536-100K"
    dataset_name: str = "Qdrant/dbpedia-entities-openai3-text-embedding-3-small-1536-100K"
    split: str = "train"
    limit: int = 10
    dry_run: bool = False
    streaming: bool = True
    start_id: int = 100000
    collection: str | None = None


class PrecomputedIngestResponse(BaseModel):
    status: str
    inserted: int
    scanned: int
    skipped: int
    collection: str
    dimensions: int
    dataset_name: str
    split: str
    dry_run: bool
    first_point_id: int | None
    last_point_id: int | None
