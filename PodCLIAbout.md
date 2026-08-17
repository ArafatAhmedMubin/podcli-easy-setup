# PodCLI - Open-Source Podcast Clip Generator

## Overview

**PodCLI** is a free, open-source, local-first podcast clip generator that transforms long-form podcast episodes into short, shareable clips optimized for TikTok, YouTube Shorts, and Instagram Reels. It combines Whisper transcription, AI-powered clip scoring, face-tracked cropping, and burned-in captions to automate the entire clipping workflow.

**Website:** [https://podcli.com](https://podcli.com)  
**GitHub:** [https://github.com/nmbrthirteen/podcli](https://github.com/nmbrthirteen/podcli)  
**License:** AGPL-3.0 (commercial license available)  
**Author:** Nika Siradze ([@nikasiradze_](https://nikusha.com))

---

## Key Features

### Core Capabilities

- **Whisper Transcription**: Word-level timestamps with speaker diarization
- **AI Clip Scoring**: Suggests the best moments using Claude or Codex API with four-dimension scoring against your knowledge base
- **Face-Tracking Crop**: Automatically follows speakers with support for:
  - Vertical 9:16 (TikTok, Reels, Shorts)
  - Horizontal 16:9 (YouTube)
  - Square 1:1 (Instagram posts)
- **Split-Screen Reframing**: Per-clip mouth-motion speaker tracking for multi-person podcasts
- **Burned-In Captions**: Four caption styles rendered via Remotion:
  - Branded
  - Hormozi
  - Karaoke
  - Subtle
- **Hardware-Accelerated Export**: VideoToolbox (Mac), NVENC (NVIDIA), VAAPI (Linux), with CPU fallback

### Content Workflow

- **Multiple Input Sources**: Process local files (`.mp4`, `.mov`, etc.) or pull episodes directly from YouTube URLs using yt-dlp
- **Alternative Transcription Engines**: AssemblyAI as an optional cloud-based alternative
- **Custom Transcripts**: Import your own transcripts as `.txt`, `.srt`, or `.vtt`
- **Highlight Detection**: Audio energy and laughter detection for automatic highlight reel creation
- **Duplicate Detection**: Episode database prevents resuggesting moments you've already published

### Web Studio (localhost:3847)

A full-featured web interface with:
- Library and episode workspace
- Per-clip detail views with content suggestions
- Thumbnail studio for 16:9 and 9:16 formats
- Analytics integration with YouTube performance sync (views, retention, CTR)
- Asset library for logos, intros, outros, and background music
- Knowledge base for maintaining show-specific voice and style
- Command palette (`⌘K`) for quick navigation
- Transcript corrections that propagate to all renders

### Publishing & Export

- **YouTube Integration**: Direct publishing with performance analytics
- **DaVinci Resolve Handoff**: Export clips as FCPXML for manual finishing
- **Clip History**: Track all renders with duplicate detection
- **Preset System**: Save and reuse configurations

---

## Why Choose PodCLI?

### vs. Hosted Clippers (OpusClip, ClipsAI, SupoClip, Descript, Riverside)

| Feature | PodCLI | Hosted Services |
|---------|--------|-----------------|
| **Cost** | Free (AGPL-3.0) | $15–$29/month |
| **Watermark** | None | Often present on free tiers |
| **Minute Cap** | Unlimited | Limited on free tiers |
| **Privacy** | Local-first, no uploads required | Requires file uploads |
| **Quality** | Full quality exports | May be compressed |
| **Agent Integration** | 26 MCP tools | Limited or none |
| **Customization** | Full control, open source | Limited customization |

### Unique Advantages

1. **Local-First Processing**: Transcription, clip picking, cropping, and export all run locally. Only optional AI scoring and YouTube publishing require network calls.

2. **Agent-Native Design**: Built as a Model Context Protocol (MCP) server with 26 tools, enabling Claude Code, Codex, Cursor, or any MCP client to drive the entire workflow through conversation.

3. **Knowledge Base**: Maintains your show's unique voice and style, preventing generic outputs and avoiding duplicate clip suggestions.

4. **Professional Handoff**: DaVinci Resolve FCPXML export for professional post-production workflows.

5. **Self-Contained Binary**: No complex setup—installer provisions Python, Node, FFmpeg, whisper.cpp, and models automatically.

---

## Installation

### macOS and Linux

```bash
curl -fsSL https://podcli.com/install.sh | sh
```

### Windows (PowerShell)

```powershell
irm https://podcli.com/install.ps1 | iex
```

**Platform Support:**
- macOS (Apple Silicon) — Intel Mac support in progress
- Linux (x64 and arm64)
- Windows (x64)

No prerequisites required. The installer fetches a self-contained binary, and the first run provisions all dependencies (Python, Node, FFmpeg, whisper.cpp, models) into a managed folder.

---

## Quick Start

### Basic Usage

```bash
# Interactive menu with web studio
podcli

# Process an episode directly
podcli process episode.mp4

# Generate top 5 clips
podcli process episode.mp4 --top 5
```

Clips are saved to `podcli-clips/` in the current directory by default. Set `PODCLI_OUTPUT` environment variable to use a fixed output location.

### MCP Integration

```bash
# Register with Claude Code
podcli mcp install
```

See [MCP Documentation](https://podcli.com/docs/mcp-server) for Claude Desktop and Codex setup.

### PodStack Slash Commands

For Claude Code users, [PodStack](https://github.com/nmbrthirteen/podstack) provides slash commands that integrate with PodCLI:

```
/produce-shorts   # Generate scored moments, titles, descriptions, thumbnail briefs, brand review, and publish checklist
```

Commands live in `.claude/commands/` with full documentation in `CLAUDE.md`.

---

## Architecture

PodCLI is built with three primary languages:

- **Go**: Core CLI and backend processing
- **TypeScript**: Web UI (React + Remotion for captions)
- **Python**: Whisper transcription and ML components

The system is designed as a local-first pipeline:

```
Input Video → Transcription → AI Scoring → Face Tracking → Cropping → Caption Rendering → Export
     ↓              ↓              ↓             ↓            ↓           ↓              ↓
  Local        whisper.cpp    Claude/Codex   MediaPipe    FFmpeg     Remotion      Hardware Encode
```

---

## Documentation

| Guide | Description |
|-------|-------------|
| [Getting Started](https://podcli.com/docs) | Installation, first episode, complete workflow |
| [The Studio](https://podcli.com/docs/the-studio) | Web UI guide: library, episodes, content, highlights |
| [CLI Reference](https://podcli.com/docs/cli) | Commands, flags, presets, assets |
| [MCP Server](https://podcli.com/docs/mcp-server) | Agent setup and 26 available tools |
| [Captions & Formats](https://podcli.com/docs/captions-and-formats) | Styles, aspect ratios, cropping options |
| [Configuration](https://podcli.com/docs/configuration) | Environment variables, config profiles, transcript formats |

Documentation repository: [nmbrthirteen/podcli-docs](https://github.com/nmbrthirteen/podcli-docs)

---

## Community & Support

- **GitHub Issues**: [Report bugs or request features](https://github.com/nmbrthirteen/podcli/issues)
- **Demo Video**: [Watch PodCLI in action on X](https://x.com/nikasiradze_/status/2056061654664708570)
- **Email Support**: [support@podcli.com](mailto:support@podcli.com)
- **Commercial Licensing**: Contact [siradze@nikusha.me](mailto:siradze@nikusha.me) for AGPL-free usage

---

## Contributing

PodCLI welcomes contributions! See:
- [CONTRIBUTING.md](https://github.com/nmbrthirteen/podcli/blob/main/CONTRIBUTING.md) — Development setup and conventions
- [RELEASE.md](https://github.com/nmbrthirteen/podcli/blob/main/RELEASE.md) — Release process

---

## Latest Version

**v2.6.0** (Released August 8, 2026)

Recent improvements include:
- Consolidated AI provider selection with optional remote sync
- Parallelized face detection during reframing for better performance
- Fixed Remotion DM Sans timeout issues
- Updated dependencies (TypeScript, yt-dlp, onnxruntime, pillow, etc.)

---

## License

**AGPL-3.0** — Free and open source. A commercial license is available for organizations that need to use PodCLI without AGPL terms.

---

*Last updated: August 2026*
