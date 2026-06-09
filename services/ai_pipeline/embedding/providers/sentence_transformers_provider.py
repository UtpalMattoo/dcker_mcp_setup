from __future__ import annotations
"""Local sentence-transformers adapter for Phase 1.

Why this exists: keep local-model code isolated so provider switching stays
configuration-driven.
"""

from typing import List

from services.ai_pipeline.embedding.providers.base import EmbeddingProvider, EmbeddingProviderError


class SentenceTransformersEmbeddingProvider(EmbeddingProvider):
    """Provider adapter that loads a local model and returns float vectors."""
    def __init__(self, model: str, cache_dir: str) -> None:
        try:
            from sentence_transformers import SentenceTransformer

            self.model_name = model
            self.model = SentenceTransformer(model_name_or_path=model, cache_folder=cache_dir)
        except Exception as exc:
            raise EmbeddingProviderError("Failed to initialize sentence-transformers provider") from exc

    def embed_text(self, text: str) -> List[float]:
        """Return embedding vector for text or raise EmbeddingProviderError."""
        try:
            vector = self.model.encode(text)
            return [float(value) for value in vector]
        except Exception as exc:
            raise EmbeddingProviderError("Sentence-transformers embedding failed") from exc