# Data Profiling: NHTSA Recall API

> **Update Log:**
> - 2026-06-22 — Initial exploration (Recall API only, ~50 sample records)

Document captures observations about the structure, quality, and patterns of the NHTSA Recall API. Findings shape transformation decisions in the silver and gold layers.

**Endpoint covered:** `https://api.nhtsa.gov/recalls/recallsByVehicle`

**Status:** Initial exploration phase. This will be expanded through systematic sampling in the next step.

---

## Response Structure

- Top-level keys: `Count`, `Message`, `results`
- `results` is an array of recall records
- Observed records per query: **3 to 20** for sampled vehicles (by `Model` and `ModelYear`)
- Open question: does the API return all matching records for a query?

## Field Glossary (In progress - to be completed based on NHTSA documentation)

### Identification fields
- `NHTSACampaignNumber` — recall campaign identifier; prefix indicates year (e.g. `"15V..."` = 2015)
- `NHTSAActionNumber` — likely a sub-identifier within a campaign (TBD: confirm `1 campaign : N actions` hypothesis)
- `Manufacturer` — full legal name of the **entity issuing the recall** — may be OEM, Tier-1 supplier, or component supplier (see Manufacturer Ambiguity below)

### Defect description
- `Component` — affected component
- `Summary` — free-text description; may indicate multiple affected models and production years
- `Consequence` — free-text safety implication
- `Remedy` — free-text repair description
- `Notes` — additional context information

### Severity flags
- `parkIt` (boolean) — vehicle should not be driven at all (user safety risk - the highest severity)
- `parkOutSide` (boolean) — vehicle should not be parked indoors (fire risk)
- `overTheAirUpdate` (boolean) — repair implemented through software update (no service visit needed)

### Dates
- `ReportReceivedDate` — date NHTSA received the report; format **DD/MM/YYYY** (verified, see below)

---

## Data Quality Observations

### 1. Manufacturer field includes suppliers, not just OEMs.
Sampled query `make=ford&model=f-150&modelYear=2015` returned recalls where `Manufacturer` field included **Tenneco Automotive** — a suspension/exhaust supplier, not an OEM.

**Implication:** `Manufacturer` reflects the entity *issuing* the recall campaign, which under US safety regulations can be either OEM or component supplier. For benchmarking analysis, `manufacturer_type` classification (`OEM | Tier-1 | Component Supplier | Other`) is needed in the Silver layer.

### 2. Long lag between vehicle production and recall
Some recalls were issued **11+ years** after the vehicle's production year. This means:
- Recalls reflect both factory defects (short lag) and field-emergent issues (long lag)
- "Complaint-to-recall lag" metric must distinguish from "production-to-recall lag"
- The Silver layer should include `years_in_service_at_recall` metric.

### 3. Date format verification — DD/MM/YYYY confirmed
Cross-field validation across 323 records from 49 different manufacturer x model x production year combinations:
- First component range: **1-31** → confirms format is DD/MM/YYYY
- Middle component range: **1-12** → confirms format is DD/MM/YYYY
- Year cross-check: 322 / 323 records (99.7%) had `NHTSACampaignNumber` prefix matching `ReportReceivedDate` year

**One mismatch identified:** `NHTSACampaignNumber: 20V675000` with `ReportReceivedDate: 12/03/2021`. Likely a recall amendment (campaign opened in 2020, date updated when scope expanded in 2021). **To be verified by inspecting Remedy/Summary text for "expands" / "amendment" keywords.**

**Implication for silver layer:**
- Date parsing: `pd.to_datetime(date_str, format="%d/%m/%Y")` 
- Cross-field test: `severity: warn` (not error) — 0.3% legitimate mismatches expected
- Possible derived field: `is_recall_amendment` based on text patterns in Remedy/Summary

### 4. Hierarchical structure: Campaign → Action - verified
**Verified:** A single `NHTSACampaignNumber` (campaign) can affect multiple models. The API returns one record per affected model when queried — campaign-level data (Manufacturer, Component, Summary, Consequence, Remedy, ReportReceivedDate, severity flags) is **identical across these records**; only `Model` field varies, echoing the query.

**Example:** Campaign `22V815000` (Volkswagen tire pressure system) returns identical records for queries of Jetta, Golf Alltrack, and GTI — all with the same Summary mentioning all three models.

**NHTSAActionNumber — likely a NHTSA Investigation reference (verified separately)**

The `NHTSAActionNumber` field is **optional** — not always present. When existing, observed values use prefixes like `RQ23007` (RQ = "Recall Query" / Investigation), suggesting this is a link to a prior NHTSA investigation that led to the recall, not an action-per-model identifier as initially hypothesized.

**Implication for gold layer modeling:** Star schema with single fact table - `fact_recall`.

Campaign-level analyses use `COUNT(DISTINCT NHTSACampaignNumber)`, and model-level analyses use `COUNT(*)` from fact table.

### 5. Sampling bias — US-market exposure
Recall counts are biased toward US-popular vehicles (based on a sample). Cross-OEM benchmarking requires normalization by US market fleet size; denominator data is required (source TBD).

### 6. Null handling — TBD on systematic sampling
No missing values observed in small sample, but:
- Sample size insufficient (~3-20 records per query)
- Empty strings / placeholder values may exist

**Hard constraints — `not_null` test, severity: error**
Records missing these fields are unusable and should fail the pipeline:
- `NHTSACampaignNumber` — primary business key (deduplication, joins)
- `NHTSAActionNumber` — natural key at action grain  
- `Manufacturer` — no analysis is meaningful without knowing the issuing entity
- `ReportReceivedDate` — required for all time-trend analyses

**Soft constraints — `not_null` test, severity: warning**
Records missing these fields are loaded but flagged for review. Null can be legitimate (e.g. fleet-wide recalls without specific model), but a null rate above threshold should trigger inspection

### 7. Severity flags — distribution unknown

All sampled records had a flag `false` in `parkIt`, `parkOutSide`, and `overTheAirUpdate`. This is expected — these flags mark rare extreme cases. In the next step: to find examples with `true` values (suspected: Tesla for OTA, EV fires for parkOutSide, Takata airbag campaigns for parkIt).

---

## Next Steps - Questions

1. Confirm hierarchy: does one `NHTSACampaignNumber` contain multiple `NHTSAActionNumber`?
2. Test for hard cap on records per query (try higher-recall scenarios)
3. Get a record with at least one severity flag = `true` to understand its semantic
4. Sample ~200 records across diverse manufacturers to compute null rates per field
5. Find or document an authoritative NHTSA API field glossary
6. Explore Complaints API (VOQ) — needed for complaint-to-recall lag metric