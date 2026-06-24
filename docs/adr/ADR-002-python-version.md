# ADR-002: Use Python 3.12 for project virtual environment

**Status:** Accepted
**Date:** 2026-06-22
**Deciders:** Anna Bialek

## Context

Used Python 3.14 was released in October 2025 — relatively recent. The project relies on data engineering libraries (pandas, duckdb, dbt-duckdb, streamlit) that may not yet have stable wheel distributions for Python 3.14.

## Decision

Install Python 3.12 alongside Python 3.14 and use **Python 3.12** as the basis for the project's virtual environment (`.venv`). Manage multiple Python versions via the `py` launcher (Windows-native tool).

## Alternatives Considered

### Use Python 3.14 (system default)

- ✅ No additional installation
- ❌ Risk of missing wheels for analytical libraries
- ❌ Less reflective of industry practice (companies typically run n-1 or n-2 Python versions)

## Consequences

**Positive:**
- Library compatibility maximized (3.12 is widely supported)
- Reflects industry practice of using stable, not bleeding-edge, runtimes
- `py` launcher already familiar pattern for Windows Python development

**Negative:**
- Slightly increased setup complexity (two Python versions to manage)
- Future contributors need to know to use `py -3.12` instead of `python`

**Neutral:**
- Will revisit when dbt-duckdb and other key dependencies officially support 3.14