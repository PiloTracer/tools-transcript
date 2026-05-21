# Code Conventions — tools-transcript

**Status:** Binding for implementation  
**Created:** 2026-05-20

Pairs with: foundation doc 04, `DOCS_TECH_STACK.md`, ADRs under `.work/decisions/`.

---

## 1. Language and tooling baselines

| Surface | Tooling | Notes |
|---------|---------|-------|
| Shell (`bin/`, `app/`) | `shellcheck` | Mandatory on shell changes |
| whisper.cpp | upstream build in Dockerfile | Pin commit or tag in Dockerfile |
| Tests | `tests/smoke.sh`, `bin/start.sh validate` | Run inside container policy per `.cursorrules` |

## 2. Type discipline

n/a for v1 (no typed application language). Future Python wrapper must use strict typing if added.

## 3. Naming

- Shell functions: `snake_case`; menu commands: lowercase kebab in CLI args.
- Dated docs: `YYYYMMDD-` prefix.
- Compose service key: `transcript` (singular).

## 4. Money, quantities, and regulated fields

n/a

## 5. Time

- Log timestamps UTC ISO-8601 in entrypoint when logging duration.

## 6. Errors

- Entrypoint uses exit codes documented in transcription SPEC.
- User-facing messages to stderr; stdout reserved for whisper output files on disk only.

## 7. Logging and secrets

- Never log transcript content or full media paths with PII beyond basename.
- No API keys in v1.

## 8. Module boundaries

- `app/entrypoint.sh` — container transcription logic only.
- `bin/start.sh` — host-side compose isolation only; no transcription logic duplicated.

## 9. Migrations

n/a — no database.

## 10. Performance budgets

| Class | Budget |
|-------|--------|
| Stack validate | < 5s |
| Smoke test audio | < 120s on CPU (assumption — measure on owner hardware) |

## 11. Review checklist (PR)

- [ ] `shellcheck` clean on touched scripts
- [ ] `bin/start.sh validate` passes
- [ ] No changes under `./sources` or `./outputs` tracked by git
