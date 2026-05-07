import pytest

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
    # Optionally, add retrieval and assertion logic here