# tools-transcript - Foundation and architecture (proposal)

**Doc:** foundation **04** · **Created:** 2026-05-20  
**Status:** proposal — owner approval before broad implementation  
**Status gate:** foundation-complete when §14 checklist passes

**References:**

- Doc 01 — `20260520-01-tools-transcript-initial-scope.md`
- Doc 02 — *(skipped — no external integrations in v1)*
- Doc 03 — *(skipped — v1 self-contained)*
- `.cursorrules` · `DOCS_TECH_STACK.md` · `.ai/standards/20260520-*`

---

## 1. First principles (binding)

1. **Local-first:** User media never leaves the machine; `./sources` is gitignored.
2. **Isolation:** Every compose operation uses `-p COMPOSE_PROJECT_NAME` and repo-root `--project-directory` via `bin/start.sh`.
3. **Evidence over memory** (`.cursorrules` §5): verify whisper build flags and model paths from repo files, not chat memory.
4. **Minimal surface:** v1 is batch CLI, not a network service.

---

## 2. Bounded contexts (proposed)

| Context | Responsibility | Owns | Talks via |
|---------|----------------|------|-----------|
| `transcription` | ffmpeg extract, whisper-cli, output `.txt`/`.srt` | `/opt/whisper.cpp`, entrypoint scripts | host `./sources`, `./outputs` volumes only |
| `stack` (ops) | Compose lifecycle, isolation guards | `bin/start.sh`, `docker-compose.yml` | Docker Engine API |

No cross-context code imports in v1 — shell + container boundaries only.

Folder layout: `.ai/standards/20260520-DIRECTORY_MAP.md`.

---

## 3. Highest-risk path

**Transcription of user-owned media on local disk.**

| Step | Failure mode | Mitigation |
|------|--------------|------------|
| Read from `./sources` | Path traversal, overwriting system files | Mount at fixed `/sources`; entrypoint rejects paths outside mount |
| ffmpeg extract | Corrupt/huge files exhaust disk | Document disk headroom; optional max duration flag (future) |
| Model download | Supply-chain / wrong checksum | Pin model name in `.env`; download via upstream script in image build or init container |
| Stack teardown | Accidental impact on other projects | Scoped compose only; double-confirm on `nuke` |

---

## 4. Recommended technology stack

| Layer | Choice | ADR |
|-------|--------|-----|
| Transcription engine | whisper.cpp (ggml) | `20260520-001-whisper-engine.md` |
| Media prep | ffmpeg | same |
| Container base | Ubuntu 22.04 | `20260520-002-hosting-docker.md` |
| Orchestration | Docker Compose v2 | same |
| CLI / ops | POSIX shell (`bin/start.sh`) | `20260520-002-hosting-docker.md` |
| Frontend | n/a | — |
| Database | n/a | — |

---

## 5. Repository layout

```
tools-transcript/
├── bin/start.sh              # isolated stack manager
├── docker-compose.yml
├── Dockerfile
├── .env.example
├── app/
│   └── entrypoint.sh         # transcribe / extract / shell dispatch
├── sources/                  # gitignored — user media
├── outputs/                  # gitignored — transcripts
├── tests/
│   └── smoke.sh
├── .ai/
└── .work/
```

---

## 6. Security summary

Link `.ai/standards/20260520-threat-model.md` and `20260520-data-classification.md`.

- User media = **Confidential / user-owned** — never log file contents or commit to git.
- No inbound network required for transcription.
- Container runs as non-root where practical (post-M1 hardening).

---

## 7. Observability summary

Link `.ai/standards/20260520-observability-spec.md`.

- v1: structured stderr from entrypoint; exit codes 0/1/2 (success / usage / runtime error).
- No metrics server in v1.

---

## 8. Testing strategy

| Layer | Tooling | Gate |
|-------|---------|------|
| Stack config | `bin/start.sh validate` (`compose config -q`) | foundation / CI |
| Smoke | `tests/smoke.sh` — short synthetic audio | milestone verify |
| Shell | `shellcheck bin/start.sh app/entrypoint.sh` | task gate |

---

## 9. ADR register (§13)

| ADR | Topic | Status |
|-----|-------|--------|
| 001 | Whisper engine (whisper.cpp) | Decided |
| 002 | Hosting (local Docker Compose) | Decided |
| 003 | Tenancy (single-user CLI) | Decided |
| 004 | Default model (`medium`) | Decided |

**Rule:** ADR headers win on conflict with this register.

---

## 10. Foundation gate checklist (§14)

- [x] Docs 01 + 04 consistent
- [x] Registries seeded and reviewed
- [x] Transcription SPEC drafted
- [x] `DOCS_TECH_STACK.md` pins versions
- [x] Directory map updated
- [x] Docker proposal approved by owner (explicit in greenfield request)
- [x] No application Python/Go service required for **plan-master-ready**

---

## 11. Explicit deferrals

| Item | Deferred to | Owner |
|------|-------------|-------|
| GPU/CUDA image variant | plan-master M2+ | eng |
| faster-whisper backend | adjacency / ADR | owner |
| Web UI | out of v1 | owner |
| REST API + published ports | adjacency | owner |
