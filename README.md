# tools-transcript

Local, offline transcription of video and audio using **whisper.cpp** inside **Docker**. No cloud upload — processing stays on your machine.

**Outputs:** `.txt` and `.srt` in `./outputs`  
**Privacy:** `./sources` and `./outputs` are gitignored; your media never belongs in this repo.

---

## Prerequisites

- **Docker** (Engine + Compose v2 plugin), daemon running
- **bash** on the host (Linux or WSL)
- Enough disk space for the Whisper model (~1.5 GB for `medium`) and your media

---

## Quick start (about 3 commands)

```bash
cp .env.example .env
chmod +x bin/start.sh
./bin/start.sh
```

The **interactive menu** opens by default. Use:

| Menu | Action |
|------|--------|
| **1** | First-time setup — validate, build image, download model |
| **4** | **Status** — confirm everything is ready (Docker, image, model, folders) |
| **10** | **Transcribe** — type or paste a path to your file |

**Typical first session**

1. Menu **1** (Start) — one-time; downloads the default model into a Docker volume (can take several minutes).
2. Menu **4** (Status) — wait for **READY TO TRANSCRIBE**.
3. Menu **10** — paste e.g. `/home/you/Videos/talk.mp4` (copied into `./sources` automatically) or enter a filename already in `./sources`.
4. Find results in `./outputs/`.

**CLI equivalent (no menu)**

```bash
./bin/start.sh start
./bin/start.sh status          # exit 0 = ready
./bin/start.sh transcribe "/path/to/your video.mp4"
ls outputs/
```

Filenames with **spaces** must be quoted.

---

## Day-to-day use

You usually **do not** need to run `start` again if the image and model are already on disk.

```bash
./bin/start.sh                  # menu — check banner for READY / NOT READY
./bin/start.sh status           # full checklist + verdict
./bin/start.sh transcribe "my recording.mp4"
./bin/start.sh list-sources     # files waiting in ./sources
```

**Paste a full path** — the CLI copies the file into `./sources` then transcribes:

```bash
./bin/start.sh transcribe "/mnt/media/2026-05-20 14-03-30.mp4"
```

**Faster model** (less accurate):

```bash
./bin/start.sh transcribe clip.mp4 --model small
```

Or set `WHISPER_MODEL=small` in `.env` and run `./bin/start.sh ensure-model`.

---

## Where things live

| Path / resource | Purpose |
|-----------------|--------|
| `./sources/` | Input media (you copy or paste paths here) |
| `./outputs/` | Transcripts: `<basename>.txt`, `<basename>.srt` |
| Docker volume `tools-transcript-models-<suffix>` | Downloaded `ggml-*.bin` models (survives `stop`) |
| `.env` | Project isolation + default model (copy from `.env.example`) |

**Note:** `docker compose ps` may show **no running containers** between jobs — that is normal. Each transcription is a one-off `compose run` container; the **model stays on the named volume**, not inside a stopped container.

---

## Interactive menu

```bash
./bin/start.sh        # same as ./bin/start.sh dev
```

| Section | Items |
|---------|--------|
| Stack | 1 Start · 2 Stop · 3 Restart · 4 **Status** · 5–9 build / model |
| Transcribe | 10 Transcribe · 11 List sources · 12 Shell |
| Verify | 13 Health · 14 Smoke test · 15 Usage |
| Danger | 17 Nuke volumes (deletes models too) |

Press **`r`** to refresh readiness; **`?`** for all CLI commands.

---

## Command reference

| Command | Description |
|---------|-------------|
| `./bin/start.sh` | Interactive menu (default) |
| `./bin/start.sh start` | Validate + build image + ensure default model |
| `./bin/start.sh status` | Readiness checklist (Docker, image, model, dirs) |
| `./bin/start.sh transcribe <file>` | Transcribe; `<file>` = basename in `./sources` or full path |
| `./bin/start.sh check-model` | Verify model on volume (no download) |
| `./bin/start.sh ensure-model` | Download `WHISPER_MODEL` if missing |
| `./bin/start.sh ensure-model --force` | Re-download (fix incomplete download) |
| `./bin/start.sh list-sources` | List files in `./sources` |
| `./bin/start.sh shell` | Bash inside the transcript container |
| `./bin/start.sh stop` | `compose down` for this project only (keeps volumes) |
| `./bin/start.sh validate` | Validate `docker-compose.yml` |
| `./bin/start.sh help` | Full command list |

---

## Configuration (`.env`)

```bash
cp .env.example .env
```

| Variable | Default | Meaning |
|----------|---------|---------|
| `COMPOSE_PROJECT_NAME` | `tools-transcript-dev` | Isolates this stack from other Docker projects |
| `STACK_SUFFIX` | `dev` | Suffix for image/volume names |
| `WHISPER_MODEL` | `medium` | `tiny`, `small`, `medium`, `large`, … |

Change `COMPOSE_PROJECT_NAME` if you run multiple clones on one machine.

---

## Model sizes

| Model | Disk (approx.) | Speed | Accuracy |
|-------|----------------|-------|----------|
| tiny | ~75 MB | Very fast | Low |
| small | ~500 MB | Fast | Good |
| medium | ~1.5 GB | Slower | Very good (**default**) |
| large | ~3 GB | Slowest | Best |

First download of `medium` can take several minutes depending on your connection.

---

## Stack isolation

| Mechanism | Purpose |
|-----------|---------|
| `COMPOSE_PROJECT_NAME` in `.env` | Unique compose project per clone |
| `bin/start.sh` | Every `docker compose` uses `-p` + `--project-directory` |
| Named volume `tools-transcript-models-<suffix>` | Model cache scoped to this project |

Starting or stopping this stack does **not** affect other Docker projects on the host.

**Ports:** v1 is CLI-only — no host ports published.

---

## Troubleshooting

| Symptom | What to do |
|---------|------------|
| Status says **NOT READY** / model missing | `./bin/start.sh start` or `./bin/start.sh ensure-model` |
| Status says model **incomplete** | `./bin/start.sh ensure-model --force` |
| `transcribe` fails after a long run | Re-check model: `./bin/start.sh check-model` |
| Wrong stack affected | Confirm `.env` `COMPOSE_PROJECT_NAME` is unique |
| Start over (deletes models) | `./bin/start.sh nuke` — double confirmation |

---

## Verification (developers)

```bash
./bin/start.sh validate
tests/smoke.sh
shellcheck bin/start.sh app/entrypoint.sh   # optional
```

---

## Further documentation

| Doc | Path |
|-----|------|
| Tech stack | `DOCS_TECH_STACK.md` |
| Initial scope | `.work/plans/foundation/20260520-01-tools-transcript-initial-scope.md` |
| Transcription SPEC | `.work/features/transcription/20260520-SPEC.md` |
| Planning backlog | `.work/plans/NEXT.md` |
