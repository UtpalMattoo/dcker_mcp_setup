# Backend API Reference

This document is the dedicated reference for the FastAPI backend.

## Location

- App entrypoint: `services/api/app.py`
- Schemas: `services/api/schemas.py`

## Run Locally

From repo root:

```bash
python -m uvicorn services.api.app:app --host 0.0.0.0 --port 8000
```

## Health Endpoints

- `GET /health`
- `GET /health/qdrant`
- `GET /health/grafana`
- `GET /health/alloy`

Quick check:

```bash
curl http://localhost:8000/health
```

## Provider and Validation

### Get provider/model catalog

- `GET /providers`

### Validate provider/model/runtime

- `POST /validate`

Example:

```bash
curl -X POST "http://localhost:8000/validate" \
  -H "Content-Type: application/json" \
  -d '{
    "provider": "sentence_transformers",
    "model": "all-MiniLM-L6-v2",
    "dimensions": 384
  }'
```

## Text Ingestion and Search

### Ingest one text payload

- `POST /ingest`

Example:

```bash
curl -X POST "http://localhost:8000/ingest" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "hello world",
    "payload": {"source": "manual"},
    "provider": "sentence_transformers",
    "model": "all-MiniLM-L6-v2",
    "collection": "embeddings_384"
  }'
```

### Search vectors

- `POST /search`

Example:

```bash
curl -X POST "http://localhost:8000/search" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "hello",
    "top_k": 5,
    "provider": "sentence_transformers",
    "model": "all-MiniLM-L6-v2",
    "collection": "embeddings_384"
  }'
```

## Delete and Stats

### Delete vector

- `DELETE /vectors/{vector_id}`

Example:

```bash
curl -X DELETE "http://localhost:8000/vectors/100001?collection=embeddings_1536&dimensions=1536"
```

### Collection stats

- `GET /stats`

Example:

```bash
curl "http://localhost:8000/stats?collection=embeddings_1536&dimensions=1536"
```

## Precomputed HF Ingestion to Qdrant

### Endpoint

- `POST /ingest/precomputed`

### Purpose

Loads precomputed embeddings from Hugging Face dataset rows and upserts to Qdrant.

### Primary model and dataset

- `model`: `Qdrant/dbpedia-entities-openai3-text-embedding-3-small-1536-100K`
- `dataset_name`: `Qdrant/dbpedia-entities-openai3-text-embedding-3-small-1536-100K`

### Example request (upsert 10)

```bash
curl -X POST "http://localhost:8000/ingest/precomputed" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Qdrant/dbpedia-entities-openai3-text-embedding-3-small-1536-100K",
    "dataset_name": "Qdrant/dbpedia-entities-openai3-text-embedding-3-small-1536-100K",
    "split": "train",
    "limit": 10,
    "dry_run": false,
    "streaming": true,
    "start_id": 100000,
    "collection": "embeddings_1536"
  }'
```

### Dry run example

```bash
curl -X POST "http://localhost:8000/ingest/precomputed" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Qdrant/dbpedia-entities-openai3-text-embedding-3-small-1536-100K",
    "dataset_name": "Qdrant/dbpedia-entities-openai3-text-embedding-3-small-1536-100K",
    "split": "train",
    "limit": 10,
    "dry_run": true,
    "streaming": true,
    "start_id": 100000,
    "collection": "embeddings_1536"
  }'
```

## CLI Alternative for Precomputed Ingestion

Use the direct runner:

```bash
python -m services.ai_pipeline.ingestion.run_precomputed \
  --model Qdrant/dbpedia-entities-openai3-text-embedding-3-small-1536-100K \
  --dataset-name Qdrant/dbpedia-entities-openai3-text-embedding-3-small-1536-100K \
  --split train \
  --limit 10 \
  --start-id 100000 \
  --collection embeddings_1536
```

## Unit Test Command

```bash
python -m pytest tests/unit -v
```
