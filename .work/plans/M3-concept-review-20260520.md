# M3 concept review — 2026-05-20

Evidence for `@code-implementation complete` · iteration M3 Operator experience (large files).

---

## MOD-06 — AI amplification

## AI change risk summary
- AI-assisted: yes
- Boundaries crossed: 2 — `bin/start.sh` (stack / compose control); `app/entrypoint.sh` (transcription / whisper+ffmpeg)
- New cross-boundary deps: none — extends existing `docker compose run … transcript <cmd>` contract; host adds `transcribe-all` subcommand mirroring container `transcribe-all` (same pattern as `transcribe`)
- Test isolation: weak — command: `tests/smoke.sh` (exit 0, **measured** 2026-05-20) exercises single-file `transcribe` only; batch loop (`transcribe-all`) not covered in CI/smoke
- Human architectural review: optional — reason: two boundaries but shared v1 CLI pattern; no new network/DB/deployable; blast radius limited to local operator batch runs; **estimated** review effort under 30 min for coupling contract check
- Blast radius: If batch logic is wrong, operators may get partial `./outputs` (some files done, others not), misleading exit codes, or accidental long runs on every file in `./sources` (including large MP4s). No cloud egress, no multi-tenant data, no shared DB. Worst case is wasted CPU/time and confused stderr logs on the operator machine.

## Recommendation
merge_with_conditions

## Conditions if merge_with_conditions
- Must add tests: **gap** — no automated `transcribe-all` test; accept manual 2-file batch on safe `./sources` or document owner waiver in HANDOFF before v1 sign-off
- Must split PR: n/a — cohesive M3 milestone
- Post-merge: owner completes [325MB MP4 checklist](operations/20260520-m3-large-mp4-checklist.md) and records date in HANDOFF
- Post-push: confirm GHA `shellcheck` + smoke green on `main` (**unknown** until push; **measured** validate+smoke locally)

---

## MOD-01 — Coupling audit

## Coupling audit summary
- Boundaries crossed: 2 — `bin/start.sh` (stack / Docker Compose control plane); `app/entrypoint.sh` (transcription runtime)
- New or tighter dependencies: CLI subcommand contract only — host `dc run --rm transcript transcribe-all [--model NAME]` mirrors existing `transcribe` invocation; no shared libraries, imports, RPC, or events between contexts
- Shared persistence risks: `./sources` and `./outputs` volume mounts (pre-existing) — batch reads all media files in `/sources`; single writer for transcripts remains whisper in container; **assumption** no new cross-context file locking issues beyond v1 single-operator use
- Coupling score: low (evidence: **assumption** — coordinated release is “same git checkout + image rebuild”; interface is two-word CLI parity; failure modes stay local)
- Human architectural review: required — reason: AI-assisted diff crosses **>1** hard boundary per DIRECTORY_MAP; review is checklist-level (command name parity, exit codes, no transcription logic duplicated into `bin/`)

## Recommendation
proceed_with_guards

## Guardrails if merging now
- Tests: keep `tests/smoke.sh` green (**measured** exit 0, 2026-05-20); add manual or future smoke step for `transcribe-all` on 2 small fixtures
- Rollout: deploy host script and container image together from one commit; document that `transcribe-all` processes **all** of `./sources` (operator must not leave unintended large files in folder)
- Contract: preserve symmetric subcommand names (`transcribe` / `transcribe-all`) and stderr log prefix `[transcript]`; do not move ffmpeg/whisper logic into `bin/start.sh` (CONVENTIONS §8)
