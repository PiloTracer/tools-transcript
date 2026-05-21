# NEXT - planning backlog

**Updated:** 2026-05-20

---

## Done

| Item | Artifact |
|------|----------|
| Agent OS bootstrap | `.work/` skeleton |
| Foundation P0–P6 | docs 01, 04; ADRs; SPEC; Docker stack; README |
| plan-master-ready | HANDOFF 2026-05-20 |
| Master plan **Approved** | `.work/plans/full/20260520-full-plan.md` |
| Dev stack menu + readiness | `bin/start.sh`, `app/entrypoint.sh` |
| Menu-first README (Linux) | `README.md` |
| Initial git push | `main` on GitHub |
| **M1 v1 hardening** | 2026-05-20 — commit `1d052f0`; pin v1.8.4, MP4 smoke, non-root, SPEC-amendment-01, docs |

### M1 complete — tasks (2026-05-20)

| Task | Completed | Notes |
|------|-----------|-------|
| M1-T1 | 2026-05-20 | WHISPER_CPP_REF=v1.8.4; U1 closed |
| M1-T2 | 2026-05-20 | smoke-video.mp4; audio+video smoke PASS |
| M1-T3 | 2026-05-20 | SPEC-amendment-01; W2 closed |
| M1-T4 | 2026-05-20 | USER transcript:1000; smoke uid gate |
| M1-T5 | 2026-05-20 | foundation doc 01 updated |
| M1-T6 | 2026-05-20 | README large-MP4 section |

**Concept evidence:** `.work/plans/M1-concept-review-20260520.md` (MOD-01, MOD-06)

---

## Blocked on owner

| # | Item | Notes |
|---|------|-------|
| - | (none) | |

---

## Recommended next

| Priority | Item | Notes |
|----------|------|-------|
| **0** | `@code-implementation plan - M2` | CI and quality gates per master plan §19 |
| **1** | `git push` | Publish `main` (ahead of origin — includes M1 + bookend commits) |
| **2** | `@session-control start` | Fresh session for M2 |

---

## Current iteration

**M1 complete** — see Done section above. Next: `@code-implementation plan - M2`.

---

## Cross-LLM verification (M1)

- **Triggered:** no
- **Result:** skipped — single-model session; M1 is local CLI hardening (not high-risk module)
- **Milestone verify:** **pass with gaps** 2026-05-20 — `@code-verify milestone` (validate + smoke exit 0)
- **code-repair 2026-05-20:** master plan §19 M1 rows → done; shellcheck → M2 (not on host)
