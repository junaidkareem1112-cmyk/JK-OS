# JK OS

**A free & open-source operating system that looks and feels like Windows 11 — built on Debian 12, powered by JK Jarvis voice AI, packed with tools for work, coding, vibe coding and art.**

Made with care in Multan, Pakistan by [JK Soft Solutions](https://jksoft.store).

![Status](https://img.shields.io/badge/status-v1.0%20in%20development-amber)
![Base](https://img.shields.io/badge/base-Debian%2012%20Bookworm-0C5B44)
![Desktop](https://img.shields.io/badge/desktop-XFCE%20(Windows%2011--like)-0C5B44)
![RAM](https://img.shields.io/badge/RAM-4%20GB-0C5B44)
![License](https://img.shields.io/badge/license-see%20NOTICE.md-0C5B44)

---

## What is JK OS?

JK OS is a complete, bootable operating system. Burn it to a USB stick, boot any PC from it, try it live, and install it to the hard disk in minutes — no Windows licence needed, no cost, ever.

It is designed around three promises, set by its creator:

1. **Har tarah ka tool** — every kind of tool is included: office, internet, media, graphics, development, utilities.
2. **Mazboot** — strong and stable. JK OS is built on Debian 12, the most battle-tested Linux base in the world.
3. **Lightweight** — no bloat. JK OS runs smoothly on a PC with just 4 GB of RAM.

## Highlights

- 🪟 **Windows 11-like desktop** — bottom taskbar, Start menu, system tray, centred JK pine-green branding
- 🎙️ **JK Jarvis** — a built-in voice assistant. Say *"Hey Jarvis"* and ask it to open apps, control volume and brightness, play music, find files, search the web and more. Works offline for commands. ([details](docs/JARVIS.md))
- 💻 **Vibe Coding suite** — a complete AI coding toolkit: OpenCode, Freebuff, Aider, Continue, Cline, Roo Code, Kilo Code, Gemini CLI, Muse, Qwen Code, Goose, Crush and local AI with Ollama — plus one-click installers for paid tools like Cursor, Windsurf and Muse. ([details](docs/VIBE-CODING.md))
- 🎨 **Art & Craft suite** — GIMP, Inkscape, Krita, Scribus, Audacity and more open-source creative tools, with one-click installers for Blender, Kdenlive and others. ([details](docs/ART-AND-CRAFT.md))
- 🧰 **Everyday tools** — LibreOffice, Firefox, Thunderbird, VLC, and every utility a normal PC user needs
- 🍷 **Wine support** — run many Windows `.exe` programs
- 🔒 **Private by design** — no telemetry, no forced accounts, voice AI is offline by default

## System requirements

| | Minimum / Target |
|---|---|
| RAM | 4 GB (JK Jarvis full mode) |
| Disk | 16 GB free (32 GB recommended) |
| CPU | 64-bit dual-core or better |
| USB stick | 8 GB (for installation) |
| Boot | BIOS and UEFI both supported (Secure Boot: off) |

## Installation

**Full step-by-step guide: [docs/INSTALLATION.md](docs/INSTALLATION.md)**

Quick version:

1. Download `JK-OS-v1.0.iso` from the [Releases](../../releases) page and verify its SHA-256 checksum.
2. Write the ISO to a USB stick with [Rufus](https://rufus.ie) (Windows) or Balena Etcher.
3. Boot the PC from the USB (boot menu key is usually F12 / F9 / Esc).
4. Try JK OS live — nothing on your disk is touched.
5. Click **Install JK OS** and follow the friendly installer (language → disk → user → done).
6. Restart, remove the USB, and log in.

**Live session:** user `jk` · password `jk`

## What's inside

### Everyday tools
LibreOffice (Writer, Calc, Impress), PDF viewer, Firefox ESR, Thunderbird, VLC, image viewer, GIMP, file manager, calculator, text editor, screenshot tool, archive manager, disk/partition tool (GParted), software store & Synaptic, printing (CUPS), Bluetooth, Wi-Fi drivers, firewall (UFW).

### Developer tools
Python 3 + pip, PHP CLI, Node.js, Git, SQLite, GCC/make, Geany, plus the full Vibe Coding suite above.

### JK Jarvis — voice AI
Wake word *"Hey Jarvis"* or push-to-talk, instant offline commands in English, an experimental Urdu pack, natural Piper voice, optional local LLM (Ollama) and optional cloud AI with **your own** key. Destructive actions (shutdown, delete, terminal commands) always ask for confirmation first. Full command list and honesty notes: [docs/JARVIS.md](docs/JARVIS.md).

## Building from source

JK OS is built with a transparent shell-script pipeline on top of `debootstrap`:

```
debootstrap (Debian 12 rootfs) → package install → customisation
(themes, panel, Jarvis, tool suites) → kernel + live-boot →
squashfs → hybrid ISO (BIOS + UEFI) with xorriso
```

The build scripts (`build.sh`, `customize-rootfs.sh`, `vibe-customize.sh`,
`art-customize.sh`, `stage4-iso.sh`, `qemu-test.sh`) are published in this
repository together with each release, so anyone can audit and rebuild the
exact ISO. Every release also passes an automated QEMU boot test before
publication.

## Project status

**v1.0 is in active development.** This repository is the public home of the
project: documentation, build scripts and release notes live here first, and
the v1.0 ISO will be published on the Releases page as soon as it passes its
boot and install tests. Watch this repo to be notified.

## Contributing

JK OS is open source and contributions are welcome — translations
(especially Urdu), testing on old hardware, artwork, documentation and bug
reports all help. See [CONTRIBUTING.md](CONTRIBUTING.md).

## Credits & licences

JK OS stands on the shoulders of giants: Debian GNU/Linux, the XFCE desktop,
the Linux kernel, and hundreds of open-source projects. JK OS's own code is
MIT-licensed; every bundled component keeps its own licence. The pre-trained
"hey jarvis" wake-word model is CC BY-NC-SA 4.0 and is being replaced by a
self-trained model in a future release. Details: [NOTICE.md](NOTICE.md) ·
[LICENSE](LICENSE)

## About the maker

**Muhammad Junaid Kareem (Jk)** — Founder & CEO, **JK Soft Solutions**
Custom ERP, POS and business software · Multan, Pakistan
🌐 [jksoft.store](https://jksoft.store)
