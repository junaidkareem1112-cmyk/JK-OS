import re
JK = '/home/hatch/workspace/jk-os'

# 1) panel plugins 12 (QS launcher) + 13 (xkb)
p = f'{JK}/customize-rootfs.sh'; s = open(p).read()
s = s.replace('''        <value type="int" value="8"/>
        <value type="int" value="9"/>''', '''        <value type="int" value="8"/>
        <value type="int" value="13"/>
        <value type="int" value="12"/>
        <value type="int" value="9"/>''')
anchor11 = '    <property name="plugin-11" type="string" value="showdesktop"/>\n'
assert anchor11 in s
s = s.replace(anchor11, anchor11 + '''    <property name="plugin-12" type="string" value="launcher">
      <property name="items" type="array"><value type="string" value="jk-quick-settings-12.desktop"/></property>
    </property>
    <property name="plugin-13" type="string" value="xkb">
      <property name="display" type="uint" value="1"/>
    </property>
''')
open(p, 'w').write(s); print("panel patched")

# 2) stage4: QS + captions + language install, Super+A, launcher-12 file
p = f'{JK}/stage4-iso.sh'; s = open(p).read()
sj = '<property name="&lt;Super&gt;j" type="string" value="jk-jarvis-ptt"/>'
assert sj in s
s = s.replace(sj, sj + '\n      <property name="&lt;Super&gt;a" type="string" value="jk-quick-settings"/>')
anchor = 'cat > "$SKEL/.config/autostart/jk-jarvis-tray.desktop"'
assert anchor in s
addition = '''
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

'''
s = s.replace(anchor, addition + anchor, 1)
open(p, 'w').write(s); print("stage4 patched")

# 3) privacy-customize: keyboard layouts + antivirus entries
p = f'{JK}/privacy-customize.sh'; s = open(p).read()
assert 'echo "privacy-customize done"' in s
block = '''# Keyboard layouts: us + pk (Urdu) + ara (Arabic), Alt+Shift switch
if [ -f "$R/etc/default/keyboard" ]; then
  sed -i 's/^XKBLAYOUT=.*/XKBLAYOUT="us,pk,ara"/; s/^XKBOPTIONS=.*/XKBOPTIONS="grp:alt_shift_toggle"/' "$R/etc/default/keyboard"
  grep -q '^XKBLAYOUT' "$R/etc/default/keyboard" || echo 'XKBLAYOUT="us,pk,ara"' >> "$R/etc/default/keyboard"
  grep -q '^XKBOPTIONS' "$R/etc/default/keyboard" || echo 'XKBOPTIONS="grp:alt_shift_toggle"' >> "$R/etc/default/keyboard"
else
  mkdir -p "$R/etc/default"
  printf 'XKBMODEL="pc105"\\nXKBLAYOUT="us,pk,ara"\\nXKBVARIANT=""\\nXKBOPTIONS="grp:alt_shift_toggle"\\nBACKSPACE="guess"\\n' > "$R/etc/default/keyboard"
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
echo "privacy-customize done"'''
s = s.replace('echo "privacy-customize done"', block)
open(p, 'w').write(s); print("privacy-customize patched")
