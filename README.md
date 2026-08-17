# easy-setup — reproducible `podcli` install for AI agents

This repo exists so any AI coding agent (Claude Code, Codex, etc.) can reproduce
the exact podcli installation documented below in **any directory, on a fresh
Linux x86_64 machine**, without re-deriving the steps.

Hand the agent this README and say something like:

> "Read this repo's README and set up podcli on this machine, then wire the MCP
> server into Claude Code."

That's all it needs.

---

## What this installs

[podcli](https://github.com/nmbrthirteen/podcli) v2.6.0 — an AI podcast
clip generator (transcribe → find viral moments → render vertical clips with
burned-in captions), driven via CLI, a local web Studio at
`http://localhost:3847`, or an MCP server exposing 26 tools to Claude Code /
Codex.

End state after the setup below:

- `podcli` binary on PATH (`/usr/local/bin/podcli`)
- Whisper base model downloaded (~141 MB) for transcription
- Backend Python deps installed (questionary, numpy, opencv-headless,
  onnxruntime, Pillow, yt-dlp, google-api + auth)
- `podcli ui` reachable at `http://localhost:3847`
- The podcli MCP server registered at **user scope** in `~/.claude.json`,
  available in every Claude Code project

---

## Required environment (verified 2026-08-17)

- **OS:** Linux x86_64 (also supports Linux arm64, Apple Silicon macOS, Windows x64)
- **Shell:** `sh` / `bash`
- **`curl`** (for the installer)
- **Node.js >= 18** on PATH (verified with v20.19.0) — used to run the MCP server
- **Python 3** on PATH (verified with 3.12.13) — used as the backend interpreter
- **FFmpeg** on PATH (verified with 4.4.2) — used for transcoding
- **git** (to clone, if you want the PodStack slash-command repo too)

Check with:

```sh
uname -sm
for t in curl node python3 ffmpeg git; do
  command -v $t >/dev/null && echo "$t: $($t --version 2>&1 | head -1)" || echo "$t: MISSING"
done
```

> The official installer needs **only `curl`** — its native binary downloads and
> self-provisions Python/Node/FFmpeg/whisper.cpp on first run. The reason we
> install a few things manually below is that `podcli setup` (the hermetic
> provisioning step) downloads several hundred MB of runtimes and can be slow
> or time out on constrained connections. Falling back to system `node`,
> `python3`, and `ffmpeg` and installing just the lightweight Python deps is far
> faster and works identically for the CLI, the web Studio, and the MCP server.

---

## Setup steps (run as a script, or hand to an agent)

### 1. Install the podcli binary (official installer)

```sh
curl -fsSL https://raw.githubusercontent.com/nmbrthirteen/podcli/main/install.sh | sh
```

This downloads the native binary into `~/.local/share/podcli/bin/podcli` and
symlinks it onto PATH (`/usr/local/bin/podcli` if writable, else
`~/.local/bin/podcli`).

Verify:

```sh
podcli --version     # -> podcli 2.6.0
podcli doctor        # shows resolved paths + interpreter
```

### 2. Provision runtimes / models (best-effort, time-boxed)

`podcli setup` downloads whisper.cpp, the Whisper base model, and (slowly)
managed FFmpeg + Python runtimes. It can take many minutes. Try it once with a
long timeout; if it times out, that's fine — step 3 makes the system
interpreters sufficient.

```sh
# best-effort; safe to interrupt if it hangs on the large FFmpeg/Python downloads
podcli setup || true
```

What actually matters from this step is the Whisper model. Confirm it landed:

```sh
ls -la ~/.local/share/podcli/models/ggml-base.bin    # ~141 MB
```

If it's missing, the model can be fetched directly:

```sh
curl -fL https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin \
  -o ~/.local/share/podcli/models/ggml-base.bin
```

### 3. Install backend Python deps into the system interpreter

`podcli doctor` falls back to the system `python3` when no managed runtime is
provisioned. That interpreter needs the backend's runtime requirements.
Install them from the requirements file the installer laid down:

```sh
REQ="$HOME/.local/share/podcli/runtime/backend/requirements-runtime.txt"
# adjust the flag for your pip: PEP 668 managed-env systems need --break-system-packages
pip3 install --break-system-packages -r "$REQ"
```

If the managed runtime dir wasn't created (installer didn't provision it),
grab the requirements list inline:

```sh
pip3 install --break-system-packages \
  opencv-python-headless>=4.8.1.78 \
  numpy>=2.5.1 \
  onnxruntime>=1.28.0 \
  Pillow>=12.3.0 \
  questionary>=2.1.1 \
  python-dotenv>=1.2.2 \
  yt-dlp>=2026.7.4 \
  google-api-python-client>=2.198.0 \
  google-auth-oauthlib>=1.4.0
```

> No torch/TF: transcription is whisper.cpp (native), and audio-event detection
> uses ONNX Runtime. That absence is intentional and is what keeps the install
> small (~not the 2GB a pure-Python Whisper path would need).

Verify all deps import:

```sh
python3 -c "import cv2,numpy,onnxruntime,PIL,questionary,dotenv,yt_dlp,googleapiclient,google.oauth2; print('backend deps OK')"
```

### 3b. (Recommended) Install yt-dlp as a standalone binary

`yt-dlp` is already pulled in by step 3 (the pip package), but podcli shells out
to the `yt-dlp` on PATH for YouTube downloads, and the pip-shim can drift with
your Python env. A standalone binary in `/usr/local/bin` is more robust and is
the method the project recommends:

```sh
sudo curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp \
  -o /usr/local/bin/yt-dlp
sudo chmod a+rx /usr/local/bin/yt-dlp
yt-dlp --version
```

This fetches the Linux standalone binary (zipapp with a shebang; works on x86_64
and arm64) and makes it executable system-wide, independent of pip.

> If you are not root, keep `sudo`. In containers/CI where you run as root,
> `sudo` is a no-op harmlessly. If `sudo` isn't available at all, drop it and
> write to a PATH dir you own (e.g. `~/.local/bin/yt-dlp`) plus the `chmod`.

### 4. Smoke-test the web Studio

```sh
podcli ui &            # starts the Studio
sleep 5
curl -sS -o /dev/null -w "Studio HTTP %{http_code}\n" http://localhost:3847/
kill %1
```

Expect `Studio HTTP 200`.

### 5. Wire the MCP server into Claude Code

The `podcli mcp install` wrapper has a provisioning check that can refuse to
start with *"MCP server not provisioned — run `podcli setup`"*. The MCP server
itself is just a Node script that runs fine on system Node, so register it
**directly** at user scope (loads in every project):

```sh
claude mcp add --scope user podcli -- \
  node "$HOME/.local/share/podcli/runtime/studio/mcp-server.mjs"
```

Verify:

```sh
claude mcp list        # -> podcli: ... ✔ Connected
claude mcp get podcli
```

> **The `claude` CLI must be on PATH** when you run the `mcp add` commands. If
> it lives in `~/.local/bin`, run `export PATH="$HOME/.local/bin:$PATH"` first.

> **Important:** Claude Code loads MCP servers **once at session startup**. The
> `mcp add` modifies `~/.claude.json`, but a running session won't see it until
> you restart. After registering, exit Claude Code and start a fresh session —
> then `/mcp` shows `podcli ✔ Connected` and the 26 tools become callable.

### 6. (Optional) Clone PodStack for the slash-command workflow

The PodStack content-workflow slash commands (`/produce-shorts`,
`/process-transcript`, `/generate-titles`, etc.) and the `.podcli/knowledge/`
brand brain live in the source repo, not the binary:

```sh
git clone https://github.com/nmbrthirteen/podcli.git
# the slash commands are in podcli/.claude/commands/
# brand knowledge templates are in podcli/.podcli/knowledge/ (14 .md files)
```

This clone is independent of the installed binary and is only needed if you
want those workflows inside Claude Code.

---

## Verifying the whole thing end-to-end

```sh
podcli doctor                              # resolved paths, interpreter, models
podcli --version                           # 2.6.0
ls -la ~/.local/share/podcli/bin/podcli    # native binary
ls -la ~/.local/share/podcli/models/ggml-base.bin   # Whisper model
claude mcp list                            # podcli ✔ Connected
```

Then (after restarting Claude Code) drive it conversationally:

> "Use the podcli MCP tools: transcribe episode.mp4 and suggest 5 clips."

Or from the CLI:

```sh
podcli process episode.mp4     # transcribe → pick highlights → render clips into ./podcli-clips/
```

**Quick add from YouTube:**

```sh
podcli add <youtube-url>       # download via yt-dlp, transcribe, auto-clip, and render shorts
```

Many AI agents aren't aware of this shortcut. The `add` command handles the full pipeline for YouTube URLs in one step.

---

## Notes / gotchas

- **Why we don't rely on `podcli setup` completing:** it downloads a managed
  Python + FFmpeg runtime that is several hundred MB and can hang/timeout. The
  system interpreters (`python3`, `node`, `ffmpeg`) cover the CLI, Studio, and
  MCP paths entirely. `podcli doctor` reports these as "PATH fallback (not yet
  hermetic)" — that's expected and fine. If you later want the fully
  self-contained install, re-run `podcli setup` on an unconstrained connection.
- **`--break-system-packages`** is needed on Debian/Ubuntu-style pip (PEP 668).
  On other distros or a venv, drop it. A cleaner alternative on
  externally-managed systems is `pip3 install --user ...` or a venv — but
  `podcli` must then resolve that interpreter; using the system one is simplest.
- **MCP registration scope:** register at `--scope user` so it loads in every
  directory. The default (project/local) scope only loads when you launch Claude
  Code from that specific project directory, which is why `/mcp` can show
  nothing even when the config is valid.
- **Restart Claude Code after `mcp add`** — MCP servers are read at startup.
- **macOS arm64 note:** the installer re-signs the binary ad-hoc; Intel Macs
  are not supported. Windows uses `install.ps1`.
- **Speaker diarization** (separate speakers) is optional and heavy:
  `podcli setup --speakers` pulls pyannote + torch (~2GB). Skip unless needed.

---

## Uninstall

```sh
# remove the MCP server from Claude Code
claude mcp remove podcli -s user

# remove the app (keeps user data: config, knowledge, presets, assets, history)
curl -fsSL https://raw.githubusercontent.com/nmbrthirteen/podcli/main/install.sh | sh -s -- --uninstall
# or, fully:
podcli uninstall --purge
```

---

## What this setup was validated against

- Linux 6.12 x86_64, 2026-08-17
- podcli 2.6.0 (binary from official installer)
- Node v20.19.0, Python 3.12.13, FFmpeg 4.4.2 (all from system, not hermetic)
- Claude Code native CLI 2.1.233
- MCP server stdio over `node /root/.local/share/podcli/runtime/studio/mcp-server.mjs` → health check ✔ Connected

---

## Files in this repo

- `README.md` — this document (the only thing an agent needs)
- `setup.sh` — the steps above as a runnable script (best-effort; keep step 2's
  timeout in mind, and run the `claude mcp add` from a shell with `claude` on PATH)
