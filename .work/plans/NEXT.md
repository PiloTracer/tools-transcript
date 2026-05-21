# NEXT - planning backlog

**Updated:** 2026-05-20 (M2 committed)

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
| **M2 CI and quality gates** | 2026-05-20 — `.github/workflows/ci.yml`, offline README, U3 closed, DOCS_TECH_STACK §4 |

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

### M2 complete — tasks (2026-05-20)

| Task | Completed | Notes |
|------|-----------|-------|
| M2-T1 | 2026-05-20 | `.github/workflows/ci.yml`; shellcheck -S error; local validate+smoke exit 0 |
| M2-T2 | 2026-05-20 | README § Offline and air-gapped operation |
| M2-T3 | 2026-05-20 | U3 resolved; DOCS_TECH_STACK §4 GitHub Actions |

**Concept evidence:** `.work/plans/M2-concept-review-20260520.md` (MOD-06)

**Milestone verify:** **pass with gaps** 2026-05-20 — `@code-verify milestone` (validate + smoke exit 0; GHA green unverified until push)

---

## Blocked on owner

| # | Item | Notes |
|---|------|-------|
| - | (none) | |

---

## Recommended next

| Priority | Item | Notes |
|----------|------|-------|
| **0** | `@code-implementation plan - M3` | Operator UX — batch transcribe, progress hints per master plan §19 |
| **1** | `git push` | Publish M2 commit; confirm GHA green on `main` |
| **2** | `@session-control start` | Fresh session for M3 |

---

## Current iteration

**M2 complete** — see Done section above. Next: `@code-implementation plan - M3`.

---

## Cross-LLM verification (M2)

- **Triggered:** no
- **Result:** skipped — CI/docs milestone; low coupling
- **Milestone verify:** **pass with gaps** 2026-05-20 — GHA first run pending push
