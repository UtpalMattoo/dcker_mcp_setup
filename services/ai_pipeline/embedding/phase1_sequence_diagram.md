# Phase 1 Flow (Simple Version)

This shows what happens from start to finish when text is converted into an embedding and saved.

```mermaid
sequenceDiagram
    participant App as App
    participant Config as Config File
    participant Health as Startup Checks
    participant Embed as Embedding Service
    participant Provider as Chosen Provider
    participant Ingest as Ingestion Service
    participant DB as Qdrant Database

    App->>Config: Load settings
    Config->>Config: Read provider + model
    Config->>Config: Read expected vector size
    Config-->>App: Return valid config

    App->>Health: Run startup checks
    Health->>Health: Check local packages (if needed)
    Health->>Health: Check cache folder can be written
    Health-->>App: Ready or stop with error

    App->>Embed: Start embedding service
    Embed->>Provider: Create the selected provider
    Provider-->>Embed: Provider ready

    App->>Ingest: Send text to ingest
    Ingest->>Embed: Ask for embedding
    Embed->>Provider: Create vector from text
    Provider-->>Embed: Return vector
    Embed->>Embed: Check vector size is correct
    Embed-->>Ingest: Return checked vector

    Ingest->>DB: Save vector + metadata
    DB->>DB: Create collection if missing
    DB->>DB: Check vector size before save
    DB-->>Ingest: Saved
    Ingest-->>App: Done
```

## In Plain Words

1. The app reads settings (which provider to use and model details).
2. The app runs startup checks so problems are caught early.
3. One embedding provider is created from the settings.
4. The text is turned into a vector.
5. The vector size is checked to avoid bad data.
6. The vector is saved in Qdrant.

If anything fails, the process stops with a clear error instead of silently continuing.
