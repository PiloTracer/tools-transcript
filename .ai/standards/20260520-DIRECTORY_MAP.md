# Directory map — tools-transcript

**Created:** 2026-05-20 · **Status:** Binding

Aligned with foundation doc 04 bounded contexts.

---

## Repository tree

```
tools-transcript/
├── bin/
│   └── start.sh                 # Host stack manager (@dev-stack contract)
├── app/
│   └── entrypoint.sh            # Container CLI: transcribe | shell | ensure-model
├── docker-compose.yml           # Isolated compose project
├── Dockerfile                   # whisper.cpp + ffmpeg image
├── .env.example                 # Committable env template
├── .env                         # Local only — gitignored
├── sources/                     # User media — gitignored
├── outputs/                     # Transcripts — gitignored
├── tests/
│   └── smoke.sh                 # Post-build smoke test
├── DOCS_TECH_STACK.md
├── README.md
├── .cursorrules
├── .ai/                         # Agent OS (process)
└── .work/                       # Plans, SPECs, ADRs
```

---

## Boundaries

| Path | Context | May import / call |
|------|---------|-------------------|
| `bin/start.sh` | stack | Docker Compose CLI only |
| `app/entrypoint.sh` | transcription | ffmpeg, whisper-cli |
| `tests/` | verification | `bin/start.sh`, fixtures in repo (not `./sources`) |

---

## Git policy

| Path | Tracked |
|------|---------|
| `sources/` | **No** — entire directory gitignored |
| `outputs/` | **No** |
| `.env` | **No** |
| `tests/fixtures/` | Yes — synthetic tiny audio only |

---

## Docker mounts

| Host | Container | Mode |
|------|-----------|------|
| `./sources` | `/sources` | read-only recommended |
| `./outputs` | `/outputs` | read-write |
| volume `whisper-models` | `/opt/whisper.cpp/models` | read-write |
