from __future__ import annotations

"""CLI runner for precomputed dataset ingestion."""

import argparse
import json
import os

from services.ai_pipeline.ingestion.precomputed_ingest import ingest_precomputed_dataset
from services.config import PROVIDER_MODEL_DIMENSIONS
from services.qdrant.qdrant_service import QdrantHelper


def parse_args() -> argparse.Namespace:
    default_model = "Qdrant/dbpedia-entities-openai3-text-embedding-3-small-1536-100K"
    default_dim = PROVIDER_MODEL_DIMENSIONS["precomputed"][default_model]

    parser = argparse.ArgumentParser(description="Ingest precomputed HF vectors into Qdrant")
    parser.add_argument("--model", default=default_model)
    parser.add_argument(
        "--dataset-name",
        default=os.getenv(
            "HF_DATASET_NAME",
            "Qdrant/dbpedia-entities-openai3-text-embedding-3-small-1536-100K",
        ),
    )
    parser.add_argument("--split", default=os.getenv("HF_DATASET_SPLIT", "train"))
    parser.add_argument("--limit", type=int, default=10)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--no-streaming", action="store_true")
    parser.add_argument("--start-id", type=int, default=100000)
    parser.add_argument("--qdrant-host", default=os.getenv("QDRANT_HOST", "localhost"))
    parser.add_argument("--qdrant-port", type=int, default=int(os.getenv("QDRANT_PORT", "6333")))
    parser.add_argument("--collection", default=f"embeddings_{default_dim}")
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    if args.model not in PROVIDER_MODEL_DIMENSIONS["precomputed"]:
        supported = ", ".join(sorted(PROVIDER_MODEL_DIMENSIONS["precomputed"]))
        raise SystemExit(f"Unsupported precomputed model '{args.model}'. Supported: {supported}")

    dimensions = PROVIDER_MODEL_DIMENSIONS["precomputed"][args.model]

    qdrant = QdrantHelper(
        host=args.qdrant_host,
        port=args.qdrant_port,
        collection=args.collection,
        dim=dimensions,
    )

    result = ingest_precomputed_dataset(
        qdrant_service=qdrant,
        dataset_name=args.dataset_name,
        split=args.split,
        expected_dimensions=dimensions,
        limit=args.limit,
        dry_run=args.dry_run,
        start_id=args.start_id,
        model_key=args.model,
        streaming=not args.no_streaming,
    )

    print(json.dumps(result.to_dict(), indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
