import json
from datetime import datetime, timezone
from pathlib import Path

import requests


# Configuration import
from src.config import (
    RECALLS_URL,
    BRONZE_DIR,
    INGESTION_TARGETS,
    HTTP_TIMEOUT_SECONDS
)

# Logging setup import
from src.utils.logging_setup import setup_logger
logger = setup_logger(__name__)


def fetch_recalls(make, model, year):
    '''
    Fetch recalls from NHTSA API for specific vehicle combination
    Return dictionary with keys: records, status_code, source_url, query_params
    '''
    params = {"make": make, "model": model, "modelYear": year}
    response = requests.get(RECALLS_URL, params=params, timeout=HTTP_TIMEOUT_SECONDS)
    response.raise_for_status()
    return {
        "records": response.json().get("results", []),
        "source_url": response.url,
        "query_params": params,
        "status_code": response.status_code
    }

def enrich_with_metadata(records, source_url, query_params, status_code):
    '''
    Enrich each record with metadata fields (prefixed with underscore to distinguish from source data fields, flatten)
    '''
    metadata_fields = {
        "_source_url": source_url,
        "_query_params": query_params,
        "_response_status": status_code,
        "_ingested_at": datetime.now(timezone.utc).isoformat(),
    }

    enriched = []

    for record in records:
        enriched_record = record.copy()
        enriched_record.update(metadata_fields) # flatten
        enriched.append(enriched_record)
    return enriched


def write_to_bronze(records, ingest_date):
    '''
    Write enriched records to bronze layer as JSONL
    '''
    folder = BRONZE_DIR / "recalls" / f"ingest_date={ingest_date}"
    folder.mkdir(parents=True, exist_ok=True)
    file_path = folder / "data.jsonl"

    with open(file_path, "a", encoding="utf-8") as f:
        for record in records:
            f.write(json.dumps(record) + "\n")

def main():
    logger.info("Start Recalls ingestion")

    ingest_date = datetime.now(timezone.utc).strftime("%Y-%m-%d")

    successful_queries = 0
    failed_queries = 0
    total_records = 0

    for make, model, year in INGESTION_TARGETS:
        try:
            response = fetch_recalls(make, model, year)
            records_with_metadata = enrich_with_metadata(
                records=response["records"],
                source_url=response["source_url"],
                query_params=response["query_params"],
                status_code=response["status_code"]
            )
            write_to_bronze(records_with_metadata, ingest_date)

            n_records = len(response["records"])
            successful_queries += 1
            total_records += n_records

            logger.info(f"OK: {make} {model} {year} - {n_records} records")
        except Exception as e:
            failed_queries += 1
            logger.error(f"FAILED: {make} {model} {year} - {e}", exc_info=True)
            # Don't crash whole pipeline, continue with next query

    logger.info(
        f"Run complete: {successful_queries} OK, {failed_queries} failed, "
        f"{total_records} records total"
    )

# Entry point
if __name__ == "__main__":
    main()