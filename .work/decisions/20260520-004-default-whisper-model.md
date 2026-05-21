# ADR 004: Default Whisper model (medium)

**Status:** Decided  
**Date:** 2026-05-20

## Context

Founder notes recommend `small` for balance and `medium` as safest default for normal speech.

## Decision

- Default `WHISPER_MODEL=medium` in `.env.example`.
- Operator may override to `small`, `base`, `large`, etc.
- Models stored on named volume `whisper-models`, downloaded on first use if missing.

## Consequences

- First transcription after fresh volume may download ~1.5GB (medium).
- Slower but higher accuracy than `small`.

## Alternatives

| Model | Tradeoff |
|-------|----------|
| `small` | Faster, slightly lower accuracy — valid override |
| `large` | Best accuracy, impractical on CPU-only v1 |

## References

- ADR 001
