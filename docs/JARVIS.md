# JK Jarvis — Voice AI Assistant

JK Jarvis is the built-in voice assistant of JK OS. It is **offline-first,
private, and honest about its limits**.

## How it works

```
"Hey Jarvis"  →  hears you  →  understands the command  →  does it  →  replies by voice
 (wake word)      (STT)            (intent router)          (action)        (Piper TTS)
```

1. **Wake word** — openWakeWord listens locally for *"Hey Jarvis"*. Nothing
   is recorded or sent anywhere while it waits. Push-to-talk (tray icon or
   keyboard shortcut) is always available as a reliable alternative.
2. **Hearing (STT)** — Vosk (small English model, 40 MB, fully offline)
   handles commands instantly. Whisper packs add better dictation and Urdu.
3. **Understanding** — a deterministic **intent router** matches your words
   to a fixed allowlist of safe commands. It does **not** need an AI model,
   so normal commands are instant and can never "hallucinate" an action.
4. **Brain (optional)** — questions that are not commands go to a local LLM
   via Ollama (Qwen 2.5), or — only if **you** add your own API key — to a
   cloud AI. Both are off/configurable in Settings; offline is the default.
5. **Voice (TTS)** — Piper natural voice (English). eSpeak-NG is the
   always-available fallback. An experimental Urdu Piper voice is available
   in the Urdu Pack.

## Example commands

| Say | Jarvis does |
|---|---|
| "Open Firefox" / "Calculator kholo" | Opens the app |
| "Volume up / down / mute" · "Volume barhao" | Controls sound (pactl) |
| "Brightness kam karo" | Controls brightness |
| "Play music" / "Pause" / "Next song" | Media control (playerctl) |
| "Find file invoice" | Searches your files by name |
| "Search the web for …" | Opens Firefox with your search |
| "What time is it?" | Speaks the time & date |
| "Take a screenshot" | Captures the screen |
| "Lock the screen" | Locks immediately |
| "Type what I say" | Dictation mode (best with a Whisper pack) |

Roman-Urdu alias phrases (e.g. *"band karo"*, *"volume barhao"*) are built
into the intent matcher — Urdu speakers can mix Urdu and English naturally.

## Safety rules (non-negotiable)

- **Confirmation first:** shutdown, restart, delete and terminal/sudo
  actions require a spoken + on-screen **YES**. No answer within a few
  seconds counts as **NO**.
- **Delete means Trash** (`gio trash`) — files can always be recovered.
  Jarvis never runs `rm`.
- **Allowlist only:** raw speech is never passed to a shell. The AI brain —
  local or cloud — cannot execute anything by itself; its suggestions go
  through the same confirmation gate.
- **Mic indicator:** the tray icon shows when Jarvis is listening. The mic
  can be switched off completely in Settings.

## Optional packs (Jarvis Settings → Downloads)

Sizes are always shown before downloading. Nothing is forced.

| Pack | Size | Gives you |
|---|---|---|
| English Dictation (Whisper base) | ~142 MB | Better free dictation |
| Urdu Pack (Whisper small + Urdu voice) | ~466 MB + ~64 MB | Urdu commands & Urdu replies — **experimental** |
| Local AI Brain (Ollama + Qwen 2.5 3B) | ~1.9 GB | Offline chat & smarter answers on 4 GB RAM |
| Local AI Brain — Light (Qwen 2.5 1.5B) | ~986 MB | Faster, lighter offline chat |

## Robustness

- Runs as a `systemd --user` service with **auto-restart on failure**
- **Self-Test** in Settings: microphone, wake word, hearing, voice and AI —
  each shown pass/fail
- No microphone? Jarvis switches to text/push-to-talk mode and tells you —
  it never silently dies
- No internet? Full offline command mode, no error spam

## Honest limitations

- **Urdu hearing is experimental.** Measured word error rate for the best
  fitting offline model is ≈ 33.7 % for Urdu — good enough for commands,
  **not** reliable for long dictation.
- The **Urdu voice is new and unbenchmarked**; it may sound rough.
- The stock *"hey jarvis"* wake-word model is **CC BY-NC-SA 4.0**
  (non-commercial). It ships in this free v1 build; a self-trained model is
  planned for v2 so commercial use is fully clean.
- Local AI chat on a 4 GB PC is **useful but slow** (a few seconds per
  reply) and small models answer noticeably worse than cloud AI.
- Wake words can occasionally false-trigger on TV/video speech. Push-to-talk
  is the reliability escape hatch.

## Privacy

Jarvis hears, understands and speaks **on your PC**. No audio leaves the
machine unless *you* enable a cloud AI with *your own* key — and even then,
only the text of unmatched questions is sent, never command audio.
