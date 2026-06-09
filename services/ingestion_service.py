"""Compatibility entry point for ingestion service.

Why this exists: preserve old import paths while active implementation lives
in services.ai_pipeline.ingestion.service.
"""

from services.ai_pipeline.ingestion.service import IngestionResult, IngestionService

__all__ = ["IngestionResult", "IngestionService"]
