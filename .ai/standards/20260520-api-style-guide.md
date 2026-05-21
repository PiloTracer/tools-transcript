# API style guide — tools-transcript

**Created:** 2026-05-20

v1 has **no HTTP API**. CLI contract is defined in `.work/features/transcription/20260520-SPEC.md` §7.

If a REST health or job API is added later:

- RFC 7807 Problem Details for errors
- `GET /health` for liveness
- Publish host port via `TRANSCRIPT_HOST_PORT=0` (ephemeral) per docker proposal
