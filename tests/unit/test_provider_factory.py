"""Tests for provider registry and factory behavior.

These tests reset the registry so test order does not affect outcomes.
"""

import pytest

from services.config import EmbeddingConfig
from services.ai_pipeline.embedding.providers.base import EmbeddingProvider
from services.ai_pipeline.embedding.service import (
    build_provider,
    register_provider,
    reset_provider_registry,
)


class DummyProvider(EmbeddingProvider):
    def embed_text(self, text: str):
        return [1.0, 2.0]


def _builder(_config):
    return DummyProvider()


def test_register_provider_and_build():
    """A provider registered at startup should be buildable by key."""
    reset_provider_registry()
    register_provider("dummy", _builder)
    config = EmbeddingConfig(provider="dummy", model="x", dimensions=2)
    provider = build_provider(config)
    assert isinstance(provider, DummyProvider)


def test_build_provider_fails_for_unknown_provider():
    """Factory should return a clear error for unregistered providers."""
    reset_provider_registry()
    config = EmbeddingConfig(provider="not_registered", model="x", dimensions=2)
    with pytest.raises(ValueError):
        build_provider(config)
