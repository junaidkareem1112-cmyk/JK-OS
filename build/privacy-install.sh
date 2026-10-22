#!/bin/bash
# Privacy/VPN + Telegram + Accessibility/AV + Language packs: host-apt URIs -> host download -> chroot offline install
set -x
JK=~/workspace/jk-os; R=$JK/rootfs; CACHE=$JK/deb-cache
PKGS="wireguard-tools openvpn network-manager-openvpn network-manager-openvpn-gnome tor torsocks torbrowser-launcher proxychains4 telegram-desktop xfce4-xkb-plugin onboard orca power-profiles-daemon redshift clamav clamtk hardinfo lshw-gtk usbview gnome-disk-utility gucharmap bleachbit deja-dup remmina gnome-logs simplescreenrecorder inxi persepolis aria2 uget git-gui gitk scrcpy adb weston"
LANGPKGS="fonts-noto-core fonts-noto-nastaliq-urdu fonts-nafees libreoffice-l10n-ur libreoffice-l10n-ar firefox-esr-l10n-ur firefox-esr-l10n-ar hunspell-ar hunspell-ur hyphen-ur hyphen-ar"
mkdir -p "$R/opt/jk"
echo "$PKGS" > "$R/opt/jk/pkgs-privacy.txt"
echo "$LANGPKGS" > "$R/opt/jk/langpkgs.txt"
# PowerShell (official Microsoft deb) + XAMPP (official Apache Friends installer) staging
DL=$JK/downloads
[ -s "$DL/powershell.deb" ] && cp "$DL/powershell.deb" "$R/opt/jk/" && echo "powershell deb staged"
[ -s "$DL/xampp-installer.run" ] && cp "$DL/xampp-installer.run" "$R/opt/jk/" && echo "xampp installer staged"
cp "$JK/aptstate/waydroid.gpg" "$R/opt/jk/waydroid.gpg" 2>/dev/null || true
# host apt (bookworm state from build2) - URIs
APTOPTS="-o Dir::State=$JK/aptstate/state -o Dir::State::status=$JK/aptstate/state/status -o Dir::Cache=$JK/aptstate/cache -o Dir::Etc::SourceList=$JK/aptstate/sources.list -o Dir::Etc::SourceParts=/dev/null -o APT::Architecture=amd64 -o Acquire::AllowInsecureRepositories=true"
apt-get $APTOPTS install --print-uris -y --allow-unauthenticated $PKGS $LANGPKGS > "$JK/uris-priv-raw.txt" 2>"$JK/uris-priv-err.log" || true
# PowerShell deps (local deb ke liye bhi URIs)
if [ -s "$DL/powershell.deb" ]; then apt-get $APTOPTS install --print-uris -y --allow-unauthenticated "$DL/powershell.deb" >> "$JK/uris-priv-raw.txt" 2>>"$JK/uris-priv-err.log" || true; fi
# Wine + Waydroid: waydro.id repo aptstate sources me add + i386 architecture enable (wine32 ke liye)
grep -q "repo.waydro.id" "$JK/aptstate/sources.list" || echo "deb [signed-by=$JK/aptstate/waydroid.gpg] https://repo.waydro.id/ bookworm main" >> "$JK/aptstate/sources.list"
APTOPTS32="-o Dir::State=$JK/aptstate/state -o Dir::State::status=$JK/aptstate/state/status -o Dir::Cache=$JK/aptstate/cache -o Dir::Etc::SourceList=$JK/aptstate/sources.list -o Dir::Etc::SourceParts=/dev/null -o APT::Architectures=amd64,i386 -o Acquire::AllowInsecureRepositories=true"
for i in 1 2 3; do apt-get $APTOPTS32 update --allow-insecure-repositories && break; sleep 5; done
apt-get $APTOPTS32 install --print-uris -y --allow-unauthenticated wine wine64 wine32 winetricks waydroid >> "$JK/uris-priv-raw.txt" 2>>"$JK/uris-priv-err.log" || echo "WINE/WAYDROID URIS FAIL (one-click tier note)" 
grep "^'" "$JK/uris-priv-raw.txt" | awk -F"'" '{print $2}' > "$JK/uris-privacy.txt" || true
wc -l "$JK/uris-privacy.txt"
while read -r url; do
  f=$(basename "${url%%\?*}"); [ -s "$CACHE/$f" ] && continue
  for t in 1 2 3 4 5; do curl -C - -L --retry 3 -o "$CACHE/$f" "$url" && break || sleep 3; done
done < "$JK/uris-privacy.txt"
mkdir -p "$R/var/lib/apt/lists/partial"
cp -a "$JK/aptstate/state/lists/." "$R/var/lib/apt/lists/" || true
mountpoint -q "$R/dev" || mount --bind /dev "$R/dev"
mountpoint -q "$R/dev/pts" || mount --bind /dev/pts "$R/dev/pts"
mountpoint -q "$R/proc" || mount -t proc proc "$R/proc"
mountpoint -q "$R/sys" || mount -t sysfs sys "$R/sys"
mkdir -p "$R/var/cache/apt/archives/partial"
mountpoint -q "$R/var/cache/apt/archives" || mount --bind "$CACHE" "$R/var/cache/apt/archives"
cat > "$R/opt/jk/install-privacy.sh" <<'EOS'
#!/bin/bash
set -x; export DEBIAN_FRONTEND=noninteractive
V=/opt/jk/verify.log
# resume-safety: pichli run agar apt/dpkg ke beech me mari ho to pehle state repair
dpkg --configure -a >> /opt/jk/apt-repair.log 2>&1 || true
apt-get -f install -y >> /opt/jk/apt-repair.log 2>&1 || true
# ZAROORI: i386 architecture update se PEHLE add ho — warna amd64-only update
# i386 lists mita deta hai aur wine32 ka koi candidate nahi rehta (run5 ki ghalti)
dpkg --add-architecture i386 || true
apt-get update >> /opt/jk/apt-privacy-update.log 2>&1 || true
# per-package loop: aik missing package (masalan scrcpy) poora set NA roke
for p in $(cat /opt/jk/pkgs-privacy.txt); do
  if apt-get install -y --no-install-recommends "$p" >> /opt/jk/apt-privacy.log 2>&1; then echo "PRIV PASS: $p" >> $V; else echo "PRIV FAIL: $p" >> $V; fi
done
echo "=== PRIVACY/TELEGRAM/AV SMOKE ===" >> $V
for c in wg openvpn tor torsocks proxychains4 torbrowser-launcher nm-connection-editor telegram-desktop clamscan freshclam clamtk powerprofilesctl onboard orca; do
  if command -v $c >/dev/null 2>&1; then echo "SMOKE PASS $c" >> $V; else echo "SMOKE FAIL $c" >> $V; fi
done
wg --version >> $V 2>&1; openvpn --version >> $V 2>&1 | head -1; tor --version >> $V 2>&1 | head -1
clamscan --version >> $V 2>&1 | head -1; freshclam --version >> $V 2>&1 | head -1
echo "=== SYSTEM TOOLS / DOWNLOADER SMOKE ===" >> $V
for c in hardinfo lshw-gtk usbview gnome-disks gucharmap bleachbit deja-dup remmina gnome-logs simplescreenrecorder inxi persepolis aria2c uget-gtk; do
  if command -v $c >/dev/null 2>&1; then echo "SMOKE PASS $c" >> $V; else echo "SMOKE FAIL $c" >> $V; fi
done
aria2c --version >> $V 2>&1 | head -1
[ -x /usr/lib/git-core/git-gui ] && echo "SMOKE PASS git-gui" >> $V || echo "SMOKE FAIL git-gui" >> $V
command -v gitk >/dev/null 2>&1 && echo "SMOKE PASS gitk" >> $V || echo "SMOKE FAIL gitk" >> $V
persepolis --version >> $V 2>&1 | head -2 || true
# PowerShell (official deb)
if [ -s /opt/jk/powershell.deb ]; then
  apt-get install -y /opt/jk/powershell.deb >> /opt/jk/apt-pwsh.log 2>&1 || apt-get install -y -f >> /opt/jk/apt-pwsh.log 2>&1 || true
  echo "--- pwsh ---" >> $V; pwsh --version >> $V 2>&1 || echo "PWSH FAIL" >> $V
fi
# XAMPP (official installer, unattended, /opt/lampp) - autostart NAHI (koi service enable nahi hoti)
if [ -s /opt/jk/xampp-installer.run ]; then
  chmod +x /opt/jk/xampp-installer.run
  mkdir -p /opt/lampp && chmod 777 /opt/lampp
  /opt/jk/xampp-installer.run --mode unattended >> /opt/jk/xampp-install.log 2>&1 || echo "XAMPP INSTALL FAIL" >> $V
  echo "--- xampp ---" >> $V
  ls /opt/lampp/lampp >> $V 2>&1 || echo "LAMPP MISSING" >> $V
  /opt/lampp/bin/php -v >> $V 2>&1 | head -1 || true
  rm -f /opt/jk/xampp-installer.run
fi
# ---- Wine (.exe) + Waydroid (Android) ----
dpkg --add-architecture i386 || true
apt-get install -y --no-install-recommends wine wine64 wine32 winetricks >> /opt/jk/apt-wine.log 2>&1 || echo "WINE INSTALL FAIL (one-click note)" >> $V
echo "--- wine ---" >> $V; wine --version >> $V 2>&1 || echo "WINE FAIL" >> $V
ls -la /usr/bin/wine* >> $V 2>&1; ls /usr/lib/wine/ >> $V 2>&1 | head -5
WINEDEBUG=-all wine64 --version >> $V 2>&1 || echo "WINE64 FAIL" >> $V
# Waydroid repo pehle add + lists update, phir install ki asal koshish (tier-1)
install -m644 /opt/jk/waydroid.gpg /usr/share/keyrings/waydroid.gpg 2>/dev/null || cp /opt/jk/waydroid.gpg /usr/share/keyrings/ 2>/dev/null || true
echo "deb [signed-by=/usr/share/keyrings/waydroid.gpg] https://repo.waydro.id/ bookworm main" > /etc/apt/sources.list.d/waydroid.list
apt-get update >> /opt/jk/apt-waydroid.log 2>&1 || true
apt-get install -y --no-install-recommends waydroid >> /opt/jk/apt-waydroid.log 2>&1 || echo "WAYDROID INSTALL FAIL (one-click note)" >> $V
echo "--- android ---" >> $V
waydroid --version >> $V 2>&1 || dpkg -l waydroid >> $V 2>&1 || echo "WAYDROID FAIL" >> $V
weston --version >> $V 2>&1 || echo "WESTON FAIL" >> $V
scrcpy --version >> $V 2>&1 | head -1; adb --version >> $V 2>&1 | head -1
echo "--- binder check ---" >> $V
ls /dev/binder /dev/binderfs >> $V 2>&1 || echo "binder device build env me nahi (target PC par kernel par munhasir)" >> $V
grep -i binder /proc/filesystems >> $V 2>&1 || true
# Waydroid repo end-user ke liye bhi rootfs me (updates ke liye)
install -m644 /opt/jk/waydroid.gpg /usr/share/keyrings/waydroid.gpg 2>/dev/null || cp /opt/jk/waydroid.gpg /usr/share/keyrings/ 2>/dev/null || true
echo "deb [signed-by=/usr/share/keyrings/waydroid.gpg] https://repo.waydro.id/ bookworm main" > /etc/apt/sources.list.d/waydroid.list
# JK Android Mode session (LightDM) - weston ke andar waydroid full-ui
cat > /usr/local/bin/jk-android-session <<'EOFS2'
#!/bin/bash
export XDG_SESSION_DESKTOP=jk-android
mkdir -p ~/.config
cat > ~/.config/weston.ini <<'EOFW'
[core]
shell=kiosk-shell.so
[autolaunch]
path=/usr/local/bin/jk-android-run
EOFW
exec weston-launch -u "$USER" -t /dev/tty7 -- --config ~/.config/weston.ini >> ~/.jk-android.log 2>&1 || exec weston >> ~/.jk-android.log 2>&1
EOFS2
cat > /usr/local/bin/jk-android-run <<'EOFS3'
#!/bin/bash
sleep 2
sudo waydroid session start >> ~/.jk-android.log 2>&1 &
sleep 5
waydroid show-full-ui >> ~/.jk-android.log 2>&1
sleep infinity
EOFS3
chmod +x /usr/local/bin/jk-android-session /usr/local/bin/jk-android-run
mkdir -p /usr/share/xsessions
cat > /usr/share/xsessions/jk-android.desktop <<'EOFS4'
[Desktop Entry]
Name=JK Android Mode
Comment=Android apps (Waydroid + Weston) full screen
Exec=jk-android-session
Type=Application
DesktopNames=JK-Android
EOFS4
echo "android session file: $(ls /usr/share/xsessions/jk-android.desktop 2>/dev/null)" >> $V
# ---- Languages: locale generation (offline switch ke liye) ----
for loc in "en_US.UTF-8 UTF-8" "ur_PK.UTF-8 UTF-8" "ar_EG.UTF-8 UTF-8" "ar_SA.UTF-8 UTF-8"; do
  code="${loc%% *}"; grep -q "^$code" /etc/locale.gen || echo "$loc" >> /etc/locale.gen
  sed -i "s/^# *\($code UTF-8\)/\1/" /etc/locale.gen
done
locale-gen >> $V 2>&1 || true
echo "--- locale -a ---" >> $V; locale -a >> $V 2>&1
# language packs per-package (cache se; fail ho to FAIL log, baqi chalein)
for p in $(cat /opt/jk/langpkgs.txt); do
  if apt-get install -y --no-install-recommends "$p" >> /opt/jk/apt-lang.log 2>&1; then echo "LANGPKG PASS: $p" >> $V; else echo "LANGPKG FAIL: $p" >> $V; fi
done
echo "--- fc-list urdu/arabic fonts ---" >> $V
fc-list 2>/dev/null | grep -i -E "nastaliq|naskh|nafees" >> $V || echo "FONTS MISSING nastaliq/naskh/nafees" >> $V
dpkg -l 2>/dev/null | grep -E "libreoffice-l10n-(ur|ar)|firefox-esr-l10n-(ur|ar)" >> $V || true
apt-get clean || true
EOS
chmod +x "$R/opt/jk/install-privacy.sh"
env APT_CONFIG=/opt/jk/apt-jk.conf chroot "$R" /bin/bash /opt/jk/install-privacy.sh || true
cp -a "$R/opt/jk/"*.log ~/workspace/jk-os/logs/ 2>/dev/null || true
umount "$R/var/cache/apt/archives" 2>/dev/null || true
for m in sys proc dev/pts dev; do mountpoint -q "$R/$m" && umount "$R/$m" || true; done
echo "=== PRIVACY INSTALL DONE ==="
