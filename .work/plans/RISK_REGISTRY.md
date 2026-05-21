# RISK_REGISTRY - planning registry

**Updated:** 2026-05-20

| ID | Risk | Category | Likelihood | Impact | Mitigation | Status | Owner |
|----|------|----------|------------|--------|------------|--------|-------|
| R1 | Scope creep before master plan | process | M | M | Foundation gates; no broad app code until implementation-ready | Open | eng |
| R2 | Agent marks gate pass without evidence | process / agent | M | M | `.cursorrules` Completion Gate | Mitigated | eng |
| R3 | User media committed to git | security | L | H | `sources/` + `outputs/` in `.gitignore` | Mitigated | eng |
| R4 | Docker compose affects foreign stacks | ops | L | H | `COMPOSE_PROJECT_NAME`, `bin/start.sh` scoping | Mitigated | eng |
| R5 | CPU transcription too slow for large MP4 | operational | M | M | Document ffmpeg extract; optional smaller model; GPU deferred | Accepted | owner |
| R6 | whisper.cpp upstream build break | technical | M | M | Pin ref in Dockerfile ARG; CI build | Open | eng |
| R7 | Model download fails offline | operational | M | M | `ensure-model` command; document pre-download | Open | eng |

## Review log

| Date | Reviewer | Action |
|------|----------|--------|
| 2026-05-20 | plan-foundation P1/P5 | Added isolation + media risks |
