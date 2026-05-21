# tools-transcript

Local, offline transcription of video and audio using **whisper.cpp** in **Docker**. No cloud upload — everything runs on your machine.

**How you run it:** `./bin/start.sh` opens an **interactive menu** — that is the main interface.

**Platform:** `bin/start.sh` is written and tested for **Linux** (e.g. Ubuntu, Pop!_OS, Debian). It is not supported on macOS or Windows natively today; WSL2 on Windows may work if Docker runs inside Linux and you execute the script from that environment.

**Outputs:** `.txt` and `.srt` in `./outputs`  
**Privacy:** `./sources` and `./outputs` are gitignored; your media never belongs in this repo.

---

## Prerequisites

Install and verify these **before** `./bin/start.sh`:

| Requirement | Details |
|---------------|---------|
| **OS** | **Linux** (64-bit). Primary target for `bin/start.sh`. |
| **Docker Engine** | Installed and running (`docker info` succeeds). |
| **Docker Compose** | Compose **v2** plugin (`docker compose version` — not legacy `docker-compose` only). |
| **bash** | Version 4+ (`bash --version`). Menu and stack control are POSIX/bash scripts. |
| **User access to Docker** | Your user in the `docker` group, or root — otherwise menu **1** / **4** will fail. |
| **Disk space** | ~2 GB free for default model (`medium`) plus space for source media and outputs. |
| **RAM** | 4 GB minimum recommended; 8 GB+ for `medium` / large files on CPU. |
| **Network** | Required **once** to build the image and download the Whisper model; transcription itself is offline. |

**Optional but useful**

| Tool | Purpose |
|------|---------|
| `git` | Clone this repository |
| `shellcheck` | Lint `bin/start.sh` / `app/entrypoint.sh` (developers) |

**Quick checks**

```bash
uname -s          # expect Linux
docker info       # daemon reachable
docker compose version
bash --version
```

---

## Setup (once)

```bash
cp .env.example .env
chmod +x bin/start.sh
./bin/start.sh
```

The menu opens automatically. No arguments needed.

---

## First-time workflow (menu)

| Step | Menu choice | What happens |
|------|-------------|----------------|
| 1 | **1** — Start / prepare | Validates Docker, builds the image, downloads the default Whisper model (several minutes first time) |
| 2 | **4** — Status | Full checklist; wait for **READY TO TRANSCRIBE** |
| 3 | **10** — Transcribe | Paste a full path or type a filename (see below) |
| 4 | — | Open `./outputs/` for `.txt` and `.srt` |

### Transcribe (menu **10**)

When prompted for **Video/audio path or filename**, you can:

- Paste a **full path**, e.g. `/home/you/Videos/my talk.mp4` — the tool copies it into `./sources` and runs the job
- Enter a **filename** already in `./sources`, e.g. `recording.mp4`
- Press Enter on **Model** to use the default from `.env` (`medium`), or type e.g. `small` for a faster run

Filenames with spaces work when you paste the full path.

### Readiness banner (every menu screen)

At the top of the menu you will see **── Readiness ──** with checks for Docker, Compose, Image, Model, sources, and outputs:

- **▶ READY TO TRANSCRIBE** — safe to use menu **10**
- **▶ NOT READY** — follow the suggested step (usually menu **1** or **8**)

Press **`r`** to refresh after a long download or build.

---

## Day-to-day workflow (menu)

```bash
./bin/start.sh
```

| Goal | Menu |
|------|------|
| Check if you can transcribe | **4** Status (or read the readiness banner) |
| Transcribe a file | **10** |
| See files in `./sources` | **11** |
| Re-download / fix model | **8** (or **9** to verify only) |
| Stop compose project | **2** |

You usually **do not** need menu **1** again if the banner already shows **READY** and the model volume still has your `ggml-*.bin` file.

Results always appear in `./outputs/<basename>.txt` and `.srt`.

---

## Full menu reference

```bash
./bin/start.sh          # default — opens the menu
./bin/start.sh dev      # same
```

**Keys:** `0` exit · `r` refresh readiness · `?` help (CLI command list)

### Stack & resources

| # | Action |
|---|--------|
| **1** | Start / prepare — validate + build image + ensure model |
| **2** | Stop stack (keeps volumes, including models) |
| **3** | Restart — stop then start |
| **4** | **Status** — readiness checklist + READY / NOT READY verdict |
| **5** | Validate compose file |
| **6** | Build image only |
| **7** | Pull base images |
| **8** | Ensure model — download `WHISPER_MODEL` from `.env` |
| **9** | Check model — verify on volume, no download |

### Transcription

| # | Action |
|---|--------|
| **10** | **Transcribe** — paste path or filename; optional model override |
| **11** | List files in `./sources` |
| **12** | Shell inside the transcript container |

### Verify & ops

| # | Action |
|---|--------|
| **13** | Health check |
| **14** | Run smoke test (`tests/smoke.sh`) |
| **15** | Usage / URLs |
| **16** | Follow service logs |

### Danger zone

| # | Action |
|---|--------|
| **17** | Nuke — deletes project volumes including downloaded models (double confirm) |

---

## Where files live

| Location | Purpose |
|----------|---------|
| `./sources/` | Input media (menu **11** lists them; menu **10** can copy from elsewhere) |
| `./outputs/` | Transcripts: `<name>.txt`, `<name>.srt` |
| Docker volume `tools-transcript-models-<suffix>` | Cached Whisper models (survives menu **2** Stop) |
| `.env` | Isolation + default model — copy from `.env.example` |

**Note:** Between jobs, `docker compose ps` may show **no running containers** — that is normal. Transcription uses short-lived `compose run` containers; the **model stays on the named volume**, not inside a stopped container.

---

## Configuration (`.env`)

| Variable | Default | Meaning |
|----------|---------|---------|
| `COMPOSE_PROJECT_NAME` | `tools-transcript-dev` | Isolates this stack from other Docker projects on the host |
| `STACK_SUFFIX` | `dev` | Image and volume name suffix |
| `WHISPER_MODEL` | `medium` | Default for menu **8** / **10** — `tiny`, `small`, `medium`, `large`, … |

Change `COMPOSE_PROJECT_NAME` if you run more than one clone on the same machine.

---

## Model sizes

| Model | Disk (approx.) | Speed | Accuracy |
|-------|----------------|-------|----------|
| tiny | ~75 MB | Very fast | Low |
| small | ~500 MB | Fast | Good |
| medium | ~1.5 GB | Slower | Very good (**default**) |
| large | ~3 GB | Slowest | Best |

At menu **10**, enter a different model name when prompted, or change `WHISPER_MODEL` in `.env` and run menu **8**.

---

## Troubleshooting (menu-first)

| Symptom | Menu / action |
|---------|----------------|
| Banner says **NOT READY**, model missing | **1** Start, or **8** Ensure model |
| Status (**4**) shows model incomplete | **8**, choose force re-download when prompted |
| Transcribe (**10**) blocked | Fix readiness first (**4**), then **10** |
| No output files | Check `./outputs/`; job may still be running in the terminal |
| Wrong Docker project affected | Unique `COMPOSE_PROJECT_NAME` in `.env` |
| Start completely over | **17** Nuke (removes models too) |

Press **`r`** on the menu after **1** or **8** finishes to refresh the readiness banner.

---

## Stack isolation

| Mechanism | Purpose |
|-----------|---------|
| `COMPOSE_PROJECT_NAME` in `.env` | Unique compose project per clone |
| `bin/start.sh` | All compose commands use `-p` + `--project-directory` |
| Named volume `tools-transcript-models-<suffix>` | Model cache scoped to this project |

Starting or stopping this stack (menu **2**) does **not** affect other Docker projects on the host. v1 has no published host ports.

---

## Optional: CLI (without menu)

Same **Linux** host and Docker requirements as the menu. For scripts or automation, every menu action has a command equivalent:

```bash
./bin/start.sh start
./bin/start.sh status
./bin/start.sh transcribe "/path/to/video.mp4"
./bin/start.sh list-sources
./bin/start.sh ensure-model
./bin/start.sh check-model
./bin/start.sh help
```

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
