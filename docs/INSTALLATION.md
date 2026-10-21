# JK OS — Installation Guide

Complete installation instructions for JK OS v1.0. This guide assumes no
technical background: follow the steps in order.

---

## 0. Before you start

You need:

- A PC with **4 GB RAM** and at least **16 GB** of free disk space
- An **8 GB or larger USB stick** (it will be **erased** — back up its files)
- The JK OS ISO file: **`JK-OS-v1.0.iso`** from the Releases page

> ⚠️ Installing an operating system **erases the disk/partition you choose**.
> Back up your important files first. If you only want to *try* JK OS, use
> the Live mode in Step 3 — it changes nothing on your PC.

### Verify your download (recommended)

Compare the SHA-256 of the downloaded file with `JK-OS-v1.0.iso.sha256`
published next to the ISO. On Windows (PowerShell):

```powershell
Get-FileHash .\JK-OS-v1.0.iso -Algorithm SHA256
```

On Linux/macOS:

```bash
sha256sum JK-OS-v1.0.iso
```

The long code must match exactly. If it does not, download the file again.

---

## 1. Create the bootable USB

### On Windows — Rufus (easiest)

1. Download Rufus (free) from <https://rufus.ie> and open it.
2. **Device:** select your USB stick.
3. **Boot selection:** click **SELECT** and choose `JK-OS-v1.0.iso`.
4. **Partition scheme:** `GPT` for new PCs (UEFI), `MBR` for very old PCs.
5. Click **START** → choose **"Write in ISO Image mode"** → **OK**.
6. Wait until it says **READY**, then close Rufus.

### Alternative — Balena Etcher (Windows / macOS / Linux)

1. Download Etcher from <https://etcher.balena.io> and open it.
2. **Flash from file** → select the ISO.
3. **Select target** → select your USB stick.
4. **Flash!** and wait for validation to finish.

---

## 2. Boot from the USB

1. Keep the USB plugged in and **restart** the PC.
2. While it starts, repeatedly press the **boot menu key** for your brand:

   | Brand | Key |
   |---|---|
   | HP | `F9` / `Esc` |
   | Dell | `F12` |
   | Lenovo | `F12` / `Fn+F12` |
   | Acer | `F12` |
   | ASUS | `F8` / `Esc` |
   | Others | `F12`, `F11` or `Esc` — try them |

3. In the boot menu, choose your USB (it may appear as *UEFI: USB name* —
   choose that one on new PCs).
4. If the PC boots back into Windows instead: restart and try again, or open
   BIOS setup (`F2` / `Del`) and set **Secure Boot = Off** and USB boot first.

---

## 3. Try JK OS live (no installation)

1. From the JK OS boot menu choose **"Try JK OS (Live)"**.
2. The desktop opens automatically.
   - **Live user:** `jk`
   - **Password:** `jk` (also the sudo password, if asked)
3. Explore freely: open the Start menu, try the apps, say *"Hey Jarvis"*
   (microphone needed) or press the Jarvis tray icon.
4. **Nothing is written to your hard disk.** Restart and remove the USB to
   return your PC to exactly how it was.

---

## 4. Install JK OS to the hard disk

1. On the live desktop, double-click **Install JK OS**.
2. **Welcome / Language:** choose your language → *Next*.
3. **Keyboard:** pick your keyboard layout → *Next*.
4. **Location / Timezone:** select your region (e.g. Asia/Karachi) → *Next*.
5. **Partitions — the important step:**
   - **Erase disk** — simplest. The selected disk is fully erased and JK OS
     uses all of it. ✅ Choose this for a dedicated JK OS PC.
   - **Install alongside** — if offered, keeps your existing system and
     dual-boots. Needs enough free space.
   - **Manual** — for advanced users only.
   Double-check the disk name/size before continuing.
6. **Users:** create your name, computer name, username and a **strong
   password**. → *Next*.
7. **Summary:** review, then click **Install**.
8. Wait for the installation to finish (the bar shows real progress).
9. Click **Restart Now**, and **remove the USB** when the screen asks.

Your PC now boots into JK OS from its own disk. 🎉

---

## 5. First boot — the 2-minute setup

1. Log in with the user you created in Step 4.6.
2. Connect to Wi-Fi (tray icon, top-right area of the taskbar).
3. Open **JK Jarvis → Settings → Self-Test** and run it once — it checks your
   microphone, hearing, voice and AI status and shows pass/fail for each.
4. **Optional Jarvis packs** (Jarvis Settings → Downloads — sizes are shown
   before anything downloads):
   - *Urdu Pack* — Whisper small + Urdu voice (experimental)
   - *Local AI Brain* — Ollama + Qwen 2.5 (offline chat & smarter answers)
5. **Vibe Coding tools** live in the **Vibe Coding** folder on the Desktop:
   free tools are ready; the one-click installers fetch Cursor, Windsurf,
   Tabby and others when you want them.

---

## 6. Troubleshooting

| Problem | Fix |
|---|---|
| PC ignores the USB | Boot menu key again; try the other USB entry (UEFI vs plain); disable Secure Boot |
| "Verification failure" / security message at boot | Secure Boot is on — turn it **Off** in BIOS |
| Wi-Fi not visible | Reboot once after install; if still missing, connect a cable and run system updates |
| Black screen after boot menu | Choose the *"safe graphics"* entry in the JK OS boot menu |
| Forgot live password | Live password is `jk` — installed systems use the password **you** created |
| Jarvis does not hear me | Check the mic in Jarvis Self-Test; allow the correct input device in Sound Settings |

Still stuck? Open an issue on this repository with your PC model and the
exact step where you stopped.
