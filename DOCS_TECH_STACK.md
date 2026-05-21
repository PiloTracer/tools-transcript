# Technology stack — tools-transcript

**Status:** Foundation pins — update when implementation changes versions  
**Updated:** 2026-05-20 (M4 GPU)

---

## 1. Summary

| Layer | Choice | Version (pin) | Notes |
|-------|--------|---------------|-------|
| Transcription | whisper.cpp (ggml) | **v1.8.4** (`WHISPER_CPP_REF` Dockerfile ARG) | ADR 001 · M1-T1 |
| Media | ffmpeg | Ubuntu 22.04 package | Video → audio extract |
| Container OS | Ubuntu | 22.04 | Dockerfile `FROM` |
| GPU image (optional) | whisper.cpp + CUDA | **v1.8.4** in `Dockerfile.cuda` | ADR 005 · profile `gpu` |
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
| `bin/start.sh` | Isolated stack manager (CPU / profile `dev`) |
| `Dockerfile.cuda` | Optional NVIDIA CUDA build (`-DGGML_CUDA=1`) |
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
shellcheck -S error bin/start.sh app/entrypoint.sh
```

---

## 4. GPU (optional)

| Item | Value |
|------|-------|
| ADR | `20260520-005-gpu-strategy.md` |
| Compose profile | `gpu` |
| Service | `transcript-gpu` |
| Build | `Dockerfile.cuda` (`nvidia/cuda:12.6.3-devel-ubuntu22.04`, `GGML_CUDA=1`) |
| Host | NVIDIA driver + Container Toolkit |
| CI | **CPU only** — no GPU build in GHA |
| Operator docs | `README.md` § GPU acceleration |

---

## 5. CI/CD

| Item | Value |
|------|-------|
| Platform | **GitHub Actions** — `.github/workflows/ci.yml` |
| Triggers | `push` and `pull_request` to `main` |
| Runner | `ubuntu-latest` (Docker + Compose preinstalled) |
| Steps | `shellcheck -S error` → `validate` → `build` → `tests/smoke.sh` (`tiny` model) |
| Secrets | None required |
| Project isolation in CI | `COMPOSE_PROJECT_NAME=tools-transcript-ci`, `STACK_SUFFIX=ci` |
| Deploy targets | n/a — local tool |

---

## 6. Open decisions (track in `.work/plans/UNKNOWNS.md`)

| ID | Topic | Owner |
|----|-------|-------|
| U2 | GPU/CUDA image | **Resolved** — ADR 005 + `Dockerfile.cuda` / profile `gpu` |

---

## 7. ADR cross-reference

| ADR | Topic |
|-----|-------|
| 20260520-001 | whisper.cpp |
| 20260520-002 | Docker Compose |
| 20260520-003 | Single-user |
| 20260520-004 | Default model medium |
| 20260520-005 | GPU (whisper.cpp CUDA) |
