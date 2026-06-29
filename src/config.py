"""
Central configuration for the NHTSA Quality Intelligence project.
"""

from pathlib import Path

# Project root (path resolution from this file)
PROJECT_ROOT = Path(__file__).parent.parent

# Data directories
DATA_DIR = PROJECT_ROOT / "data"
BRONZE_DIR = DATA_DIR / "bronze"
SILVER_DIR = DATA_DIR / "silver"
GOLD_DIR = DATA_DIR / "gold"

# API endpoints
RECALLS_URL = "https://api.nhtsa.gov/recalls/recallsByVehicle"
COMPLAINTS_URL = "https://api.nhtsa.gov/complaints/complaintsByVehicle"

# Ingestion parameters
HTTP_TIMEOUT_SECONDS = 30
HTTP_MAX_RETRIES = 3
HTTP_BACKOFF_FACTOR = 1.5

# Sample query targets (which vehicles to ingest)
# To be expanded; initial list for testing
MODELS = [
    ("toyota", "camry"),
    ("toyota", "rav4"),
    ("ford", "f-150"),
    ("honda", "civic"),
    ("honda", "accord"),
    ("chevrolet", "silverado"),
    ("nissan", "altima"),
    ("tesla", "model 3"),
    ("jeep", "grand cherokee"),
]

INGESTION_TARGETS = [
    (make, model, year)
    for make, model in MODELS
    for year in range(2020, 2026)
]