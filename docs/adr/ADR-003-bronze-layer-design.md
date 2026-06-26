 # ADR-003: Bronze Layer Design — Format, Granularity, Metadata, Idempotency

**Status:** Accepted  
**Date:** 2026-06-26
**Deciders:** Anna Bialek

## Context

The Bronze layer is the first layer in the Medallion architecture. It is responsible for ingesting and storing raw data from source systems with minimal transformations, preserving the original data as closely as possible. The layer ensures reproducibility, auditability, and traceability while maintaining a simple and stable data model.

## Decision

To preserve the highest possible fidelity to the source data, **JSON Lines (JSONL)** was selected as the ingestion format. JSONL supports efficient append operations by adding new records to the end of the file, making it well suited for incremental data ingestion. It also enables line-by-line processing, which improves scalability for large datasets. Additionally, its human-readable format simplifies inspection and debugging of ingested data.

Each API endpoint has its own top-level folder, with daily **Hive-style partitioning** by ingestion date (for example, *ingest_date=2025-05-25/data.jsonl*). 

```
data/bronze/
├── recalls/
│   └── ingest_date=YYYY-MM-DD/
└── complaints/
    └── ingest_date=YYYY-MM-DD/
```

This approach enables efficient partition pruning and time-based filtering based on directory names, reducing the amount of data scanned during queries.Endpoint separation keeps schemas isolated, since `Recalls` and `Complaints` have fundamentally different structures. It provides a standard layout that is compatible with Spark, DuckDB, and other analytical engines, while remaining scalable as the dataset grows.

To support reproducibility, lineage, and auditability, the Bronze layer augments each ingested record with **technical metadata**: *_ingested_at* (ingestion timestamp), *_source_url* (source endpoint), *_query_params* (request parameters), and *_response_status* (HTTP response status). These fields do not alter the source data itself; they capture the technical context of the ingestion process while preserving the original payload.

The Bronze layer follows an **append-only** ingestion strategy. New records are always appended, while duplicate detection and deduplication are deferred to the Silver layer. This approach preserves the complete ingestion history and provides a full audit trail. The trade-off is that duplicate records may temporarily exist in the Bronze layer until they are resolved during downstream processing.

## Alternatives Considered

### Format
- **Raw JSON:** This option provides the highest fidelity to the source format because it preserves the original document structure without modification. However, processing and incremental ingestion are less efficient, as parsing typically requires reading the entire document rather than processing records independently.
- **Parquet:** Parquet offers significantly smaller storage requirements (typically around 10× smaller than raw JSON due to columnar compression) and integrates well with analytical tools such as DuckDB, Spark, and pandas. However, writing data in Parquet requires transforming the source data into a columnar schema. Since schema normalization and data transformation are responsibilities of the Silver layer in the Medallion Architecture, using Parquet in the ingestion (Bronze) layer would violate the intended separation of concerns.

### Granularity
- **One file per request:** (for example, *2025-05-25_ford_fiesta_2020.jsonl*) was rejected because it would create a very large number of small files, leading to increased filesystem overhead and reduced performance in distributed processing environments.
- **One file per day:** (for example, *2025-05-25.jsonl*) was rejected because it provides no partition hierarchy beyond the file name. While suitable for simple ingestion, it would make future filtering, incremental processing, and partition-based optimizations more difficult as the dataset grows.

### Metadata
- **No metadata enrichment:** Storing only the raw API payload was rejected because it would prevent reproducibility (no way to verify when data was ingested or from which exact query) and complicate auditing.
- **Metadata in a separate file:** Storing technical metadata in a parallel manifest file (one per partition) was rejected because it splits related information across two locations, requiring JOINs at query time for any audit-related question.

### Idempotency
- **Overwrite per date:** replacing the file for a given ingestion date would prevent duplicate records in the Bronze layer. However, it would also remove the history of previously ingested snapshots, making it impossible to track changes or reproduce the state of the source API at a given point in time.
- **Versioned per run_id:** storing each ingestion run in a separate versioned location would provide complete auditability and reproducibility for every pipeline execution. However, this approach was rejected because it significantly increases the number of files and the complexity of storage management, which is unnecessary for this project and could negatively affect performance on a local development environment.

## Consequences

**Positive:**
- Native compatibility with modern analytical stack (DuckDB, Spark, dbt)
- Predictable file location for any given (endpoint, date) combination
- Future endpoints can be added without restructuring existing data
- Straightforward migration path to object storage (S3/GCS/Azure) — same folder structure works

**Negative:**
- Many small files if ingestion runs sub-daily (multiple times per day) — mitigated by file consolidation in the Silver layer if needed
- Folder structure becomes verbose with many dates; navigable but visually noisy
- Duplicate records exist temporarily in Bronze, requiring deduplication in the Silver layer

**Neutral / Future considerations:**
- Sub-partitioning (e.g., by manufacturer) is possible if daily volume grows