# Observability spec — tools-transcript (v1)

**Created:** 2026-05-20

## Logging (entrypoint)

| Event | Level | Fields |
|-------|-------|--------|
| transcribe start | info | basename, model |
| extract audio | info | basename, format |
| transcribe complete | info | basename, duration_sec, exit_code |
| failure | error | stage, exit_code (no transcript body) |

## Metrics

None in v1 (batch CLI).

## Traces

None.

## Health

- `bin/start.sh validate` — compose config valid.
- Successful `tests/smoke.sh` — end-to-end path.

## Future (adjacency)

If HTTP health added: `GET /health` on ephemeral host port; document port via `bin/start.sh urls`.
