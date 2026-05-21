# tools-transcript - Initial exploration and scope

**Doc:** foundation **01** (P0 product intent) · **Created:** 2026-05-20

## Audience and document purpose

| Layer | Audience | What they need |
|-------|----------|----------------|
| **Development** | Engineers | Boundaries, invariants, volume layout, Docker isolation, test strategy |
| **Shipped product** | End users (operator on own machine) | Simple CLI workflow: drop media in `./sources`, run transcribe, collect `.txt`/`.srt` in `./outputs` |

---

## Assumption ledger

### Founder intent (verbatim - P0 capture)

> Local, free, offline transcription of video/audio (e.g. 325MB MP4) using Whisper — no cloud upload, no size limits, good accuracy. Preferred engine: **whisper.cpp** (build locally, run via `whisper-cli` with ffmpeg for audio extraction when needed). Recommended models: `small` (balance) or `medium` (safer default). Alternative noted: faster-whisper for GPU-heavy setups (out of v1 scope unless ADR revises).
>
> **Infrastructure requirement:** Run on **Docker**, **totally isolated** from other stacks on the host. Use **random/ephemeral host port mappings only when a service must publish a port**; v1 is CLI-first (`docker compose run`) and needs **no published ports**. Starting/stopping this stack must **not affect** any other Docker project. Mount **`./sources`** read-only (or rw if extraction writes there) so the container can read user media. **`./sources` must never be committed** — user-owned media stays local.

### Confirmed facts (repository evidence)

- Repository name / workspace: `tools-transcript`.
- Agent OS bootstrap present: `.ai/`, `.work/`, `.cursorrules`.
- Application tree implemented: `app/entrypoint.sh`, `bin/start.sh`, `Dockerfile`, `docker-compose.yml`, `tests/smoke.sh`, `tests/fixtures/` (foundation stack delivered; v1 hardening tracked in master plan M1).
- Transcription SPEC + amendment: `.work/features/transcription/20260520-SPEC.md`, `20260520-SPEC-amendment-01.md`.

### Inferences (plausible, not proven)

- Primary user is a developer or power user on Linux (Pop!_OS / Ubuntu) transcribing owned media locally.
- v1 does not require a web UI, API server, database, or multi-tenant hosting.
- CPU-only transcription is acceptable for v1; GPU acceleration is a later optimization (see UNKNOWNS).

### Unknowns (decide with stakeholders)

| # | Unknown | Impact |
|---|---------|--------|
| 1 | Default Whisper model pin at first run (`small` vs `medium`) | Image size, first-run time, accuracy |
| 2 | GPU / CUDA support in Docker | Build complexity, performance |
| 3 | Whether to ship a thin Python wrapper vs shell-only CLI | Testability, dependency surface |

---

## Product scope (v1)

### In scope

- Docker Compose dev/runtime stack with **project-scoped isolation** (`COMPOSE_PROJECT_NAME`, `bin/start.sh`).
- Volume mounts: `./sources` (input media), `./outputs` (transcripts), persistent model cache volume.
- Container image building **whisper.cpp** + **ffmpeg**; transcribe to `.txt` and `.srt`.
- Optional audio extraction path (video → audio via ffmpeg before whisper).
- `.gitignore` excludes `./sources` (and `./outputs`) — no user media in git.
- Operator docs: README + stack manager (`bin/start.sh`).

### Out of scope (v1)

- Cloud upload services (TurboScribe, Notta, etc.).
- GUI (Subtitle Edit integration docs only — not bundled).
- faster-whisper, MacWhisper, online APIs.
- Multi-user SaaS, auth, billing, REST API (unless added in adjacency doc).
- Committing or scanning user media in CI.

---

## Non-functional expectations

| Area | Requirement |
|------|-------------|
| Privacy | All processing local; no outbound upload of `./sources` |
| Isolation | Compose project name + scoped networks; no bare `docker stop` on foreign containers |
| Portability | Linux host with Docker Engine + Compose v2 |
| Operability | `bin/start.sh start|stop|transcribe|shell` documented |
| Accuracy | Model selectable; default `medium` per founder note |

---

## Architecture directions (non-prescriptive - architecture foundation in doc 04)

- **Single bounded context:** `transcription` — ffmpeg prep + whisper.cpp execution + artifact writers.
- **CLI entry:** `bin/start.sh` wraps `docker compose run --rm` — no long-lived HTTP service in v1.
- **Stack layout:** one primary service `transcript`; models on named volume; host ports omitted unless a future health/metrics endpoint is added (then use `0:port` for ephemeral host binding).
- **Architecture foundation (doc 04):** `.work/plans/foundation/20260520-04-foundation-architecture.md` — **Not** the master implementation plan (`*-full-plan.md`).

---

## Traceability

| Artifact | Path |
|----------|------|
| Architecture foundation | `20260520-04-foundation-architecture.md` |
| Docker proposal | `.work/plans/operations/20260520-docker-compose-proposal.md` |
| Transcription SPEC | `.work/features/transcription/20260520-SPEC.md` |
| Registries | `ASSUMPTIONS.md`, `RISK_REGISTRY.md`, `UNKNOWNS.md` |
