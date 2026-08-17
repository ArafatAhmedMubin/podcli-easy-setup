#!/usr/bin/env bash
# Reproducible podcli setup — see README.md. Safe to re-run.
# Validates on Linux x86_64. For other platforms, see the official install.sh.
set -uo pipefail

RC=0

step() { printf '\n\033[1m=== %s ===\033[0m\n' "$*"; }

step "0. Preflight — check required tools"
missing=0
for t in curl; do
  if ! command -v "$t" >/dev/null 2>&1; then
    echo "MISSING required: $t"; missing=1
  fi
done
for t in node python3 ffmpeg; do
  if ! command -v "$t" >/dev/null 2>&1; then
    echo "WARNING: '$t' not on PATH — backend/MCP/transcoding may fall back to slower paths."
  fi
done
[ "$missing" -eq 0 ] || { echo "Install the missing required tools, then re-run."; exit 1; }
uname -sm

step "1. Install podcli binary (official installer)"
curl -fsSL https://raw.githubusercontent.com/nmbrthirteen/podcli/main/install.sh | sh
command -v podcli >/dev/null 2>&1 || { echo "FAIL: podcli not on PATH"; RC=1; exit $RC; }
podcli --version

step "2. Provision runtimes + models (time-boxed; FFmpeg fetch often hangs)"
# `podcli setup` downloads the whisper model (fast) then a managed FFmpeg/Python
# runtime whose host (johnvansickle.com) frequently resets the connection here,
# hanging indefinitely. We time-box it tightly: 90s is enough for the model; if
# it's still going, kill it and fetch the model directly. System ffmpeg covers
# transcoding; system python3 covers the backend (step 3). Do NOT let this block
# steps 3-5.
echo "  trying podcli setup (capped at 90s)..."
if timeout 90 podcli setup 2>&1 | grep -E 'model:|done|error|interrupted' | tail -8; then :; fi
# whatever happened, ensure the model is present
if [ ! -s "$HOME/.local/share/podcli/models/ggml-base.bin" ]; then
  echo "  model missing or partial — fetching ggml-base.bin directly..."
  mkdir -p "$HOME/.local/share/podcli/models"
  curl -fL --retry 3 https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin \
    -o "$HOME/.local/share/podcli/models/ggml-base.bin" \
    || echo "  WARN: model fetch failed; transcription may fall back to system whisper"
fi
if [ -s "$HOME/.local/share/podcli/models/ggml-base.bin" ]; then
  echo "  Whisper model present: $(stat -c%s "$HOME/.local/share/podcli/models/ggml-base.bin" 2>/dev/null) bytes"
fi

step "3. Install backend Python deps into system python3"
REQ="$HOME/.local/share/podcli/runtime/backend/requirements-runtime.txt"
PIPPKG=(pip3 install)
# PEP 668 managed-env systems need this flag; harmless to try, fall back without it.
pip3 install --break-system-packages -r "$REQ" 2>/dev/null || \
  pip3 install -r "$REQ" 2>/dev/null || \
  pip3 install --break-system-packages \
    "opencv-python-headless>=4.8.1.78" "numpy>=2.5.1" "onnxruntime>=1.28.0" \
    "Pillow>=12.3.0" "questionary>=2.1.1" "python-dotenv>=1.2.2" "yt-dlp>=2026.7.4" \
    "google-api-python-client>=2.198.0" "google-auth-oauthlib>=1.4.0"
python3 -c \
  "import cv2,numpy,onnxruntime,PIL,questionary,dotenv,yt_dlp,googleapiclient,google.oauth2; print('backend deps OK')" \
  || { echo "WARN: some backend deps did not import"; }

step "4. Smoke-test the web Studio (localhost:3847)"
podcli ui >/tmp/podcli-ui.log 2>&1 &
UI_PID=$!
# Poll up to ~25s: the Studio can take ~10s to come up cold (downloads remotion
# bundles on first launch). A fixed short sleep will false-negative.
code=000
for i in $(seq 1 25); do
  sleep 1
  code=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 2 http://localhost:3847/ 2>/dev/null || echo "000")
  [ "$code" = "200" ] && break
done
echo "Studio HTTP: $code (${i}s waited)"
[ "$code" = "200" ] || echo "  WARN: Studio not reachable in 25s — see /tmp/podcli-ui.log; CLI/MCP still work"
kill "$UI_PID" 2>/dev/null || true
wait "$UI_PID" 2>/dev/null || true

step "5. Wire podcli MCP server into Claude Code (user scope)"
if command -v claude >/dev/null 2>&1; then
  claude mcp remove podcli -s user 2>/dev/null || true
  claude mcp add --scope user podcli -- node "$HOME/.local/share/podcli/runtime/studio/mcp-server.mjs"
  echo "--- mcp list ---"; claude mcp list || true
  echo
  echo "REMINDER: restart Claude Code so the MCP server loads (it is read at startup)."
else
  echo "claude CLI not on PATH — ensure it is, then run:"
  echo "  export PATH=\"\$HOME/.local/bin:\$PATH\"; bash setup.sh"
  echo "  (or just the step-5 line from README.md)"
fi

step "6. (Optional) clone PodStack slash-command repo"
if command -v git >/dev/null 2>&1; then
  read -r -p "Clone the PodStack source repo (for /produce-shorts etc.)? [y/N] " ans
  case "$ans" in y|Y) git clone https://github.com/nmbrthirteen/podcli.git || true ;; esac
fi

step "Done  (rc=$RC)"
echo "Run 'podcli doctor' to confirm, then restart Claude Code and run '/mcp'."
exit $RC
