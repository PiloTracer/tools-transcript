#!/usr/bin/env bash
# tools-transcript stack manager — isolated Docker Compose control plane.
# See .ai/skills/dev-stack/skill.md and DOCS_TECH_STACK.md
#
# Reads from .env (never sources it): COMPOSE_PROJECT_NAME, STACK_SUFFIX,
# WHISPER_MODEL, PUBLIC_HOST, TRANSCRIPT_HOST_PORT.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
COMPOSE_ABS="${REPO_ROOT}/docker-compose.yml"
PROFILE="${COMPOSE_PROFILE:-dev}"
DEFAULT_PROJECT="tools-transcript-dev"
DEFAULT_MODEL="medium"

# Colors (empty when not a TTY)
C_RESET=""
C_BOLD=""
C_DIM=""
C_OK=""
C_WARN=""
C_ERR=""
C_SEC=""

read_dotenv_value() {
  local key="$1"
  local line k v
  local env_file="${REPO_ROOT}/.env"
  [[ -f "$env_file" ]] || return 1
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    k="${line%%=*}"
    v="${line#*=}"
    k="${k#"${k%%[![:space:]]*}"}"
    k="${k%"${k##*[![:space:]]}"}"
    v="${v#"${v%%[![:space:]]*}"}"
    v="${v%"${v##*[![:space:]]}"}"
    if [[ "$k" == "$key" ]]; then
      if [[ "$v" == \"*\" && "$v" == *\" ]]; then
        v="${v#\"}"
        v="${v%\"}"
      elif [[ "$v" == \'*\' && "$v" == *\' ]]; then
        v="${v#\'}"
        v="${v%\'}"
      fi
      printf '%s' "$v"
      return 0
    fi
  done <"$env_file"
  return 1
}

init_colors() {
  if [[ -t 2 ]] && command -v tput >/dev/null 2>&1; then
    C_RESET="$(tput sgr0 2>/dev/null || true)"
    C_BOLD="$(tput bold 2>/dev/null || true)"
    C_DIM="$(tput dim 2>/dev/null || true)"
    C_OK="$(tput setaf 2 2>/dev/null || true)"
    C_WARN="$(tput setaf 3 2>/dev/null || true)"
    C_ERR="$(tput setaf 1 2>/dev/null || true)"
    C_SEC="$(tput setaf 6 2>/dev/null || true)"
  fi
}

load_env() {
  COMPOSE_PROJECT_NAME="$(read_dotenv_value COMPOSE_PROJECT_NAME || true)"
  STACK_SUFFIX="$(read_dotenv_value STACK_SUFFIX || true)"
  PUBLIC_HOST="$(read_dotenv_value PUBLIC_HOST || true)"
  TRANSCRIPT_HOST_PORT="$(read_dotenv_value TRANSCRIPT_HOST_PORT || true)"
  WHISPER_MODEL="$(read_dotenv_value WHISPER_MODEL || true)"
  WHISPER_LANGUAGE="$(read_dotenv_value WHISPER_LANGUAGE || true)"
  COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-$DEFAULT_PROJECT}"
  STACK_SUFFIX="${STACK_SUFFIX:-dev}"
  PUBLIC_HOST="${PUBLIC_HOST:-localhost}"
  WHISPER_MODEL="${WHISPER_MODEL:-$DEFAULT_MODEL}"
}

default_model() {
  printf '%s' "$WHISPER_MODEL"
}

default_language_hint() {
  if [[ -n "${WHISPER_LANGUAGE:-}" ]]; then
    printf '%s' "$WHISPER_LANGUAGE"
  else
    printf '%s' 'whisper default (en)'
  fi
}

transcript_run_env_flags() {
  local -a flags=()
  if [[ -n "${WHISPER_LANGUAGE:-}" ]]; then
    flags+=(-e "WHISPER_LANGUAGE=${WHISPER_LANGUAGE}")
  fi
  if [[ ${#flags[@]} -gt 0 ]]; then
    printf '%s\n' "${flags[@]}"
  fi
}

run_transcript() {
  local -a env_flags=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && env_flags+=("$line")
  done < <(transcript_run_env_flags)
  if [[ ${#env_flags[@]} -gt 0 ]]; then
    dc run --rm "${env_flags[@]}" transcript "$@"
  else
    dc run --rm transcript "$@"
  fi
}

require_compose_file() {
  if [[ ! -f "$COMPOSE_ABS" ]]; then
    printf '%sERROR:%s compose file not found: %s\n' "$C_ERR" "$C_RESET" "$COMPOSE_ABS" >&2
    exit 1
  fi
}

require_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    printf '%sERROR:%s docker not found in PATH\n' "$C_ERR" "$C_RESET" >&2
    exit 1
  fi
  if ! docker info >/dev/null 2>&1; then
    printf '%sERROR:%s docker daemon not reachable (is Docker running?)\n' "$C_ERR" "$C_RESET" >&2
    exit 1
  fi
}

_compose_invoke() {
  docker compose \
    --project-directory "$REPO_ROOT" \
    -f "$COMPOSE_ABS" \
    -p "$COMPOSE_PROJECT_NAME" \
    --profile "$PROFILE" \
    "$@"
}

dc() {
  _compose_invoke "$@"
}

quiet_dc() {
  local log
  log="$(mktemp "${TMPDIR:-/tmp}/startsh.XXXXXX")"
  if dc "$@" >"$log" 2>&1; then
    rm -f "$log"
    return 0
  fi
  cat "$log" >&2
  rm -f "$log"
  return 1
}

menu_read() {
  local prompt="$1"
  local var="$2"
  if [[ -r /dev/tty ]]; then
    printf '%s' "$prompt" >/dev/tty
    IFS= read -r "$var" </dev/tty || return 1
  else
    printf '%s' "$prompt"
    IFS= read -r "$var" || return 1
  fi
}

ensure_workspace_dirs() {
  mkdir -p "${REPO_ROOT}/sources" "${REPO_ROOT}/outputs"
}

print_banner() {
  printf '\n%s=== tools-transcript stack ===%s\n' "$C_BOLD" "$C_RESET" >&2
  printf 'Project:  %s\n' "$COMPOSE_PROJECT_NAME" >&2
  printf 'Suffix:   %s\n' "$STACK_SUFFIX" >&2
  printf 'Model:    %s (WHISPER_MODEL)\n' "$(default_model)" >&2
  printf 'Root:     %s\n' "$REPO_ROOT" >&2
}

stack_counts() {
  local running total
  running="$(dc ps -q --status running 2>/dev/null | wc -l | tr -d ' ')"
  total="$(dc ps -aq 2>/dev/null | wc -l | tr -d ' ')"
  running="${running:-0}"
  total="${total:-0}"
  printf '%s/%s' "$running" "$total"
}

image_ref() {
  printf 'tools-transcript:%s' "$STACK_SUFFIX"
}

image_exists() {
  docker image inspect "$(image_ref)" >/dev/null 2>&1
}

model_volume_name() {
  printf 'tools-transcript-models-%s' "$STACK_SUFFIX"
}

model_min_bytes() {
  case "$1" in
    tiny) printf '70000000' ;;
    base) printf '130000000' ;;
    small) printf '450000000' ;;
    medium) printf '1400000000' ;;
    large) printf '2900000000' ;;
    large-v1|large-v2|large-v3) printf '2900000000' ;;
    *) printf '1000000' ;;
  esac
}

volume_exists() {
  docker volume inspect "$(model_volume_name)" >/dev/null 2>&1
}

# Model file size on the named Docker volume (persists across compose run --rm).
query_model_bytes() {
  local model="${1:-$(default_model)}"
  local vol out
  vol="$(model_volume_name)"
  if ! volume_exists; then
    printf '0'
    return 1
  fi
  out="$(docker run --rm -v "${vol}:/models:ro" alpine sh -c \
    "f=/models/ggml-${model}.bin; if test -f \"\$f\"; then stat -c '%s' \"\$f\"; else echo 0; fi" \
    2>/dev/null | tr -d '[:space:]')"
  printf '%s' "${out:-0}"
}

format_bytes_human() {
  local n="${1:-0}"
  if [[ "$n" -ge 1073741824 ]]; then
    printf '%s GB' "$((n / 1073741824))"
  elif [[ "$n" -ge 1048576 ]]; then
    printf '%s MB' "$((n / 1048576))"
  else
    printf '%s bytes' "$n"
  fi
}

# 0 = ready, 1 = missing, 2 = incomplete
check_model_on_volume() {
  local model="${1:-$(default_model)}"
  local min size
  min="$(model_min_bytes "$model")"
  size="$(query_model_bytes "$model")"
  if [[ "${size:-0}" -eq 0 ]]; then
    return 1
  fi
  if [[ "${size:-0}" -lt "$min" ]]; then
    return 2
  fi
  return 0
}

# Populated by assess_readiness (used by menu, status, health).
RDY_OK=0
RDY_DOCKER=0
RDY_COMPOSE=0
RDY_SOURCES=0
RDY_OUTPUTS=0
RDY_IMAGE=0
RDY_MODEL=0
RDY_MODEL_BYTES=0
RDY_SOURCES_COUNT=0
RDY_FIX=""
RDY_MODEL_LABEL=""

assess_readiness() {
  local mrc=0
  RDY_OK=1
  RDY_DOCKER=0
  RDY_COMPOSE=0
  RDY_SOURCES=0
  RDY_OUTPUTS=0
  RDY_IMAGE=0
  RDY_MODEL=0
  RDY_MODEL_BYTES=0
  RDY_SOURCES_COUNT=0
  RDY_FIX=""
  RDY_MODEL_LABEL=""

  if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    RDY_DOCKER=1
  else
    RDY_OK=0
    RDY_FIX="Start Docker, then menu 1 (Start)"
    return 0
  fi

  if dc config -q >/dev/null 2>&1; then
    RDY_COMPOSE=1
  else
    RDY_OK=0
    RDY_FIX="Fix docker-compose.yml / .env"
    return 0
  fi

  ensure_workspace_dirs
  if [[ -d "${REPO_ROOT}/sources" && -w "${REPO_ROOT}/sources" ]]; then
    RDY_SOURCES=1
    RDY_SOURCES_COUNT=$(find "${REPO_ROOT}/sources" -maxdepth 1 -type f 2>/dev/null | wc -l | tr -d ' ')
  else
    RDY_OK=0
    RDY_FIX="Cannot write sources/ directory"
  fi

  if [[ -d "${REPO_ROOT}/outputs" && -w "${REPO_ROOT}/outputs" ]]; then
    RDY_OUTPUTS=1
  else
    RDY_OK=0
    RDY_FIX="Cannot write outputs/ directory"
  fi

  if image_exists; then
    RDY_IMAGE=1
  else
    RDY_OK=0
    [[ -z "$RDY_FIX" ]] && RDY_FIX="Menu 1 (Start) to build image"
  fi

  RDY_MODEL_BYTES="$(query_model_bytes "$(default_model)")"
  check_model_on_volume "$(default_model)"
  mrc=$?
  if [[ "$mrc" -eq 0 ]]; then
    RDY_MODEL=1
    RDY_MODEL_LABEL="ggml-$(default_model).bin $(format_bytes_human "$RDY_MODEL_BYTES") on $(model_volume_name)"
  else
    RDY_OK=0
    if [[ "$mrc" -eq 2 ]]; then
      RDY_MODEL_LABEL="incomplete ($(format_bytes_human "$RDY_MODEL_BYTES") on $(model_volume_name))"
      [[ -z "$RDY_FIX" ]] && RDY_FIX="Menu 8 (Ensure model) or: $0 ensure-model"
    elif volume_exists; then
      RDY_MODEL_LABEL="missing on $(model_volume_name)"
      [[ -z "$RDY_FIX" ]] && RDY_FIX="Menu 8 (Ensure model) or: $0 ensure-model"
    else
      RDY_MODEL_LABEL="volume $(model_volume_name) not created yet"
      [[ -z "$RDY_FIX" ]] && RDY_FIX="Menu 1 (Start) or 8 (Ensure model)"
    fi
  fi
}

readiness_chip() {
  local ok="$1"
  local label="$2"
  if [[ "$ok" == 1 ]]; then
    printf ' %s✓%s %s' "$C_OK" "$C_RESET" "$label"
  else
    printf ' %s✗%s %s' "$C_ERR" "$C_RESET" "$label"
  fi
}

render_readiness_banner() {
  assess_readiness
  printf '\n%s── Readiness ──%s\n' "$C_SEC" "$C_RESET"
  readiness_chip "$RDY_DOCKER" "Docker"
  readiness_chip "$RDY_COMPOSE" "Compose"
  readiness_chip "$RDY_IMAGE" "Image"
  readiness_chip "$RDY_MODEL" "Model"
  readiness_chip "$RDY_SOURCES" "sources/"
  readiness_chip "$RDY_OUTPUTS" "outputs/"
  printf '\n'

  if [[ "$RDY_MODEL" -eq 1 ]]; then
    printf '  Model: %s\n' "$RDY_MODEL_LABEL"
  else
    printf '  Model: %s%s%s\n' "$C_WARN" "$RDY_MODEL_LABEL" "$C_RESET"
  fi

  if [[ "$RDY_OK" -eq 1 ]]; then
    printf '\n  %s▶ READY TO TRANSCRIBE%s — use menu 10 or: %s transcribe <file>\n' \
      "$C_OK" "$C_RESET" "$0"
    return 0
  fi
  printf '\n  %s▶ NOT READY%s — %s\n' "$C_ERR" "$C_RESET" "$RDY_FIX"
  printf '  %s(Menu 4 = full Status checklist)%s\n' "$C_DIM" "$C_RESET"
  return 1
}

readiness_row() {
  local ok="$1"
  local label="$2"
  local detail="${3:-}"
  if [[ "$ok" == 1 ]]; then
    printf '  %s✓%s %-28s %s\n' "$C_OK" "$C_RESET" "$label" "$detail"
  else
    printf '  %s✗%s %-28s %s\n' "$C_ERR" "$C_RESET" "$label" "$detail"
  fi
}

normalize_transcribe_input() {
  local raw="$1"
  local base src

  raw="${raw#"${raw%%[![:space:]]*}"}"
  raw="${raw%"${raw##*[![:space:]]}"}"
  case "$raw" in
    \"*)
      raw="${raw%\"}"
      raw="${raw#\"}"
      ;;
    \'*)
      raw="${raw%\'}"
      raw="${raw#\'}"
      ;;
  esac

  [[ -n "$raw" ]] || return 1

  raw="${raw#./}"
  raw="${raw#sources/}"
  base="$(basename "$raw")"
  ensure_workspace_dirs

  if [[ -f "${REPO_ROOT}/sources/${base}" ]]; then
    printf '%s' "$base"
    return 0
  fi

  if [[ -f "$raw" ]]; then
    printf '%sCopying → ./sources/%s\n' "$C_DIM" "$base" >&2
    cp "$raw" "${REPO_ROOT}/sources/${base}"
    printf '%s' "$base"
    return 0
  fi

  printf '%sERROR:%s cannot find media: %s\n' "$C_ERR" "$C_RESET" "$raw" >&2
  printf 'Put files in ./sources or paste a full path to an existing file.\n' >&2
  return 1
}

urls_hint() {
  printf '\n%sUsage%s\n' "$C_SEC" "$C_RESET"
  printf '  Drop media in ./sources (gitignored)\n'
  printf '  Transcribe:  %s transcribe <file> [--model NAME] [--language CODE]\n' "$0"
  printf '  Quote spaces: %s transcribe "my video.mp4"\n' "$0"
  if [[ -n "${TRANSCRIPT_HOST_PORT:-}" ]]; then
    printf '\nOptional HTTP (if enabled in compose): http://%s:%s\n' "$PUBLIC_HOST" "$TRANSCRIPT_HOST_PORT"
  else
    printf '\n%sMode:%s CLI via docker compose run (no published host ports in v1)\n' "$C_DIM" "$C_RESET"
  fi
}

cmd_validate() {
  dc config -q
  printf '%scompose config:%s ok\n' "$C_OK" "$C_RESET"
}

cmd_build() {
  require_docker
  dc build --pull "$@"
}

cmd_pull() {
  require_docker
  dc pull "$@"
}

cmd_ensure_model() {
  require_docker
  dc run --rm transcript ensure-model "$@"
}

cmd_check_model() {
  local model="${1:-$(default_model)}"
  local size min vol
  require_docker
  vol="$(model_volume_name)"
  min="$(model_min_bytes "$model")"
  if check_model_on_volume "$model"; then
    size="$(query_model_bytes "$model")"
    printf '%smodel ok:%s ggml-%s.bin on volume %s (%s bytes)\n' \
      "$C_OK" "$C_RESET" "$model" "$vol" "$size"
    return 0
  fi
  size="$(query_model_bytes "$model")"
  if [[ "${size:-0}" -gt 0 ]]; then
    printf '%smodel incomplete:%s ggml-%s.bin (%s bytes, need >= %s)\n' \
      "$C_WARN" "$C_RESET" "$model" "$size" "$min" >&2
    return 2
  fi
  printf '%smodel missing:%s ggml-%s.bin not on volume %s — run: %s ensure-model\n' \
    "$C_ERR" "$C_RESET" "$model" "$vol" "$0" >&2
  return 1
}

ensure_all_resources() {
  local step="${1:-all}"
  require_docker
  ensure_workspace_dirs

  if [[ "$step" == "all" || "$step" == "validate" ]]; then
    printf '%s[1/3]%s Validating compose configuration...\n' "$C_DIM" "$C_RESET"
    cmd_validate
  fi

  if [[ "$step" == "all" || "$step" == "build" ]]; then
    printf '%s[2/3]%s Building transcript image...\n' "$C_DIM" "$C_RESET"
    if [[ "${MENU_QUIET:-0}" == 1 ]]; then
      quiet_dc build
    else
      dc build
    fi
  fi

  if [[ "$step" == "all" || "$step" == "model" ]]; then
    printf '%s[3/3]%s Ensuring Whisper model "%s" (volume: whisper-models)...\n' \
      "$C_DIM" "$C_RESET" "$(default_model)"
    cmd_ensure_model
  fi
}

cmd_start() {
  ensure_all_resources "$@"
  printf '\n%sStack ready.%s Transcribe with:\n' "$C_OK" "$C_RESET"
  printf '  %s transcribe <file-in-sources>\n' "$0"
  urls_hint
}

cmd_prepare() {
  cmd_start "$@"
}

cmd_stop() {
  dc down --remove-orphans
  printf '%sStack stopped%s (named volumes kept, including whisper-models).\n' "$C_OK" "$C_RESET"
}

cmd_restart() {
  cmd_stop
  cmd_start
}

cmd_status() {
  print_banner
  assess_readiness
  printf '\n%sReadiness for transcription%s\n' "$C_SEC" "$C_RESET"

  readiness_row "$RDY_DOCKER" "Docker daemon" \
    "$(command -v docker 2>/dev/null || echo 'not installed')"
  readiness_row "$RDY_COMPOSE" "Compose configuration" "$COMPOSE_PROJECT_NAME"
  readiness_row "$RDY_SOURCES" "sources/ directory" "${RDY_SOURCES_COUNT} file(s)"
  readiness_row "$RDY_OUTPUTS" "outputs/ directory" "writable"
  readiness_row "$RDY_IMAGE" "Transcript image" \
    "$(if [[ "$RDY_IMAGE" -eq 1 ]]; then image_ref; else printf 'missing — menu 1 or: %s start' "$0"; fi)"
  readiness_row "$RDY_MODEL" "Whisper model ($(default_model))" "$RDY_MODEL_LABEL"

  printf '\n%s%sNote:%s Models persist on Docker volume %s (not inside stopped containers).\n' \
    "$C_DIM" "$C_RESET" "$C_DIM" "$(model_volume_name)"
  printf '%s%sNote:%s containers=0/0 is normal — jobs use ephemeral compose run containers.\n' \
    "$C_DIM" "$C_RESET" "$C_DIM"

  printf '\n%sContainers%s\n' "$C_SEC" "$C_RESET"
  set +e
  dc ps -a 2>/dev/null || printf '  %s(unable to list)%s\n' "$C_DIM" "$C_RESET"
  set -e

  printf '\n%sVerdict:%s ' "$C_BOLD" "$C_RESET"
  if [[ "$RDY_OK" -eq 1 ]]; then
    printf '%sREADY%s — you can transcribe (menu 10 or: %s transcribe <file>)\n' \
      "$C_OK" "$C_RESET" "$0"
    return 0
  fi
  printf '%sNOT READY%s\n' "$C_ERR" "$C_RESET"
  [[ -n "$RDY_FIX" ]] && printf '  Next step: %s\n' "$RDY_FIX"
  return 1
}

cmd_logs_all() {
  dc logs -f --tail=200
}

cmd_logs_service() {
  dc logs -f --tail=200 "$@"
}

cmd_shell() {
  require_docker
  ensure_workspace_dirs
  dc run --rm transcript shell
}

cmd_transcribe() {
  if [[ $# -lt 1 ]]; then
    printf 'Usage: %s transcribe <file> [--model NAME] [--language CODE]\n' "$0" >&2
    printf '  <file> = basename in ./sources, or a full path (copied into ./sources)\n' >&2
    printf '  --language = ISO code (case-insensitive), e.g. en, es, auto\n' >&2
    printf 'Quote paths with spaces: %s transcribe "/path/my video.mp4"\n' "$0" >&2
    exit 1
  fi
  local -a args=("$@")
  local model_args=() transcribe_args=() i=0 resolved=""
  require_docker
  ensure_workspace_dirs
  while [[ $i -lt ${#args[@]} ]]; do
    if [[ "${args[i]}" == --model ]]; then
      if [[ $((i + 1)) -ge ${#args[@]} ]]; then
        printf 'missing value for --model\n' >&2
        exit 1
      fi
      model_args=(--model "${args[i + 1]}")
      transcribe_args+=("--model" "${args[i + 1]}")
      i=$((i + 2))
    elif [[ "${args[i]}" == --language ]]; then
      if [[ $((i + 1)) -ge ${#args[@]} ]]; then
        printf 'missing value for --language\n' >&2
        exit 1
      fi
      transcribe_args+=("--language" "${args[i + 1]}")
      i=$((i + 2))
    else
      if [[ -z "$resolved" ]]; then
        resolved="$(normalize_transcribe_input "${args[i]}")" || exit 1
        transcribe_args+=("$resolved")
      else
        transcribe_args+=("${args[i]}")
      fi
      i=$((i + 1))
    fi
  done
  if [[ ${#model_args[@]} -gt 0 ]]; then
    cmd_ensure_model "${model_args[@]}"
  else
    cmd_ensure_model
  fi
  run_transcript transcribe "${transcribe_args[@]}"
}

cmd_transcribe_all() {
  local -a args=("$@")
  local model_args=() transcribe_args=() i=0
  require_docker
  ensure_workspace_dirs
  while [[ $i -lt ${#args[@]} ]]; do
    if [[ "${args[i]}" == --model ]]; then
      if [[ $((i + 1)) -ge ${#args[@]} ]]; then
        printf 'missing value for --model\n' >&2
        exit 1
      fi
      model_args=(--model "${args[i + 1]}")
      transcribe_args+=("--model" "${args[i + 1]}")
      i=$((i + 2))
    elif [[ "${args[i]}" == --language ]]; then
      if [[ $((i + 1)) -ge ${#args[@]} ]]; then
        printf 'missing value for --language\n' >&2
        exit 1
      fi
      transcribe_args+=("--language" "${args[i + 1]}")
      i=$((i + 2))
    else
      printf 'unknown argument: %s (usage: %s transcribe-all [--model NAME] [--language CODE])\n' \
        "${args[i]}" "$0" >&2
      exit 1
    fi
  done
  if [[ ${#model_args[@]} -gt 0 ]]; then
    cmd_ensure_model "${model_args[@]}"
  else
    cmd_ensure_model
  fi
  run_transcript transcribe-all "${transcribe_args[@]}"
}

cmd_list_sources() {
  ensure_workspace_dirs
  local count=0 f
  printf '%sFiles in ./sources:%s\n' "$C_SEC" "$C_RESET"
  shopt -s nullglob
  for f in "${REPO_ROOT}/sources"/*; do
    [[ -f "$f" ]] || continue
    printf '  %s\n' "$(basename "$f")"
    count=$((count + 1))
  done
  shopt -u nullglob
  if [[ "$count" -eq 0 ]]; then
    printf '  %s(empty — copy media here before transcribing)%s\n' "$C_DIM" "$C_RESET"
  fi
}

cmd_smoke() {
  local smoke="${REPO_ROOT}/tests/smoke.sh"
  if [[ ! -x "$smoke" ]]; then
    printf '%sERROR:%s %s not found or not executable\n' "$C_ERR" "$C_RESET" "$smoke" >&2
    exit 1
  fi
  "$smoke"
}

cmd_health() {
  assess_readiness
  render_readiness_banner || true
  if [[ "$RDY_OK" -eq 1 ]]; then
    cmd_validate
    return 0
  fi
  return 1
}

cmd_resources() {
  ensure_all_resources "$@"
}

cmd_nuke() {
  print_banner
  printf '%sWARNING:%s removes named volumes for THIS project only (including downloaded models).\n' \
    "$C_ERR" "$C_RESET" >&2
  local confirm confirm2
  menu_read "Type the project name to confirm: " confirm || return 0
  if [[ "$confirm" != "$COMPOSE_PROJECT_NAME" ]]; then
    printf 'Aborted (name mismatch).\n' >&2
    return 0
  fi
  menu_read 'Second confirm: type YES to delete volumes: ' confirm2 || return 0
  if [[ "$confirm2" != "YES" ]]; then
    printf 'Aborted.\n' >&2
    return 0
  fi
  dc down -v --remove-orphans
  printf '%sNuke complete%s for project %s\n' "$C_OK" "$C_RESET" "$COMPOSE_PROJECT_NAME"
}

show_help() {
  cat <<EOF
tools-transcript stack manager

Usage:
  $0 [command] [args...]

Stack & resources (start = validate + build + ensure-model):
  start, prepare       Build image, ensure dirs, download default model
  stop                 docker compose down (scoped; keeps volumes)
  restart              stop then start
  status               Readiness check (Docker, image, model, dirs) + containers
  build                Build image only
  pull                 Pull base images
  validate             Validate compose file
  resources            Same as start (alias for explicit resource prep)
  health               validate + model check

Transcription:
  transcribe <file>    Run job (auto-ensures model first)
  transcribe-all       Transcribe every media file in ./sources (sequential)
  --language CODE      Optional on transcribe / transcribe-all (ISO, e.g. en, es, auto)
  ensure-model         Download WHISPER_MODEL if missing
  ensure-model --force Re-download model (fix incomplete download)
  check-model          Verify model on volume (no download)
  list-sources         List files in ./sources

Development:
  shell                Interactive shell in transcript container
  smoke                Run tests/smoke.sh
  logs                 Follow all service logs
  logs:transcript      Follow transcript service logs
  urls                 Show usage and connection hints

Interactive:
  dev, menu            Full interactive menu (default when no command)

Danger:
  nuke                 down -v with double confirmation

Environment (.env, never committed):
  COMPOSE_PROJECT_NAME=$COMPOSE_PROJECT_NAME
  STACK_SUFFIX=$STACK_SUFFIX
  WHISPER_MODEL=$(default_model)

Isolation: every compose call uses -p and --project-directory.
EOF
}

render_menu() {
  print_banner
  render_readiness_banner || true
  cat <<EOF

${C_SEC}── Stack & resources ──${C_RESET}
  1)  Start / prepare stack (validate + build + ensure model)
  2)  Stop stack (keep volumes)
  3)  Restart stack
  4)  Status — ready to transcribe? (full checklist)
  5)  Validate compose
  6)  Build image only
  7)  Pull base images
  8)  Ensure model (download WHISPER_MODEL)
  9)  Check model (no download)

${C_SEC}── Transcription ──${C_RESET}
 10)  Transcribe (type or paste path / filename)
 11)  Transcribe all files in ./sources
 12)  List ./sources
 13)  Interactive shell

${C_SEC}── Verify & ops ──${C_RESET}
 14)  Health check
 15)  Run smoke test
 16)  Usage / URLs
 17)  Follow logs (transcript service)

${C_SEC}── Danger zone ──${C_RESET}
 18)  Nuke volumes (double confirm)

  0)  Exit
  r)  Refresh
  ?)  Help
EOF
}

menu_transcribe_prompt() {
  local f model language resolved ans
  assess_readiness
  if [[ "$RDY_OK" -ne 1 ]]; then
    printf '\n%sCannot transcribe yet — readiness check failed.%s\n' "$C_ERR" "$C_RESET" >&2
    render_readiness_banner || true
    menu_read 'Run readiness fix first? [Y/n]: ' ans || return 0
    if [[ ! "$ans" =~ ^[Nn]$ ]]; then
      return 0
    fi
  fi
  cmd_list_sources
  printf '\n'
  printf 'Enter a filename in ./sources, or paste a full path to copy into ./sources.\n'
  menu_read 'Video/audio path or filename: ' f || return 0
  [[ -n "$f" ]] || return 0
  set +e
  resolved="$(normalize_transcribe_input "$f")"
  local nrc=$?
  set -e
  [[ "$nrc" -eq 0 ]] || return "$nrc"
  menu_read "Model [$(default_model)]: " model || return 0
  menu_read "Language [$(default_language_hint)] (empty=default): " language || return 0
  local -a targs=("$resolved")
  [[ -n "$model" ]] && targs+=(--model "$model")
  [[ -n "$language" ]] && targs+=(--language "$language")
  cmd_transcribe "${targs[@]}"
}

menu_ensure_model_prompt() {
  local model force=""
  menu_read "Model [$(default_model)]: " model || return 0
  menu_read 'Force re-download? [y/N]: ' force || return 0
  if [[ "$force" =~ ^[Yy]$ ]]; then
    if [[ -n "$model" ]]; then
      cmd_ensure_model --model "$model" --force
    else
      cmd_ensure_model --force
    fi
  elif [[ -n "$model" ]]; then
    cmd_ensure_model --model "$model"
  else
    cmd_ensure_model
  fi
}

dispatch_menu_choice() {
  local choice="$1"
  local rc=0
  case "$choice" in
    1) cmd_start ;;
    2) cmd_stop ;;
    3) cmd_restart ;;
    4) cmd_status ;;
    5) cmd_validate ;;
    6) cmd_build ;;
    7) cmd_pull ;;
    8) menu_ensure_model_prompt ;;
    9) cmd_check_model ;;
    10) menu_transcribe_prompt ;;
    11) cmd_transcribe_all ;;
    12) cmd_list_sources ;;
    13) cmd_shell ;;
    14) cmd_health; rc=$? ;;
    15) cmd_smoke; rc=$? ;;
    16) urls_hint ;;
    17) cmd_logs_service transcript; rc=$? ;;
    18) cmd_nuke ;;
    0|q|Q) return 2 ;;
    r|R) return 0 ;;
    h|H|\?) show_help; return 0 ;;
    *)
      printf '%sUnknown choice:%s %s\n' "$C_ERR" "$C_RESET" "$choice" >&2
      return 0
      ;;
  esac
  return "${rc:-0}"
}

show_menu() {
  init_colors
  while true; do
    render_menu
    local choice rc=0
    menu_read 'Choice: ' choice || exit 0
    set +e
    dispatch_menu_choice "$choice"
    rc=$?
    set -e
    [[ "$rc" -eq 2 ]] && exit 0
    if [[ "$rc" -ne 0 ]]; then
      printf '%sCommand exited with status %s%s\n' "$C_WARN" "$rc" "$C_RESET" >&2
    fi
    menu_read 'Press Enter to continue...' _ || true
  done
}

main() {
  load_env
  init_colors
  require_compose_file
  local cmd="${1:-}"
  if [[ -z "$cmd" ]]; then
    show_menu
    exit 0
  fi
  shift || true

  case "$cmd" in
    start|prepare) cmd_start "$@" ;;
    stop) cmd_stop "$@" ;;
    restart) cmd_restart "$@" ;;
    status) cmd_status "$@" ;;
    build) cmd_build "$@" ;;
    pull) cmd_pull "$@" ;;
    validate) cmd_validate "$@" ;;
    health) cmd_health "$@" ;;
    resources) cmd_resources "$@" ;;
    transcribe) cmd_transcribe "$@" ;;
    transcribe-all) cmd_transcribe_all "$@" ;;
    ensure-model) cmd_ensure_model "$@" ;;
    check-model) cmd_check_model "$@" ;;
    list-sources) cmd_list_sources "$@" ;;
    shell) cmd_shell "$@" ;;
    smoke) cmd_smoke "$@" ;;
    logs) cmd_logs_all "$@" ;;
    logs:transcript) cmd_logs_service transcript "$@" ;;
    urls) urls_hint ;;
    nuke) cmd_nuke "$@" ;;
    dev|menu) show_menu ;;
    help|-h|--help) show_help ;;
    *)
      printf '%sUnknown command:%s %s\n' "$C_ERR" "$C_RESET" "$cmd" >&2
      show_help
      exit 1
      ;;
  esac
}

main "$@"
