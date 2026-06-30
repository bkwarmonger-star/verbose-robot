#!/usr/bin/env bash
#
# try.sh — download a HeavyD-9B GGUF and run it locally.
#
# The weights are not in this git repo (they're multi-GB binaries). This script
# pulls the chosen quant from the upstream source repo on Hugging Face and runs
# it with llama.cpp (or hands you an Ollama one-liner if that's what you have).
#
# Usage:
#   ./scripts/try.sh                      # chat, Q4_K_M, GPU if available
#   QUANT=Q5_K_M ./scripts/try.sh         # pick a different quant
#   MODE=server ./scripts/try.sh          # OpenAI-compatible server on :8080
#   MODE=image IMAGE=./photo.jpg ./scripts/try.sh   # vision (downloads mmproj)
#   NGL=0 ./scripts/try.sh                # force CPU-only (0 GPU layers)
#
set -euo pipefail

# ---- config (override via env) ---------------------------------------------
QUANT="${QUANT:-Q4_K_M}"          # Q4_K_M Q5_K_M Q6_K Q8_0 BF16, or MTP-<quant>
MODE="${MODE:-chat}"              # chat | server | image
CTX="${CTX:-16384}"              # context window (up to 1010000)
NGL="${NGL:-99}"                 # GPU layers to offload (0 = CPU only)
PORT="${PORT:-8080}"             # server port
MODEL_DIR="${MODEL_DIR:-./models}"
IMAGE="${IMAGE:-}"               # path to an image for MODE=image

# Upstream source the weights actually live at. HeavyD is a local alias for this.
SRC_REPO="${SRC_REPO:-empero-ai/Qwythos-9B-Claude-Mythos-5-1M-GGUF}"
SRC_PREFIX="Qwythos-9B-Claude-Mythos-5-1M"
HF_BASE="https://huggingface.co/${SRC_REPO}/resolve/main"

MODEL_FILE="${SRC_PREFIX}-${QUANT}.gguf"
MMPROJ_FILE="mmproj-${SRC_PREFIX}-F16.gguf"

# recommended sampling (Qwen3.5 thinking mode)
SAMPLING=(--temp 0.6 --top-p 0.95 --top-k 20 --repeat-penalty 1.05)

mkdir -p "$MODEL_DIR"

say() { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
die() { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

# ---- download helper --------------------------------------------------------
fetch() {
  # fetch <remote-filename> -> $MODEL_DIR/<remote-filename>
  local name="$1" dest="$MODEL_DIR/$1"
  if [[ -s "$dest" ]]; then say "already have $name"; return; fi
  say "downloading $name from $SRC_REPO ..."
  if command -v hf >/dev/null 2>&1; then
    hf download "$SRC_REPO" "$name" --local-dir "$MODEL_DIR"
  elif command -v huggingface-cli >/dev/null 2>&1; then
    huggingface-cli download "$SRC_REPO" "$name" --local-dir "$MODEL_DIR"
  elif command -v curl >/dev/null 2>&1; then
    curl -fL -C - -o "$dest" "$HF_BASE/$name"   # -C - resumes partial downloads
  elif command -v wget >/dev/null 2>&1; then
    wget -c -O "$dest" "$HF_BASE/$name"
  else
    die "need one of: hf, huggingface-cli, curl, or wget to download"
  fi
}

# ---- locate a runtime -------------------------------------------------------
find_bin() { for b in "$@"; do command -v "$b" >/dev/null 2>&1 && { echo "$b"; return; }; done; }

CLI="$(find_bin llama-cli)"
SERVER="$(find_bin llama-server)"
MTMD="$(find_bin llama-mtmd-cli llama-llava-cli)"

if [[ -z "$CLI$SERVER$MTMD" ]]; then
  cat >&2 <<EOF
No llama.cpp binaries found on PATH (llama-cli / llama-server / llama-mtmd-cli).

Fastest path — Ollama (handles the engine for you):
  ollama run hf.co/${SRC_REPO}:${QUANT}

Or install llama.cpp, then re-run this script:
  - macOS:  brew install llama.cpp
  - Linux:  see https://github.com/ggml-org/llama.cpp#building   (or grab a release binary)
EOF
  exit 1
fi

# ---- run --------------------------------------------------------------------
case "$MODE" in
  chat)
    [[ -n "$CLI" ]] || die "MODE=chat needs llama-cli"
    fetch "$MODEL_FILE"
    say "starting chat (ctx=$CTX, gpu-layers=$NGL) — Ctrl-C to quit"
    exec "$CLI" -m "$MODEL_DIR/$MODEL_FILE" -c "$CTX" -ngl "$NGL" \
      "${SAMPLING[@]}" -cnv
    ;;
  server)
    [[ -n "$SERVER" ]] || die "MODE=server needs llama-server"
    fetch "$MODEL_FILE"
    say "serving OpenAI-compatible API on http://localhost:$PORT"
    exec "$SERVER" -m "$MODEL_DIR/$MODEL_FILE" -c "$CTX" -ngl "$NGL" --port "$PORT"
    ;;
  image)
    [[ -n "$MTMD" ]] || die "MODE=image needs llama-mtmd-cli"
    [[ -n "$IMAGE" ]] || die "MODE=image needs IMAGE=/path/to/file"
    [[ -f "$IMAGE" ]] || die "image not found: $IMAGE"
    fetch "$MODEL_FILE"; fetch "$MMPROJ_FILE"
    exec "$MTMD" -m "$MODEL_DIR/$MODEL_FILE" --mmproj "$MODEL_DIR/$MMPROJ_FILE" \
      --image "$IMAGE" -p "Describe this image in detail." \
      "${SAMPLING[@]}" -c "$CTX" -ngl "$NGL"
    ;;
  *)
    die "unknown MODE=$MODE (use chat | server | image)"
    ;;
esac
