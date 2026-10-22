#!/usr/bin/env python3
"""JK Language - JK OS interface language switcher (English / اردو / العربية).
Writes user locale properly (~/.dmrc for LightDM + ~/.xsessionrc), phir logout
karne ko kehta hai - koi jhoota instant-switch dawa nahi. Voice (Jarvis) language
alag se Jarvis Settings me hai."""
import gi, subprocess
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk
from pathlib import Path
LANGS = [("English", "en_US.UTF-8", "Language set to English. Please log out and log back in."),
         ("اردو (Urdu)", "ur_PK.UTF-8", "زبان اردو مقرر ہو گئی ہے۔ براہ کرم لاگ آؤٹ کر کے دوبارہ لاگ اِن کریں۔"),
         ("العربية (Arabic)", "ar_EG.UTF-8", "تم تعيين اللغة إلى العربية. يرجى تسجيل الخروج ثم تسجيل الدخول مرة أخرى.")]
def apply(code, msg, win):
    home = Path.home()
    (home / ".dmrc").write_text(f"[Desktop]\nSession=xfce\nLanguage={code}\n")
    (home / ".xsessionrc").write_text(f"export LANG={code}\nexport LANGUAGE={code.split('.')[0]}:en\nexport LC_ALL={code}\n")
    cfg = home / ".config" / "locale.conf"; cfg.parent.mkdir(parents=True, exist_ok=True)
    cfg.write_text(f"LANG={code}\n")
    d = Gtk.MessageDialog(parent=win, flags=0, message_type=Gtk.MessageType.INFO, buttons=Gtk.ButtonsType.NONE, text=msg)
    d.add_button("Log Out Now / لاگ آؤٹ", 1); d.add_button("Later / بعد میں", 0)
    if d.run() == 1: subprocess.Popen(["xfce4-session-logout", "--logout"])
    d.destroy()
def main():
    w = Gtk.Window(title="JK Language / زبان / اللغة"); w.set_default_size(360, 260); w.set_position(Gtk.WindowPosition.CENTER)
    box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
    box.set_margin_top(16); box.set_margin_bottom(16); box.set_margin_start(16); box.set_margin_end(16)
    t = Gtk.Label(); t.set_markup("<b><big>Choose Language / زبان منتخب کریں</big></b>"); box.pack_start(t, False, False, 4)
    for name, code, msg in LANGS:
        b = Gtk.Button(label=name); b.set_size_request(-1, 48)
        b.connect("clicked", lambda _, c=code, m=msg: apply(c, m, w)); box.pack_start(b, False, False, 2)
    n = Gtk.Label(label="Keyboard: Alt+Shift se English / اردو / العربية switch hota hai.\nJarvis voice language alag se Jarvis Settings me hai.")
    n.set_line_wrap(True); box.pack_start(n, False, False, 6)
    w.add(box); w.connect("destroy", Gtk.main_quit); w.show_all(); Gtk.main()
if __name__ == "__main__": main()
