# M1 concept review — 2026-05-20

Evidence for `@code-implementation complete` · iteration M1 v1 hardening.

---

## MOD-01 — Coupling audit

## Coupling audit summary
- Boundaries crossed: 4 — `bin/` (stack), `app/` (transcription), `tests/` (verification), `Dockerfile` (image)
- New or tighter dependencies: none — same compose + entrypoint contract; smoke calls `bin/start.sh` only
- Shared persistence risks: Docker volume `whisper-models` (read by transcribe; write on ensure-model) — single owner `app/entrypoint.sh`
- Coupling score: low (evidence: measured — DIRECTORY_MAP §Boundaries; single bounded context)
- Human architectural review: optional — reason: deliberate M1 cross-cutting hardening in one CLI monolith, no service split

## Recommendation
proceed_with_guards

## Guardrails if merging now
- Tests: `tests/smoke.sh` (audio + video + non-root uid check)
- Rollout: rebuild image after Dockerfile change; document outputs permission migration in README

---

## MOD-06 — AI amplification

## AI change risk summary
- AI-assisted: yes
- Boundaries crossed: 4 — `bin/`, `app/`, `tests/`, `Dockerfile`
- New cross-boundary deps: none material (entrypoint remains sole whisper/ffmpeg caller)
- Test isolation: ok — command: `tests/smoke.sh` (exit 0 on 2026-05-20 complete run)
- Human architectural review: optional — reason: small repo; automated smoke covers extract + transcribe + uid 1000
- Blast radius: Bad entrypoint or Dockerfile breaks all transcribe/ensure-model paths; `bin/start.sh` unchanged for compose wiring; host `outputs/` permissions can block writes after non-root upgrade (documented)

## Recommendation
merge_ok

## Conditions if merge_with_conditions
- Must add tests: satisfied by M1-T2 smoke (video path)
- Must split PR: n/a — cohesive M1 milestone
