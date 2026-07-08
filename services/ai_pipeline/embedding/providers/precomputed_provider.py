from __future__ import annotations
"""Embedding provider backed by a precomputed Hugging Face dataset."""

from typing import Iterable

from services.ai_pipeline.embedding.providers.base import EmbeddingProvider, EmbeddingProviderError


class PrecomputedDatasetEmbeddingProvider(EmbeddingProvider):
    """Loads dataset rows and serves vectors by normalized text lookup."""

    _TEXT_KEYS = ("text", "content", "document", "body", "article")
    _VECTOR_KEYS = ("embedding", "vector", "embeddings")

    def __init__(
        self,
        model: str,
        expected_dimensions: int,
        dataset_name: str,
        split: str = "train",
        cache_dir: str | None = None,
    ) -> None:
        self.model = model
        self.expected_dimensions = expected_dimensions
        self.dataset_name = dataset_name
        self.split = split
        self.cache_dir = cache_dir
        self._vector_by_text: dict[str, list[float]] = {}
        self._load_dataset_index()

    def _load_dataset_index(self) -> None:
        try:
            from datasets import load_dataset

            dataset = load_dataset(
                path=self.dataset_name,
                split=self.split,
                cache_dir=self.cache_dir,
            )
        except Exception as exc:
            raise EmbeddingProviderError(
                "Failed to load precomputed embedding dataset. "
                "Install 'datasets' and verify HF_DATASET_NAME/HF_DATASET_SPLIT."
            ) from exc

        loaded = 0
        for row in dataset:  # type: ignore[assignment]
            text = self._extract_text(row)
            vector = self._extract_vector(row)
            if not text or vector is None:
                continue
            if len(vector) != self.expected_dimensions:
                continue
            key = self._normalize_text(text)
            self._vector_by_text[key] = vector
            loaded += 1

        if loaded == 0:
            raise EmbeddingProviderError(
                "No valid precomputed embeddings were loaded from dataset. "
                "Check dataset schema and configured dimensions."
            )

    @staticmethod
    def _normalize_text(text: str) -> str:
        return " ".join(text.split()).strip().lower()

    def _extract_text(self, row: dict) -> str | None:
        for key in self._TEXT_KEYS:
            value = row.get(key)
            if isinstance(value, str) and value.strip():
                return value
        return None

    def _extract_vector(self, row: dict) -> list[float] | None:
        vector_raw: Iterable[float] | None = None
        for key in self._VECTOR_KEYS:
            candidate = row.get(key)
            if isinstance(candidate, list):
                vector_raw = candidate
                break
        if vector_raw is None:
            return None
        try:
            return [float(value) for value in vector_raw]
        except (TypeError, ValueError):
            return None

    def embed_text(self, text: str) -> list[float]:
        key = self._normalize_text(text)
        if not key:
            raise EmbeddingProviderError("text cannot be empty")
        vector = self._vector_by_text.get(key)
        if vector is None:
            raise EmbeddingProviderError(
                "Text not found in precomputed dataset index. "
                "Use known dataset text values or switch provider."
            )
        return vector