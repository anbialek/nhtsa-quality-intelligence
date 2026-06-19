# ADR-001: Use DuckDB + Parquet for local storage

**Status:** Accepted
**Date:** 2026-06-19
**Deciders:** [Twoje imię]

## Context

The project requires a storage layer for a medallion architecture (Bronze/Silver/Gold) processing NHTSA public datasets. Estimated data volume: ~5-20 GB across all layers. Single-developer project, no concurrent writes, portfolio-focused.

Constraints:
- Zero cost (portfolio project)
- Fast iteration during development
- Should demonstrate modern analytics engineering practices
- Must integrate well with dbt

## Decision

Use **DuckDB** as the query engine with **Parquet files** as the underlying storage format for Bronze and Silver layers. Gold layer materialized as DuckDB tables for fast dashboard queries.

## Alternatives Considered

### PostgreSQL
- ✅ Familiar from previous projects
- ❌ Slower for analytical queries (row-based storage)
- ❌ Requires running a server
- ❌ Less idiomatic for modern analytics stack

### Snowflake / BigQuery free tier
- ✅ Cloud-native, "enterprise" look
- ❌ Free tier limits would constrain experimentation
- ❌ Network latency slows iteration
- ❌ Overkill for project scale

### SQLite
- ✅ Zero-config, file-based
- ❌ Not optimized for analytical workloads
- ❌ No columnar storage

## Consequences

**Positive:**
- Fast local iteration (columnar, vectorized execution)
- Native Parquet support enables industry-standard data lake patterns
- Excellent dbt-duckdb adapter
- Easy to demo (single file, no server)

**Negative:**
- Single-user only (acceptable for portfolio)
- Migration path to cloud (Snowflake/BigQuery) would require effort — documented as future work

**Neutral:**
- Reviewers unfamiliar with DuckDB may need brief explanation in README
