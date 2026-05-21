# ADR 002: Local Docker Compose hosting

**Status:** Decided  
**Date:** 2026-05-20

## Context

Operator runs multiple Docker projects on one Linux host. This stack must start/stop without affecting others and must mount `./sources` for local media.

## Decision

- **Docker Compose v2** with a single `transcript` service.
- **Isolation:** `COMPOSE_PROJECT_NAME` + `--project-directory` on every compose invocation via `bin/start.sh` (per `@dev-stack`).
- **CLI pattern:** `docker compose run --rm transcript …` for batch jobs; no long-lived published ports in v1.
- **Future ports:** when required, use host port `0` for ephemeral assignment documented in `.env.example`.

## Consequences

**Positive**

- Reproducible toolchain (ffmpeg + whisper.cpp versions pinned in Dockerfile).
- Clear boundary between host `./sources` and container `/sources`.

**Negative**

- Requires Docker on host; not bare-metal whisper install.

## References

- `.work/plans/operations/20260520-docker-compose-proposal.md`
- ADR 003 (tenancy)
