"""Tests for provider registry and factory behavior.

These tests reset the registry so test order does not affect outcomes.
"""

import sys
import types

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


def test_build_provider_accepts_precomputed_key_when_registered_defaults_loaded():
    """Default registry should include the precomputed provider key."""
    reset_provider_registry()
    fake_module = types.SimpleNamespace(
        load_dataset=lambda path, split, cache_dir: [
            {
                "text": "hello",
                "embedding": [0.1] * 1536,
            }
        ]
    )
    previous = sys.modules.get("datasets")
    sys.modules["datasets"] = fake_module
    config = EmbeddingConfig(
        provider="precomputed",
        model="qdrant-dbpedia-entities-100k-openai-1536",
        dimensions=1536,
    )
    try:
        provider = build_provider(config)
        assert provider.embed_text("hello")
    finally:
        if previous is None:
            del sys.modules["datasets"]
        else:
            sys.modules["datasets"] = previous
