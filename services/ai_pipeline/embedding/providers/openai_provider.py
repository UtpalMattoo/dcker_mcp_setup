from __future__ import annotations
"""OpenAI embedding adapter for Phase 1.

Why this exists: keep OpenAI-specific SDK calls isolated from the rest of the
pipeline and return normalized errors on failure.
"""

from typing import List

from services.ai_pipeline.embedding.providers.base import EmbeddingProvider, EmbeddingProviderError


class OpenAIEmbeddingProvider(EmbeddingProvider):
    """Provider adapter that calls OpenAI embeddings with basic retries."""
    def __init__(self, model: str, api_key: str, max_retries: int = 3) -> None:
        if max_retries < 1:
            raise ValueError("max_retries must be >= 1")
        from openai import OpenAI

        self.model = model
        self.client = OpenAI(api_key=api_key)
        self.max_retries = max_retries

    def embed_text(self, text: str) -> List[float]:
        """Return embedding vector for text or raise EmbeddingProviderError."""
        last_error: Exception | None = None
        for _ in range(self.max_retries):
            try:
                response = self.client.embeddings.create(model=self.model, input=[text])
                return list(response.data[0].embedding)
            except Exception as exc:  # SDK exceptions vary by version.
                last_error = exc
        raise EmbeddingProviderError(
            f"OpenAI embedding failed after {self.max_retries} attempts"
        ) from last_error
