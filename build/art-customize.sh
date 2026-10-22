#!/bin/bash
# Art & Craft folder: Tier-1 launchers (real apps) + Tier-2 one-click installers + README
set -e
R="$1"; SKEL="$R/etc/skel"; AC="$SKEL/Desktop/Art & Craft"
mkdir -p "$AC" "$R/usr/share/jk-os/scripts"
app_launcher() { # file, name, exec, icon, comment
  local bin; bin=$(echo $3 | awk '{print $1}')
  if [ ! -x "$R/usr/bin/$bin" ] && [ ! -x "$R/usr/local/bin/$bin" ]; then echo "SKIP launcher $2 (not installed)"; return; fi
  cat > "$AC/$1.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=$2
Exec=$3
Icon=$4
Comment=$5
Terminal=false
Categories=Graphics;
EOF
  chmod +x "$AC/$1.desktop"
}
app_launcher "GIMP" "GIMP - Photo/Image Editor" "gimp" "gimp" "Photoshop jaisa free editor (open source)"
app_launcher "Inkscape" "Inkscape - Vector/Logo Design" "inkscape" "inkscape" "Logo, poster, illustration (open source)"
app_launcher "Krita" "Krita - Digital Painting" "krita" "krita" "Digital painting flagship (open source)"
app_launcher "Pinta" "Pinta - Simple Painting" "pinta" "pinta" "Halka simple paint/drawing (open source)"
app_launcher "MyPaint" "MyPaint - Painting" "mypaint" "mypaint" "Natural brushes painting (open source)"
app_launcher "Scribus" "Scribus - Desktop Publishing" "scribus" "scribus" "Flyer, poster, book layout (open source)"
app_launcher "Audacity" "Audacity - Audio Editor" "audacity" "audacity" "Audio record/edit (open source)"
app_launcher "TuxPaint" "Tux Paint - Kids Art" "tuxpaint" "tuxpaint" "Bachon ke liye art & craft (open source)"
app_launcher "LibreCAD" "LibreCAD - 2D Design" "librecad" "librecad" "2D drawing/CAD (open source)"
inst() { # scriptname, title, apt packages, note
  cat > "$R/usr/share/jk-os/scripts/$1" <<EOS
#!/bin/bash
echo "=== $2 - one-click install (JK OS) ==="
echo "$4"
sudo apt update && sudo apt install -y $3
echo "--- Khatam. Menu/Graphics me icon aa jayega. ---"; read -p "Enter..."
EOS
  chmod +x "$R/usr/share/jk-os/scripts/$1"
  cat > "$AC/Install-$2.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Install $2 (One-Click)
Exec=xfce4-terminal -e "bash /usr/share/jk-os/scripts/$1"
Icon=system-software-install
Comment=$4
Terminal=false
Categories=Graphics;
EOF
  chmod +x "$AC/Install-$2.desktop"
}
inst install-scribus.sh "Scribus" "scribus" "Desktop publishing - flyer/poster/book (size ki wajah se one-click)."
inst install-librecad.sh "LibreCAD" "librecad" "2D CAD design (size ki wajah se one-click)."
inst install-blender.sh "Blender" "blender" "3D art/animation - bara software hai is liye ISO me nahi, one-click se lagega."
inst install-kdenlive.sh "Kdenlive Video Editor" "kdenlive" "Video editing. Halka alternative: OpenShot (sudo apt install openshot-qt)."
inst install-darktable.sh "Darktable" "darktable" "RAW photo studio."
inst install-freecad.sh "FreeCAD" "freecad" "3D design / 3D printing models."
inst install-animation.sh "Synfig + Pencil2D" "synfig pencil2d" "2D animation tools dono lageinge."
inst install-obs.sh "OBS Studio" "obs-studio" "Screen recording / live streaming."
inst install-thunderbird.sh "Thunderbird Mail" "thunderbird" "Mozilla ka free email client (size ki wajah se one-click)."
# Thunderbird launcher is a general utility, also copy to Desktop root of skel
cp "$AC/Install-Thunderbird Mail.desktop" "$SKEL/Desktop/" 2>/dev/null || true
cat > "$AC/README-Art-Craft.txt" <<'EOF'
JK OS - ART & CRAFT TOOLS (sab OPEN SOURCE / FREE hain)
=========================================================
PEHLE SE INSTALLED:
GIMP       : Photo/image editing - Photoshop ka free badal.
Inkscape   : Vector design - logo, poster, illustration.
Krita      : Digital painting - professionals ki pasand.
Pinta      : Simple halka paint program.
MyPaint    : Natural brush painting.
Scribus    : Desktop publishing - flyer, poster, book layout.
Audacity   : Audio recording aur editing.
Tux Paint  : Bachon ke liye mazaydar art program.
LibreCAD   : 2D design/drawing (CAD).

ONE-CLICK INSTALL (is folder ke Install icons, internet chahiye):
Blender    : 3D art aur animation (bara hai, is liye download wala).
Kdenlive   : Video editing (halka alternative: OpenShot).
Darktable  : RAW photo studio.
FreeCAD    : 3D design / printing models.
Synfig + Pencil2D : 2D animation.
OBS Studio : Recording / live streaming.
Thunderbird: Email client.
Note: Agar koi Tier-1 tool size ki wajah se one-click me gaya ho to uska
installer bhi yahin milega - main README me wazeh likha hai.
=========================================================
EOF
echo "art-customize done"
