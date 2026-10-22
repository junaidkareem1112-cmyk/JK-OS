#!/bin/bash
# Privacy & VPN folder + JK Proxy Setup app + README (host-side, arg1=rootfs)
set -e
R="$1"; SKEL="$R/etc/skel"; PV="$SKEL/Desktop/Privacy & VPN"
mkdir -p "$PV"
install -m755 ~/workspace/jk-os/jk-proxy-setup.py "$R/usr/local/bin/jk-proxy-setup"
cat > "$PV/JK Proxy Setup.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=JK Proxy Setup
Comment=Apna proxy (host/port, HTTP ya SOCKS5) lagain, test karein, OFF karein
Exec=jk-proxy-setup
Icon=network-proxy
Terminal=false
Categories=Network;Settings;
EOF
chmod +x "$PV/JK Proxy Setup.desktop"; cp "$PV/JK Proxy Setup.desktop" "$R/usr/share/applications/"
cat > "$PV/Tor Browser.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Tor Browser
Comment=Private browsing - PEHLI dafa chalane par official Tor Browser download hoga
Exec=torbrowser-launcher
Icon=torbrowser
Terminal=false
Categories=Network;WebBrowser;
EOF
chmod +x "$PV/Tor Browser.desktop"; cp "$PV/Tor Browser.desktop" "$R/usr/share/applications/"
cat > "$PV/VPN Setup (Network Connections).desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=VPN Setup
Comment=WireGuard ya OpenVPN (.ovpn) config yahan import karein
Exec=nm-connection-editor
Icon=network-vpn
Terminal=false
Categories=Network;Settings;
EOF
chmod +x "$PV/VPN Setup (Network Connections).desktop"; cp "$PV/VPN Setup (Network Connections).desktop" "$R/usr/share/applications/"
cat > "$PV/README-Privacy.txt" <<'EOF'
JK OS - PRIVACY & VPN GUIDE (Roman Urdu + English)
====================================================
YE TOOLS PEHLE SE INSTALLED HAIN:
- WireGuard (wg): modern fast VPN protocol. NetworkManager me built-in support hai.
- OpenVPN + plugin: .ovpn files GUI se import ho jati hain.
- Tor daemon + torsocks: terminal apps ko Tor se guzarna (torsocks <program>).
- Tor Browser Launcher: pehli dafa chalane par OFFICIAL Tor Browser khud download hoga (internet chahiye), phir is icon se chalega.
- Proxychains4: terminal apps ko proxy se (proxychains4 <program>) - config /etc/proxychains4.conf.
- JK Proxy Setup: is folder ka apna helper - apna proxy host/port likho, Apply/Test/OFF buttons.

VPN CONFIG KAHAN SE AATI HAI?
JK OS koi VPN account ya server NAHI deta. Aap apne VPN provider (Proton, Mullvad,
apni company, ya apna khud ka server) se WireGuard .conf ya OpenVPN .ovpn file lein,
phir "VPN Setup" khol kar + dabain > Import a saved VPN configuration > file chunein.
Phir upar network icon se VPN on/off hota hai.
(Free option: Proton VPN ka free account bana kar unki .ovpn/WireGuard file le sakte hain.)

PROXY:
"JK Proxy Setup" me apna proxy dalen (host, port, HTTP ya SOCKS5). Test button exit IP
dikhayega. OFF button system proxy saaf kar deta hai. JK OS koi proxy server nahi deta.

NOTE: Ye tools privacy ke liye hain - istemal apne mulk ke qanoon ke mutabiq karein.
====================================================
EOF
# Telegram desktop shortcut (sirf agar package sach me installed hai)
for tf in "$R/usr/share/applications/org.telegram.desktop.desktop" "$R/usr/share/applications/telegram-desktop.desktop"; do
  if [ -f "$tf" ]; then cp "$tf" "$SKEL/Desktop/Telegram.desktop"; chmod +x "$SKEL/Desktop/Telegram.desktop"; echo "telegram shortcut added"; fi
done
# Keyboard layouts: us + pk (Urdu) + ara (Arabic), Alt+Shift switch
if [ -f "$R/etc/default/keyboard" ]; then
  sed -i 's/^XKBLAYOUT=.*/XKBLAYOUT="us,pk,ara"/; s/^XKBOPTIONS=.*/XKBOPTIONS="grp:alt_shift_toggle"/' "$R/etc/default/keyboard"
  grep -q '^XKBLAYOUT' "$R/etc/default/keyboard" || echo 'XKBLAYOUT="us,pk,ara"' >> "$R/etc/default/keyboard"
  grep -q '^XKBOPTIONS' "$R/etc/default/keyboard" || echo 'XKBOPTIONS="grp:alt_shift_toggle"' >> "$R/etc/default/keyboard"
else
  mkdir -p "$R/etc/default"
  printf 'XKBMODEL="pc105"\nXKBLAYOUT="us,pk,ara"\nXKBVARIANT=""\nXKBOPTIONS="grp:alt_shift_toggle"\nBACKSPACE="guess"\n' > "$R/etc/default/keyboard"
fi
# JK Antivirus (ClamAV engine, ClamTk GUI)
if [ -f "$R/usr/share/applications/clamtk.desktop" ]; then
  sed 's/^Name=.*/Name=JK Antivirus (ClamAV)/' "$R/usr/share/applications/clamtk.desktop" > "$PF/JK Antivirus.desktop"
  cp "$PF/JK Antivirus.desktop" "$R/usr/share/applications/jk-antivirus.desktop"
  chmod +x "$PF/JK Antivirus.desktop"
fi
cat > "$PF/Update-Virus-Definitions.desktop" <<'EOFUP'
[Desktop Entry]
Name=Update Virus Definitions
Comment=freshclam - internet chahiye
Exec=xfce4-terminal -e "bash -c 'sudo freshclam; echo; echo Ho gaya - Enter dabain; read'"
Icon=system-software-update
Terminal=false
Type=Application
Categories=System;Security;
EOFUP
chmod +x "$PF/Update-Virus-Definitions.desktop"
echo "privacy-customize done"
