JK = '/home/hatch/workspace/jk-os'
p = f'{JK}/privacy-install.sh'; s = open(p).read()

# packages: scrcpy + adb + weston (Debian se); wine/waydroid alag URIs (multiarch + waydro.id repo)
s = s.replace('persepolis aria2 uget git-gui gitk"',
              'persepolis aria2 uget git-gui gitk scrcpy adb weston"')

old = '''if [ -s "$DL/powershell.deb" ]; then apt-get $APTOPTS install --print-uris -y --allow-unauthenticated "$DL/powershell.deb" >> "$JK/uris-priv-raw.txt" 2>>"$JK/uris-priv-err.log" || true; fi'''
new = old + '''
# Wine + Waydroid: waydro.id repo aptstate sources me add + i386 architecture enable (wine32 ke liye)
grep -q "repo.waydro.id" "$JK/aptstate/sources.list" || echo "deb [signed-by=$JK/aptstate/waydroid.gpg] https://repo.waydro.id/ bookworm main" >> "$JK/aptstate/sources.list"
APTOPTS32="-o Dir::State=$JK/aptstate/state -o Dir::State::status=$JK/aptstate/state/status -o Dir::Cache=$JK/aptstate/cache -o Dir::Etc::SourceList=$JK/aptstate/sources.list -o Dir::Etc::SourceParts=/dev/null -o APT::Architectures=amd64,i386 -o Acquire::AllowInsecureRepositories=true"
for i in 1 2 3; do apt-get $APTOPTS32 update --allow-insecure-repositories && break; sleep 5; done
apt-get $APTOPTS32 install --print-uris -y --allow-unauthenticated wine wine64 wine32 winetricks waydroid >> "$JK/uris-priv-raw.txt" 2>>"$JK/uris-priv-err.log" || echo "WINE/WAYDROID URIS FAIL (one-click tier note)" '''
assert old in s; s = s.replace(old, new, 1)

# chroot: i386 enable + wine/waydroid install + smoke + binder check + session file
old = '''# ---- Languages: locale generation (offline switch ke liye) ----'''
new = '''# ---- Wine (.exe) + Waydroid (Android) ----
dpkg --add-architecture i386 || true
apt-get install -y --no-install-recommends wine wine64 wine32 winetricks >> /opt/jk/apt-wine.log 2>&1 || echo "WINE INSTALL FAIL (one-click note)" >> $V
echo "--- wine ---" >> $V; wine --version >> $V 2>&1 || echo "WINE FAIL" >> $V
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
# ---- Languages: locale generation (offline switch ke liye) ----'''
assert old in s; s = s.replace(old, new, 1)
# waydroid.gpg must be staged into rootfs /opt/jk by host part
old = '''[ -s "$DL/xampp-installer.run" ] && cp "$DL/xampp-installer.run" "$R/opt/jk/" && echo "xampp installer staged"'''
new = old + '''
cp "$JK/aptstate/waydroid.gpg" "$R/opt/jk/waydroid.gpg" 2>/dev/null || true'''
assert old in s; s = s.replace(old, new, 1)
open(p, 'w').write(s); print("privacy-install: wine+waydroid hooked")

# systools: Windows Apps folder + mimeapps + uca exe/apk actions + scrcpy + JK Android entries
p = f'{JK}/systools-customize.sh'; s = open(p).read()
add = r'''
# ---- Windows Apps (Wine) + Android entries ----
WF="$SKEL/Desktop/Windows Apps"; mkdir -p "$WF"
if [ -x "$R/usr/bin/wine" ] || [ -x "$R/usr/lib/wine/wine64" ] || ls "$R/usr/bin/wine"* >/dev/null 2>&1; then
  mkentry "Wine Configuration" "winecfg" wine "$WF/Wine Configuration.desktop"
  mkentry "Winetricks" "winetricks" winetricks "$WF/Winetricks.desktop"
  mkentry "Install a Windows Program" "wine uninstaller" wine "$WF/Install a Windows Program.desktop"
  mkentry "Wine Control Panel" "wine control" wine "$WF/Wine Control Panel.desktop"
  mkentry "Wine File Manager" "wine explorer" wine "$WF/Wine File Manager.desktop"
fi
# .exe double-click -> Wine (mimeapps default, skel)
mkdir -p "$SKEL/.config"
cat > "$SKEL/.config/mimeapps.list" <<'EOFM'
[Default Applications]
application/x-ms-dos-executable=wine.desktop
application/x-executable=wine.desktop
application/x-wine-extension-exe=wine.desktop
EOFM
# uca: .exe + .apk actions (existing uca.xml me append - agar file hai)
UCA="$SKEL/.config/Thunar/uca.xml"
if [ -f "$UCA" ]; then
  python3 - "$UCA" <<'PYEOF'
import sys
p = sys.argv[1]; s = open(p).read()
extra = ('<action><icon>wine</icon><name>Open with Wine (.exe)</name><unique-id>jk-wine-1</unique-id><command>wine %f</command><description>Windows program Wine se chalao</description><patterns>*.exe;*.EXE;*.msi;*.MSI</patterns><files/></action>\n'
'<action><icon>android</icon><name>Install in Android (Waydroid)</name><unique-id>jk-apk-1</unique-id><command>xfce4-terminal -e "bash -c \'waydroid app install %f; echo; echo Enter dabain; read\'"</command><description>APK ko Android (Waydroid) me install karo - pehle JK Android setup lazmi</description><patterns>*.apk;*.APK</patterns><files/></action>\n')
s = s.replace('</actions>', extra + '</actions>')
open(p, 'w').write(s); print("uca exe/apk actions added")
PYEOF
  python3 -c "import xml.dom.minidom; xml.dom.minidom.parse('$UCA')" && echo "uca.xml still VALID" || echo "uca.xml INVALID after append"
fi
# Android entries
if [ -x "$R/usr/bin/waydroid" ] || [ -f "$R/usr/bin/waydroid" ]; then
  install -m755 "$JK/jk-android.py" "$R/usr/local/bin/jk-android"
  mkentry "JK Android (Waydroid)" "jk-android" android "$SKEL/Desktop/JK Android.desktop"
  cp "$SKEL/Desktop/JK Android.desktop" "$APPS/jk-android.desktop"
fi
has scrcpy && mkentry "Phone Screen (scrcpy)" "scrcpy" phone "$STF/Phone Screen scrcpy.desktop"
echo "wine/android entries done"
'''
s = s.replace('echo "=== SYSTOOLS CUSTOMIZE DONE ==="', add + '\necho "=== SYSTOOLS CUSTOMIZE DONE ==="')
open(p, 'w').write(s); print("systools: wine/android added")
