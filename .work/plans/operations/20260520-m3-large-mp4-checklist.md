# M3 manual sign-off — large MP4 (325MB class)

**Purpose:** Owner verification before v1 sign-off (master plan M3-T3, goal G1).  
**Not automated in CI** — run once on owner hardware and record completion date in `.work/context/HANDOFF.md`.

---

## Prerequisites

- [ ] Stack **READY TO TRANSCRIBE** (`./bin/start.sh status` or menu **4**)
- [ ] Default or chosen model present (`./bin/start.sh check-model`)
- [ ] Test MP4 available (~300MB+, representative of production use)
- [ ] Sufficient disk: source + temp WAV + outputs + model cache
- [ ] Sufficient RAM (8 GB+ recommended for `medium` on CPU)

---

## Single-file run

1. Copy or place the MP4 in `./sources` (basename only inside container).
2. Run: `./bin/start.sh transcribe "<filename>.mp4"` (quote spaces).
3. Confirm logs show:
   - [ ] `[transcript] extracting audio:` (if video)
   - [ ] `[transcript] transcribe start: … size_bytes=…` (no transcript text)
   - [ ] `[transcript] transcribe complete: … duration_sec=… exit_code=0`
4. Confirm outputs exist:
   - [ ] `./outputs/<basename>.txt` non-empty
   - [ ] `./outputs/<basename>.srt` non-empty

---

## Batch run (optional, if multiple files in `./sources`)

1. Ensure at least two media files in `./sources`.
2. Run: `./bin/start.sh transcribe-all`
3. Confirm:
   - [ ] Each file processed sequentially
   - [ ] `transcribe-all complete: exit_code=0` on success
   - [ ] Non-media files skipped with `skipping non-media` log line

---

## Sign-off record

| Field | Value |
|-------|--------|
| **Date completed** | YYYY-MM-DD |
| **Operator** | (name or role) |
| **File tested** | (basename only — no full paths with PII) |
| **Model** | e.g. `medium` |
| **duration_sec** | (from log) |
| **Result** | pass / fail |

After completion, add one line to HANDOFF **What this cycle produced** or resolve the M3 owner action in HANDOFF §Open owner actions.
