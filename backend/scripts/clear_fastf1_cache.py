#!/usr/bin/env python3
import logging
import shutil
from pathlib import Path

CACHE_DIR = Path(__file__).resolve().parent.parent / "f1_cache"


def clear_cache(cache_dir: Path) -> None:
    if not cache_dir.exists():
        logging.info("Cache directory %s does not exist; nothing to clear.", cache_dir)
        return

    logging.info("Clearing FastF1 cache at %s", cache_dir)

    for child in cache_dir.iterdir():
        if child.is_dir():
            shutil.rmtree(child, ignore_errors=True)
        else:
            child.unlink(missing_ok=True)

    logging.info("FastF1 cache cleared at %s", cache_dir)


if __name__ == "__main__":
    logging.basicConfig(
        level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s"
    )
    clear_cache(CACHE_DIR)
