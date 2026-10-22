#!/usr/bin/env python3
"""JK XAMPP Panel - XAMPP (Apache Friends) ke liye simple GUI front-end.
Engine asal XAMPP hai (/opt/lampp); ye panel sirf Start/Stop/Status buttons
deta hai (pkexec se root). Koi autostart nahi - jab chahiye tab Start."""
import gi, subprocess
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, GLib
LAMPP = "/opt/lampp/lampp"
def status():
    try:
        out = subprocess.run([LAMPP, "status"], capture_output=True, text=True, timeout=20).stdout
        return out.strip().replace("\n", " | ")
    except Exception as e:
        return f"Status nahi mila: {e}"
def main():
    w = Gtk.Window(title="XAMPP Control Panel (JK)"); w.set_default_size(430, 300); w.set_position(Gtk.WindowPosition.CENTER)
    box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
    box.set_margin_top(16); box.set_margin_bottom(16); box.set_margin_start(16); box.set_margin_end(16)
    t = Gtk.Label(); t.set_markup("<b><big>XAMPP</big></b>\nApache + MariaDB + PHP (Apache Friends)"); box.pack_start(t, False, False, 2)
    lab = Gtk.Label(label=status()); lab.set_line_wrap(True); box.pack_start(lab, False, False, 4)
    def act(cmd, label):
        subprocess.run(["pkexec", LAMPP, cmd]); lab.set_text(status())
    row = Gtk.Box(spacing=8)
    for name, cmd in [("Start XAMPP", "start"), ("Stop XAMPP", "stop"), ("Restart", "restart")]:
        b = Gtk.Button(label=name); b.connect("clicked", lambda _, c=cmd: act(c, _)); row.pack_start(b, True, True, 0)
    box.pack_start(row, False, False, 2)
    row2 = Gtk.Box(spacing=8)
    h = Gtk.Button(label="htdocs Folder"); h.connect("clicked", lambda _: subprocess.Popen(["xdg-open", "/opt/lampp/htdocs"])); row2.pack_start(h, True, True, 0)
    p = Gtk.Button(label="phpMyAdmin"); p.connect("clicked", lambda _: subprocess.Popen(["xdg-open", "http://localhost/phpmyadmin"])); row2.pack_start(p, True, True, 0)
    box.pack_start(row2, False, False, 2)
    n = Gtk.Label(label="Note: phpMyAdmin sirf tab khulega jab XAMPP Start ho.\nPorts: Apache 80, MariaDB 3306. Pehle Start par password poochha jayega (pkexec).")
    n.set_line_wrap(True); box.pack_start(n, False, False, 2)
    w.add(box); w.connect("destroy", Gtk.main_quit); w.show_all(); Gtk.main()
if __name__ == "__main__": main()
