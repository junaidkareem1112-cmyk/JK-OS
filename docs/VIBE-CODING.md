# Vibe Coding in JK OS

JK OS ships a complete **AI coding ("vibe coding") toolkit** — free and
open-source tools pre-installed, paid tools one click away. Everything lives
in the **Vibe Coding** folder on the Desktop and in the Start menu.

> The tools are free. The AI *model* behind them is your choice: free local
> AI (Ollama), a free Gemini API key, or your own paid key/subscription.
> JK OS never bundles cracked software or anyone else's licence.

## Pre-installed — free & open source

| Tool | What it is | Start it with |
|---|---|---|
| **OpenCode** | Terminal AI coding agent, model-agnostic | `opencode` |
| **Freebuff** | Free terminal coding agent by the Codebuff team | Vibe Coding folder |
| **Aider** | Pair-programming in your terminal, git-aware | `aider` |
| **Continue** | AI autocomplete + chat inside the editor | Open the editor |
| **Cline** | Autonomous coding agent inside the editor | Editor sidebar |
| **Roo Code** | Cline fork with multiple modes | Editor sidebar |
| **Kilo Code** | Roo-family agent | Editor sidebar |
| **Gemini CLI** | Google's open-source terminal agent | `gemini` |
| **Muse** | OpenAI's open-source coding CLI | `codex` |
| **Qwen Code** | Qwen's terminal coding agent | Vibe Coding folder |
| **Goose** | Block's open-source AI agent | `goose` |
| **Crush** | Charmbracelet terminal AI coder | `crush` |
| **Ollama** | Local AI models — private, offline, free | `ollama run qwen2.5-coder` |

The code editor (VSCodium) and the light editor Geany are included, with
Python, PHP, Node.js, Git and SQLite ready for real project work.

## One-click installers — heavier free tools

| Tool | What it is |
|---|---|
| **Tabby** | Self-hosted AI code autocomplete server |
| **OpenHands** | Full autonomous dev-agent (Docker) |
| **Void** | Open-source Cursor-style editor |

## One-click installers — paid tools

These download the **official** apps. You sign in with **your own** paid
account — JK OS includes no licence, key or crack.

| Tool | Notes |
|---|---|
| **Cursor** | Official download from cursor.com |
| **Windsurf** | Official download, free tier available |
| **Muse** | Extension in the editor; needs your GitHub subscription |

## Recommended free setup (2 minutes)

1. Get a free **Google AI Studio** key (aistudio.google.com) — or skip this
   and use Ollama fully offline.
2. Open a terminal in your project folder.
3. Run `opencode`, choose your model, and start building — or open the
   editor and use Cline/Roo Code from the sidebar.

## Notes

- Exact pre-installed vs one-click status for every tool is verified at
  build time and printed in each release's notes — if a tool could not be
  verified during the ISO build, it is honestly listed as a one-click
  installer instead of being claimed as installed.
