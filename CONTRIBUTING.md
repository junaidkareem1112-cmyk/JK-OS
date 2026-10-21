# Contributing to JK OS

Thank you for helping make JK OS better! JK OS is a community open-source
project by JK Soft Solutions.

## Ways to help

- 🐛 **Bug reports** — open an issue with your PC model, RAM, what you did,
  what you expected, and what happened. A photo of the screen helps a lot.
- 🧪 **Hardware testing** — JK OS targets ordinary 4 GB PCs. Reports from
  old laptops are gold.
- 🌍 **Translations** — Urdu first! Interface strings, docs and Jarvis
  command aliases (Roman Urdu phrases are especially welcome).
- 🎨 **Artwork** — wallpapers, icons and themes in the JK pine-green style:
  deep pine `#0C5B44`, dark green-charcoal `#0A1F18`, warm cream `#FAF6EE`.
  Solid, human-crafted colours — no blue/purple AI-style gradients.
- 📖 **Documentation** — clearer guides, screenshots, how-to videos.
- 💻 **Code** — build scripts, Jarvis intents and tools. Keep it lightweight:
  every addition is weighed against the 4 GB RAM / small-ISO promise.

## Ground rules

1. **Lightweight is law.** If a feature makes JK OS heavy, it belongs in a
   one-click installer, not in the ISO.
2. **Honesty is law.** Never claim a feature works if it is not tested.
   "Experimental" is a respectable label — hiding a limitation is not.
3. **Safety in Jarvis.** New voice intents must be allowlisted, and anything
   destructive needs the confirmation gate. Deletes go to Trash, never `rm`.

## Getting started

1. Fork the repo and clone your fork.
2. Read the build overview in the main README.
3. Make your change, test it (a QEMU boot test for anything system-level),
   and open a pull request describing **what** changed and **how you tested
   it**.
