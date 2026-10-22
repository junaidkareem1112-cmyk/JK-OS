JK = '/home/hatch/workspace/jk-os'
p = f'{JK}/privacy-install.sh'; s = open(p).read()

s = s.replace('PKGS="wireguard-tools openvpn network-manager-openvpn network-manager-openvpn-gnome tor torsocks torbrowser-launcher proxychains4 telegram-desktop xfce4-xkb-plugin onboard orca power-profiles-daemon redshift clamav clamtk"',
 'PKGS="wireguard-tools openvpn network-manager-openvpn network-manager-openvpn-gnome tor torsocks torbrowser-launcher proxychains4 telegram-desktop xfce4-xkb-plugin onboard orca power-profiles-daemon redshift clamav clamtk hardinfo lshw-gtk usbview gnome-disk-utility gucharmap bleachbit deja-dup remmina gnome-logs simplescreenrecorder inxi persepolis aria2 uget"')

# host: stage powershell deb + xampp installer + powershell dep URIs
old = '''# host apt (bookworm state from build2) - URIs'''
new = '''# PowerShell (official Microsoft deb) + XAMPP (official Apache Friends installer) staging
DL=$JK/downloads
[ -s "$DL/powershell.deb" ] && cp "$DL/powershell.deb" "$R/opt/jk/" && echo "powershell deb staged"
[ -s "$DL/xampp-installer.run" ] && cp "$DL/xampp-installer.run" "$R/opt/jk/" && echo "xampp installer staged"
# host apt (bookworm state from build2) - URIs'''
assert old in s; s = s.replace(old, new, 1)

old = '''apt-get $APTOPTS install --print-uris -y --allow-unauthenticated $PKGS $LANGPKGS > "$JK/uris-priv-raw.txt" 2>"$JK/uris-priv-err.log" || true'''
new = '''apt-get $APTOPTS install --print-uris -y --allow-unauthenticated $PKGS $LANGPKGS > "$JK/uris-priv-raw.txt" 2>"$JK/uris-priv-err.log" || true
# PowerShell deps (local deb ke liye bhi URIs)
if [ -s "$DL/powershell.deb" ]; then apt-get $APTOPTS install --print-uris -y --allow-unauthenticated "$DL/powershell.deb" >> "$JK/uris-priv-raw.txt" 2>>"$JK/uris-priv-err.log" || true; fi'''
assert old in s; s = s.replace(old, new, 1)

# chroot install script: extra smoke + powershell + xampp steps
old = '''clamscan --version >> $V 2>&1 | head -1; freshclam --version >> $V 2>&1 | head -1'''
new = '''clamscan --version >> $V 2>&1 | head -1; freshclam --version >> $V 2>&1 | head -1
echo "=== SYSTEM TOOLS / DOWNLOADER SMOKE ===" >> $V
for c in hardinfo lshw-gtk usbview gnome-disks gucharmap bleachbit deja-dup remmina gnome-logs simplescreenrecorder inxi persepolis aria2c uget-gtk; do
  if command -v $c >/dev/null 2>&1; then echo "SMOKE PASS $c" >> $V; else echo "SMOKE FAIL $c" >> $V; fi
done
aria2c --version >> $V 2>&1 | head -1
persepolis --version >> $V 2>&1 | head -2 || true
# PowerShell (official deb)
if [ -s /opt/jk/powershell.deb ]; then
  apt-get install -y /opt/jk/powershell.deb >> /opt/jk/apt-pwsh.log 2>&1 || apt-get install -y -f >> /opt/jk/apt-pwsh.log 2>&1 || true
  echo "--- pwsh ---" >> $V; pwsh --version >> $V 2>&1 || echo "PWSH FAIL" >> $V
fi
# XAMPP (official installer, unattended, /opt/lampp) - autostart NAHI (koi service enable nahi hoti)
if [ -s /opt/jk/xampp-installer.run ]; then
  chmod +x /opt/jk/xampp-installer.run
  /opt/jk/xampp-installer.run --mode unattended >> /opt/jk/xampp-install.log 2>&1 || echo "XAMPP INSTALL FAIL" >> $V
  echo "--- xampp ---" >> $V
  ls /opt/lampp/lampp >> $V 2>&1 || echo "LAMPP MISSING" >> $V
  /opt/lampp/bin/php -v >> $V 2>&1 | head -1 || true
  rm -f /opt/jk/xampp-installer.run
fi'''
assert old in s; s = s.replace(old, new, 1)
open(p, 'w').write(s); print("privacy-install: systools+downloader+pwsh+xampp hooked")

# stage4: systools-customize call + extra shortcuts
p = f'{JK}/stage4-iso.sh'; s = open(p).read()
old = 'bash "$JK/privacy-customize.sh"'
assert old in s
s = s.replace(old, old + '\nbash "$JK/systools-customize.sh"', 1)
old = '<property name="&lt;Super&gt;a" type="string" value="jk-quick-settings"/>'
assert old in s
s = s.replace(old, old + '''
      <property name="&lt;Primary&gt;&lt;Alt&gt;t" type="string" value="xfce4-terminal"/>
      <property name="Print" type="string" value="xfce4-screenshooter"/>
      <property name="&lt;Primary&gt;&lt;Shift&gt;Escape" type="string" value="xfce4-taskmanager"/>
      <property name="&lt;Super&gt;r" type="string" value="xfce4-appfinder"/>''', 1)
open(p, 'w').write(s); print("stage4: systools call + shortcuts hooked")

# systools-customize: Downloader folder + notes + XDM/FDM/JD2 one-click
p = f'{JK}/systools-customize.sh'; s = open(p).read()
add = '''
# ---- Downloader folder (IDM-style) ----
DF="$SKEL/Desktop/Downloader"; mkdir -p "$DF"
has persepolis && copy_or_make com.github.persepolisdm.persepolis.desktop "Download Manager" "persepolis" folder-download "$DF/Download Manager.desktop"
if ! ls "$DF/Download Manager.desktop" >/dev/null 2>&1 && has persepolis; then mkentry "Download Manager" "persepolis" folder-download "$DF/Download Manager.desktop"; fi
has uget-gtk && mkentry "uGet (Light Downloader)" "uget-gtk" folder-download "$DF/uGet.desktop"
cat > "$DF/Downloader - Browser Setup.txt" <<'EOFN'
DOWNLOADER - BROWSER SETUP (Roman Urdu + English)
=================================================
JK OS ka Download Manager = Persepolis (aria2 engine). IDM jaisa style:
multi-part (ek file ke kai hisse ek sath) tez download, resume, queue, schedule.
Default mashwara: Settings me connections per download 8-16 rakhein, download
folder ~/Downloads, clipboard watch ON (Persepolis Settings me milta hai).

BROWSER INTEGRATION (Firefox):
1. Firefox kholein, Add-ons (extensions) me "Persepolis Download Manager"
   integration extension search karke add karein (official extension).
2. Uske baad Firefox ke download links Persepolis pakar lega.
Note: koi extension pehle se zabardasti install NAHI kiya gaya - sirf official
extension hi add karein jo Persepolis ki site/docs batate hain.
EOFN
cat > "$DF/Install XDM (IDM jaisa).sh" <<'EOFS'
#!/bin/bash
# Xtreme Download Manager - official GitHub release se one-click install
echo "XDM official release download ho raha hai..."
cd /tmp && curl -L -o xdm.tar.xz "https://github.com/subhra74/xdm/releases/download/7.2.11/xdm-7.2.11.tar.xz" && tar -xf xdm.tar.xz && sudo ./install.sh && echo "Ho gaya! XDM menu me mil jayega."
echo "Enter dabain band karne ke liye"; read
EOFS
chmod +x "$DF/Install XDM (IDM jaisa).sh"
mkentry "Install XDM (One-Click)" "xfce4-terminal -e \\"bash '$DF/Install XDM (IDM jaisa).sh'\\"" folder-download "$DF/Install XDM.desktop" true
mkentry "JDownloader 2 (Website)" "xdg-open https://jdownloader.org/download/index" web-browser "$DF/JDownloader 2.desktop"
mkentry "Free Download Manager (Website)" "xdg-open https://www.freedownloadmanager.org/download.htm" web-browser "$DF/Free Download Manager.desktop"
echo "downloader folder done"
'''
s = s.replace('echo "=== SYSTOOLS CUSTOMIZE DONE ==="', add + '\necho "=== SYSTOOLS CUSTOMIZE DONE ==="')
open(p, 'w').write(s); print("systools: downloader folder added")
