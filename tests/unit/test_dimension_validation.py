"""Simple safety test for Qdrant vector-size guard.

This test does not call a live Qdrant server. It checks local validation logic
so bad vector sizes fail early.
"""

import pytest

pytest.importorskip("qdrant_client")

from services.qdrant.qdrant_service import QdrantHelper


def test_qdrant_dimension_validation(monkeypatch):
    """Mismatched vector size should raise ValueError before write operations."""
    helper = QdrantHelper.__new__(QdrantHelper)
    helper.collection = "embeddings"
    helper.dim = 384

    with pytest.raises(ValueError):
        helper._validate_vector_dimension([0.1] * 10)
