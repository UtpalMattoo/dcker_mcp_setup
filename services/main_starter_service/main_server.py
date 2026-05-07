
from qdrant.qdrant_service import QdrantHelper
import os

def main():
    qdrant_host = os.environ["QDRANT_HOST"]  # Will raise KeyError if not set
    qdrant = QdrantHelper(host=qdrant_host)
    # Example usage
    vector = [0.1] * 384
    qdrant.upsert_embedding(vector, {"text": "example"}, point_id=1)
    print("Embedding uploaded.")

if __name__ == "__main__":
    main()