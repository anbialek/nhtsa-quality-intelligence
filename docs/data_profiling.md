# Data Profiling: NHTSA Recall API

> **Update Log:**
> - 2026-06-22 — Initial exploration (Recall API only, ~50 sample records)
> - 2026-06-23 — Campaign/Action hierarchy verification; data model revision (single fact + dimensions); DD/MM/YYYY date format confirmation on 323-record sample
> - 2026-06-24 — Missing values verification using bigger sample, lack of hard cap confirmation, Complaints API Initial exploration
> - 2026-06-25 — Complete Complaints API systematic exploration; add cohort concentration analysis

---

Document captures observations about the structure, quality, and patterns of the NHTSA Recall API. Findings shape transformation decisions in the silver and gold layers.

**Endpoint covered:** `https://api.nhtsa.gov/recalls/recallsByVehicle`

**Status:** Systematic exploration phase.

---

## Response Structure

- Top-level keys: `Count`, `Message`, `results`
- `results` is an array of recall records
- Observed records per query: **3 to 20** for sampled vehicles (by `Model` and `ModelYear`)
- Open question: does the API return all matching records for a query?

## Field Glossary (In progress - to be completed based on NHTSA documentation)

### Identification fields
- `NHTSACampaignNumber` — recall campaign identifier; prefix indicates year (e.g. `"15V..."` = 2015)
- `NHTSAActionNumber` — likely references a NHTSA Investigation (`RQ`-prefixed) that led to the recall
- `Manufacturer` — full legal name of the **entity issuing the recall** — may be OEM, Tier-1 supplier, or component supplier (see Manufacturer Ambiguity below)

### Defect description
- `Component` — affected component
- `Summary` — free-text description; may indicate multiple affected models and production years
- `Consequence` — free-text safety implication
- `Remedy` — free-text repair description
- `Notes` — additional non-mandatory context information

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
Cross-field validation across 323 records from 49 different (make × model × year) combinations:
- First component range: **1-31** → confirms format is DD/MM/YYYY
- Middle component range: **1-12** → confirms format is DD/MM/YYYY
- Year cross-check: 322 / 323 records (99.7%) had `NHTSACampaignNumber` prefix matching `ReportReceivedDate` year

**One mismatch identified:** `NHTSACampaignNumber: 20V675000` with `ReportReceivedDate: 12/03/2021`. Likely a recall amendment (campaign opened in 2020, date updated when scope expanded in 2021). **To be verified by inspecting Remedy/Summary text for "expands" / "amendment" keywords.**

**Implication for the Silver layer:**
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

### 6. Null handling — verified
**Verified:** Missing values are present in the 323-record sample at varying rates per field. 
`NHTSAActionNumber` is missing in ~92.26% of records — confirming earlier observation that this field is optional. Its semantic role (likely a reference to prior NHTSA Investigation, based on observed RQ-prefixed values) requires NHTSA documentation verification. 
`Notes` is missing in ~12.38% which indicates a non-mandatory additional information.
Severity flags: `parkIt`, `parkOutSide`, and `overTheAirUpdate` show identical null rates with missing values **in the same records**.

**Critical fields:** No missing values observed for `NHTSACampaignNumber`, `Manufacturer`, `Make`, `Model`, `ModelYear`, `ReportReceivedDate`, `Component`, `Summary`, `Consequence`, `Remedy`. These align with the **hard constraint** classification proposed in earlier profiling.

**Architectural implication:** 
- Silver layer must enforce `not_null` tests for fields confirmed as 100% complete (campaign key, manufacturer, model, dates, narrative fields).
- `NHTSAActionNumber` to be loaded as nullable; only non-null values are used to populate `dim_investigation` (per earlier model decision).
- Records with null `parkIt`, `parkOutSide`, and `overTheAirUpdate` need further investigation — if confirmed coincident, may indicate older recall records pre-dating the introduction of these severity classifications by NHTSA. Worth checking the date distribution of records with missing severity flags.
- All severity-flag null records to be flagged with a derived column `has_complete_severity_classification` (boolean) for downstream filtering of severity-weighted analyses.

### 7. Severity flags — distribution unknown

All sampled records had a flag `false` in `parkIt`, `parkOutSide`, and `overTheAirUpdate`. This is expected — these flags mark rare extreme cases. In the next step: to find examples with `true` values (suspected: Tesla for OTA, EV fires for parkOutSide, Takata airbag campaigns for parkIt).

---

## Next Steps - Questions

1. Confirm hierarchy: does one `NHTSACampaignNumber` contain multiple `NHTSAActionNumber`? - verified
2. Test for hard cap on records per query (try higher-recall scenarios) - verified
3. Get a record with at least one severity flag = `true` to understand its semantic
4. Sample ~200 records across diverse manufacturers to compute null rates per field - verified
5. Find or document an authoritative NHTSA API field glossary
6. Explore Complaints API — needed for complaint-to-recall lag metric - done

---

# Data Profiling: NHTSA Complaints API

**Endpoint:** `https://api.nhtsa.gov/complaints/complaintsByVehicle`

**Status:** Initial exploration phase.

## Response Structure
- Top-level keys: `Count`, `Message`, `results` (matches `Recalls`)
- **Records are nested:** each result contains a `products` list (1+ products affected per complaint)
- Volume vastly higher than Recalls (for example, Honda Accord 2018: ~1767 and complaints vs ~6 recalls)

## Field Glossary

### Identification
- `odiNumber` — unique complaint ID (analogous to `NHTSACampaignNumber`)
- `vin` — affected vehicle VIN (absent in Recalls — Complaints reported by an individual vehicle, Recalls - by a campaign, so group of vehicles)
- `manufacturer` — OEM (suppliers do not appear, unlike `Recalls`)

### Severity flags (critical for quality scoring)
- `crash` (boolean)
- `fire` (boolean)  
- `numberOfInjuries` (integer)
- `numberOfDeaths` (integer)

### Dates — **FORMAT DIFFERS FROM RECALLS** !!!
- `dateOfIncident` — **MM/DD/YYYY** (US format, opposite to `Recalls` DD/MM/YYYY)
- `dateComplaintFiled` — **MM/DD/YYYY**
- Observed lag between incident and filing: 0 to even more than 6 months — metric worth tracking to investigate the delay

### Components
- `components` — affected components (free text, taxonomy similar to `Recalls` but verify alignment for cross-source JOINs)

### Nested products
- `products` — list of (`type`, `productYear`, `productMake`, `productModel`, `manufacturer`)

### Narrative
- `summary` — free-text user description; high variability, NLP would be required for systematic categorization

---

## Data Quality Observations

### 1. Date format inconsistency between Recalls and Complaints !
Recalls API uses European data formatting (DD/MM/YYYY); where Complaints API uses American one (MM/DD/YYYY). 
**Each endpoint must be parsed with its own format spec in the Silver layer.**

### 2. VIN normalization needed
Observed mixed case (`"1HGCV1F19JA"` vs `"1hgcv1f49ja"`). 
- NHTSA Complaints API returns **partial VIN**, without the serial number (positions 12-17) due to personal data security.
- The partial VIN still contains:
  - WMI (position 1-3): manufacturer identifier
  - VDS (position 4-8): vehicle descriptor (model/engine/body)
  - Check digit (position 9)
  - Model year (position 10)
  - Plant code (position 11)
- Silver layer: standardize to uppercase, validate **11-character length**, validate alphanumeric only.
- **Important**: identical 11-character VINs across multiple complaints do NOT indicate the same physical vehicle — they indicate the same manufacturer, model, year, and plant of production.

### 3. Nested products require flattening
Based on 10 (make × model × year) combinations: complaints with `len(products) > 1` exist:
- `Vehicle + Tire` (most common multi-product pattern)
- `Vehicle + Child Seat`  
- `Vehicle + Equipment`
- `2 × Vehicle` (multi-vehicle complaints)

**Conclusion:** `products` is not a single-element wrapper.
As the platform should focus on OEM production and filter `products` to `type = "Vehicle"` before linking to the complaint fact table, so:
- Project's business questions target automotive OEM quality intelligence
- Tire, Child Seat, and Equipment categories are not included (separate NHTSA regulatory tracks)

**Out-of-scope consequence:** complaints that are **primarily** about tires/child seats/equipment (where Vehicle is incidental context) will still appear as Vehicle-tagged complaints, but the actual root cause won't be tracked which is acceptable for project scope.

**Revisit condition:** if future analysis benefits from tire/equipment-level quality tracking, extend the Silver layer with bridge table.

### 4. Higher volume than Recalls
Complaints can exceed even more than 1000 per (make × model × year) combination. There is no hard cap.

## Cross-source Observations

### Component nomenclature alignment — TBD
Both endpoints use free-text `Component` / `components`. Need to compare distinct values across both sources to assess JOIN feasibility. Likely requires fuzzy matching or controlled vocabulary mapping in the Silver layer.

### Manufacturer scope
- `Recalls`: includes OEMs **and** suppliers (Tenneco, etc.)
- `Complaints`: only OEMs (consumer perspective — user doesn't know suppliers)

**Implication:** cross-source JOIN should filter `Recalls` to OEM-only when matching with `Complaints`

### Key metric enabled by combining sources
**Complaint-to-recall lag:** for each recall, count and time-distribute prior complaints on the same (`make`, `model`, `year`, `component`) — measures responsiveness of manufacturer to field signals.

## Hypotheses for Systematic Verification

1. **Pagination / hard cap on Complaints API** — given 1000+ records observed, suspect API may paginate
2. **VIN duplication patterns** — how concentrated are complaints across partial vin? Are some partial vin (same WMI+VDS+year+plant) reported more often than others?
3. **Component nomenclature alignment** — are `Recalls` and `Complaints` `Component` values possible to map?
4. **Severity field distributions** — fraction of complaints with crash/fire/injuries/deaths > 0