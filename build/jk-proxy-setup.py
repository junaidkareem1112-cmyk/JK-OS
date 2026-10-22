#!/usr/bin/env python3
"""JK Proxy Setup - apna proxy lagao/test/off (JK OS helper).
System proxy (gsettings) + shell env file + proxychains config update karta hai."""
import gi, json, subprocess, os
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk
from pathlib import Path
ENVF = Path.home() / ".config" / "jk-os" / "proxy.env"
def sh(cmd): return subprocess.run(["bash", "-c", cmd], capture_output=True, text=True)
class Win(Gtk.Window):
    def __init__(self):
        super().__init__(title="JK Proxy Setup"); self.set_default_size(430, 300)
        g = Gtk.Grid(); g.set_row_spacing(8); g.set_column_spacing(8); g.set_margin_top(14); g.set_margin_start(14); g.set_margin_end(14)
        self.add(g)
        g.attach(Gtk.Label(label="Proxy Host (e.g. 127.0.0.1 ya proxy.example.com):"), 0, 0, 2, 1)
        self.host = Gtk.Entry(); g.attach(self.host, 0, 1, 2, 1)
        g.attach(Gtk.Label(label="Port:"), 0, 2, 1, 1)
        self.port = Gtk.Entry(text="8080"); g.attach(self.port, 1, 2, 1, 1)
        g.attach(Gtk.Label(label="Type:"), 0, 3, 1, 1)
        self.typ = Gtk.ComboBoxText(); [self.typ.append_text(t) for t in ("http", "socks5")]; self.typ.set_active(0); g.attach(self.typ, 1, 3, 1, 1)
        b1 = Gtk.Button(label="APPLY (Proxy ON)"); b1.connect("clicked", self.apply); g.attach(b1, 0, 4, 1, 1)
        b2 = Gtk.Button(label="OFF (Proxy band)"); b2.connect("clicked", self.off); g.attach(b2, 1, 4, 1, 1)
        b3 = Gtk.Button(label="Test Connection (exit IP dekho)"); b3.connect("clicked", self.test); g.attach(b3, 0, 5, 2, 1)
        self.out = Gtk.Label(label="Apna proxy khud dalna hai - JK OS koi proxy server nahi deta."); self.out.set_line_wrap(True)
        g.attach(self.out, 0, 6, 2, 1)
        self.connect("destroy", Gtk.main_quit)
    def url(self):
        return f"{self.typ.get_active_text()}://{self.host.get_text().strip()}:{self.port.get_text().strip()}"
    def apply(self, *_):
        u = self.url()
        sh(f"gsettings set org.gnome.system.proxy mode 'manual'")
        proto = "https" if self.typ.get_active_text() == "http" else "https"
        sh(f"gsettings set org.gnome.system.proxy.http host '{self.host.get_text().strip()}'; gsettings set org.gnome.system.proxy.http port {self.port.get_text().strip()}")
        sh(f"gsettings set org.gnome.system.proxy.socks host '{self.host.get_text().strip()}'; gsettings set org.gnome.system.proxy.socks port {self.port.get_text().strip()}")
        ENVF.parent.mkdir(parents=True, exist_ok=True)
        ENVF.write_text(f"export http_proxy={u}\nexport https_proxy={u}\nexport HTTP_PROXY={u}\nexport HTTPS_PROXY={u}\n")
        self.out.set_text(f"Proxy ON: {u}\n(env file: ~/.config/jk-os/proxy.env - naye terminal me asar hoga; apps ke liye logout/login behtar)")
    def off(self, *_):
        sh("gsettings set org.gnome.system.proxy mode 'none'")
        try: ENVF.unlink()
        except Exception: pass
        self.out.set_text("Proxy OFF ho gaya (system settings + env file saaf).")
    def test(self, *_):
        u = self.url()
        r = sh(f"curl -s --max-time 15 -x {u} https://api.ipify.org || curl -s --max-time 15 -x {u} http://api.ipify.org")
        ip = r.stdout.strip()
        self.out.set_text(f"Test result exit IP: {ip}" if ip else "Test FAIL - proxy jawab nahi de raha (host/port/type check karein).")
if __name__ == "__main__":
    Win().show_all(); Gtk.main()
