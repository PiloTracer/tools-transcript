# Technology stack — tools-transcript

**Status:** Foundation pins — update when implementation changes versions  
**Updated:** 2026-05-20

---

## 1. Summary

| Layer | Choice | Version (pin) | Notes |
|-------|--------|---------------|-------|
| Transcription | whisper.cpp (ggml) | master @ build (see Dockerfile ARG) | ADR 001 |
| Media | ffmpeg | Ubuntu 22.04 package | Video → audio extract |
| Container OS | Ubuntu | 22.04 | Dockerfile `FROM` |
| Orchestration | Docker Compose | v2 plugin | ADR 002 |
| Host CLI | POSIX bash | 5.x | `bin/start.sh` |
| Frontend | n/a | — | CLI only |
| Database | n/a | — | |
| Auth | n/a | — | Single-user local |

---

## 2. Repository layout

| Path | Purpose |
|------|---------|
| `app/` | Container entrypoint scripts |
| `bin/start.sh` | Isolated stack manager |
| `tests/` | Smoke tests |
| `sources/` | User media (gitignored) |
| `outputs/` | Artifacts (gitignored) |
| `.ai/` | Agent OS |
| `.work/` | Plans, SPECs, ADRs |

See `.ai/standards/20260520-DIRECTORY_MAP.md`.

---

## 3. Local development

| Item | Value |
|------|-------|
| Dev stack script | `bin/start.sh` |
| Compose file | `docker-compose.yml` |
| Test command | `tests/smoke.sh` |
| Lint | `shellcheck bin/start.sh app/entrypoint.sh` |
| Type check | n/a |

**Run tests in container policy:** All transcription and smoke tests invoke Docker via `bin/start.sh` — do not require host-installed whisper.cpp.

```bash
./bin/start.sh validate
./bin/start.sh build
tests/smoke.sh
shellcheck bin/start.sh app/entrypoint.sh
```

---

## 4. CI/CD

| Item | Status |
|------|--------|
| Platform | TBD (see UNKNOWNS U3) |
| Deploy targets | n/a — local tool |

---

## 5. Open decisions (track in `.work/plans/UNKNOWNS.md`)

| ID | Topic | Owner |
|----|-------|-------|
| U2 | GPU/CUDA image | eng |
| U3 | CI platform | eng |

---

## 6. ADR cross-reference

| ADR | Topic |
|-----|-------|
| 20260520-001 | whisper.cpp |
| 20260520-002 | Docker Compose |
| 20260520-003 | Single-user |
| 20260520-004 | Default model medium |
