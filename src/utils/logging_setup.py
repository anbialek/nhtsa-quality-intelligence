"""
Logging configuration for the project.
"""

import logging
import sys
from pathlib import Path
from datetime import datetime


def setup_logger(name: str, log_dir: Path | None = None) -> logging.Logger:
    """
    Configure a logger that writes both to console and to a daily log file.
    
    Args:
        name: Logger name (typically the module __name__)
        log_dir: Directory for log files. If None, uses ./logs/
    
    Returns:
        Configured logger instance
    """
    if log_dir is None:
        log_dir = Path("logs")
    
    log_dir.mkdir(parents = True, exist_ok = True)
    
    logger = logging.getLogger(name)
    logger.setLevel(logging.INFO)
    
    # Avoid duplicate handlers if called multiple times
    if logger.handlers:
        return logger
    
    formatter = logging.Formatter(
        "%(asctime)s | %(name)s | %(levelname)s | %(message)s"
    )
    
    # Console handler
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setFormatter(formatter)
    logger.addHandler(console_handler)
    
    # File handler (daily log file)
    log_file = log_dir / f"{datetime.now().strftime('%Y-%m-%d')}.log"
    file_handler = logging.FileHandler(log_file)
    file_handler.setFormatter(formatter)
    logger.addHandler(file_handler)
    
    return logger