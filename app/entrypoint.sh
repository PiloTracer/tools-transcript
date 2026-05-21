#!/usr/bin/env bash
# Container entrypoint — transcription CLI (see .work/features/transcription/20260520-SPEC.md)

set -euo pipefail

WHISPER_ROOT="/opt/whisper.cpp"
WHISPER_BIN="${WHISPER_ROOT}/build/bin/whisper-cli"
MODELS_DIR="${WHISPER_ROOT}/models"
SOURCES_DIR="/sources"
OUTPUTS_DIR="/outputs"
TMP_DIR="${OUTPUTS_DIR}/.tmp"

log() {
  printf '[transcript] %s\n' "$*" >&2
}

usage() {
  cat >&2 <<'EOF'
Usage:
  entrypoint.sh transcribe <file-in-sources> [--model NAME]
  entrypoint.sh ensure-model [--model NAME] [--force]
  entrypoint.sh check-model [--model NAME]
  entrypoint.sh shell
  entrypoint.sh help

Notes:
  Path is relative to ./sources (do not include a sources/ prefix).
  Quote filenames that contain spaces:
    transcribe "2026-05-20 14-03-30.mp4"

Environment:
  WHISPER_MODEL   Default model name (default: medium)
EOF
  exit 1
}

normalize_source_rel() {
  local rel="$1"
  rel="${rel#./}"
  rel="${rel#sources/}"
  printf '%s' "$rel"
}

resolve_source() {
  local rel="$1"
  local resolved

  rel="$(normalize_source_rel "$rel")"

  if [[ "$rel" == /* ]]; then
    printf 'absolute paths are not allowed: %s\n' "$rel" >&2
    exit 1
  fi

  if [[ "$rel" == *".."* ]]; then
    printf 'path traversal is not allowed: %s\n' "$rel" >&2
    exit 1
  fi

  resolved="${SOURCES_DIR}/${rel}"
  if [[ ! -f "$resolved" ]]; then
    printf 'source not found: %s (looked in /sources; quote paths with spaces)\n' "$rel" >&2
    exit 1
  fi

  printf '%s' "$resolved"
}

model_name() {
  local override="${1:-}"
  if [[ -n "$override" ]]; then
    printf '%s' "$override"
  else
    printf '%s' "${WHISPER_MODEL:-medium}"
  fi
}

model_path() {
  local name
  name="$(model_name "$1")"
  printf '%s/ggml-%s.bin' "$MODELS_DIR" "$name"
}

model_min_bytes() {
  case "$1" in
    tiny) printf '%s' 70000000 ;;
    base) printf '%s' 130000000 ;;
    small) printf '%s' 450000000 ;;
    medium) printf '%s' 1400000000 ;;
    large) printf '%s' 2900000000 ;;
    large-v1|large-v2|large-v3) printf '%s' 2900000000 ;;
    *) printf '%s' 1000000 ;;
  esac
}

model_file_size() {
  local path="$1"
  stat -c '%s' "$path" 2>/dev/null || stat -f '%z' "$path" 2>/dev/null || wc -c <"$path"
}

model_is_valid() {
  local name="$1"
  local path min size
  path="$(model_path "$name")"
  min="$(model_min_bytes "$name")"
  [[ -f "$path" ]] || return 1
  size="$(model_file_size "$path")"
  [[ "$size" -ge "$min" ]]
}

download_model() {
  local name="$1"
  log "downloading model: ${name}"
  if [[ ! -x "${WHISPER_ROOT}/models/download-ggml-model.sh" ]]; then
    printf 'model download script missing\n' >&2
    exit 2
  fi
  (cd "$WHISPER_ROOT" && bash ./models/download-ggml-model.sh "$name")
}

ensure_model() {
  local name path force="${2:-0}"
  name="$(model_name "${1:-}")"
  path="$(model_path "$name")"

  if [[ -f "$path" ]] && model_is_valid "$name" && [[ "$force" -eq 0 ]]; then
    log "model ready: ${name}"
    return 0
  fi

  if [[ -f "$path" ]]; then
    local size min
    size="$(model_file_size "$path")"
    min="$(model_min_bytes "$name")"
    log "model file incomplete (${size} bytes, need >= ${min}), re-downloading: ${name}"
    rm -f "$path"
  fi

  download_model "$name"

  if [[ ! -f "$path" ]] || ! model_is_valid "$name"; then
    printf 'model download incomplete or corrupt: %s\n' "$name" >&2
    printf 'hint: re-run ensure-model --force after a stable network connection\n' >&2
    exit 2
  fi

  log "model ready: ${name}"
}

parse_model_args() {
  local -n _override="$1"
  local -n _force="$2"
  _override=""
  _force=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --force) _force=1 ;;
      --model)
        shift
        _override="${1:-}"
        [[ -n "$_override" ]] || usage
        ;;
      *)
        if [[ -z "$_override" ]]; then
          _override="$1"
        else
          printf 'unknown option: %s\n' "$1" >&2
          exit 1
        fi
        ;;
    esac
    shift || true
  done
}

cmd_ensure_model() {
  local model_override="" force=0
  parse_model_args model_override force "$@"
  ensure_model "$model_override" "$force"
}

cmd_check_model() {
  local model_override="" force=0 name path size min
  parse_model_args model_override force "$@"
  name="$(model_name "$model_override")"
  path="$(model_path "$name")"

  if [[ ! -f "$path" ]]; then
    printf 'model missing: %s (%s)\n' "$name" "$path" >&2
    exit 1
  fi

  if ! model_is_valid "$name"; then
    size="$(model_file_size "$path")"
    min="$(model_min_bytes "$name")"
    printf 'model incomplete: %s (%s bytes, need >= %s)\n' "$name" "$size" "$min" >&2
    exit 2
  fi

  log "model ok: ${name}"
}

is_video() {
  case "${1##*.}" in
    mp4|mkv|webm|mov|avi|m4v|flv|wmv) return 0 ;;
    *) return 1 ;;
  esac
}

prepare_audio() {
  local source="$1"
  local base
  base="$(basename "$source")"
  base="${base%.*}"

  mkdir -p "$TMP_DIR"
  local wav="${TMP_DIR}/${base}.wav"

  if is_video "$source"; then
    log "extracting audio: $(basename "$source")"
    if ! ffmpeg -hide_banner -loglevel error -y -i "$source" -vn -ac 1 -ar 16000 -c:a pcm_s16le "$wav"; then
      printf 'audio extraction failed\n' >&2
      exit 2
    fi
    printf '%s' "$wav"
  else
    printf '%s' "$source"
  fi
}

cmd_transcribe() {
  local rel="${1:-}"
  shift || true
  local model_override=""
  local start_ts end_ts duration

  if [[ -z "$rel" ]]; then
    usage
  fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --model)
        shift
        model_override="${1:-}"
        [[ -n "$model_override" ]] || usage
        ;;
      *)
        printf 'unknown option: %s\n' "$1" >&2
        if [[ "$1" == *.* ]] || [[ "$rel" == *" "* ]]; then
          printf 'hint: quote the full filename, e.g. %s transcribe "my video.mp4"\n' \
            "entrypoint.sh" >&2
        fi
        exit 1
        ;;
    esac
    shift || true
  done

  local source audio model_path_out base
  rel="$(normalize_source_rel "$rel")"
  source="$(resolve_source "$rel")"
  base="$(basename "$rel")"
  base="${base%.*}"

  ensure_model "$model_override"
  model_path_out="$(model_path "$model_override")"
  audio="$(prepare_audio "$source")"

  mkdir -p "$OUTPUTS_DIR"
  log "transcribe start: ${base} model=$(model_name "$model_override")"

  start_ts=$(date +%s)
  if ! "$WHISPER_BIN" \
      -m "$model_path_out" \
      -f "$audio" \
      -of "${OUTPUTS_DIR}/${base}" \
      -otxt -osrt; then
    printf 'transcription failed\n' >&2
    if ! model_is_valid "$(model_name "$model_override")"; then
      printf 'hint: model file may be corrupt — run: %s ensure-model --force\n' \
        "entrypoint.sh" >&2
    fi
    exit 2
  fi
  end_ts=$(date +%s)
  duration=$((end_ts - start_ts))

  log "transcribe complete: ${base} duration_sec=${duration} exit_code=0"
}

cmd_shell() {
  exec /bin/bash
}

main() {
  local cmd="${1:-help}"
  shift || true

  case "$cmd" in
    transcribe) cmd_transcribe "$@" ;;
    ensure-model) cmd_ensure_model "$@" ;;
    check-model) cmd_check_model "$@" ;;
    shell) cmd_shell ;;
    help|-h|--help)
      usage
      ;;
    *)
      printf 'unknown command: %s\n' "$cmd" >&2
      exit 1
      ;;
  esac
}

main "$@"
