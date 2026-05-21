#!/usr/bin/env bash
# Smoke test — requires Docker. Synthetic audio + video fixtures in tests/fixtures.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

START="${ROOT}/bin/start.sh"
COMPOSE_FILE="${ROOT}/docker-compose.yml"
COMPOSE_PROJECT="${COMPOSE_PROJECT_NAME:-tools-transcript-dev}"
FIXTURES="${ROOT}/tests/fixtures"

read_env() {
  local key="$1" line k v
  local env_file="${ROOT}/.env"
  [[ -f "$env_file" ]] || return 1
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    k="${line%%=*}"
    v="${line#*=}"
    if [[ "$k" == "$key" ]]; then
      v="${v#"${v%%[![:space:]]*}"}"
      v="${v%"${v##*[![:space:]]}"}"
      printf '%s' "$v"
      return 0
    fi
  done <"$env_file"
  return 1
}

COMPOSE_PROJECT="$(read_env COMPOSE_PROJECT_NAME || true)"
COMPOSE_PROJECT="${COMPOSE_PROJECT:-tools-transcript-dev}"

if ! command -v docker >/dev/null 2>&1; then
  printf 'SKIP: docker not available\n' >&2
  exit 0
fi

compose_run_fixture() {
  docker compose \
    --project-directory "$ROOT" \
    -f "$COMPOSE_FILE" \
    -p "$COMPOSE_PROJECT" \
    --profile dev \
    run --rm \
    -v "${FIXTURES}:/fixtures:rw" \
    --entrypoint bash \
    transcript \
    -c "$1"
}

ensure_fixtures() {
  mkdir -p "$FIXTURES"
  if [[ -f "${FIXTURES}/tone.wav" && -f "${FIXTURES}/smoke-video.mp4" ]]; then
    return 0
  fi
  printf 'smoke: generating fixtures via ffmpeg in container...\n' >&2
  compose_run_fixture 'set -e
    if [[ ! -f /fixtures/tone.wav ]]; then
      ffmpeg -hide_banner -loglevel error -y \
        -f lavfi -i "sine=frequency=1000:duration=0.5" \
        -ar 16000 -ac 1 /fixtures/tone.wav
    fi
    if [[ ! -f /fixtures/smoke-video.mp4 ]]; then
      ffmpeg -hide_banner -loglevel error -y \
        -f lavfi -i "color=c=black:s=160x120:d=0.5:r=1" \
        -f lavfi -i "sine=frequency=1000:duration=0.5" \
        -shortest -c:v libx264 -pix_fmt yuv420p -c:a aac -ar 16000 \
        /fixtures/smoke-video.mp4
    fi
  '
  [[ -f "${FIXTURES}/tone.wav" && -f "${FIXTURES}/smoke-video.mp4" ]]
}

run_transcribe_smoke() {
  local base="$1"
  local model="${2:-}"
  if [[ -n "$model" ]]; then
    if "$START" transcribe "$base" --model "$model"; then
      return 0
    fi
    "$START" transcribe "$base"
  else
    "$START" transcribe "$base"
  fi
}

bash -n "$START"
bash -n "$0"
if command -v shellcheck >/dev/null 2>&1; then
  shellcheck "$START" "${ROOT}/app/entrypoint.sh" "$0"
fi

"$START" validate
ensure_fixtures
"$START" build

mkdir -p "${ROOT}/sources" "${ROOT}/outputs"
# Non-root container user (uid 1000) must write outputs; prior root-owned runs may block.
chmod a+rwx "${ROOT}/outputs" 2>/dev/null || true
if [[ -d "${ROOT}/outputs/.tmp" ]]; then
  docker compose \
    --project-directory "$ROOT" \
    -f "$COMPOSE_FILE" \
    -p "$COMPOSE_PROJECT" \
    --profile dev \
    run --rm --user root \
    --entrypoint rm \
    transcript \
    -rf /outputs/.tmp 2>/dev/null || true
fi

uid="$(
  docker compose \
    --project-directory "$ROOT" \
    -f "$COMPOSE_FILE" \
    -p "$COMPOSE_PROJECT" \
    --profile dev \
    run --rm --entrypoint id \
    transcript \
    -u
)"
if [[ "$uid" -eq 0 ]]; then
  printf 'smoke: FAIL container runs as root (uid=0)\n' >&2
  exit 1
fi
printf 'smoke: container uid=%s (non-root)\n' "$uid" >&2

# --- Audio smoke (FR3 path on wav) ---
cp "${FIXTURES}/tone.wav" "${ROOT}/sources/smoke-tone.wav"
rm -f "${ROOT}/outputs/smoke-tone.txt" "${ROOT}/outputs/smoke-tone.srt"
run_transcribe_smoke smoke-tone.wav tiny
test -f "${ROOT}/outputs/smoke-tone.txt"
test -f "${ROOT}/outputs/smoke-tone.srt"
printf 'smoke: audio PASS\n' >&2

# --- Video smoke (FR2 extract + transcribe) ---
cp "${FIXTURES}/smoke-video.mp4" "${ROOT}/sources/smoke-video.mp4"
rm -f "${ROOT}/outputs/smoke-video.txt" "${ROOT}/outputs/smoke-video.srt"
run_transcribe_smoke smoke-video.mp4 tiny
test -f "${ROOT}/outputs/smoke-video.txt"
test -f "${ROOT}/outputs/smoke-video.srt"
printf 'smoke: video PASS\n' >&2

printf 'smoke: PASS\n'
