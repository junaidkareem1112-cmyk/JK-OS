#!/bin/bash
# JK OS build v7 — v6 + do fixes:
# (e) diskbind dirs 2770 root:nogroup the -> bind ke baad _apt/user unhe traverse
#     nahi kar sakta tha (apt-key exec fail). chmod 755 lazmi.
# (f) apt sandbox _apt is restricted env me fail hota hai: chroot apt ke liye
#     APT_CONFIG se APT::Sandbox::User=root (signature check phir bhi hoga).
set -x
exec > >(tee -a ~/workspace/jk-os/build7-run.log) 2>&1
JK=~/workspace/jk-os; DL=$JK/downloads; R=$JK/rootfs; CACHE=$JK/deb-cache; DB=$JK/diskbind
export DEBIAN_FRONTEND=noninteractive
abort(){ echo "=== BUILD7 ABORT: $1 ==="; df -h "$R" 2>/dev/null; exit 1; }

# ---------- CHECKPOINT (restart-proof) ----------
# tmpfs rootfs har VM restart/session-kill par mar jata hai. Is liye har stage ke
# PASS par rootfs ka tmpfs-hissa disk par squashfs checkpoint (checkpoints/) aur
# diskbind hisse (usr/lib, usr/share, usr/local, opt) ke liye sentinel rakha jata
# hai. Agli run valid checkpoint se resume karti hai — S1/S2 dobara NAHI hote.
# Checkpoint sirf tab valid hai jab: squashfs ki sha256 match kare, meta me is
# script ki sha ho, diskbind sentinel bhi is script ki sha rakhta ho, aur restore
# ke baad rootfs ke andar ka marker bhi match kare. Warna checkpoint IGNORE.
CKPT=$JK/checkpoints; mkdir -p "$CKPT"
# HIFAZATI GUARD (2026-10-22 wala hadsa: VM reboot ke baad host se unsquashfs gayab tha,
# restore fail hua aur fresh-start path ne diskbind WIPE kar diya -> poora bana hua
# system zaya). Agar checkpoint mojood hai lekin restore ke tools nahi, to yahin RUK jao:
# diskbind ko haath mat lagao. Pehle host heal karo, phir dobara chalao.
if ls "$CKPT"/rootfs-*.sqsh >/dev/null 2>&1 && ! command -v unsquashfs >/dev/null 2>&1; then
  echo "=== BUILD7 GUARD: checkpoint mojood hai lekin unsquashfs MISSING - diskbind ki hifazat ke liye ABORT. Pehle: dpkg -i downloads/squashfs-tools.deb ==="
  exit 1
fi
SCRIPT_SHA=$(sha256sum "$(readlink -f "$0")" | awk '{print $1}')
ckpt_ok(){
  local n="$1"
  [ -s "$CKPT/rootfs-$n.sqsh" ] || return 1
  [ -s "$CKPT/rootfs-$n.sha256" ] || return 1
  (cd "$CKPT" && sha256sum -c "rootfs-$n.sha256" >/dev/null 2>&1) || return 1
  grep -q "^script_sha=$SCRIPT_SHA$" "$CKPT/rootfs-$n.meta" 2>/dev/null || return 1
  grep -q "^script_sha=$SCRIPT_SHA$" "$DB/.diskbind-$n" 2>/dev/null || return 1
  return 0
}
make_ckpt(){
  local n="$1"
  echo "=== CHECKPOINT $n BAN RAHA HAI ==="
  umounts 2>/dev/null || true
  mountpoint -q "$R/var/cache/apt/archives" && umount "$R/var/cache/apt/archives" 2>/dev/null || true
  echo "jk-os checkpoint $n $(date -u +%FT%TZ) script_sha=$SCRIPT_SHA" > "$R/etc/jk-os-checkpoint-$n" || { echo "CHECKPOINT $n FAIL: marker write"; return 1; }
  rm -f "$CKPT/rootfs-$n.sqsh.tmp"
  if mksquashfs "$R" "$CKPT/rootfs-$n.sqsh.tmp" -e usr/lib usr/share usr/local opt var/cache/apt/archives dev proc sys run -comp xz -Xbcj x86 -processors 2 >/dev/null; then
    mv "$CKPT/rootfs-$n.sqsh.tmp" "$CKPT/rootfs-$n.sqsh"
  else
    echo "CHECKPOINT $n FAIL: mksquashfs"; rm -f "$CKPT/rootfs-$n.sqsh.tmp"; return 1
  fi
  (cd "$CKPT" && sha256sum "rootfs-$n.sqsh" > "rootfs-$n.sha256")
  { echo "script_sha=$SCRIPT_SHA"; echo "stage=$n"; echo "created=$(date -u +%FT%TZ)"; } > "$CKPT/rootfs-$n.meta"
  echo "script_sha=$SCRIPT_SHA" > "$DB/.diskbind-$n"
  echo "=== CHECKPOINT $n OK ($(du -h "$CKPT/rootfs-$n.sqsh" | cut -f1)) ==="
}
restore_ckpt(){
  local n="$1"
  echo "=== CHECKPOINT $n RESTORE ==="
  mountpoint -q "$R" && umount -R "$R" 2>/dev/null
  rm -rf "$R"; mkdir -p "$R"
  mount -t tmpfs -o size=6G,mode=755 tmpfs "$R" || return 1
  unsquashfs -f -d "$R" "$CKPT/rootfs-$n.sqsh" >/dev/null || { echo "RESTORE $n FAIL: unsquashfs"; return 1; }
  [ -f "$R/etc/jk-os-checkpoint-$n" ] || { echo "RESTORE $n FAIL: marker missing"; return 1; }
  grep -q "script_sha=$SCRIPT_SHA" "$R/etc/jk-os-checkpoint-$n" || { echo "RESTORE $n FAIL: marker sha mismatch"; return 1; }
  mkdir -p "$R"/usr/{lib,share,local} "$R/opt" "$R/dev" "$R/proc" "$R/sys" "$R/run"
  chmod 755 "$DB" "$DB"/usrlib "$DB"/usrshare "$DB"/usrlocal "$DB"/opt || return 1
  mount --bind "$DB/usrlib" "$R/usr/lib" || return 1
  mount --bind "$DB/usrshare" "$R/usr/share" || return 1
  mount --bind "$DB/usrlocal" "$R/usr/local" || return 1
  mount --bind "$DB/opt" "$R/opt" || return 1
  cp /etc/resolv.conf "$R/etc/resolv.conf" 2>/dev/null || true
  cp /etc/hosts "$R/etc/hosts" || return 1
  echo "=== CHECKPOINT $n RESTORE OK ==="
}
RESUME=""
if ckpt_ok s4; then RESUME=s4; elif ckpt_ok s2; then RESUME=s2; fi
if [ -n "$RESUME" ]; then
  restore_ckpt "$RESUME" || { echo "RESTORE $RESUME FAIL — fresh start hoga"; RESUME=""; }
fi
if [ -z "$RESUME" ]; then
  mountpoint -q "$R" && umount -R "$R" 2>/dev/null
  rm -rf "$R" "$DB"; mkdir -p "$R"
  mount -t tmpfs -o size=6G,mode=755 tmpfs "$R" || abort "tmpfs mount"
  mkdir -p "$DB"/{usrlib,usrshare,usrlocal,opt} "$R"/usr/{lib,share,local} "$R/opt"
  chmod 755 "$DB" "$DB"/usrlib "$DB"/usrshare "$DB"/usrlocal "$DB"/opt
  mount --bind "$DB/usrlib" "$R/usr/lib" || abort "bind usrlib"
  mount --bind "$DB/usrshare" "$R/usr/share" || abort "bind usrshare"
  mount --bind "$DB/usrlocal" "$R/usr/local" || abort "bind usrlocal"
  mount --bind "$DB/opt" "$R/opt" || abort "bind opt"
  df -h "$R"; ls -la "$R/usr" | head -6
fi
mounts(){
  if ! mountpoint -q "$R/dev"; then
    mount -t tmpfs -o mode=755 tmpfs "$R/dev"
    for n in null zero full random urandom tty console ptmx; do
      [ -e "/dev/$n" ] && { touch "$R/dev/$n"; mount --bind "/dev/$n" "$R/dev/$n"; }
    done
    mkdir -p "$R/dev/pts" "$R/dev/shm"
    mount -t devpts devpts "$R/dev/pts" 2>/dev/null || mount --bind /dev/pts "$R/dev/pts" 2>/dev/null || true
    mount -t tmpfs tmpfs "$R/dev/shm" 2>/dev/null || true
    ln -s /proc/self/fd "$R/dev/fd" 2>/dev/null || true
    ln -s /proc/self/fd/0 "$R/dev/stdin" 2>/dev/null || true
    ln -s /proc/self/fd/1 "$R/dev/stdout" 2>/dev/null || true
    ln -s /proc/self/fd/2 "$R/dev/stderr" 2>/dev/null || true
  fi
  mountpoint -q "$R/proc" || mount -t proc proc "$R/proc"
  mountpoint -q "$R/sys" || mount -t sysfs sys "$R/sys"
  mkdir -p "$R/var/cache/apt/archives/partial"
  mountpoint -q "$R/var/cache/apt/archives" || mount --bind "$CACHE" "$R/var/cache/apt/archives"
}
umounts(){ for m in var/cache/apt/archives sys proc dev/pts dev; do mountpoint -q "$R/$m" && umount "$R/$m" 2>/dev/null || true; done; umount -R "$R/dev" 2>/dev/null || true; }
CHROOT="env APT_CONFIG=/opt/jk/apt-jk.conf chroot"

# ---------- S1: debootstrap ----------
if [ -z "$RESUME" ]; then
KR=/usr/share/keyrings/debian-archive-keyring.gpg
# keyring host par gayab ho sakta hai (VM refresh jaisi surat me) — pehle local deb-cache se lagao, phir apt, warna abort
if [ ! -f "$KR" ]; then
  KD=$(ls "$CACHE"/debian-archive-keyring_*.deb 2>/dev/null | head -1)
  { [ -n "$KD" ] && dpkg -i "$KD" >/dev/null 2>&1; } || apt-get install -y debian-archive-keyring >/dev/null 2>&1 || abort "keyring"
fi
[ -f "$KR" ] || abort "keyring"
debootstrap --keyring="$KR" --arch=amd64 --components=main,contrib,non-free,non-free-firmware bookworm "$R" http://deb.debian.org/debian || abort "debootstrap"
[ -x "$R/bin/bash" ] && [ -d "$R/etc/apt" ] || abort "debootstrap verify"
echo "S1 OK rootfs=$(du -sh $R | cut -f1)"
cp /etc/resolv.conf "$R/etc/resolv.conf" 2>/dev/null || true
cp /etc/hosts "$R/etc/hosts" || abort "hosts copy (proxy ke liye lazmi)"
cat > "$R/etc/apt/sources.list" <<'EOF'
deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
deb http://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
EOF
printf '#!/bin/sh\nexit 101\n' > "$R/usr/sbin/policy-rc.d"; chmod +x "$R/usr/sbin/policy-rc.d"
mkdir -p "$R/opt/jk"
printf 'APT::Sandbox::User "root";\n' > "$R/opt/jk/apt-jk.conf"
cp "$DL"/codium.deb "$DL"/continue.vsix "$DL"/cline.vsix "$DL"/roo.vsix "$DL"/kilo.vsix "$R/opt/jk/" || abort "stage debs/vsix"
cp "$DL/node.tar.xz" "$R/opt/jk/"
PKGS_MAIN="linux-image-amd64 live-boot live-config live-config-systemd systemd systemd-sysv sudo dbus dbus-x11 initramfs-tools xz-utils firmware-linux-free firmware-iwlwifi firmware-realtek firmware-atheros firmware-misc-nonfree xorg xserver-xorg-video-all xserver-xorg-input-all policykit-1 udisks2 upower xfce4-session xfwm4 xfdesktop4 xfce4-panel xfce4-settings xfce4-appfinder xfconf xfce4-whiskermenu-plugin xfce4-taskmanager xfce4-screenshooter xfce4-terminal xfce4-power-manager xfce4-notifyd xfce4-clipman-plugin xfce4-pulseaudio-plugin thunar thunar-archive-plugin thunar-volman tumbler gvfs gvfs-backends lightdm lightdm-gtk-greeter mousepad ristretto xarchiver papirus-icon-theme arc-theme pulseaudio pavucontrol alsa-utils zenity xclip xsel libportaudio2 python3 python3-pip python3-venv python3-gi gir1.2-gtk-3.0 espeak-ng xdotool wmctrl brightnessctl playerctl pulseaudio-utils libreoffice-writer libreoffice-calc libreoffice-impress libreoffice-gtk3 evince firefox-esr thunderbird vlc gimp php-cli php-mbstring php-xml git geany sqlite3 build-essential cmake file-roller galculator gparted synaptic network-manager network-manager-gnome blueman bluez cups cups-client system-config-printer ufw unzip zip p7zip-full curl wget htop neofetch xdg-utils psmisc fonts-dejavu fonts-liberation fonts-noto-core locales calamares calamares-settings-debian grub-common grub2-common grub-efi-amd64-bin grub-pc-bin efibootmgr os-prober dosfstools squashfs-tools rsync fdisk qml-module-qtquick-window2 qml-module-qtquick2 qml-module-qtquick-controls2 qml-module-qtquick-layouts"
PKGS_ART="inkscape krita mypaint audacity tuxpaint pinta scribus librecad"
echo "$PKGS_MAIN" > "$R/opt/jk/pkgs-main.txt"; echo "$PKGS_ART" > "$R/opt/jk/pkgs-art.txt"
mkdir -p "$R/var/lib/apt/lists/partial"; cp -a "$JK/aptstate/state/lists/." "$R/var/lib/apt/lists/" 2>/dev/null || true
cp -a "$JK/npm-prefix/bin/." "$R/usr/local/bin/" 2>/dev/null || true
cp -a "$JK/npm-prefix/lib/." "$R/usr/local/lib/" 2>/dev/null || true
mkdir -p "$R/opt/jk/bin"; for b in goose crush ollama; do [ -x "$JK/tmp-extract/$b" ] && install -m755 "$JK/tmp-extract/$b" "$R/opt/jk/bin/$b"; done
rm -rf "$R/opt/whisper.cpp"; cp -a "$JK/whisper.cpp" "$R/opt/whisper.cpp"; rm -rf "$R/opt/whisper.cpp/.git"

# ---------- S2: main + art (chroot) ----------
mounts
cat > "$R/opt/jk/install-main.sh" <<'EOS'
#!/bin/bash
set -x; export DEBIAN_FRONTEND=noninteractive
V=/opt/jk/verify.log; echo "=== B7 MAIN INSTALL ===" >> $V
apt-get update >> /opt/jk/apt-update.log 2>&1; echo "apt-update rc=$?" >> $V
PKGS_MAIN=$(cat /opt/jk/pkgs-main.txt); PKGS_ART=$(cat /opt/jk/pkgs-art.txt)
apt-get install -y --no-install-recommends $PKGS_MAIN 2>&1 | tee /opt/jk/apt-main.log; echo "MAIN rc=${PIPESTATUS[0]}" >> $V
for i in 1 2; do apt-get -f install -y >> /opt/jk/apt-main.log 2>&1; apt-get install -y --no-install-recommends $PKGS_MAIN >> /opt/jk/apt-main.log 2>&1 && break; done
for pkg in $PKGS_ART; do
  if apt-get install -y --no-install-recommends $pkg >> /opt/jk/apt-art.log 2>&1; then echo "ART PASS: $pkg" >> $V; else echo "ART FAIL: $pkg" >> $V; fi
done
for c in gimp inkscape krita mypaint audacity tuxpaint pinta scribus librecad; do echo -n "art $c: " >> $V; command -v $c >> $V 2>&1 || echo MISSING >> $V; done
id jk || useradd -m -s /bin/bash -G sudo,audio,video,plugdev,netdev,bluetooth,lpadmin jk
usermod -p "$(openssl passwd -6 jk)" jk && echo "jk password set (usermod)" >> $V
echo 'jk:jk' | chpasswd || echo "chpasswd fail (usermod hash pehle lag chuka)" >> $V
grep '^jk:' /etc/shadow | cut -c1-12 >> $V
apt-get install -y /opt/jk/codium.deb 2>&1 | tee /opt/jk/apt-codium.log; echo "codium rc=${PIPESTATUS[0]}" >> $V
# codium deb binary /usr/share/codium/bin/codium par lagata hai; postinst wala /usr/bin/codium symlink chroot me guarantee nahi — khud banao taake S2/GATE verify pass ho.
# ZAROORI: symlink RELATIVE ho (../share/...). Absolute link chroot ke andar to chalta hai, lekin host-side verify [ -e $R/... ] usay host root par resolve karke "missing" samajhta hai — 12:00 wali restart isi wajah se S2 par dobara giri thi.
[ -x /usr/share/codium/bin/codium ] && ln -sf ../share/codium/bin/codium /usr/bin/codium && echo "codium symlink OK (relative)" >> $V || echo "WARN: codium binary not found after deb install" >> $V
tar -xJf /opt/jk/node.tar.xz -C /usr/local --strip-components=1; hash -r
node --version >> $V 2>&1; npm --version >> $V 2>&1; codium --version >> $V 2>&1 | head -1
df -h / >> $V 2>&1
EOS
chmod +x "$R/opt/jk/install-main.sh"
$CHROOT "$R" /bin/bash /opt/jk/install-main.sh || abort "chroot main install (crash)"
cp -a "$R/opt/jk/"*.log "$JK/logs/" 2>/dev/null || true
for f in usr/bin/codium usr/bin/firefox-esr usr/bin/xfce4-session; do [ -e "$R/$f" ] || abort "S2 verify missing $f"; done
ls "$R"/boot/vmlinuz-* >/dev/null 2>&1 || abort "S2 verify: kernel missing"
grep -q "MAIN rc=0" "$R/opt/jk/verify.log" || echo "WARN: MAIN rc not 0 (verify.log dekho, aage barho)"
echo "S2 OK tmpfs:"; df -h "$R" | tail -1
make_ckpt s2 || echo "WARN: s2 checkpoint nahi bana (build aage jayegi, lekin resume point nahi hoga)"
fi

# ---------- S3: privacy/telegram/wine/waydroid/lang ----------
if [ "$RESUME" != "s4" ]; then
umounts
bash "$JK/privacy-install.sh" || echo "S3 privacy-install nonzero (logs dekho)"
cp -a "$R/opt/jk/"*.log "$JK/logs/" 2>/dev/null || true
mountpoint -q "$R/dev" || mounts
echo "S3 done"

# ---------- S4a: wheelhouse (host, cp311 wheels) ----------
if [ ! -d "$JK/wheelhouse" ]; then
  python3 -m pip --version >/dev/null 2>&1 || python3 -m venv "$JK/host-venv" || true
  PIP="python3 -m pip"; python3 -m pip --version >/dev/null 2>&1 || PIP="$JK/host-venv/bin/pip"
  echo "wheelhouse pip: $PIP"
  $PIP download --dest "$JK/wheelhouse" --only-binary=:all: \
    --platform manylinux2014_x86_64 --platform manylinux_2_17_x86_64 --platform manylinux_2_28_x86_64 \
    --python-version 311 --implementation cp --abi cp311 \
    vosk piper-tts openwakeword sounddevice numpy 2>&1 | tail -5
fi
[ -d "$JK/wheelhouse" ] && cp -a "$JK/wheelhouse" "$R/opt/jk/wheelhouse" || echo "wheelhouse missing - online pip fallback hoga"

# ---------- S4: vibe/whisper/jarvis-venv/extensions/initramfs ----------
mounts
cat > "$R/opt/jk/install2.sh" <<'EOS'
#!/bin/bash
set -x; export DEBIAN_FRONTEND=noninteractive HOME=/home/jk
V=/opt/jk/verify.log; echo "=== B7 PHASE2 ===" >> $V
dpkg --configure -a >> /opt/jk/apt-repair.log 2>&1 || true
apt-get -f install -y >> /opt/jk/apt-repair.log 2>&1 || true
for c in opencode gemini codex qwen freebuff; do echo -n "$c: " >> $V; $c --version >> $V 2>&1 || $c --help >> $V 2>&1 | head -1 || echo MISSING >> $V; done
for b in goose crush ollama; do install -m755 /opt/jk/bin/$b /usr/local/bin/$b 2>/dev/null && { echo -n "$b: " >> $V; $b --version >> $V 2>&1 || echo FAIL >> $V; }; done
cat > /etc/systemd/system/ollama.service <<'EOF'
[Unit]
Description=Ollama Local AI (JK OS)
After=network.target
[Service]
ExecStart=/usr/local/bin/ollama serve
Environment=OLLAMA_HOST=127.0.0.1:11434 OLLAMA_KEEP_ALIVE=2m
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
mkdir -p /etc/systemd/system/multi-user.target.wants; ln -sf /etc/systemd/system/ollama.service /etc/systemd/system/multi-user.target.wants/ollama.service
if [ ! -x /usr/local/bin/whisper-cli ]; then
  cmake -S /opt/whisper.cpp -B /opt/whisper.cpp/build -DCMAKE_BUILD_TYPE=Release >> /opt/jk/whisper.log 2>&1 && \
  cmake --build /opt/whisper.cpp/build -j2 --target whisper-cli >> /opt/jk/whisper.log 2>&1 && \
  install -m755 /opt/whisper.cpp/build/bin/whisper-cli /usr/local/bin/whisper-cli
  echo "whisper-cli build rc=$?" >> $V; rm -rf /opt/whisper.cpp
fi
python3 -m venv /opt/jk-assistant-venv
if [ -d /opt/jk/wheelhouse ]; then
  /opt/jk-assistant-venv/bin/pip install --no-index --find-links /opt/jk/wheelhouse vosk piper-tts openwakeword sounddevice numpy >> /opt/jk/jarvis-pip.log 2>&1 || \
  /opt/jk-assistant-venv/bin/pip install --retries 5 vosk piper-tts openwakeword sounddevice numpy >> /opt/jk/jarvis-pip.log 2>&1
else
  for i in 1 2 3; do /opt/jk-assistant-venv/bin/pip install --retries 5 vosk piper-tts openwakeword sounddevice numpy >> /opt/jk/jarvis-pip.log 2>&1 && break; done
fi
/opt/jk-assistant-venv/bin/python -c "import vosk, piper, openwakeword, sounddevice; print('jarvis imports OK')" >> $V 2>&1 || echo "jarvis imports FAIL" >> $V
for v in /opt/jk/continue.vsix /opt/jk/cline.vsix /opt/jk/roo.vsix /opt/jk/kilo.vsix; do
  [ -f "$v" ] && su - jk -c "codium --install-extension $v --force" >> /opt/jk/ext.log 2>&1; echo "$v rc=$?" >> /opt/jk/ext.log
done
ls /home/jk/.vscode-oss/extensions >> $V 2>&1 || echo "no ext dir" >> $V
B=$(find /etc/calamares/branding -maxdepth 2 -name branding.desc | head -1); [ -n "$B" ] && sed -i 's/Debian/JK OS/g; s/debian/jk-os/g' "$B"
update-initramfs -u -k all >> /opt/jk/initramfs.log 2>&1; echo "initramfs rc=$?" >> $V
echo "=== SMOKE ===" >> $V
for c in xfce4-session lightdm Xorg firefox-esr thunderbird codium geany python3 php node npm git sqlite3 gimp inkscape krita pinta scribus audacity tuxpaint vlc libreoffice evince thunar calamares gparted synaptic galculator xfce4-screenshooter xfce4-taskmanager mousepad telegram-desktop pwsh persepolis grub-install efibootmgr; do
  if command -v $c >/dev/null 2>&1; then echo "SMOKE PASS $c $(command -v $c)" >> $V; else echo "SMOKE FAIL $c" >> $V; fi
done
df -h / >> $V 2>&1; du -sh /usr /opt /home 2>/dev/null >> $V
EOS
chmod +x "$R/opt/jk/install2.sh"
$CHROOT "$R" /bin/bash /opt/jk/install2.sh || abort "chroot phase2 (crash)"
cp -a "$R/opt/jk/"*.log "$JK/logs/" 2>/dev/null || true

# ---------- XAMPP target-side perms fix helper ----------
cat > "$R/usr/local/bin/jk-xampp-fixperms" <<'EOF'
#!/bin/bash
echo "XAMPP permissions fix ho rahi hain..."
sudo chown -R mysql:mysql /opt/lampp/var/mysql /opt/lampp/var/run 2>/dev/null
sudo chown -R mysql /opt/lampp/logs /opt/lampp/temp 2>/dev/null
sudo chown root:daemon /opt/lampp/logs 2>/dev/null
echo "Ho gaya. Ab XAMPP Control Panel se Start karein."
read -p "Enter dabain..."
EOF
chmod +x "$R/usr/local/bin/jk-xampp-fixperms"
cat > "$R/usr/share/applications/jk-xampp-fixperms.desktop" <<'EOF'
[Desktop Entry]
Name=XAMPP - First Run Fix
Comment=XAMPP pehli dafa chalane se pehle ye chalain (permissions theek karega)
Exec=xfce4-terminal -e "jk-xampp-fixperms"
Icon=applications-development
Terminal=false
Type=Application
Categories=System;Development;
EOF
make_ckpt s4 || echo "WARN: s4 checkpoint nahi bana (build aage jayegi, lekin resume point nahi hoga)"
fi

# ---------- GATE (v2 wala hi, kamzor NAHI) ----------
umounts
echo "=== GATE ==="
FAIL=0
for f in usr/bin/xfce4-session usr/sbin/lightdm usr/bin/firefox-esr usr/bin/calamares usr/bin/codium usr/bin/Xorg usr/bin/inkscape usr/bin/krita; do [ -e "$R/$f" ] || { echo "GATE FAIL missing $f"; FAIL=1; }; done
ls "$R"/boot/vmlinuz-* >/dev/null 2>&1 || { echo "GATE FAIL no kernel"; FAIL=1; }
[ "$FAIL" = 0 ] && echo "=== B2 GATE PASS (build7) ===" || abort "B2 GATE FAILED"

# ---------- S5: stage4b ----------
sed 's|^bash "$JK/privacy-install.sh".*|echo "privacy S3 me ho chuka - skip"|' "$JK/stage4-iso.sh" > "$JK/stage4b.sh"
sync; echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
bash "$JK/stage4b.sh" || abort "stage4b"
[ -s ~/workspace/your_files/JK-OS-v1.0.iso ] || abort "ISO missing after stage4b"
echo "=== BUILD7 DONE ==="
ls -lh ~/workspace/your_files/JK-OS-v1.0.iso
