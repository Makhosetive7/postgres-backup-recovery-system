#!/usr/bin/env python3
"""
Phase 2 Day 10: Check that backups exist and are recent enough.

Exit 0 = healthy, 1 = unhealthy (for cron / CI).
"""

from __future__ import annotations

import os
import sys
from datetime import datetime, timezone
from pathlib import Path

from dotenv import load_dotenv

MAX_AGE_HOURS = 25
MIN_SIZE_BYTES = 102_400


def main() -> int:
    load_dotenv()
    backup_dir = Path(os.getenv("BACKUP_DIR", "./backups"))
    if not backup_dir.is_dir():
        print(f"UNHEALTHY: backup dir missing: {backup_dir}")
        return 1

    dumps = sorted(backup_dir.glob("backup_*.dump"), reverse=True)
    if not dumps:
        print("UNHEALTHY: no backup_*.dump files found")
        return 1

    latest = dumps[0]
    size = latest.stat().st_size
    mtime = datetime.fromtimestamp(latest.stat().st_mtime, tz=timezone.utc)
    age_hours = (datetime.now(timezone.utc) - mtime).total_seconds() / 3600

    issues: list[str] = []
    if age_hours > MAX_AGE_HOURS:
        issues.append(f"latest backup is {age_hours:.1f}h old (max {MAX_AGE_HOURS}h)")
    if size < MIN_SIZE_BYTES:
        issues.append(f"latest backup is only {size} bytes (min {MIN_SIZE_BYTES})")

    print(f"Latest: {latest.name}")
    print(f"Size:   {size:,} bytes")
    print(f"Age:    {age_hours:.1f} hours")

    if issues:
        for msg in issues:
            print(f"UNHEALTHY: {msg}")
        return 1

    print("HEALTHY")
    return 0


if __name__ == "__main__":
    sys.exit(main())
