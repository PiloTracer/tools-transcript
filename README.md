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
| **Network** | Required **once** to build the image and download the Whisper model; transcription itself is offline. See [Offline and air-gapped operation](#offline-and-air-gapped-operation). |

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

## Large video files (e.g. 300MB+ MP4)

You do **not** need a separate “extract audio” step. The container runs **ffmpeg** automatically for video formats (MP4, MKV, WebM, …), writes a temporary mono 16 kHz WAV under `./outputs/.tmp/`, then runs whisper. That temp file is removed when the job finishes.

### Before you start a long run

| Check | Why |
|-------|-----|
| Menu **4** shows **READY TO TRANSCRIBE** | Image built and model on the Docker volume |
| Enough **disk space** | Source file + temporary WAV (similar size order) + `.txt`/`.srt` + model cache (~1.5 GB for default `medium`) |
| Enough **RAM** | 8 GB+ recommended on CPU for `medium` and long files |
| **Model choice** | `medium` (default) — best accuracy; `small` — faster, less RAM; `tiny` — smoke/tests only |

### During the run

- **CPU time** scales with duration of the audio; a multi-hour MP4 can take hours on CPU — this is expected in v1 (no GPU image yet).
- **Network** is not used for your media; only the initial model download (menu **1** / **8**) needs connectivity. See SPEC amendment 01 for setup vs transcribe egress.
- Watch the terminal for `[transcript] extracting audio:` then `transcribe start:` — extraction failure exits before whisper runs.

### Paste path workflow (menu **10**)

For a file outside `./sources`, paste the **full path** (quoted if it contains spaces). The menu copies it into `./sources` and transcribes. Example sizes tested in development include ~325 MB MP4s.

### Batch transcribe (all files in `./sources`)

```bash
./bin/start.sh transcribe-all
# or menu 11
```

Processes every supported audio/video file in `./sources` **one after another**. Non-media files are skipped. If any file fails, the command exits non-zero after attempting the rest.

Logs include `size_bytes` at start and `duration_sec` on complete (no transcript text in logs).

**Owner sign-off for large MP4:** [`.work/plans/operations/20260520-m3-large-mp4-checklist.md`](.work/plans/operations/20260520-m3-large-mp4-checklist.md) — run once and record the date in HANDOFF.

### If transcribe fails with “not writable”

After upgrading to a non-root container, old root-owned files under `./outputs/.tmp` can block writes. Fix on the host:

```bash
chmod a+rwx outputs
docker compose -p "$(grep COMPOSE_PROJECT_NAME .env | cut -d= -f2)" \
  --profile dev run --rm --user root --entrypoint rm \
  transcript -rf /outputs/.tmp
```

Or remove `./outputs/.tmp` with sufficient permissions, then retry menu **10**.

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

## Offline and air-gapped operation

Transcription of files already in `./sources` does **not** use the network. You only need connectivity for **image build** and **model download** (one-time per machine, or prepared on another host).

### Two phases

| Phase | Needs network? | Commands |
|-------|----------------|----------|
| **Prepare** | Yes (or copy artifacts from another machine) | Menu **1** / **6** + **8**, or `./bin/start.sh start` |
| **Transcribe** | No | Menu **10** or `./bin/start.sh transcribe <file>` |

After prepare, menu **4** should show **READY TO TRANSCRIBE**. From then on, jobs only read `./sources` and write `./outputs` — no cloud upload.

### Ensure model (online prep)

Download the ggml weights into the Docker volume (not into the git repo):

```bash
# Default model from .env (WHISPER_MODEL, usually medium)
./bin/start.sh ensure-model

# Specific model
./bin/start.sh ensure-model --model small

# Fix incomplete download
./bin/start.sh ensure-model --force
```

Menu **8** / **9** are the same operations interactively. Models live on volume `tools-transcript-models-<STACK_SUFFIX>` (see `.env` `STACK_SUFFIX`, default `dev`).

### Model volume backup and restore

Use these commands on a machine that **already** has a working model. Replace `dev` with your `STACK_SUFFIX` from `.env`.

**Backup** (creates a tarball on the host):

```bash
STACK_SUFFIX=dev   # match .env
VOL="tools-transcript-models-${STACK_SUFFIX}"
docker run --rm \
  -v "${VOL}:/data:ro" \
  -v "$(pwd):/backup" \
  alpine \
  tar czf "/backup/whisper-models-${STACK_SUFFIX}.tar.gz" -C /data .
ls -lh "whisper-models-${STACK_SUFFIX}.tar.gz"
```

**Restore** on another host (volume must exist or be created by `ensure-model` / menu **1** once):

```bash
STACK_SUFFIX=dev
VOL="tools-transcript-models-${STACK_SUFFIX}"
docker volume create "${VOL}" 2>/dev/null || true
docker run --rm \
  -v "${VOL}:/data" \
  -v "$(pwd):/backup:ro" \
  alpine \
  sh -c "rm -rf /data/* && tar xzf /backup/whisper-models-${STACK_SUFFIX}.tar.gz -C /data"
./bin/start.sh check-model
```

### Fully air-gapped workflow

On a **connected** machine (same `STACK_SUFFIX` and model name you will use offline):

1. `cp .env.example .env` and set `WHISPER_MODEL` (e.g. `medium`).
2. `./bin/start.sh build`
3. `./bin/start.sh ensure-model`
4. Backup the model volume (above).
5. Save the Docker image: `docker save tools-transcript:dev -o tools-transcript-dev.tar` (image tag matches `STACK_SUFFIX` in `.env`).
6. Copy to the air-gapped host: `tools-transcript-dev.tar`, `whisper-models-dev.tar.gz`, this repo (no `./sources` / `./outputs` required).

On the **air-gapped** machine:

1. Install Docker + Compose; copy `.env` with the **same** `STACK_SUFFIX` and `WHISPER_MODEL`.
2. `docker load -i tools-transcript-dev.tar`
3. Restore the model volume (above).
4. `./bin/start.sh check-model` — must report model ok.
5. Transcribe with menu **10** or `./bin/start.sh transcribe <file>` — no further downloads.

**CI note:** GitHub Actions runs the same prepare path (build + smoke with `tiny`) on every PR; see `.github/workflows/ci.yml`.

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
shellcheck -S error bin/start.sh app/entrypoint.sh   # optional locally; required in CI
```

Pull requests run **GitHub Actions** (`.github/workflows/ci.yml`): validate, build, smoke (`tiny`), shellcheck.

---

## Further documentation

| Doc | Path |
|-----|------|
| Tech stack | `DOCS_TECH_STACK.md` |
| Initial scope | `.work/plans/foundation/20260520-01-tools-transcript-initial-scope.md` |
| Transcription SPEC | `.work/features/transcription/20260520-SPEC.md` |
| Planning backlog | `.work/plans/NEXT.md` |
