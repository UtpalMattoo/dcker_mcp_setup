from __future__ import annotations
"""Phase 1 embedding service and provider selection logic.

This module builds exactly one provider from config and enforces vector
dimension checks before data is passed to ingestion/Qdrant.
"""

from typing import Callable, Dict

from services.config import ConfigError, EmbeddingConfig, load_embedding_config
from services.ai_pipeline.embedding.providers.base import EmbeddingProvider
from services.ai_pipeline.embedding.providers.openai_provider import OpenAIEmbeddingProvider
from services.ai_pipeline.embedding.providers.sentence_transformers_provider import (
    SentenceTransformersEmbeddingProvider,
)

ProviderBuilder = Callable[[EmbeddingConfig], EmbeddingProvider]


def _build_openai_provider(config: EmbeddingConfig) -> EmbeddingProvider:
    """Build OpenAI provider from validated config."""
    if not config.openai_api_key:
        raise ValueError("OPENAI_API_KEY is required for openai provider")
    return OpenAIEmbeddingProvider(model=config.model, api_key=config.openai_api_key)


def _build_sentence_provider(config: EmbeddingConfig) -> EmbeddingProvider:
    """Build local sentence-transformers provider from validated config."""
    return SentenceTransformersEmbeddingProvider(model=config.model, cache_dir=config.hf_cache_dir)


_PROVIDER_REGISTRY: Dict[str, ProviderBuilder] = {
    "openai": _build_openai_provider,
    "sentence_transformers": _build_sentence_provider,
}
_PROVIDER_REGISTRY_LOCKED = False


def register_provider(name: str, builder: ProviderBuilder) -> None:
    """Register a provider builder during startup only.

    Why this guard exists: avoid runtime mutation of global registry state.
    """
    global _PROVIDER_REGISTRY_LOCKED
    if _PROVIDER_REGISTRY_LOCKED:
        raise RuntimeError("Provider registration is only allowed during startup")
    _PROVIDER_REGISTRY[name.strip().lower()] = builder


def reset_provider_registry() -> None:
    """Reset registry to defaults. Intended for tests only."""
    global _PROVIDER_REGISTRY_LOCKED
    _PROVIDER_REGISTRY.clear()
    _PROVIDER_REGISTRY.update(
        {
            "openai": _build_openai_provider,
            "sentence_transformers": _build_sentence_provider,
        }
    )
    _PROVIDER_REGISTRY_LOCKED = False


def build_provider(config: EmbeddingConfig) -> EmbeddingProvider:
    """Resolve provider key from config and return provider instance."""
    provider_key = config.provider.strip().lower()
    if provider_key not in _PROVIDER_REGISTRY:
        supported = ", ".join(sorted(_PROVIDER_REGISTRY))
        raise ConfigError(f"Unsupported embedding provider: {provider_key}. Supported: {supported}")
    return _PROVIDER_REGISTRY[provider_key](config)


class EmbeddingService:
    """Small facade used by ingestion code.

    It hides provider-specific details and guarantees vector-size validation.
    """
    def __init__(
        self,
        config: EmbeddingConfig | None = None,
        provider: EmbeddingProvider | None = None,
    ) -> None:
        global _PROVIDER_REGISTRY_LOCKED
        self.config = config or load_embedding_config()
        self.provider = provider or build_provider(self.config)
        _PROVIDER_REGISTRY_LOCKED = True

    def embed_text(self, text: str) -> list[float]:
        """Embed one text value and enforce configured output dimensions."""
        if not text or not text.strip():
            raise ValueError("text cannot be empty")
        vector = self.provider.embed_text(text.strip())
        if len(vector) != self.config.dimensions:
            raise ValueError(
                f"Embedding dimension mismatch. Expected {self.config.dimensions}, got {len(vector)}"
            )
        return vector
