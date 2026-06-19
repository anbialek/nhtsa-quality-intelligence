# NHTSA Quality Intelligence Platform

> Early-warning quality intelligence platform for automotive recalls and customer complaints. Medallion architecture on NHTSA public data — DuckDB, dbt, Streamlit.

## Project Goal

This project applies automotive quality management thinking (VDA 6.3, IATF 16949 mindset) to publicly available NHTSA data, building a data platform that surfaces early signals of quality issues before they become recalls.

## Business Questions

The platform answers four key questions:

1. **Manufacturer scorecard** — which manufacturers show the worst quality trajectory over the last 12 months?
2. **Component Pareto** — which components fail most frequently and how does this evolve?
3. **Complaint-to-recall lag** — how much time passes between first customer complaints and official recalls?
4. **Anomaly detection** — are there complaint spikes that may foreshadow future recalls?

## Architecture
[diagram]
Medallion architecture (Bronze → Silver → Gold) on local DuckDB.

## Tech Stack

- **Ingestion**: Python (requests, pydantic)
- **Storage**: DuckDB + Parquet files
- **Transformations**: dbt-duckdb
- **Orchestration**: cron + bash (planned migration path documented in ADR-XXX)
- **Visualization**: Streamlit
- **Quality**: dbt tests, custom data quality framework
- **CI/CD**: GitHub Actions

## Data Sources

- [NHTSA Recalls API](https://www.nhtsa.gov/nhtsa-datasets-and-apis)
- [NHTSA Complaints API](https://www.nhtsa.gov/nhtsa-datasets-and-apis)
- [NHTSA Investigations API](https://www.nhtsa.gov/nhtsa-datasets-and-apis)
- [vPIC VIN Decoder API](https://vpic.nhtsa.dot.gov/api/)

## Results

[dashboard's screenshots]

## How to Run

[TBD]

## Documentation

- [Project Brief](docs/project_brief.md) — problem framing
- [Architecture](docs/architecture.md) — system design
- [Data Profiling](docs/data_profiling.md) — quirks and findings
- [Architecture Decision Records](docs/adr/) — design choices and rationale
- [Learning Log](learning_log.md) — daily journal during the build

## Author

Anna Bialek — Process Production Engineer transitioning to Data Analytics. VDA 6.3 auditor with automotive quality background.

## 📄 License

MIT
