# Local development stack - proposal

**Status:** Approved (owner request 2026-05-20) · **Created:** 2026-05-20  
**Implemented:** `docker-compose.yml`, `Dockerfile`, `.env.example`, `bin/start.sh`

---

## 1. Goals

- **Isolated compose project** per clone: `COMPOSE_PROJECT_NAME=tools-transcript-${STACK_SUFFIX}`.
- **No impact on other stacks:** all lifecycle via `docker compose -p … --project-directory …`; no bare `docker stop/rm`.
- **Ephemeral host ports when needed:** v1 publishes **no ports** (CLI via `compose run`). If a future HTTP health endpoint is added, bind with `"0:<container_port>"` so Docker assigns a random host port.
- **Volume mapping:** `./sources` → `/sources`, `./outputs` → `/outputs`, named volume `whisper-models` for ggml weights.
- **Operator entry:** `bin/start.sh` (see `@dev-stack` contract).

---

## 2. Service table

| Service key | Image / build | Purpose | Host port |
|-------------|---------------|---------|-----------|
| `transcript` | `Dockerfile` (whisper.cpp + ffmpeg) | Batch transcription CLI | *(none in v1)* |

---

## 3. Volumes and networks

| Name | Mount | Notes |
|------|-------|-------|
| `./sources` | `/sources` | User media; **gitignored** |
| `./outputs` | `/outputs` | `.txt`, `.srt`, extracted audio |
| `whisper-models` | `/opt/whisper.cpp/models` | Persist downloaded ggml models |
| Network `tools-transcript-${STACK_SUFFIX}` | default network | Scoped name avoids cross-project attachment |

---

## 4. Dev entrypoint

- Script: `bin/start.sh`
- Key commands: `start`, `stop`, `status`, `build`, `shell`, `transcribe <file>`, `validate`, `nuke` (double confirm)
- Health: container exits 0 on successful transcribe; `validate` runs `compose config -q`

---

## 5. Environment variables (`.env.example`)

| Variable | Default | Role |
|----------|---------|------|
| `COMPOSE_PROJECT_NAME` | `tools-transcript-dev` | Isolation key |
| `STACK_SUFFIX` | `dev` | Container/network suffix |
| `WHISPER_MODEL` | `medium` | ggml model name (`small`, `medium`, …) |
| `PUBLIC_HOST` | `localhost` | URL hints if ports added later |
| `TRANSCRIPT_HOST_PORT` | *(empty)* | If set to `0` or a number, publish optional future HTTP port |

---

## 6. Approval

| Role | Approved | Date |
|------|----------|------|
| Owner | yes (explicit Docker + isolation request) | 2026-05-20 |
