# ASSUMPTIONS - planning registry

**Updated:** 2026-05-20 · **Maintained by:** plan-foundation / plan-master

| ID | Assumption | Label | Source | Notes |
|----|------------|-------|--------|-------|
| A1 | Primary user transcribes owned media locally on Linux | Inference | foundation doc 01 | |
| A2 | Dev workflow uses Docker via `bin/start.sh` | Confirmed | `DOCS_TECH_STACK.md`, ADR 002 | |
| A3 | whisper.cpp `master` branch builds cleanly on Ubuntu 22.04 | Confirmed | Docker build + `tests/smoke.sh` PASS | Verified 2026-05-20 |
| A4 | Default `medium` model acceptable for CPU-only v1 | Inference | ADR 004, founder intent | |
| A5 | `./sources` gitignore prevents accidental media commits | Confirmed | `.gitignore` | |

## Rejected

| ID | Assumption | Reason |
|----|------------|--------|
| A0 | Cloud transcription as v1 default | Conflicts with local/private requirement |

## Review log

| Date | Reviewer | Action |
|------|----------|--------|
| 2026-05-20 | plan-foundation / plan-master | certify pass with waivers |
