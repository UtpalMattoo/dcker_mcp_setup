from qdrant_client import QdrantClient
from qdrant_client.models import PointStruct, VectorParams, Distance

class QdrantHelper:
    # This class is used to store and manage embeddings (lists of numbers)
    # in a Qdrant database. Think of it like saving and organizing data
    # so we can search it later.

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

    def upsert_embedding(self, vector, payload, point_id):
        # This function adds a new vector OR updates an existing one
        
        # vector: the embedding (a list of numbers, like [0.1, 0.5, ...])
        # payload: extra information (like text, labels, or metadata)
        # point_id: unique ID so we can find or update this item later
        
        self.client.upsert(
            collection_name=self.collection,
            
            # We send a list of points (here just one)
            points=[
                PointStruct(
                    id=point_id,     # unique ID for this data
                    vector=vector,   # the embedding values
                    payload=payload  # extra information attached to the vector
                )
            ]
        )