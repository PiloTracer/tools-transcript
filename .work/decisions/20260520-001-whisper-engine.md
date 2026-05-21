# ADR 001: Whisper transcription engine (whisper.cpp)

**Status:** Decided  
**Date:** 2026-05-20  
**Deciders:** owner (greenfield)

## Context

Need free, offline, local transcription of large video/audio files (e.g. 325MB MP4) with good accuracy and no upload limits. Options considered: cloud APIs, faster-whisper, whisper.cpp, GUI tools.

## Decision

Use **whisper.cpp** (ggml) built inside the project Docker image, invoked via `whisper-cli`, with **ffmpeg** for optional audio extraction from video containers.

## Consequences

**Positive**

- No cloud dependency or API keys.
- Handles large files when audio is extracted first.
- Well-documented upstream; models downloadable via upstream scripts.

**Negative**

- CPU transcription can be slow vs GPU-accelerated faster-whisper.
- Image build compiles C++ on first `docker compose build`.

## Alternatives considered

| Alternative | Rejected because |
|-------------|------------------|
| faster-whisper | Extra Python/CUDA complexity for v1; defer to adjacency |
| Cloud (TurboScribe, etc.) | Privacy, size limits, upload required |
| Subtitle Edit GUI | Not containerized; out of v1 product scope |

## References

- Foundation doc 01: `.work/plans/foundation/20260520-01-tools-transcript-initial-scope.md`
- [whisper.cpp](https://github.com/ggml-org/whisper.cpp)
