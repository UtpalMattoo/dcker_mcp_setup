"""Qdrant helper used by Phase 1.

Why this exists: provide a small storage-focused layer for vector operations,
while keeping embedding/provider logic outside this module.
"""

from qdrant_client import QdrantClient
from qdrant_client.models import PointIdsList, PointStruct, VectorParams, Distance


class QdrantHelper:
    """Store and query vectors in one collection with dimension safety checks."""

    def __init__(self, host, port=6333, collection="embeddings", dim=384):
        # Connect to the Qdrant database using the host and port
        self.client = QdrantClient(host=host, port=port)
        
        # Name of the collection (like a table in a database)
        self.collection = collection
        
        # Number of values each vector should have (example: 384 numbers per vector)
        self.dim = dim
        
        # Make sure the collection exists and is set up correctly
        self._ensure_collection()

    def _ensure_collection(self):
        """Keep compatibility with existing call flow."""
        self.create_collection()

    def create_collection(self):
        """Create the collection if missing."""
        # Create the collection only once to avoid deleting existing data.
        if not self.client.collection_exists(collection_name=self.collection):
            self.client.create_collection(
                collection_name=self.collection,

                # Tell Qdrant how big each vector is and how to compare them
                vectors_config=VectorParams(
                    size=self.dim,              # number of values in each vector
                    distance=Distance.COSINE   # how similarity between vectors is measured
                )
            )

    def _validate_vector_dimension(self, vector):
        """Fail fast when vector size does not match collection schema."""
        if len(vector) != self.dim:
            raise ValueError(
                f"Vector dimension mismatch for collection '{self.collection}'. "
                f"Expected {self.dim}, got {len(vector)}"
            )

    def upsert(self, vector, payload, point_id):
        """Insert or update one vector point."""
        self._validate_vector_dimension(vector)
        self.client.upsert(
            collection_name=self.collection,
            points=[
                PointStruct(
                    id=point_id,
                    vector=vector,
                    payload=payload,
                )
            ],
        )

    def upsert_embedding(self, vector, payload, point_id):
        # This function adds a new vector OR updates an existing one
        
        # vector: the embedding (a list of numbers, like [0.1, 0.5, ...])
        # payload: extra information (like text, labels, or metadata)
        # point_id: unique ID so we can find or update this item later
        
        self.upsert(vector=vector, payload=payload, point_id=point_id)

    def search(self, query_vector, limit=5, score_threshold=None, query_filter=None):
        """Run vector similarity search with optional filter/threshold."""
        self._validate_vector_dimension(query_vector)
        return self.client.search(
            collection_name=self.collection,
            query_vector=query_vector,
            limit=limit,
            score_threshold=score_threshold,
            query_filter=query_filter,
            with_payload=True,
        )

    def delete_document(self, point_id):
        """Delete one point by id."""
        self.client.delete(
            collection_name=self.collection,
            points_selector=PointIdsList(points=[point_id]),
        )

    def collection_stats(self):
        """Return lightweight collection information for diagnostics."""
        info = self.client.get_collection(collection_name=self.collection)
        return {
            "collection": self.collection,
            "vector_size": self.dim,
            "points_count": info.points_count,
            "indexed_vectors_count": info.indexed_vectors_count,
            "status": str(info.status),
        }

    def get_collection_stats(self):
        """Compatibility alias for older callers."""
        return self.collection_stats()