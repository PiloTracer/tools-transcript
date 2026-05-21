# Threat model — tools-transcript (v1)

**Created:** 2026-05-20 · **Scope:** local CLI transcription stack

---

## Assets

| Asset | Classification |
|-------|----------------|
| User media in `./sources` | Confidential — user-owned |
| Transcripts in `./outputs` | Confidential |
| Whisper models (volume) | Public upstream binaries |

## Trust boundaries

```text
[Operator host]
  ├── ./sources (gitignored)
  ├── bin/start.sh ──► Docker Engine
  └── transcript container ──► ffmpeg / whisper-cli
         └── writes ./outputs only
```

## Threats (STRIDE-lite)

| Threat | Mitigation |
|--------|------------|
| User media committed to git | `.gitignore` `sources/` + `outputs/` |
| Path traversal via malicious filename | Entrypoint R1 — paths under `/sources` only |
| Cross-stack Docker interference | ADR 002 — scoped compose project |
| Supply chain (model download) | Upstream whisper.cpp scripts; pin in Dockerfile |
| Log leakage of transcript | SPEC R5 |

## Out of scope v1

- Network-facing attack surface (no published ports).
- Multi-tenant data separation.
