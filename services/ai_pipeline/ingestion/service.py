from __future__ import annotations
"""Phase 1 ingestion orchestration.

Why this exists: keep ingestion flow thin and predictable by only coordinating
embedding generation and Qdrant write operations.
"""

from dataclasses import dataclass

from services.ai_pipeline.embedding.service import EmbeddingService
from services.qdrant.qdrant_service import QdrantHelper


@dataclass
class IngestionResult:
    """Small response model returned after one ingestion call."""
    point_id: int | str
    dimensions: int


class IngestionService:
    """Phase 1 thin orchestration layer for embed + upsert."""

    def __init__(self, embedding_service: EmbeddingService, qdrant_service: QdrantHelper) -> None:
        self.embedding_service = embedding_service
        self.qdrant_service = qdrant_service

    def ingest_text(self, text: str, payload: dict, point_id: int | str) -> IngestionResult:
        """Create vector from text and store it in Qdrant."""
        vector = self.embedding_service.embed_text(text)
        self.qdrant_service.upsert(vector=vector, payload=payload, point_id=point_id)
        return IngestionResult(point_id=point_id, dimensions=len(vector))
