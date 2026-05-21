# NEXT - planning backlog

**Updated:** 2026-05-20

---

## Done

| Item | Artifact |
|------|----------|
| Agent OS bootstrap | `.work/` skeleton |
| Foundation P0–P6 | docs 01, 04; ADRs; SPEC; Docker stack; README |
| plan-master-ready | HANDOFF 2026-05-20 |
| Master plan (Draft) | `.work/plans/full/20260520-full-plan.md` |
| Dev stack menu + readiness | `bin/start.sh`, `app/entrypoint.sh` |
| Menu-first README (Linux) | `README.md` |
| Initial git push | `main` on GitHub |

---

## Blocked on owner

| # | Item | Notes |
|---|------|-------|
| 1 | Master plan **Approved** | Review Draft plan; set Status Approved or request revise |

---

## Recommended next

| Priority | Item | Notes |
|----------|------|-------|
| **0** | Review + **Approve** master plan | `.work/plans/full/20260520-full-plan.md` |
| **1** | `@code-implementation plan - M1` | After Approved (or HANDOFF waiver) |
| **2** | `@code-implementation start` | First task: M1-T1 pin whisper.cpp |

---

## Current iteration

```markdown
## Current iteration - M1: v1 hardening

**Milestone ref:** M1 · `.work/plans/full/20260520-full-plan.md` §19
**Status:** planning
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
| M1-T1 | Pin WHISPER_CPP_REF to tagged release | Dockerfile, DOCS_TECH_STACK.md | pending | Closes U1 |
| M1-T2 | MP4 fixture + video smoke test | tests/ | pending | Closes W1 |
| M1-T3 | SPEC amendment — network egress | SPEC amendment | pending | Closes W2 |
| M1-T4 | Non-root container user | Dockerfile, app/entrypoint.sh | pending | |
| M1-T5 | Fix stale foundation doc 01 | foundation doc 01 | pending | |
| M1-T6 | README large MP4 workflow | README.md | pending | |

### Acceptance criteria
- [ ] All M1 tasks done
- [ ] `./bin/start.sh validate` PASS
- [ ] `tests/smoke.sh` PASS (audio + video)
- [ ] W1–W4 waivers closed

### Validation steps
- [ ] Tests: `tests/smoke.sh`
- [ ] Lint: `shellcheck bin/start.sh app/entrypoint.sh`
- [ ] Type: n/a

### Owner blockers
- Master plan Status still **Draft** — approve before broad M1 execution

### Done this iteration
| Task | Completed | Notes |
|------|-----------|-------|
| (none) | | |
```
