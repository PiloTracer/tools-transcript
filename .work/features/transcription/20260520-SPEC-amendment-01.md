# SPEC amendment 01 — Network egress (transcription)

**Amends:** `.work/features/transcription/20260520-SPEC.md` §11 Security  
**Created:** 2026-05-20  
**Milestone:** M1-T3 · Closes HANDOFF waiver **W2**  
**Status:** Active

---

## 1. Problem

Foundation SPEC §11 states: *"No network egress required for core path."* That is true for **user media** (no cloud upload of `./sources` or `./outputs`), but it is **misleading** for operators because:

- **Model weights** are downloaded on first use via `ensure-model` / `bin/start.sh start`.
- **Docker image build** clones whisper.cpp from GitHub (`WHISPER_CPP_REF` in `Dockerfile`).

Without this amendment, readers assume the tool is fully offline at all times.

---

## 2. Clarification (replaces §11 network bullet for implementation)

| Path | User media leaves host? | Network required? | When |
|------|-------------------------|-------------------|------|
| **Transcribe** (ffmpeg + whisper-cli) | **No** — reads `./sources`, writes `./outputs` locally | **No** | Normal operation after model + image exist |
| **ensure-model** / first model fetch | **No** | **Yes** — downloads `ggml-*.bin` to Docker volume `tools-transcript-models-*` | First run per model, or after `nuke` |
| **Image build** (`docker compose build`) | **No** | **Yes** — `git clone` whisper.cpp per `Dockerfile` | Rebuild after pin or Dockerfile change |

**Core path (transcribe):** Processing stays on the local machine. Source files and transcripts are not transmitted to a transcription SaaS or third-party API.

**Permitted egress (setup only):**

1. **Model download** — `app/entrypoint.sh ensure-model` invokes whisper.cpp `models/download-ggml-model.sh` against the upstream model host (see `DOCS_TECH_STACK.md` for pinned tool versions).
2. **Build-time clone** — `Dockerfile` clones `https://github.com/ggml-org/whisper.cpp` at tag `WHISPER_CPP_REF`.

---

## 3. Supplemental rules (effective with base SPEC §5)

| ID | Rule |
|----|------|
| R7 | **Offline transcribe:** After the model file exists on the named volume and the image is built, `transcribe` must not require network access for reading user media or writing artifacts. |
| R8 | **Model download is explicit:** Operators use `bin/start.sh` menu **8** (Ensure model), menu **1** (Start), or `ensure-model` before expecting offline transcribe. Readiness menu **4** / **9** reports model-on-volume status. |
| R9 | **Air-gapped workflow:** Pre-build the image and pre-populate the model volume on a connected machine; copy the volume or use `ensure-model` once, then run transcribe with no outbound connections. Documented in README (M1-T6). |

---

## 4. Security posture (unchanged intent)

- User media in `./sources` and transcripts in `./outputs` remain **confidential local data** (base SPEC R5, R6).
- Network use is limited to **toolchain setup** (build + model weights), not to sending user recordings off-device.

---

## 5. Test implications

| Test | Network |
|------|---------|
| `tests/smoke.sh` | May use network on **build** and **tiny** model ensure; transcribe steps use local fixtures only |
| Manual large MP4 | **No** network required during transcribe if model already on volume |

---

## 6. Traceability

| Closes | Reference |
|--------|-----------|
| HANDOFF W2 | SPEC §11 network wording |
| M1-T3 | `.work/plans/full/20260520-full-plan.md` §19 |
| NFR1 | Offline-first operation for user data |
