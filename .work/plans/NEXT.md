# NEXT - planning backlog

**Updated:** 2026-05-20 (language feature close commit)

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
| **M3 operator UX (large files)** | 2026-05-20 — transcribe-all, size_bytes logging, 325MB checklist doc |
| **M4 GPU / performance** | 2026-05-20 — ADR 005, Dockerfile.cuda, compose profile gpu, README GPU section |

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

**Milestone verify:** **pass with gaps** 2026-05-20 — GHA green unverified until push

### M3 complete — tasks (2026-05-20)

| Task | Completed | Notes |
|------|-----------|-------|
| M3-T1 | 2026-05-20 | `transcribe-all` host + container; menu 11 |
| M3-T2 | 2026-05-20 | `size_bytes` on transcribe start; `duration_sec` on complete |
| M3-T3 | 2026-05-20 | `.work/plans/operations/20260520-m3-large-mp4-checklist.md`; README link |

**Concept evidence:** `.work/plans/M3-concept-review-20260520.md` (MOD-01, MOD-06)

**Milestone verify:** **pass with gaps** 2026-05-20 — validate+smoke exit 0; manual 2-file batch + owner 325MB sign-off deferred (HANDOFF)

### M4 complete — tasks (2026-05-20)

| Task | Completed | Notes |
|------|-----------|-------|
| M4-T1 | 2026-05-20 | ADR 005 — whisper.cpp CUDA; faster-whisper rejected |
| M4-T2 | 2026-05-20 | `Dockerfile.cuda`, compose `transcript-gpu` + profile `gpu` |
| M4-T3 | 2026-05-20 | README § GPU; DOCS_TECH_STACK §4 |

**Concept evidence:** `.work/plans/M4-concept-review-20260520.md` (MOD-01, MOD-03–06)

**Milestone verify:** **pass with gaps** 2026-05-20 — validate+smoke CPU exit 0; manual GPU transcribe + GHA push unverified (HANDOFF)

---

## Blocked on owner

| # | Item | Notes |
|---|------|-------|
| - | (none) | |

---

## Recommended next

| Priority | Item | Notes |
|----------|------|-------|
| **0** | `git push` + confirm GHA green | Publish language feature commit; rebuild image on hosts after pull |
| **1** | Owner: 325MB MP4 checklist | `.work/plans/operations/20260520-m3-large-mp4-checklist.md` |
| **2** | Owner: manual GPU transcribe | README § GPU on NVIDIA host; record in HANDOFF |
| **3** | `@plan-master revise` | Only if post-M4 scope changes (all plan milestones done) |

---

## Current iteration

**M4 complete** — see Done section above. Master plan M1–M4 implemented.

---

## Cross-LLM verification (M4)

- **Triggered:** no
- **Result:** skipped — infra/docs milestone; MOD reviews in `M4-concept-review-20260520.md`
- **Milestone verify:** **pass with gaps** 2026-05-20 — `@code-verify milestone`; `@code-implementation complete`
