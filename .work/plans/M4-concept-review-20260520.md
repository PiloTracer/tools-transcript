# M4 concept review — 2026-05-20

Evidence for `@code-implementation complete` · iteration M4 GPU / performance.

---

## MOD-06 — AI amplification

## AI change risk summary
- AI-assisted: yes
- Boundaries crossed: 2 — `docker-compose.yml` (stack topology); `Dockerfile.cuda` (build/runtime image); docs only in README/DOCS (no app logic change)
- New cross-boundary deps: none — additive `transcript-gpu` service; same entrypoint/volumes; CPU `transcript` unchanged
- Test isolation: weak — command: `tests/smoke.sh` (**measured** exit 0, 2026-05-20) covers CPU path only; GPU image not built in CI
- Human architectural review: optional — reason: infra/docs milestone; no entrypoint or `bin/start.sh` changes; blast radius is optional GPU profile
- Blast radius: Wrong CUDA build breaks GPU profile only; CPU menu/`bin/start.sh` unchanged. Operators without NVIDIA who avoid `--profile gpu` unaffected. Risk: large CUDA image build failure or driver mismatch on owner GPU host.

## Recommendation
merge_with_conditions

## Conditions if merge_with_conditions
- Manual GPU transcribe on NVIDIA host before v1 GPU sign-off (**gap** — waived for complete; owner checklist)
- Post-push: GHA validate+smoke green on CPU path (**unknown** until push; **measured** locally)

---

## MOD-01 — Coupling audit

## Coupling audit summary
- Boundaries crossed: 2 — Compose/stack (`docker-compose.yml`); container build (`Dockerfile.cuda`)
- New or tighter dependencies: shared model volume + entrypoint between `transcript` and `transcript-gpu` — **assumption** intentional parity per ADR 005
- Shared persistence risks: `whisper-models` volume (pre-existing) — both services mount same path
- Coupling score: low (**assumption** — additive profile; CPU path independent)
- Human architectural review: optional — reason: no application source edits; DIRECTORY_MAP boundaries are build/compose only

## Recommendation
proceed_with_guards

## Guardrails if merging now
- Never make `gpu` profile the default in `bin/start.sh` without ADR revision
- Keep `transcript` (dev) as CI/smoke target

---

## MOD-03 — Cost model (abbreviated)

- New billable unit: second Docker image (CUDA devel base) — **estimated** larger disk and build time vs CPU image
- No recurring cloud cost (local tool)
- Recommendation: document build time in README (**done** M4-T3)

---

## MOD-04 — Ops headcount (abbreviated)

- New ops surface: NVIDIA driver + Container Toolkit on host — **assumption** owner-maintained
- No new on-call service; CLI batch jobs unchanged
- Recommendation: manual GPU verify documented as owner action

---

## MOD-05 — Modularity vs distribution (abbreviated)

- Chose additive Compose profile vs separate repo/service — aligns with ADR 005
- CPU modular monolith path preserved
- Recommendation: proceed
