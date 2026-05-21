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
| M1 iteration planned | `NEXT.md` § Current iteration |
| M1 v1 hardening (T1–T6) | 2026-05-20 — pin, smoke, SPEC amendment, non-root, docs |

---

## Blocked on owner

| # | Item | Notes |
|---|------|-------|
| - | (none) | |

---

## Recommended next

| Priority | Item | Notes |
|----------|------|-------|
| **0** | `@code-implementation complete` | Close M1 iteration block; attach MOD-06 evidence |
| **1** | `@code-verify milestone` | M1 formal gate after complete |
| **2** | `git push` | Publish `main` when auth ready (branch ahead of origin) |

---

## Current iteration - M1: v1 hardening

**Milestone ref:** M1 · `.work/plans/full/20260520-full-plan.md` §19  
**Status:** in-progress  
**Started:** 2026-05-20

### In scope

- Pin whisper.cpp ref (M1-T1)
- MP4 smoke test (M1-T2)
- SPEC amendment network wording (M1-T3)
- Non-root container (M1-T4)
- Doc fixes (M1-T5, M1-T6)

### Out of scope (explicit)

- CI (M2)
- GPU (M4)
- Batch transcribe (M3)

### Tasks

| ID | Description | Files | Status | Notes |
|----|-------------|-------|--------|-------|
| M1-T1 | Pin `WHISPER_CPP_REF` to tagged release; document in DOCS_TECH_STACK | `Dockerfile`, `DOCS_TECH_STACK.md` | done 2026-05-20 | `v1.8.4` · U1 closed · validate pass · rebuild not run |
| M1-T2 | Add minimal MP4 fixture + video path in smoke test | `tests/fixtures/`, `tests/smoke.sh` | done 2026-05-20 | video+audio smoke PASS · entrypoint parse_model_args fix |
| M1-T3 | SPEC amendment: clarify network egress (model download only, not user media) | `.work/features/transcription/20260520-SPEC-amendment-01.md` | done 2026-05-20 | Closes W2 · NFR1 |
| M1-T4 | Run transcript container as non-root user | `Dockerfile`, `app/entrypoint.sh`, `tests/smoke.sh` | done 2026-05-20 | uid 1000 · smoke PASS |
| M1-T5 | Fix stale facts in foundation doc 01 (app tree exists) | `.work/plans/foundation/20260520-01-tools-transcript-initial-scope.md` | done 2026-05-20 | |
| M1-T6 | README: large MP4 workflow (extract implicit, model choice, disk headroom) | `README.md` | done 2026-05-20 | G4, FR2 |

### Acceptance criteria

- [x] `WHISPER_CPP_REF` is a git tag, not `master`
- [x] Smoke test covers video extract + transcribe (tiny model)
- [x] SPEC amendment written; W2 closed
- [x] Container runs as non-root (`docker compose run … id` ≠ 0)
- [x] All M1 tasks done
- [x] `./bin/start.sh validate` PASS
- [x] `tests/smoke.sh` PASS (audio + video)
- [x] W1–W4 waivers closed (W3 optional customize remains n/a)

### Validation steps

- [x] `./bin/start.sh validate`
- [x] `tests/smoke.sh`
- [ ] `shellcheck bin/start.sh app/entrypoint.sh` (if installed)
- [ ] Type: n/a

### Owner blockers

- none

### Concept / NFR registry (this iteration)

| Concept id | Applies | Status | Evidence / trigger |
|------------|---------|--------|-------------------|
| MOD-01 | yes | pending | Edits cross `app/`, `bin/`, `tests/`, `Dockerfile` per DIRECTORY_MAP |
| MOD-02 | no | n/a | No new synchronous network hops |
| MOD-03 | no | n/a | No new billable infrastructure units |
| MOD-04 | no | n/a | Same single-operator local stack |
| MOD-05 | no | n/a | No service extraction |
| MOD-06 | yes | pending | AI-assisted implementation — required before **complete** |

### Cross-LLM verification

- **Triggered:** no
- **Result:** n/a

### Done this iteration

| Task | Completed | Notes |
|------|-----------|-------|
| M1-T1 | 2026-05-20 | WHISPER_CPP_REF=v1.8.4; SC1: scope ok; rebuild unverified this session |
| M1-T2 | 2026-05-20 | smoke-video.mp4 fixture; tests/smoke.sh audio+video; parse_model_args shift fix |
| M1-T3 | 2026-05-20 | SPEC-amendment-01 network egress; §11 pointer in base SPEC |
| M1-T4 | 2026-05-20 | USER transcript:1000; writable-dir checks; smoke uid gate |
| M1-T5 | 2026-05-20 | foundation doc 01 confirmed facts updated |
| M1-T6 | 2026-05-20 | README large MP4 section (extract, model, disk, permissions) |
