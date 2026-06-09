"""Tests for embedding service behavior.

These tests use a stub provider so we can test service logic without making
real model/API calls.
"""

import pytest

from services.ai_pipeline.config import EmbeddingConfig
from services.ai_pipeline.embedding.service import EmbeddingService


class StubProvider:
    def __init__(self, dims):
        self.dims = dims

    def embed_text(self, _text):
        return [0.5] * self.dims


def test_embed_text_success():
    """Service should return vector when provider output matches expected size."""
    config = EmbeddingConfig(provider="sentence_transformers", model="all-MiniLM-L6-v2", dimensions=384)
    service = EmbeddingService(config=config, provider=StubProvider(dims=384))

    vector = service.embed_text("hello")
    assert len(vector) == 384


def test_embed_text_dimension_mismatch_fails():
    """Service should block writes when provider returns wrong vector length."""
    config = EmbeddingConfig(provider="sentence_transformers", model="all-MiniLM-L6-v2", dimensions=384)
    service = EmbeddingService(config=config, provider=StubProvider(dims=10))

    with pytest.raises(ValueError):
        service.embed_text("hello")
