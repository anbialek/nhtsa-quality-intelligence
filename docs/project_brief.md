# Project Brief: NHTSA Quality Intelligence Platform

## Problem Statement

In the automotive industry, the cost of defect leakage grows exponentially with every process stage it escapes — reaching its maximum when the defect reaches the end user. At that point, the cost is no longer only financial: it includes reputational damage to both the OEM and its suppliers, and in the worst case — when customer safety is at risk — it can permanently remove a brand from the market. This is why the automotive sector is among the most heavily regulated industries. Quality management systems based on IATF 16949, VDA 6.3, and AIAG standards exist precisely to enforce process standardization, non-conformance management, and reaction procedures, all verified through regular audits.

NHTSA — the U.S. National Highway Traffic Safety Administration — is a federal agency within the Department of Transportation responsible for road and vehicle safety. It investigates defects, manages recall campaigns, and publishes large volumes of public data on recalls, customer complaints, and safety investigations. This data is a valuable external source for benchmarking, supplier evaluation, and competitive intelligence in the automotive quality domain.

However, the raw data is not analytically ready. It suffers from inconsistent manufacturer naming, missing or duplicated values, lack of standardized component taxonomy, and absence of meaningful time-based aggregation. Without preprocessing, no actionable insight can be derived directly from NHTSA endpoints.

**The NHTSA Quality Intelligence Platform** (hereafter "the platform") solves this gap. It standardizes, cleans, and aggregates raw NHTSA data through a reproducible pipeline, producing analytics-ready datasets that support time-trend analysis, segmentation, and quality KPI calculation in the language familiar to automotive quality professionals.

## Target Users

The platform serves multiple stakeholder groups within an automotive organization, each with distinct questions:

* **Supplier Quality Management** — tracks supplier performance over time and compares vendors:
  *"Which suppliers require development? Which are the most reliable? Are they performing consistently across different OEMs?"*

* **Quality Engineering** — drills down into component-level trends:
  *"Which components generate the highest defect volumes? Which production processes should be re-audited or additionally protected? Where are extra inline quality controls needed?"*

* **Quality Management / Audit** — verifies the effectiveness of the quality system:
  *"Is our non-conformance management process robust enough? Is there a correlation between recall frequency and audit findings?"*

* **Directors and Senior Management** — benchmarks the company against peers:
  *"What are our quality-related economic losses? How do we perform relative to competitors?"*

## Value Proposition

The platform delivers a ready-to-use analytical layer over NHTSA public data, designed specifically for automotive quality professionals. Instead of browsing raw API responses or building ad-hoc Excel analyses, users get pre-aggregated datasets at the granularity required to compute industry-standard metrics: PPM rates, severity-weighted scores, complaint-to-recall lag, and supplier scorecards.

This shifts effort from data wrangling to decision-making, and allows quality teams to detect emerging issues earlier — before they escalate into formal recalls.

## Deliverables

The project delivers the following artifacts:

* **Data pipeline** built on a medallion architecture (Bronze → Silver → Gold) ensuring reproducibility, traceability, and incremental improvability
* **Gold-layer star schema** with dimension and fact tables ready for analytical queries
* **Streamlit dashboards** (one per business question) consuming the Gold layer
* **Test suite** with data quality checks across all layers
* **Documentation**: README, Architecture Decision Records (ADR), data dictionary, and architecture diagram
* **Public GitHub repository** containing all source code and documentation

## Business Questions Answered

1. **Complaint-to-recall lag** — What is the average time between the first customer complaint and the corresponding recall campaign?
2. **Component Pareto** — Which components, models, or manufacturers are the primary source of recalls?
3. **Top defects by severity** — What are the most common defects reported by end users, and how severe are they?
4. **Supplier risk ranking** — Which suppliers generate the highest number of recalls? Which require the most urgent development action?
5. **OEM benchmarking** — Which OEM demonstrates the strongest recall performance (lowest recall volume relative to fleet)?

> *Note: Some metrics (e.g. PPM) require vehicle production volumes as a denominator. Where NHTSA data does not provide this, the platform will document the limitation explicitly and use available proxies (e.g. complaint counts per recall campaign).*

## Success Metrics

Success is evaluated on three dimensions:

**Learning outcomes**
- Hands-on proficiency in dbt, DuckDB, Streamlit, and GitHub Actions
- Demonstrated understanding of medallion architecture and data modeling principles
- Workflow comparable to a mid-level analytics engineer

**Technical quality**
- Pipeline reproducible from scratch on a clean machine in under 30 minutes
- 100% of Gold-layer models covered by dbt tests (including business-rule tests, not only structural)
- All decisions documented as ADRs
- Zero hardcoded secrets, clean `.gitignore`, conventional commit history

**Demonstrable outcomes**
- Four functioning Streamlit dashboards, each tied to a business question
- Automated pipeline refresh (scheduled job)
- Public repository ready to share on LinkedIn and link in CV

## Scope & Out-of-Scope

**In scope**: Historical defect trend analysis, KPI computation, time-trend drill-down, supplier comparison, audit-oriented reporting — all based on publicly available NHTSA data for the U.S. market.

**Out of scope**:
- Predictive modeling of future recalls (no ML forecasting)
- Real-time / streaming ingestion (batch refresh only)
- Cloud deployment (local DuckDB-based architecture)
- Non-U.S. markets (Transport Canada, KBA, etc. — flagged as future work)
- Production-grade orchestration (cron used instead of Airflow/Dagster — migration path documented in ADR)
- Integration with internal OEM systems (SAP QM, supplier portals, etc.)

## Assumptions & Constraints

**Assumptions**
- NHTSA data is reliable and reflects real recall and complaint events
- Customer complaints (VOQ) are a leading indicator of latent quality defects
- Manufacturer and component names can be reasonably normalized despite source inconsistencies
- NHTSA public APIs remain available and stable throughout the project timeline

**Constraints**
- Single developer (one data analyst)
- Four-week project timeline
- Local development environment, no cloud budget
- Public data only — no access to internal OEM quality systems

## Domain Context

This project is shaped by several years of professional experience in the automotive industry, focused on process audit and quality management system implementation according to **IATF 16949**, **VDA 6.3**, and **AIAG** frameworks. Where applicable, the platform's metrics, terminology, and analytical framing follow conventions familiar to automotive quality professionals — including concepts such as escape rate, severity-weighted scoring, supplier scorecard logic, and the cost-of-poor-quality pyramid (the "rule of 10x" by detection stage).
