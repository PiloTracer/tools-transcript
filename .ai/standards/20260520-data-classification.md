# Data classification — tools-transcript

**Created:** 2026-05-20

| Class | Examples | Storage | Git | Logs |
|-------|----------|---------|-----|------|
| **User media** | MP4, MP3 in `./sources` | Host disk, container mount | Never | Basename only |
| **Transcripts** | `.txt`, `.srt` in `./outputs` | Host disk | Never | Never full text |
| **Config** | `.env`, model name | Host | `.env` ignored; `.env.example` ok | Non-secret vars only |
| **Public** | Dockerfile, docs, SPECs | Git | Yes | n/a |

**Retention:** Operator-controlled; `bin/start.sh nuke` removes named volumes after double confirmation.
