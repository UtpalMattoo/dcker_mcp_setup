"""Compatibility entry point for embedding service.

Why this exists: keep existing imports stable while core code runs from
services.ai_pipeline.embedding.service.
"""

from services.ai_pipeline.embedding.service import (
    EmbeddingService,
    build_provider,
    register_provider,
)

__all__ = ["EmbeddingService", "build_provider", "register_provider"]
