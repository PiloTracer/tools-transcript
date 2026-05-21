# SPEC amendment 02 — optional language

**Date:** 2026-05-20  
**Amends:** `.work/features/transcription/20260520-SPEC.md`

## Change

| ID | Rule |
|----|------|
| R7 | Optional spoken language via `--language CODE` (ISO, case-insensitive) or `WHISPER_LANGUAGE` env; passed to whisper-cli as `-l`. Aliases `english`→`en`, `spanish`→`es`. Value `auto` enables whisper auto-detect. When unset, whisper default applies (English). |

## CLI

```bash
./bin/start.sh transcribe file.mp4 --language es
./bin/start.sh transcribe-all --language EN
```

## Trace

- `app/entrypoint.sh` — `language_code`, `normalize_language_code`, `-l` on `whisper-cli`
- `bin/start.sh` — `--language` on transcribe / transcribe-all; menu **10** prompt
