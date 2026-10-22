#!/bin/bash
# JK OS stage 4: customize rootfs, Jarvis install, squashfs, hybrid ISO, verify
set -x
exec > >(tee -a ~/workspace/jk-os/build.log) 2>&1
JK=~/workspace/jk-os; R=$JK/rootfs; ISO_DIR=$JK/iso
# ensure mounts released before customization edits
for m in sys proc dev/pts dev; do mountpoint -q "$R/$m" && umount "$R/$m" || true; done
bash "$JK/privacy-install.sh" || echo "PRIVACY INSTALL ISSUE (see logs)"
bash "$JK/customize-rootfs.sh" "$R"
bash "$JK/vibe-customize.sh" "$R"
bash "$JK/art-customize.sh" "$R"
bash "$JK/privacy-customize.sh"
bash "$JK/systools-customize.sh" "$R"
# ---- Panel launchers (files the panel plugins reference) ----
SKEL="$R/etc/skel"
for id in 2 3 4; do mkdir -p "$SKEL/.config/xfce4/panel/launcher-$id"; done
cp "$R/usr/share/applications/firefox-esr.desktop" "$SKEL/.config/xfce4/panel/launcher-2/firefox-esr-1.desktop" 2>/dev/null || true
cp "$R/usr/share/applications/thunar.desktop" "$SKEL/.config/xfce4/panel/launcher-3/thunar-2.desktop" 2>/dev/null || true
cp "$R/usr/share/applications/libreoffice-writer.desktop" "$SKEL/.config/xfce4/panel/launcher-4/libreoffice-writer-3.desktop" 2>/dev/null || true
# codium extensions mirror to skel (so installed-system users also get them)
if [ -d "$R/home/jk/.vscode-oss/extensions" ]; then mkdir -p "$SKEL/.vscode-oss"; mv "$R/home/jk/.vscode-oss/extensions" "$SKEL/.vscode-oss/"; fi
cp -a "$R/home/jk/.vscode-oss" "$SKEL/" 2>/dev/null || true
# user jk home gets skel content too (live session uses existing jk user, not skel!)
cp -a "$SKEL/." "$R/home/jk/" 2>/dev/null || true
chown -R 1000:1000 "$R/home/jk" 2>/dev/null || chroot "$R" chown -R jk:jk /home/jk || true
# ---- JK Jarvis install ----
JM="$R/usr/share/jk-assistant"; mkdir -p "$JM/models/piper" "$JM/models/openwakeword"
install -m755 "$JK/jarvis/jk-assistant.py" "$JM/jk-assistant.py"
install -m755 "$JK/jarvis/test_intents.py" "$JM/test_intents.py"
install -m755 "$JK/jarvis/jk-jarvis-settings.py" "$R/usr/local/bin/jk-jarvis-settings"
install -m755 "$JK/jarvis/jk-jarvis-tray.py" "$R/usr/local/bin/jk-jarvis-tray"
cat > "$R/usr/local/bin/jk-assistant" <<'EOF'
#!/bin/sh
exec /opt/jk-assistant-venv/bin/python /usr/share/jk-assistant/jk-assistant.py "$@"
EOF
chmod +x "$R/usr/local/bin/jk-assistant"
# models
cd "$JK/jarvis/dl" && unzip -o -q vosk.zip && cp -a vosk-model-small-en-us-0.15 "$JM/models/"
cp en_US-lessac-medium.onnx en_US-lessac-medium.onnx.json "$JM/models/piper/"
# openwakeword hey_jarvis model from venv (pip package resources)
find "$R/opt/jk-assistant-venv" -iname "*hey_jarvis*" -exec cp {} "$JM/models/openwakeword/" \; 2>/dev/null || true
ls -lhR "$JM/models" | head -40
# systemd --user service + health timer
U="$R/etc/skel/.config/systemd/user"; mkdir -p "$U"
cat > "$U/jk-jarvis.service" <<'EOF'
[Unit]
Description=JK Jarvis Voice Assistant
After=graphical-session.target sound.target
[Service]
ExecStart=/usr/local/bin/jk-assistant
Restart=on-failure
RestartSec=3
Environment=PYTHONUNBUFFERED=1
[Install]
WantedBy=default.target
EOF
cat > "$U/jk-jarvis-health.service" <<'EOF'
[Unit]
Description=JK Jarvis health check
[Service]
Type=oneshot
ExecStart=/bin/sh -c "systemctl --user is-active --quiet jk-jarvis.service || systemctl --user restart jk-jarvis.service"
EOF
cat > "$U/jk-jarvis-health.timer" <<'EOF'
[Unit]
Description=JK Jarvis health check every 2 minutes
[Timer]
OnBootSec=2min
OnUnitActiveSec=2min
[Install]
WantedBy=timers.target
EOF
mkdir -p "$U/default.target.wants" "$U/timers.target.wants"
ln -sf ../jk-jarvis.service "$U/default.target.wants/jk-jarvis.service"
ln -sf ../jk-jarvis-health.timer "$U/timers.target.wants/jk-jarvis-health.timer"
# autostart tray + PTT shortcut helper
mkdir -p "$SKEL/.config/autostart"

# ---- JK Quick Settings + Live Captions + Language tool ----
install -m755 "$JK/jk-quick-settings.py" "$R/usr/local/bin/jk-quick-settings"
install -m755 "$JK/jk-live-captions.py" "$R/usr/local/bin/jk-live-captions"
install -m755 "$JK/jk-language.py" "$R/usr/local/bin/jk-language"
cat > "$R/usr/share/applications/jk-quick-settings.desktop" <<'EOFQS'
[Desktop Entry]
Name=JK Quick Settings
Comment=WiFi, Bluetooth, Flight Mode, Volume, Brightness
Exec=jk-quick-settings
Icon=preferences-system-network
Terminal=false
Type=Application
Categories=Settings;System;
EOFQS
cat > "$R/usr/share/applications/jk-live-captions.desktop" <<'EOFQS'
[Desktop Entry]
Name=JK Live Captions (Experimental)
Exec=jk-live-captions
Icon=accessibility
Terminal=false
Type=Application
Categories=Accessibility;Utility;
EOFQS
cat > "$R/usr/share/applications/jk-language.desktop" <<'EOFQS'
[Desktop Entry]
Name=JK Language
Comment=English / Urdu / Arabic interface language
Exec=jk-language
Icon=preferences-desktop-locale
Terminal=false
Type=Application
Categories=Settings;System;
EOFQS
mkdir -p "$SKEL/.config/xfce4/panel/launcher-12"
cat > "$SKEL/.config/xfce4/panel/launcher-12/jk-quick-settings-12.desktop" <<'EOFQS'
[Desktop Entry]
Name=JK Quick Settings
Exec=jk-quick-settings
Icon=preferences-system-network
Terminal=false
Type=Application
EOFQS
cp "$R/usr/share/applications/jk-language.desktop" "$SKEL/Desktop/JK-Language.desktop" 2>/dev/null || true
chmod +x "$SKEL/Desktop/JK-Language.desktop" 2>/dev/null || true

cat > "$SKEL/.config/autostart/jk-jarvis-tray.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=JK Jarvis Tray
Exec=jk-jarvis-tray
X-GNOME-Autostart-enabled=true
EOF
cat > "$R/usr/local/bin/jk-jarvis-ptt" <<'EOF'
#!/bin/sh
touch /tmp/jk-jarvis-ptt
EOF
chmod +x "$R/usr/local/bin/jk-jarvis-ptt"
# XFCE keyboard shortcut for PTT (Super+J) via xfconf skel
cat > "$SKEL/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-keyboard-shortcuts" version="1.0">
  <property name="commands" type="empty">
    <property name="default" type="empty"/>
    <property name="custom" type="empty">
      <property name="&lt;Super&gt;j" type="string" value="jk-jarvis-ptt"/>
      <property name="&lt;Super&gt;a" type="string" value="jk-quick-settings"/>
      <property name="&lt;Primary&gt;&lt;Alt&gt;t" type="string" value="xfce4-terminal"/>
      <property name="Print" type="string" value="xfce4-screenshooter"/>
      <property name="&lt;Primary&gt;&lt;Shift&gt;Escape" type="string" value="xfce4-taskmanager"/>
      <property name="&lt;Super&gt;r" type="string" value="xfce4-appfinder"/>
    </property>
  </property>
</channel>
EOF
# Jarvis menu entries + desktop guide
cat > "$R/usr/share/applications/jk-jarvis.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=JK Jarvis (Voice Assistant)
Comment=Hey Jarvis - voice control, offline first
Exec=jk-jarvis-settings
Icon=audio-input-microphone
Categories=Utility;Accessibility;
EOF
cat > "$SKEL/Desktop/Jarvis - Kaise Chalaye.txt" <<'EOF'
JK JARVIS - Voice Assistant (JK OS)
====================================
CHALANA:
1) Bolein: "Hey Jarvis" - phir command bole.
2) Ya Push-to-Talk: keyboard Super+J dabain, ya neeche tray ke mic icon par click karein.
3) Settings/Self-Test: Start menu > JK Jarvis, ya tray icon par right-click.

COMMANDS (English - full):
"Open Firefox / Calculator / Terminal / File Manager", "Volume up/down", "Mute",
"Brightness up/down", "Play / Pause / Next song", "What time is it", "What is the date",
"Take a screenshot", "Lock the screen", "System info", "Close this window",
"Set a timer for 5 minutes", "Search the web for ...", "Google ...",
"Shut down / Reboot" (confirmation dialog aayega - Yes lazmi, warna cancel),
"Delete file <naam>" (confirmation + sirf Trash, kabhi permanent delete nahi).

ROMAN URDU (experimental, best-effort):
"Volume barhao", "Awaaz kam karo", "Firefox kholo", "Band karo", "Waqt kya hai", "Light barhao".
Urdu sahi support ke liye Settings se "Whisper Small (Urdu)" pack download karein.

OPTIONAL PACKS (Settings > Download, size pehle dikhta hai):
- Ollama + Qwen2.5 3B (1.9GB): local AI brain - sawalon ke jawab, offline. 4GB RAM par recommended.
- Whisper Small 466MB: Urdu mode. Whisper Base 142MB: English dictation behtar.
- Piper Urdu voice 64MB: Urdu awaz me jawab (experimental).

PRIVACY: Jarvis by default OFFLINE hai. Mic sirf wake word / push-to-talk par sunta hai,
tray me mic indicator rehta hai. Cloud AI OFF hai jab tak AAP apni key Settings me na dalein.
Local AI (Ollama) bhi sirf aapke PC par chalta hai.

LIMITS (imaandari se): Mic/voice asal hardware par test hoga - pehli dafa mic check kar lein.
Urdu pehchan experimental hai (commands chalenge, lambi dictation reliable nahi).
"Hey Jarvis" model free use ke liye hai (CC BY-NC-SA license).
RAM: 4 GB recommended (Jarvis full/strong mode). Bina mic ke text/PTT mode bhi chalta hai.
====================================
EOF
cp -a "$SKEL/Desktop/Jarvis - Kaise Chalaye.txt" "$R/home/jk/Desktop/" 2>/dev/null || true
cp -a "$SKEL/." "$R/home/jk/" 2>/dev/null || true
chroot "$R" chown -R jk:jk /home/jk 2>/dev/null || true
# live config: username jk
mkdir -p "$R/etc/live/config"; echo 'LIVE_USERNAME="jk"
LIVE_HOSTNAME="jk-os"' > "$R/etc/live/config.conf" 2>/dev/null || true
install -m755 "$JK/jk-install-test.sh" "$R/usr/local/bin/jk-install-test" 2>/dev/null || true
# ---- JK LOGO (user faisla 2026-10-21: design JK monogram+arrow, rang PINE GREEN) ----
if [ -f "$JK/jk-os-logo.png" ]; then
  install -m644 "$JK/jk-os-logo.png" "$R/etc/calamares/branding/debian/jk-os-logo.png" && echo "JK LOGO: pine logo calamares branding me lag gaya (jk-os-logo.png)"
else
  echo "JK LOGO: WARN jk-os-logo.png nahi mili - branding baghair naye logo ke"
fi
# ---- JK: Automatic security updates (Jk ka faisla 2026-10-21) ----
mkdir -p "$R/etc/apt/apt.conf.d"
cat > "$R/etc/apt/apt.conf.d/20auto-upgrades" <<'EOFAU'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOFAU
cat > "$R/etc/apt/apt.conf.d/51jk-unattended-upgrades" <<'EOFAU'
// JK OS: automatic updates SIRF Debian security ke liye
Unattended-Upgrade::Origins-Pattern {
        "origin=Debian,codename=bookworm-security,label=Debian-Security";
};
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Automatic-Reboot "false";
EOFAU
AU_OK=0
# bind-mount + deb-cache par inhisaar khatam: run14 me bind-mount fail hua (glob khali)
# aur privacy-install ka apt-get clean deb-cache saaf kar deta hai. Is liye 6 debs
# $JK/au-debs se seedha rootfs me COPY karke dpkg -i (network-free, mount-free).
rm -f "$JK/auto-updates-install.log"
mkdir -p "$R/tmp/au-debs"
for f in distro-info-data_0.58+deb12u7_all.deb lsb-release_12.0-1_all.deb python-apt-common_2.6.0_all.deb python3-apt_2.6.0_amd64.deb python3-distro-info_1.5+deb12u1_all.deb unattended-upgrades_2.9.1+nmu3_all.deb; do
  cp "$JK/au-debs/$f" "$R/tmp/au-debs/$f" 2>/dev/null && echo "AU deb copied: $f" >> "$JK/auto-updates-install.log" || echo "JK AUTO-UPDATES: WARN deb copy FAIL $f"
done
mount -t tmpfs tmpfs "$R/dev" 2>/dev/null || true
for d in null zero tty urandom ptmx; do [ -e "/dev/$d" ] && touch "$R/dev/$d" && mount --bind "/dev/$d" "$R/dev/$d" 2>/dev/null || true; done
mount -t proc proc "$R/proc" 2>/dev/null || true
chroot "$R" /bin/bash -c "dpkg -i /tmp/au-debs/distro-info-data_0.58+deb12u7_all.deb /tmp/au-debs/lsb-release_12.0-1_all.deb /tmp/au-debs/python-apt-common_2.6.0_all.deb /tmp/au-debs/python3-apt_2.6.0_amd64.deb /tmp/au-debs/python3-distro-info_1.5+deb12u1_all.deb /tmp/au-debs/unattended-upgrades_2.9.1+nmu3_all.deb; echo ---; dpkg -l unattended-upgrades | tail -1; ls -l /usr/bin/unattended-upgrade" >> "$JK/auto-updates-install.log" 2>&1 || true
[ -x "$R/usr/bin/unattended-upgrade" ] && AU_OK=1
mountpoint -q "$R/proc" && umount "$R/proc" 2>/dev/null
mountpoint -q "$R/dev" && umount -R "$R/dev" 2>/dev/null
rm -rf "$R/tmp/au-debs"
echo "JK AUTO-UPDATES: $([ $AU_OK = 1 ] && echo 'unattended-upgrades INSTALLED + security-only auto-updates ON' || echo 'package install nahi hua (auto-updates-install.log dekho) - config files mojood hain')"
# ---- cleanup + squashfs ----
rm -rf "$R/opt/jk/"*.deb "$R/opt/jk/"*.vsix "$R/opt/jk/node.tar.xz" "$R/root/.cache" "$R/home/jk/.cache" 2>/dev/null || true
rm -rf "$R/var/lib/apt/lists/"* "$R/var/cache/apt/"*.bin 2>/dev/null || true
echo > "$R/etc/machine-id"; rm -f "$R/var/lib/dbus/machine-id"
du -sh "$R"
mkdir -p "$ISO_DIR/live" "$ISO_DIR/boot/grub" "$ISO_DIR/isolinux" "$ISO_DIR/EFI/BOOT"
cp "$R"/boot/vmlinuz-* "$ISO_DIR/live/vmlinuz"; cp "$R"/boot/initrd.img-* "$ISO_DIR/live/initrd.img"
ls -lh "$ISO_DIR/live/"
echo "===== JK LOOK FIX (user verdicts 2026-10-22 13:37-13:47 PKT) ====="
# (1) Remove "Install ..." desktop shortcuts for apps that ARE pre-installed
#     (Wine, Thunderbird, LibreCAD, Scribus are dpkg-verified installed; the
#     shortcuts were misleading clutter on the desktop Jk saw).
for D in "$R/etc/skel/Desktop" "$R/home/jk/Desktop"; do
  rm -f "$D/Install Wine.desktop" "$D/Install-Thunderbird Mail.desktop" \
        "$D/Art & Craft/Install-Thunderbird Mail.desktop" \
        "$D/Art & Craft/Install-LibreCAD.desktop" \
        "$D/Art & Craft/Install-Scribus.desktop" 2>/dev/null || true
done
# (2) Wallpaper: the baked xfconf only set monitor0, but real displays
#     enumerate as monitorVirtual-1 / monitoreDP-1 / monitorHDMI-1 etc, so
#     xfdesktop fell back to the stock xfce-shapes backdrop (Jk: "logo show
#     nahi howa"). Login-time fixer sets it on the CONNECTED monitor.
cat > "$R/usr/local/bin/jk-wallpaper-fix" <<'EOFWP'
#!/bin/sh
sleep 2
MON=$(xrandr 2>/dev/null | awk '/ connected/{print $1; exit}')
[ -n "$MON" ] || MON="Virtual-1"
for W in 0 1 2 3; do
  xfconf-query -c xfce4-desktop -p "/backdrop/screen0/monitor$MON/workspace$W/last-image" -n -t string -s /usr/share/backgrounds/jk-os/wallpaper.png 2>/dev/null
  xfconf-query -c xfce4-desktop -p "/backdrop/screen0/monitor$MON/workspace$W/image-style" -n -t int -s 5 2>/dev/null
done
EOFWP
chmod 755 "$R/usr/local/bin/jk-wallpaper-fix"
for D in "$R/etc/skel/.config/autostart" "$R/home/jk/.config/autostart"; do
  mkdir -p "$D"
  printf '[Desktop Entry]\nType=Application\nName=JK Wallpaper Fix\nExec=/usr/local/bin/jk-wallpaper-fix\nX-GNOME-Autostart-enabled=true\nNoDisplay=true\n' > "$D/jk-wallpaper.desktop"
done
echo "JK LOOK FIX applied (install-shortcuts cleaned, wallpaper fixer installed)"

echo "===== JK PERMS FIX: build-umask (0007) damage normalization ====="
# Root cause found in QEMU live test 2026-10-22: /usr was 2770 -> non-root users
# could not traverse it -> /bin/bash "Permission denied", user@1000 failed, no desktop.
chmod 755 "$R" "$R/usr" "$R/etc" "$R/var" "$R/opt" 2>/dev/null || true
find "$R/etc/skel" -type d -exec chmod 755 {} + 2>/dev/null || true
find "$R/home/jk" -type d -exec chmod 755 {} + 2>/dev/null || true
find "$R/etc/skel" "$R/home/jk" -type f -perm 0660 -exec chmod 644 {} + 2>/dev/null || true
chmod 644 "$R/etc/firefox-esr/jkos.js" "$R/etc/lsb-release" "$R/etc/live/config.conf" 2>/dev/null || true
find "$R" -xdev -type f -perm 0660 ! -path "*/ssl/private/*" ! -name ".pwd.lock" ! -name "opasswd" ! -name "shadow*" ! -name "gshadow*" -exec chmod 644 {} + 2>/dev/null || true
rm -rf "$R/home/hatch"
# v2 (QEMU live test #2, 2026-10-22): bind-mounted trees (usr/local, usr/share,
# usr/lib, opt) were SKIPPED by the -xdev sweep above -> jk-* helper scripts
# stayed 770 -> jk-assistant 203/EXEC (Jarvis crash-loop), XAMPP/Android helpers dead.
for T in usr/local usr/share usr/lib; do
  find "$R/$T" -type d -perm 2770 -exec chmod 755 {} + 2>/dev/null || true
  find "$R/$T" -type f -perm 0660 -exec chmod 644 {} + 2>/dev/null || true
  find "$R/$T" -type f -perm 0770 -exec chmod 755 {} + 2>/dev/null || true
done
find "$R/opt" -type f -perm 0660 ! -path "*/lampp/*" -exec chmod 644 {} + 2>/dev/null || true
find "$R/opt" -type f -perm 0770 ! -path "*/lampp/*" -exec chmod 755 {} + 2>/dev/null || true
JAM=$(stat -c %a "$R/usr/local/bin/jk-assistant" 2>/dev/null || echo "?")
BADBIN=$(find "$R/usr/local/bin" -type f ! -perm -o=r 2>/dev/null | wc -l)
echo "JK PERMS FIX v2: jk-assistant mode=$JAM, usr/local/bin non-world-readable files=$BADBIN"
[ "$JAM" = "755" ] || { echo "PERMS GATE FAIL: jk-assistant=$JAM (expected 755)"; exit 1; }
# v3 (QEMU live test #3, 2026-10-22): the damaged dirs are 0770, NOT 2770 as the
# v1/v2 find filters assumed (plain 'x' in group position = no setgid) -> every
# -perm 2770 dir sweep was a silent no-op. Jarvis then failed one layer deeper:
# /usr/share/jk-assistant + /opt/jk-assistant-venv stayed 0770 -> venv python
# "Permission denied" (exit 126). Blanket-fix ALL 0770 dirs (Debian-legit
# private dirs are 0700/2710/setgid-2770, none are plain 0770 root:root).
find "$R" -type d -perm 0770 ! -path "*/lampp/*" -exec chmod 755 {} + 2>/dev/null || true
BADDIR=$(find "$R" -type d -perm 0770 ! -path "*/lampp/*" 2>/dev/null | wc -l)
JSD=$(stat -c %a "$R/usr/share/jk-assistant" 2>/dev/null || echo "?")
VENV=$(stat -c %a "$R/opt/jk-assistant-venv" 2>/dev/null || echo "?")
echo "JK PERMS FIX v3: 0770 dirs left=$BADDIR, jk-assistant dir=$JSD, venv dir=$VENV"
[ "$BADDIR" = "0" ] && [ "$JSD" = "755" ] && [ "$VENV" = "755" ] || { echo "PERMS GATE FAIL v3: dirs=$BADDIR jsd=$JSD venv=$VENV"; exit 1; }
UPERM=$(stat -c %a "$R/usr" 2>/dev/null || echo "?")
echo "JK PERMS FIX done: /usr mode=$UPERM"
[ "$UPERM" = "755" ] || { echo "PERMS GATE FAIL: /usr=$UPERM (expected 755)"; exit 1; }
echo "bash path check: $(stat -c %a "$R/usr/bin/bash" 2>/dev/null)"

mksquashfs "$R" "$ISO_DIR/live/filesystem.squashfs" -comp zstd -Xcompression-level 19 -b 1M -noappend -wildcards -e "proc/*" "sys/*" "dev/*" "run/*" "tmp/*" | tail -3
ls -lh "$ISO_DIR/live/filesystem.squashfs"
# ---- boot files ----
cp /usr/lib/ISOLINUX/isolinux.bin "$ISO_DIR/isolinux/"; cp /usr/lib/syslinux/modules/bios/*.c32 "$ISO_DIR/isolinux/" 2>/dev/null || cp /usr/share/syslinux/*.c32 "$ISO_DIR/isolinux/" 2>/dev/null || true
APPEND="boot=live components username=jk hostname=jk-os locales=en_US.UTF-8 keyboard-layouts=us quiet splash"
cat > "$ISO_DIR/isolinux/isolinux.cfg" <<EOF
UI menu.c32
PROMPT 0
TIMEOUT 50
MENU TITLE JK OS 1.0 - by JK Soft Solutions
LABEL live
  MENU LABEL JK OS 1.0 - Live (try without installing)
  KERNEL /live/vmlinuz
  APPEND initrd=/live/initrd.img $APPEND
LABEL install
  MENU LABEL Install JK OS (Live + Installer)
  KERNEL /live/vmlinuz
  APPEND initrd=/live/initrd.img $APPEND
EOF
cat > "$ISO_DIR/boot/grub/grub.cfg" <<EOF
set timeout=5
set default=0
menuentry "JK OS 1.0 - Live (try without installing)" {
  linux /live/vmlinuz $APPEND
  initrd /live/initrd.img
}
menuentry "Install JK OS (Live + Installer on Desktop)" {
  linux /live/vmlinuz $APPEND
  initrd /live/initrd.img
}
EOF
cat > /tmp/grub-embed.cfg <<'EOF'
search --no-floppy --file --set=root /live/filesystem.squashfs
set prefix=($root)/boot/grub
configfile ($root)/boot/grub/grub.cfg
EOF
# GRUB modules MUST live on the ISO at boot/grub/x86_64-efi (QEMU UEFI test
# 2026-10-22: embed search set root=cd0 OK, but configfile/normal/linux .mod
# files were missing on the media -> boot dropped to the grub> shell).
mkdir -p "$ISO_DIR/boot/grub/x86_64-efi"
cp /usr/lib/grub/x86_64-efi/*.mod "$ISO_DIR/boot/grub/x86_64-efi/" 2>/dev/null || true
echo "GRUB modules on ISO: $(ls "$ISO_DIR/boot/grub/x86_64-efi/" 2>/dev/null | wc -l)"
grub-mkstandalone -O x86_64-efi -o "$ISO_DIR/EFI/BOOT/BOOTX64.EFI" --compress=xz "boot/grub/grub.cfg=/tmp/grub-embed.cfg"
dd if=/dev/zero of="$ISO_DIR/boot/efiboot.img" bs=1M count=12; mkfs.vfat "$ISO_DIR/boot/efiboot.img"
mmd -i "$ISO_DIR/boot/efiboot.img" ::/EFI ::/EFI/BOOT; mcopy -i "$ISO_DIR/boot/efiboot.img" "$ISO_DIR/EFI/BOOT/BOOTX64.EFI" ::/EFI/BOOT/BOOTX64.EFI
echo "JK OS 1.0 - JK Soft Solutions" > "$ISO_DIR/README.txt"
for f in "$ISO_DIR/live/vmlinuz" "$ISO_DIR/live/initrd.img" "$ISO_DIR/live/filesystem.squashfs" "$ISO_DIR/EFI/BOOT/BOOTX64.EFI" "$ISO_DIR/boot/efiboot.img"; do [ -s "$f" ] || { echo "STAGE4 GATE FAIL missing $f"; exit 1; }; done
echo "STAGE4 GATE PASS"
xorriso -as mkisofs -iso-level 3 -full-iso9660-filenames -volid "JK_OS_1_0" \
 -output ~/workspace/your_files/JK-OS-v1.0.iso \
 -eltorito-boot isolinux/isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table \
 -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
 -eltorito-alt-boot -e boot/efiboot.img -no-emul-boot -isohybrid-gpt-basdat \
 "$ISO_DIR" 2>&1 | tail -5
ls -lh ~/workspace/your_files/JK-OS-v1.0.iso
sha256sum ~/workspace/your_files/JK-OS-v1.0.iso | tee ~/workspace/your_files/JK-OS-v1.0.iso.sha256
echo "=== STAGE4 ISO DONE ==="
