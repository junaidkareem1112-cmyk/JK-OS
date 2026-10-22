#!/bin/bash
# Run on HOST as root, arg1 = rootfs dir
set -e
R="$1"
SKEL="$R/etc/skel"
mkdir -p "$SKEL/.config/xfce4/xfconf/xfce-perchannel-xml" "$SKEL/Desktop" "$SKEL/.config/xfce4/panel" "$SKEL/.config/gtk-3.0"
mkdir -p "$R/usr/share/backgrounds/jk-os" "$R/usr/share/jk-os" "$R/usr/share/icons/jk"
cp ~/workspace/jk-os/wallpaper.png "$R/usr/share/backgrounds/jk-os/wallpaper.png"
cp ~/workspace/jksoft-website/assets/img/logo/jk-mark-pine.png "$R/usr/share/icons/jk/jk-logo.png" || true
cp ~/workspace/jksoft-website/assets/img/logo/jk-soft-solutions-pine.png "$R/usr/share/jk-os/logo.png" || true
cp ~/workspace/jksoft-website/assets/img/logo/jk-mark-pine.png "$SKEL/.config/xfce4/panel/jk-logo.png" || true

# --- os-release / identity ---
cat > "$R/etc/os-release" <<'EOF'
PRETTY_NAME="JK OS 1.0"
NAME="JK OS"
VERSION_ID="1.0"
VERSION="1.0 (Bookworm)"
VERSION_CODENAME=bookworm
ID=jk-os
ID_LIKE=debian
HOME_URL="https://jksoft.store/"
SUPPORT_URL="https://jksoft.store/"
BUG_REPORT_URL="https://jksoft.store/"
EOF
echo "jk-os" > "$R/etc/hostname"
cat > "$R/etc/hosts" <<'EOF'
127.0.0.1 localhost
127.0.1.1 jk-os
::1 localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF
cat > "$R/etc/motd" <<'EOF'
Welcome to JK OS 1.0 - by JK Soft Solutions (Smart Solutions, Stronger Business)
EOF
cat > "$R/etc/issue" <<'EOF'
JK OS 1.0 \n \l
EOF
ln -sf ../usr/share/os-release "$R/etc/os-release.link" 2>/dev/null || true
# lsb-release compat
cat > "$R/etc/lsb-release" <<'EOF'
DISTRIB_ID=JKOS
DISTRIB_RELEASE=1.0
DISTRIB_CODENAME=bookworm
DISTRIB_DESCRIPTION="JK OS 1.0"
EOF

# --- Welcome / About ---
cat > "$R/usr/share/jk-os/welcome.html" <<'EOF'
<!doctype html><html><head><meta charset="utf-8"><title>Welcome to JK OS</title>
<style>body{font-family:sans-serif;background:#FAF6EE;color:#1A2420;margin:40px}h1{color:#0C5B44}.bar{background:#0A1F18;color:#FAF6EE;padding:20px;border-radius:12px}a{color:#0C5B44}</style></head>
<body><div class="bar"><h1 style="color:#FAF6EE">Welcome to JK OS 1.0</h1><p>By JK Soft Solutions &mdash; Smart Solutions, Stronger Business.</p></div>
<h2>Shuruaat</h2><p>Neeche taskbar me Start (JK logo) dabayein. Live user: <b>jk</b> / password: <b>jk</b>. PC me install karne ke liye Desktop par <b>Install JK OS</b> icon chalain.</p>
<h2>Tools</h2><p>LibreOffice, Firefox, Thunderbird, VLC, GIMP, Python3, PHP, Node.js, Git, Geany, GParted aur bohat kuch pehle se mojood hai.</p>
<p>Website: <a href="https://jksoft.store/">jksoft.store</a></p></body></html>
EOF
cat > "$SKEL/Desktop/Welcome to JK OS.txt" <<'EOF'
Welcome to JK OS 1.0
====================
By JK Soft Solutions - Smart Solutions, Stronger Business.
Website: https://jksoft.store/

Live User: jk   Password: jk (sudo available)
Install: Desktop par "Install JK OS" icon double-click karein, Calamares installer khulega.

Tools included: LibreOffice Writer/Calc/Impress, Firefox, Thunderbird, VLC, GIMP,
Python 3, PHP, Node.js, Git, Geany IDE, SQLite, GParted, Synaptic, Calculator,
Screenshot, Task Manager, Printing (CUPS), Bluetooth, WiFi/Network Manager.

Agar koi Windows (.exe) program chahiye to Desktop par "Install Wine" script hai
(jahan Wine pehle se na ho wahan aik click se lag jayega).
EOF

# Install + Wine desktop launchers
cat > "$SKEL/Desktop/Install JK OS.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Install JK OS
Comment=Install JK OS to hard disk
Exec=sh -c "pkexec calamares || sudo calamares || calamares"
Icon=system-software-install
Terminal=false
Categories=System;
EOF
chmod +x "$SKEL/Desktop/Install JK OS.desktop"
cat > "$SKEL/Desktop/Install Wine.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Install Wine (Windows Apps)
Comment=Install Wine to run Windows .exe programs
Exec=xfce4-terminal -e "bash -c 'echo Wine install ho raha hai...; sudo apt update && sudo apt install -y wine wine64 libwine winetricks; echo Done. Enter dabayein.; read'"
Icon=system-software-install
Terminal=false
Categories=System;
EOF
chmod +x "$SKEL/Desktop/Install Wine.desktop"

# --- XFCE panel: single bottom taskbar, Whisker as Start ---
cat > "$SKEL/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-panel" version="1.0">
  <property name="configver" type="int" value="2"/>
  <property name="panels" type="array">
    <value type="int" value="1"/>
    <property name="dark-mode" type="bool" value="true"/>
    <property name="panel-1" type="empty">
      <property name="position" type="string" value="p=10;x=0;y=0"/>
      <property name="length" type="uint" value="100"/>
      <property name="position-locked" type="bool" value="true"/>
      <property name="icon-size" type="uint" value="28"/>
      <property name="size" type="uint" value="44"/>
      <property name="plugin-ids" type="array">
        <value type="int" value="1"/>
        <value type="int" value="2"/>
        <value type="int" value="3"/>
        <value type="int" value="4"/>
        <value type="int" value="5"/>
        <value type="int" value="6"/>
        <value type="int" value="7"/>
        <value type="int" value="8"/>
        <value type="int" value="13"/>
        <value type="int" value="12"/>
        <value type="int" value="9"/>
        <value type="int" value="10"/>
        <value type="int" value="11"/>
      </property>
      <property name="background-style" type="uint" value="1"/>
      <property name="background-rgba" type="array">
        <value type="double" value="0.039000"/>
        <value type="double" value="0.122000"/>
        <value type="double" value="0.094000"/>
        <value type="double" value="1.000000"/>
      </property>
    </property>
  </property>
  <property name="plugins" type="empty">
    <property name="plugin-1" type="string" value="whiskermenu">
      <property name="button-icon" type="string" value="/usr/share/icons/jk/jk-logo.png"/>
      <property name="button-title" type="string" value=" Start"/>
      <property name="show-button-title" type="bool" value="true"/>
      <property name="show-button-icon" type="bool" value="true"/>
    </property>
    <property name="plugin-2" type="string" value="launcher">
      <property name="items" type="array"><value type="string" value="firefox-esr-1.desktop"/></property>
    </property>
    <property name="plugin-3" type="string" value="launcher">
      <property name="items" type="array"><value type="string" value="thunar-2.desktop"/></property>
    </property>
    <property name="plugin-4" type="string" value="launcher">
      <property name="items" type="array"><value type="string" value="libreoffice-writer-3.desktop"/></property>
    </property>
    <property name="plugin-5" type="string" value="tasklist">
      <property name="grouping" type="uint" value="1"/>
      <property name="show-labels" type="bool" value="true"/>
      <property name="flat-buttons" type="bool" value="true"/>
    </property>
    <property name="plugin-6" type="string" value="separator"><property name="expand" type="bool" value="true"/><property name="style" type="uint" value="0"/></property>
    <property name="plugin-7" type="string" value="systray"><property name="square-icons" type="bool" value="true"/></property>
    <property name="plugin-8" type="string" value="pulseaudio"><property name="enable-keyboard-shortcuts" type="bool" value="true"/></property>
    <property name="plugin-9" type="string" value="notification-plugin"/>
    <property name="plugin-10" type="string" value="clock">
      <property name="digital-format" type="string" value="%I:%M %p%n%d %b %Y"/>
    </property>
    <property name="plugin-11" type="string" value="showdesktop"/>
    <property name="plugin-12" type="string" value="launcher">
      <property name="items" type="array"><value type="string" value="jk-quick-settings-12.desktop"/></property>
    </property>
    <property name="plugin-13" type="string" value="xkb">
      <property name="display" type="uint" value="1"/>
    </property>
  </property>
</channel>
EOF
# launcher .desktop copies for panel (ids referenced above) placed by post-install hook in customize2
mkdir -p "$SKEL/.config/xfce4/panel/launcher-2" "$SKEL/.config/xfce4/panel/launcher-3" "$SKEL/.config/xfce4/panel/launcher-4"
for pair in "launcher-2 firefox-esr-1:/usr/share/applications/firefox-esr.desktop" "launcher-3 thunar-2:/usr/share/applications/thunar.desktop" "launcher-4 libreoffice-writer-3:/usr/share/applications/libreoffice-writer.desktop"; do
  set -- $pair; dir=$1; name=$2; src=${name#*:}; name=${name%%:*}; base=$(basename $src)
  # name var handling simplified below in python step
  true
done

# desktop wallpaper config
cat > "$SKEL/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitor0" type="empty">
        <property name="workspace0" type="empty">
          <property name="color-style" type="int" value="0"/>
          <property name="image-style" type="int" value="5"/>
          <property name="last-image" type="string" value="/usr/share/backgrounds/jk-os/wallpaper.png"/>
        </property>
        <property name="workspace1" type="empty"><property name="last-image" type="string" value="/usr/share/backgrounds/jk-os/wallpaper.png"/></property>
        <property name="workspace2" type="empty"><property name="last-image" type="string" value="/usr/share/backgrounds/jk-os/wallpaper.png"/></property>
        <property name="workspace3" type="empty"><property name="last-image" type="string" value="/usr/share/backgrounds/jk-os/wallpaper.png"/></property>
      </property>
      <property name="monitorVirtual1" type="empty">
        <property name="workspace0" type="empty"><property name="last-image" type="string" value="/usr/share/backgrounds/jk-os/wallpaper.png"/><property name="image-style" type="int" value="5"/></property>
      </property>
    </property>
  </property>
  <property name="desktop-icons" type="empty">
    <property name="file-icons" type="empty">
      <property name="show-home" type="bool" value="true"/>
      <property name="show-trash" type="bool" value="true"/>
      <property name="show-filesystem" type="bool" value="true"/>
      <property name="show-removable" type="bool" value="true"/>
    </property>
  </property>
</channel>
EOF
cat > "$SKEL/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="Arc-Dark"/>
    <property name="IconThemeName" type="string" value="Papirus-Dark"/>
    <property name="CursorThemeName" type="string" value="Adwaita"/>
  </property>
  <property name="Gtk" type="empty">
    <property name="FontName" type="string" value="Sans 10"/>
    <property name="MonospaceFontName" type="string" value="Monospace 10"/>
  </property>
</channel>
EOF
cat > "$SKEL/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="theme" type="string" value="Default"/>
    <property name="title_font" type="string" value="Sans Bold 10"/>
    <property name="button_layout" type="string" value="O|HMC"/>
    <property name="workspace_count" type="int" value="2"/>
  </property>
</channel>
EOF
cat > "$SKEL/.config/gtk-3.0/settings.ini" <<'EOF'
[Settings]
gtk-theme-name=Arc-Dark
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=Sans 10
gtk-application-prefer-dark-theme=1
EOF
# Also place xfconf defaults system-wide so live user (created by live-config from skel) and installed users get them
mkdir -p "$R/etc/xdg/xfce4/xfconf/xfce-perchannel-xml"
cp "$SKEL/.config/xfce4/xfconf/xfce-perchannel-xml/"*.xml "$R/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/" 2>/dev/null || true

# --- LightDM ---
mkdir -p "$R/etc/lightdm"
cat > "$R/etc/lightdm/lightdm.conf" <<'EOF'
[LightDM]
[Seat:*]
greeter-session=lightdm-gtk-greeter
user-session=xfce
autologin-user=jk
autologin-user-timeout=0
autologin-session=xfce
session-wrapper=/etc/X11/Xsession
greeter-show-manual-login=true
EOF
cat > "$R/etc/lightdm/lightdm-gtk-greeter.conf" <<'EOF'
[greeter]
background=/usr/share/backgrounds/jk-os/wallpaper.png
theme-name=Arc-Dark
icon-theme-name=Papirus-Dark
font-name=Sans 11
position=50%,center 50%,center
default-user-image=/usr/share/icons/jk/jk-logo.png
EOF

# Firefox homepage pref (Debian firefox-esr syspref)
mkdir -p "$R/etc/firefox-esr"
cat > "$R/etc/firefox-esr/jkos.js" <<'EOF'
pref("browser.startup.homepage", "file:///usr/share/jk-os/welcome.html");
pref("browser.startup.page", 1);
pref("browser.newtabpage.enabled", false);
EOF
# Ensure syspref is picked up: debian reads firefox-esr.js dir? also add to defaults pref via symlink attempt in chroot later
echo "customize-rootfs done"
