from __future__ import annotations

"""Reusable precomputed dataset ingestion helpers.

Why this exists: keep batch dataset ingestion separate from startup and API
transport concerns while reusing existing Qdrant helper behavior.
"""

from dataclasses import asdict, dataclass
from typing import Any

from services.qdrant.qdrant_service import QdrantHelper


_TEXT_KEYS = ("text", "content", "document", "body", "article")
_VECTOR_KEYS = ("embedding", "vector", "embeddings")


@dataclass
class PrecomputedIngestResult:
    inserted: int
    scanned: int
    skipped: int
    collection: str
    dimensions: int
    dataset_name: str
    split: str
    dry_run: bool
    first_point_id: int | None
    last_point_id: int | None

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


def _extract_text(row: dict[str, Any]) -> str | None:
    for key in _TEXT_KEYS:
        value = row.get(key)
        if isinstance(value, str) and value.strip():
            return value.strip()
    return None


def _extract_vector(row: dict[str, Any]) -> list[float] | None:
    vector_raw = None
    for key in _VECTOR_KEYS:
        value = row.get(key)
        if isinstance(value, list):
            vector_raw = value
            break

    if vector_raw is None:
        return None

    try:
        return [float(value) for value in vector_raw]
    except (TypeError, ValueError):
        return None


def ingest_precomputed_dataset(
    *,
    qdrant_service: QdrantHelper,
    dataset_name: str,
    split: str,
    expected_dimensions: int,
    limit: int,
    dry_run: bool,
    start_id: int,
    model_key: str,
    streaming: bool = True,
) -> PrecomputedIngestResult:
    """Load dataset rows and upsert up to limit rows into Qdrant."""
    if limit <= 0:
        raise ValueError("limit must be greater than zero")

    try:
        from datasets import load_dataset
    except Exception as exc:  # pragma: no cover - depends on runtime env
        raise RuntimeError(
            "The 'datasets' package is required for precomputed ingestion"
        ) from exc

    dataset = load_dataset(path=dataset_name, split=split, streaming=streaming)

    inserted = 0
    scanned = 0
    skipped = 0
    first_point_id: int | None = None
    last_point_id: int | None = None

    point_id = start_id
    for row in dataset:  # type: ignore[assignment]
        if inserted >= limit:
            break
        scanned += 1

        if not isinstance(row, dict):
            skipped += 1
            continue

        text = _extract_text(row)
        vector = _extract_vector(row)
        if text is None or vector is None:
            skipped += 1
            continue

        if len(vector) != expected_dimensions:
            skipped += 1
            continue

        payload = {
            "text": text,
            "source": dataset_name,
            "split": split,
            "model_key": model_key,
        }

        if not dry_run:
            qdrant_service.upsert(vector=vector, payload=payload, point_id=point_id)

        if first_point_id is None:
            first_point_id = point_id
        last_point_id = point_id

        inserted += 1
        point_id += 1

    return PrecomputedIngestResult(
        inserted=inserted,
        scanned=scanned,
        skipped=skipped,
        collection=qdrant_service.collection,
        dimensions=expected_dimensions,
        dataset_name=dataset_name,
        split=split,
        dry_run=dry_run,
        first_point_id=first_point_id,
        last_point_id=last_point_id,
    )
