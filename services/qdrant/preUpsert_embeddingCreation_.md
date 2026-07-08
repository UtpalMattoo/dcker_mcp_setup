## embedding creation prompt for some or all data sources

## Table of Contents

- [Phase 1 — Embedding Foundation and Configuration](#phase-1--embedding-foundation-and-configuration)
- [Phase 2 — Document Processing Pipeline](#phase-2--document-processing-pipeline)
- [Phase 3 — Qdrant Integration and Persistence](#phase-3--qdrant-integration-and-persistence)
- [Phase 4 — CLI-Based Ingestion](#phase-4--cli-based-ingestion)
- [Phase 5 — Gmail Integration](#phase-5--gmail-integration)
- [Phase 6 — Search API](#phase-6--search-api)
- [Phase 7 — Frontend UI](#phase-7--frontend-ui)
- [Phase 8 — Production Readiness](#phase-8--production-readiness)
- [Additional Requirements and Clarifications](#additional-requirements-and-clarifications)


### Phase 1 — Embedding Foundation and Configuration

Goal:
- Build a clean embedding base with config-driven provider selection.

Active code paths:
- services/qdrant/qdrant_service.py (talks to qdrant)   
- services/config.py (central configuration, rather than reading environment variables throughout the codebase)
- services/ai_pipeline/embedding/service.py (main embedding interface)
- services/ai_pipeline/ingestion/service.py (sends embedded text into Qdrant)

Internal Phase 1 modules:
- services/ai_pipeline/embedding/service.py
- services/ai_pipeline/embedding/providers/
- services/ai_pipeline/ingestion/service.py

Test folder:
- tests/unit

Phase 1 directory tree (current implementation):

```text
services/
├── config.py
│   └── Embedding config and model dimensions.
├── qdrant/
│   ├── qdrant_service.py
│   │   └── Qdrant collection, upsert, and search logic.
│   └── preUpsert_embeddingCreation_.md
│       └── Phase plan and acceptance criteria.
└── ai_pipeline/
   ├── embedding/
   │   ├── service.py
   │   │   └── Provider registry and embed_text service layer.
   │   └── providers/
   │       ├── base.py
   │       │   └── Base provider interface and common error type.
   │       ├── openai_provider.py
   │       │   └── OpenAI embeddings with retry.
   │       ├── sentence_transformers_provider.py
   │       │   └── Local sentence-transformers embeddings.
   │       └── precomputed_provider.py
   │           └── Precomputed embeddings from Hugging Face dataset.
   └── ingestion/
      └── service.py
         └── Ingest flow: embed text and upsert.

tests/
└── unit/
   ├── test_config.py
   │   └── Config validation tests.
   ├── test_embedding_service.py
   │   └── Embedding service behavior tests.
   ├── test_provider_factory.py
   │   └── Provider registry and factory tests.
   ├── test_precomputed_provider.py
   │   └── Precomputed provider lookup tests.
   ├── test_dimension_validation.py
   │   └── Dimension validation tests.
   └── test_cache_path_config.py
      └── Cache path and startup check tests.
```

Keep this structure for now:
- Use one active Qdrant service at services/qdrant/qdrant_service.py.
- Keep services/config.py as the single config module.

Phase 1 scope:
1) Embedding service with one method: embed_text(text).
2) Three providers behind one interface:
   - openai
   - sentence_transformers
   - precomputed (Hugging Face dataset-backed)
3) Config-driven switch only. No auto fallback provider.
4) Config checks:
   - valid provider
   - valid model for provider
   - valid dimensions
   - required API key for openai
5) Startup health checks (separate from config load):
   - local runtime dependency check
   - cache path write check
6) Provider reliability:
   - retry transient OpenAI failures
   - normalized provider error type
7) Qdrant safety:
   - collection create if missing
   - vector dimension check before write/search
8) Ingestion stays thin:
   - embed text
   - upsert to Qdrant

Acceptance criteria:
- Provider is selected by config only.
- Provider must be set explicitly.
- Vector size is validated before Qdrant operations.
- Local cache path is persistent and writable.
- Provider failures return normalized errors.
- Phase 1 unit tests pass.

### Phase 2 — Document Processing Pipeline

1) File Readers
   - Support:
     - txt
     - md
     - pdf
     - eml
     - mbox

2) Chunking Service
   - Create a chunking component.
   - Configurable:
     - chunk_size
     - chunk_overlap
   - Preserve sentence boundaries when possible.

3) Document Identity
   - Generate stable document identifiers.
   - All chunks from the same source document must share the same document_id.

4) Chunk Identity
   - Generate unique chunk identifiers.

5) Metadata Schema
   - Attach metadata to every chunk:
     - document_id
     - chunk_id
     - source_file
     - source_type
     - ingestion_timestamp
     - embedding_model

6) Email Metadata
   - For eml and mbox ingestion include:
     - subject
     - sender
     - recipients
     - message_id
     - thread_id if available
     - sent_date

7) Testing
   - Validate:
     - chunk creation
     - metadata generation
     - document identity preservation
     - email parsing

Acceptance criteria:
- All supported file types can be parsed.
- Documents are chunked correctly.
- Metadata is attached consistently.
- Tests pass.


### Phase 3 — Qdrant Integration and Persistence

Implement Qdrant integration and persistent vector storage.

Requirements:

1) Qdrant Service
   - Extend qdrant_service.py.
   - Support:
     - create_collection()
     - upsert()
     - search()
     - delete_document()
     - collection_stats()

2) Embedding Integration
   - Modify upsert workflow.
   - Automatically generate embeddings before insertion.

3) Collection Management (how collections are created, selected, and maintained)
   - Support configurable collections.
   - Allow collection creation if missing.

4) Metadata Storage (store document/chunk context with each vector)
   - Store all chunk metadata in Qdrant payloads.

5) Persistent Storage (data remains after container restart)
   - Configure Docker volumes for persistence.
   - Store vector data in a parent-level folder outside the application source tree.

6) Shared Visibility (same stored data is visible from both environments)
   - Storage location must be visible:
     - from local host
     - from devcontainer

7) Validation (guardrails to prevent schema/model mismatch)
   - Verify collection dimensions match selected embedding model.

8) Testing (integration-level checks across service boundaries)
   - Integration tests:
     - collection creation
     - vector insertion
     - metadata persistence
     - vector retrieval

Acceptance criteria:
- Documents can be embedded and stored.
- Data survives container restarts.
- Metadata is retrievable.
- Integration tests pass.

### Phase 4 — CLI-Based Ingestion

Implement command-line ingestion workflows.

Requirements:

1) File Ingestion
   - Support:
     - --file
     - --mbox
     - --eml

2) Collection Selection
   - Support:
     - --collection

3) Reprocessing Controls
   - Support:
     - --reindex
     - --reembed

4) Validation
   - Validate:
     - file existence
     - supported file type
     - collection existence

5) Progress Reporting
   - Display:
     - files processed
     - chunks created
     - embeddings generated
     - vectors stored

6) Error Handling
   - Gracefully handle:
     - invalid files
     - embedding failures
     - Qdrant failures

7) Testing
   - CLI integration tests.

Acceptance criteria:
- Documents can be ingested from CLI.
- Collections can be selected.
- Reindexing works.
- Progress is visible.


### Phase 5 — Gmail Integration

Implement Gmail ingestion support.

Requirements:

1) Gmail API Integration
   - Connect to Gmail using OAuth.

2) Individual Email Support
   - Support:
     - --gmail-email user@example.com

3) Batch Email Support
   - Support:
     - --gmail-file emails.txt

4) Filtering
   - Allow ingestion by:
     - sender
     - recipient
     - date range

5) Metadata Preservation (keep message context for search and traceability)
   - Store:
     - subject
     - sender
     - recipients
     - thread_id
     - message_id
     - timestamps

6) Incremental Sync
   - Avoid re-ingesting previously indexed messages.

7) Testing
   - Gmail integration tests.

Acceptance criteria:
- Gmail messages can be indexed.
- Metadata is preserved.
- Duplicate ingestion is prevented.


### Phase 6 — Search API

Implement a backend semantic search API.

Requirements:

1) Search Endpoint
   - POST /search

2) Query Processing
   - Embed incoming search queries.
   - Perform vector search.

3) Search Controls
   - Support:
     - collection selection
     - top_k
     - score threshold

4) Metadata Filtering
   - Support filtering by:
     - source type
     - sender
     - file name
     - date ranges

5) Result Formatting
   - Return:
     - chunk text
     - score
     - document metadata

6) Health Endpoints
   - GET /health
   - GET /collections

7) Testing
   - Search integration tests.

Acceptance criteria:
- Search returns relevant results.
- Metadata filtering works.
- APIs are documented.


### Phase 7 — Frontend UI

Implement a frontend UI for ingestion and search.

Requirements:

1) Upload Interface
   - Upload:
     - txt
     - md
     - pdf
     - eml
     - mbox

2) Collection Management
   - Create collections.
   - View collections.
   - View collection statistics.

3) Ingestion Dashboard
   - Display:
     - upload status
     - processing status
     - indexing status

4) Search Interface
   - Query input
   - top_k selector
   - metadata filters

5) Search Results
   - Show:
     - matched text
     - similarity score
     - source metadata

6) Error Handling
   - Display upload and indexing failures.

Acceptance criteria:
- Users can upload and index documents.
- Users can perform semantic searches.
- Collection information is visible.


### Phase 8 — Production Readiness

Implement operational and production-readiness capabilities.

Requirements:

1) Observability
   - Metrics:
     - ingestion rate
     - embedding latency
     - indexing latency
     - search latency
   - Integrate with existing observability stack.

2) Background Processing
   - Support asynchronous ingestion jobs.

3) Embedding Cache
   - Cache previously generated embeddings.

4) Security
   - Authentication
   - Upload validation
   - File size limits
   - Secret management

5) Backup and Restore
   - Export collections.
   - Import collections.
   - Restore backups.

6) Documentation
   - Architecture diagrams
   - Setup instructions
   - Deployment instructions
   - Troubleshooting guide

7) Testing
   - End-to-end tests.
   - Load testing.

Acceptance criteria:
- System is observable.
- System is recoverable.
- Documentation is complete.
- Production validation passes.


### Additional Requirements and Clarifications:

#### Additional Requirements TOC

- [1. Shared Ingestion Pipeline Architecture](#shared-ingestion-pipeline-architecture)
- [2. Embedding Configuration Ownership and Collection Schema Management](#embedding-configuration-ownership-and-collection-schema-management)
- [3. Duplicate Detection and Idempotent Ingestion](#duplicate-detection-and-idempotent-ingestion)
- [4. Metadata Schema Requirements](#metadata-schema-requirements)
- [5. Metadata Retrieval Validation](#metadata-retrieval-validation)
- [6. Phase Dependency Clarification](#phase-dependency-clarification)
- [7. Concrete API Acceptance Criteria](#concrete-api-acceptance-criteria)

Refinement section to the existing phased implementation plan, not as a replacement for the phase-by-phase requirements. The goal is to clarify a few areas that could otherwise lead to ambiguity during implementation—specifically ownership of embedding and collection configuration, how all ingestion sources should flow through a shared pipeline, metadata requirements and validation, duplicate-document handling, and more concrete, testable acceptance criteria.

<a id="shared-ingestion-pipeline-architecture"></a>
1. Shared Ingestion Pipeline Architecture

All ingestion sources must use a common ingestion workflow.

Supported ingestion sources include:

* txt
* md
* pdf
* eml
* mbox
* Gmail

Implement source-specific reader/adaptor components only:

* TextFileReader
* PdfReader
* EmlReader
* MboxReader
* GmailReader

Each reader must output a common Document object containing:

* document content
* source metadata

All downstream processing must be shared:

Document
→ Chunker
→ Metadata Generator
→ EmbeddingService
→ QdrantService

Gmail ingestion must reuse the existing chunking, embedding, metadata creation, duplicate detection, and Qdrant insertion logic.

Duplicate ingestion code paths are not permitted.

---

<a id="embedding-configuration-ownership-and-collection-schema-management"></a>
2. Embedding Configuration Ownership and Collection Schema Management

The embedding configuration is the single source of truth for vector dimensions.

The system must derive vector dimensions automatically from the configured embedding model.

Example:

embedding:
provider: openai
model: text-embedding-3-large

The system should internally determine the vector dimension associated with the model.

Vector dimensions must not be manually configured in multiple locations.

Collection creation requirements:

* Collection schema must be derived from the active embedding model configuration.
* Collection vector size must be automatically set using the configured embedding model dimensions.
* Collection metadata should record:

  * embedding provider
  * embedding model
  * vector dimension
  * collection creation timestamp

Validation requirements:

* Before every upsert, verify that collection dimensions match the active embedding model dimensions.
* If dimensions do not match, fail the operation with a clear error.

Model migration requirements:

If the configured embedding model changes:

* Detect mismatches between the active model and the collection model.
* Prevent accidental insertion into incompatible collections.
* Require either:

  * explicit re-indexing, or
  * creation of a new collection.

Example error:

"Collection was created using text-embedding-3-small. Current configuration uses text-embedding-3-large. Run re-indexing before continuing."

---

<a id="duplicate-detection-and-idempotent-ingestion"></a>
3. Duplicate Detection and Idempotent Ingestion

The system must prevent duplicate document ingestion.

Requirements:

* Generate a content fingerprint using SHA256 hashing.
* Store the fingerprint with document metadata.
* Check for existing fingerprints before indexing.

Expected behavior:

First ingestion:

* Document processed
* Chunks generated
* Embeddings created
* Vectors inserted

Second ingestion of identical content:

* Document identified as already indexed
* No new chunks created
* No duplicate vectors inserted

Acceptance criteria:

* Duplicate files must not create duplicate vectors.
* Search results must not contain duplicate chunks originating from duplicate ingestion attempts.
* Duplicate detection must work across service restarts.

---

<a id="metadata-schema-requirements"></a>
4. Metadata Schema Requirements

Every indexed chunk must contain metadata.

Required metadata:

* document_id
* chunk_id
* source_type
* source_name
* source_path
* content_hash
* embedding_provider
* embedding_model
* created_at
* ingested_at

File-specific metadata:

* file_name
* file_extension
* file_size

Email-specific metadata:

* sender
* recipients
* cc
* bcc (when available)
* subject
* sent_date
* thread_id
* message_id

Metadata must be stored within Qdrant payloads and returned with search results.

---

<a id="metadata-retrieval-validation"></a>
5. Metadata Retrieval Validation

Metadata retrieval must be explicitly tested.

Requirements:

Search results must return:

* chunk text
* similarity score
* metadata payload

Example search response:

{
"text": "...",
"score": 0.92,
"metadata": {
"document_id": "contract_001",
"chunk_id": "chunk_05",
"source_file": "contract.pdf",
"source_type": "pdf"
}
}

Acceptance criteria:

* Search results must include stored metadata.
* Returned metadata values must exactly match original ingested values.
* Metadata must remain available after service restart.
* Metadata must be available through both API and UI.

Filtering validation:

Metadata filters must support:

* source type
* file name
* sender
* recipient
* date ranges
* collection

Example:

Search query:

{
"query": "employment history",
"source_file": "resume.pdf"
}

Expected result:

All returned documents must contain:

{
"source_file": "resume.pdf"
}

Email metadata validation:

Search query:

{
"sender": "[john@example.com](mailto:john@example.com)"
}

Expected result:

All returned documents must contain:

{
"sender": "[john@example.com](mailto:john@example.com)"
}

Persistence validation:

* Index document.
* Restart services.
* Execute search again.
* Verify metadata remains available and unchanged.

---

<a id="phase-dependency-clarification"></a>
6. Phase Dependency Clarification

Phase 1:
Embedding Foundation and Configuration

Phase 2:
Document Processing, Chunking, Metadata Generation

Phase 3:
Qdrant Integration, Collection Management, Persistence, Duplicate Detection

Phase 4:
CLI Ingestion Pipeline

Phase 5:
Search API

Phase 6:
Frontend UI

Phase 7:
Gmail Integration using the shared ingestion pipeline

Phase 8:
Production Readiness, Observability, Security, Backup and Restore

The Gmail implementation must build on the ingestion pipeline developed in earlier phases and must not introduce a separate indexing architecture.

---

<a id="concrete-api-acceptance-criteria"></a>
7. Concrete API Acceptance Criteria

Search endpoint:

POST /search

Request:

{
"query": "machine learning",
"top_k": 5
}

Expected response:

HTTP 200

{
"results": [...]
}

Invalid collection:

Request:

{
"collection": "missing_collection"
}

Expected response:

HTTP 404

{
"error": "Collection not found"
}

Empty query:

Request:

{
"query": ""
}

Expected response:

HTTP 400

{
"error": "Query cannot be empty"
}

Health endpoint:

GET /health

Expected response:

HTTP 200

{
"status": "healthy"
}

Collection endpoint:

GET /collections

Expected response:

HTTP 200

{
"collections": [...]
}

All API endpoints must include integration tests covering:

* successful requests
* validation failures
* missing resources
* metadata retrieval
* filtering behavior
* duplicate ingestion behavior
