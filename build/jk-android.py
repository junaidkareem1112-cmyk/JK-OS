#!/usr/bin/env python3
"""JK Android - Waydroid helper (Android apps JK OS par).
Sach: pehli dafa `waydroid init` Android image (~1GB) download karega - internet lazmi.
Android asal me "JK Android Mode" login session (Weston/Wayland) me chalta hai,
kyunke Waydroid ko Wayland chahiye. Banking/anti-cheat apps aksar nahi chalte."""
import gi, os, subprocess
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk
def binder_status():
    if os.path.exists("/dev/binderfs") or os.path.exists("/dev/binder"): return "Binder: available lagta hai"
    try:
        out = subprocess.run(["lsmod"], capture_output=True, text=True).stdout
        if "binder" in out: return "Binder: module loaded hai"
    except Exception: pass
    return "Binder: abhi nahi mila (Android Mode session me kernel module chahiye hota hai)"
def waydroid_ready():
    return subprocess.run(["bash", "-c", "ls /var/lib/waydroid/*.img /usr/share/waydroid/*.img 2>/dev/null | head -1"], capture_output=True, text=True).stdout.strip() != "" or os.path.exists("/var/lib/waydroid")
def main():
    w = Gtk.Window(title="JK Android (Waydroid)"); w.set_default_size(470, 380); w.set_position(Gtk.WindowPosition.CENTER)
    box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
    box.set_margin_top(16); box.set_margin_bottom(16); box.set_margin_start(16); box.set_margin_end(16)
    t = Gtk.Label(); t.set_markup("<b><big>JK Android</big></b>\nAndroid apps Waydroid ke zariye (open source)"); box.pack_start(t, False, False, 2)
    st = Gtk.Label(label=f"{binder_status()}\nImage: {'ready lagta hai' if waydroid_ready() else 'pehli dafa setup baqi hai (~1GB download)'}")
    st.set_line_wrap(True); box.pack_start(st, False, False, 4)
    def refresh(_=None): st.set_text(f"{binder_status()}\nImage: {'ready lagta hai' if waydroid_ready() else 'pehli dafa setup baqi hai (~1GB download)'}")
    b1 = Gtk.Button(label="1) Pehli Dafa Setup - waydroid init (internet, ~1GB)")
    b1.connect("clicked", lambda _: (subprocess.run(["xfce4-terminal", "-e", "bash -c 'sudo waydroid init; echo; echo Ho gaya - Enter dabain; read'"]), refresh()))
    box.pack_start(b1, False, False, 2)
    b2 = Gtk.Button(label="2) Android Chalao (is session me koshish)")
    b2.connect("clicked", lambda _: subprocess.Popen(["bash", "-c", "waydroid session start & sleep 3; waydroid show-full-ui"]))
    box.pack_start(b2, False, False, 2)
    b3 = Gtk.Button(label="APK Install karein (file chunein)")
    def apk(_):
        d = Gtk.FileChooserDialog(title="APK chunein", parent=w, action=Gtk.FileChooserAction.OPEN)
        d.add_buttons("Cancel", Gtk.ResponseType.CANCEL, "Install", Gtk.ResponseType.OK)
        if d.run() == Gtk.ResponseType.OK: subprocess.run(["xfce4-terminal", "-e", f"bash -c 'waydroid app install \"{d.get_filename()}\"; echo; echo Enter dabain; read'"])
        d.destroy()
    b3.connect("clicked", apk); box.pack_start(b3, False, False, 2)
    n = Gtk.Label(label="Behtareen tareeqa: Log out karke login screen par 'JK Android Mode' session chunein - wahan Android full screen chalega.\nAPK: File Manager me .apk par right-click > 'Install in Android' bhi hai.\nPlay Store: GAPPS image + Google registration alag steps hain (README dekhein) - guarantee nahi.\nBanking / anti-cheat games aksar nahi chalte (Play Integrity).")
    n.set_line_wrap(True); box.pack_start(n, False, False, 4)
    w.add(box); w.connect("destroy", Gtk.main_quit); w.show_all(); Gtk.main()
if __name__ == "__main__": main()
