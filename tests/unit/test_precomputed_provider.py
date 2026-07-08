"""Tests for the dataset-backed precomputed embedding provider."""

import sys
import types

import pytest

from services.ai_pipeline.embedding.providers.base import EmbeddingProviderError
from services.ai_pipeline.embedding.providers.precomputed_provider import (
    PrecomputedDatasetEmbeddingProvider,
)


def test_precomputed_provider_returns_vector_for_known_text():
    fake_module = types.SimpleNamespace(
        load_dataset=lambda path, split, cache_dir: [
            {"text": "Alpha entry", "embedding": [0.2, 0.3, 0.4]},
            {"text": "Beta entry", "embedding": [0.1, 0.2, 0.3]},
        ]
    )
    previous = sys.modules.get("datasets")
    sys.modules["datasets"] = fake_module

    try:
        provider = PrecomputedDatasetEmbeddingProvider(
            model="qdrant-dbpedia-entities-100k-openai-1536",
            expected_dimensions=3,
            dataset_name="Qdrant/dbpedia-entities-100k",
            split="train",
            cache_dir="/tmp/hf",
        )
        assert provider.embed_text("alpha entry") == [0.2, 0.3, 0.4]
    finally:
        if previous is None:
            del sys.modules["datasets"]
        else:
            sys.modules["datasets"] = previous


def test_precomputed_provider_raises_for_unknown_text():
    fake_module = types.SimpleNamespace(
        load_dataset=lambda path, split, cache_dir: [
            {"text": "Known entry", "embedding": [1.0, 2.0, 3.0]},
        ]
    )
    previous = sys.modules.get("datasets")
    sys.modules["datasets"] = fake_module

    try:
        provider = PrecomputedDatasetEmbeddingProvider(
            model="qdrant-dbpedia-entities-100k-openai-1536",
            expected_dimensions=3,
            dataset_name="Qdrant/dbpedia-entities-100k",
        )
        with pytest.raises(EmbeddingProviderError):
            provider.embed_text("missing entry")
    finally:
        if previous is None:
            del sys.modules["datasets"]
        else:
            sys.modules["datasets"] = previous
