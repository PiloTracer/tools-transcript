#!/usr/bin/env bash
# Smoke test — requires Docker. Uses synthetic tone in tests/fixtures.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

START="${ROOT}/bin/start.sh"

if ! command -v docker >/dev/null 2>&1; then
  printf 'SKIP: docker not available\n' >&2
  exit 0
fi

bash -n "$START"
if command -v shellcheck >/dev/null 2>&1; then
  shellcheck "$START" "${ROOT}/app/entrypoint.sh"
fi

"$START" validate
"$START" build

FIXTURE="${ROOT}/tests/fixtures/tone.wav"
mkdir -p "${ROOT}/sources" "${ROOT}/outputs"
cp "$FIXTURE" "${ROOT}/sources/smoke-tone.wav"

# Use tiny model for faster smoke if available; fall back to env default.
if "$START" transcribe smoke-tone.wav --model tiny; then
  :
else
  "$START" transcribe smoke-tone.wav
fi

test -f "${ROOT}/outputs/smoke-tone.txt"
test -f "${ROOT}/outputs/smoke-tone.srt"

printf 'smoke: PASS\n'
