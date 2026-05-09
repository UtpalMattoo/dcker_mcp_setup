import sys
from pathlib import Path

# Resolve import paths for both local and container environments.
# Local:     .../dcker_mcp_setup/tests/  → parents[1] = dcker_mcp_setup root
# Container: /app/tests/            → parents[1] = /app
# In both cases parents[1] is the correct root to add to sys.path.
_parents = Path(__file__).resolve().parents
sys.path.insert(0, str(_parents[1]))
print(f"\nDEBUG: sys.path is {sys.path}\n")

try:
    from services.qdrant.qdrant_service import QdrantHelper
except ModuleNotFoundError:
    from qdrant.qdrant_service import QdrantHelper

def test_qdrant_connection():
    import os
    qdrant_host = os.environ["QDRANT_HOST"]  # Will raise KeyError if not set
    qdrant = QdrantHelper(host=qdrant_host)
    collections = qdrant.client.get_collections()
    assert collections is not None

def test_upsert_embedding():
    import os
    qdrant_host = os.environ["QDRANT_HOST"]  # Will raise KeyError if not set
    qdrant = QdrantHelper(host=qdrant_host)
    vector = [0.2] * 384
    qdrant.upsert_embedding(vector, {"text": "test"}, point_id=2)


def test_retrieve_upserted_embedding():
    import os
    qdrant_host = os.environ["QDRANT_HOST"]  # Will raise KeyError if not set
    qdrant = QdrantHelper(host=qdrant_host)

    # Read an existing point from Qdrant and verify stored data shape.
    points, _ = qdrant.client.scroll(
        collection_name=qdrant.collection,
        limit=1,
        with_payload=True,
        with_vectors=True,
    )

    # Ensure at least one vector already exists in the collection.
    assert len(points) >= 1, "No vectors found in collection; insert data before retrieval test"

    # Select the first returned point for structural validation.
    point = points[0]

    # A valid Qdrant point must include a non-null unique identifier.
    assert point.id is not None

    # Confirm metadata (payload) exists alongside the stored vector.
    assert point.payload is not None

    # Verify the retrieved vector dimension matches the collection schema.
    assert len(point.vector) == qdrant.dim

    # Verify every vector entry is numeric and usable for similarity math.
    assert all(isinstance(value, (int, float)) for value in point.vector)