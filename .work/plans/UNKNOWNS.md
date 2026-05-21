# UNKNOWNS - planning registry

**Updated:** 2026-05-20 (M2-T3)

| ID | Question / blocker | Blocks | Owner | Status |
|----|-------------------|--------|-------|--------|
| U1 | Pin whisper.cpp to specific tag vs `master` at build | Reproducible builds | eng | **Resolved** 2026-05-20 — `WHISPER_CPP_REF=v1.8.4` (M1-T1) |
| U2 | GPU/CUDA Docker variant for faster-whisper or whisper.cpp CUDA | Performance roadmap | eng | Open |
| U3 | CI platform (GitHub Actions vs none) | Automated smoke on PR | eng | **Resolved** 2026-05-20 — `.github/workflows/ci.yml` (M2-T1, D5) |
| U4 | ~~plan-master integrity on foundation~~ | ~~certify~~ | eng | **Closed** 2026-05-20 |

## Review log

| Date | Reviewer | Action |
|------|----------|--------|
| 2026-05-20 | plan-foundation greenfield | Initial |
| 2026-05-20 | plan-master integrity + certify | U4 closed; plan-master-ready certified |
| 2026-05-20 | M2-T3 | U3 closed — GitHub Actions CI on push/PR to `main` |
