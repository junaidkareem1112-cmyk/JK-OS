#!/usr/bin/env python3
"""JK Quick Settings - Windows 11 style (Jk ke reference screenshot jaisa layout,
JK pine/charcoal palette). Tiles: WiFi / Bluetooth / Airplane | Accessibility /
Energy saver / Live captions (experimental). Sliders: Brightness, Volume.
Bottom: battery % (left), Settings gear (right). Sab controls REAL backends:
pactl, brightnessctl, nmcli, bluetoothctl, rfkill (state save/restore ke sath),
powerprofilesctl (energy saver). Koi dummy switch nahi.
CLI (Jarvis/tests): --wifi on|off --bluetooth on|off --flight on|off
--energy on|off --volume N --brightness N --mute --state
"""
import json, re, subprocess, sys
from pathlib import Path

STATE = Path.home() / ".config" / "jk-os" / "flight-state.json"

def run(cmd, runner=None):
    if runner: return runner(cmd)
    r = subprocess.run(cmd, capture_output=True, text=True, timeout=15)
    return r.stdout or ""

class Controls:
    def __init__(self, runner=None): self.runner = runner
    def _r(self, cmd): return run(cmd, self.runner)
    def volume(self):
        out = self._r(["pactl", "get-sink-volume", "@DEFAULT_SINK@"])
        m = re.search(r"(\d+)%", out); vol = int(m.group(1)) if m else 50
        mute = "yes" in self._r(["pactl", "get-sink-mute", "@DEFAULT_SINK@"])
        return vol, mute
    def brightness(self):
        out = self._r(["brightnessctl", "-m"])
        for p in out.split(","):
            if p.strip().endswith("%"):
                try: return int(p.strip().rstrip("%"))
                except Exception: pass
        return 80
    def wifi_on(self): return self._r(["nmcli", "radio", "wifi"]).strip() == "enabled"
    def wifi_name(self):
        out = self._r(["nmcli", "-t", "-f", "NAME", "connection", "show", "--active"])
        names = [n for n in out.splitlines() if n and n != "lo"]
        return names[0] if names else ""
    def bt_on(self): return "Powered: yes" in self._r(["bluetoothctl", "show"])
    def flight_on(self):
        blocks = re.findall(r"Soft blocked: (\w+)", self._r(["rfkill", "list", "all"]))
        return bool(blocks) and all(b == "yes" for b in blocks)
    def energy_on(self):
        return self._r(["powerprofilesctl", "get"]).strip() == "power-saver"
    def battery(self):
        import glob
        for p in glob.glob("/sys/class/power_supply/BAT*/capacity"):
            try: return int(Path(p).read_text().strip())
            except Exception: pass
        return None
    def state(self):
        v = self.volume()
        return {"volume": v[0], "muted": v[1], "brightness": self.brightness(),
                "wifi": self.wifi_on(), "wifi_name": self.wifi_name(), "bluetooth": self.bt_on(),
                "flight": self.flight_on(), "energy_saver": self.energy_on(), "battery": self.battery()}
    def set_volume(self, v): self._r(["pactl", "set-sink-volume", "@DEFAULT_SINK@", f"{int(v)}%"])
    def toggle_mute(self): self._r(["pactl", "set-sink-mute", "@DEFAULT_SINK@", "toggle"])
    def set_brightness(self, v): self._r(["brightnessctl", "set", f"{int(v)}%"])
    def set_wifi(self, on): self._r(["nmcli", "radio", "wifi", "on" if on else "off"])
    def set_bluetooth(self, on): self._r(["bluetoothctl", "power", "on" if on else "off"])
    def set_energy(self, on): self._r(["powerprofilesctl", "set", "power-saver" if on else "balanced"])
    def mic_muted(self): return "yes" in self._r(["pactl", "get-source-mute", "@DEFAULT_SOURCE@"])
    def toggle_mic(self): self._r(["pactl", "set-source-mute", "@DEFAULT_SOURCE@", "toggle"])
    def set_flight(self, on):
        if on:
            prev = {"wifi": self.wifi_on(), "bluetooth": self.bt_on()}
            STATE.parent.mkdir(parents=True, exist_ok=True)
            STATE.write_text(json.dumps(prev))
            self._r(["rfkill", "block", "all"])
            return prev
        prev = {"wifi": True, "bluetooth": False}
        try: prev = json.loads(STATE.read_text())
        except Exception: pass
        self._r(["rfkill", "unblock", "all"])
        self.set_wifi(bool(prev.get("wifi", True)))
        self.set_bluetooth(bool(prev.get("bluetooth", False)))
        return prev

def cli(argv):
    c = Controls(); a = argv[1:]
    if a[:1] == ["--state"]: print(json.dumps(c.state())); return 0
    if a[:1] == ["--wifi"] and len(a) > 1: c.set_wifi(a[1] == "on"); print("wifi", a[1]); return 0
    if a[:1] == ["--bluetooth"] and len(a) > 1: c.set_bluetooth(a[1] == "on"); print("bluetooth", a[1]); return 0
    if a[:1] == ["--flight"] and len(a) > 1: c.set_flight(a[1] == "on"); print("flight", a[1]); return 0
    if a[:1] == ["--energy"] and len(a) > 1: c.set_energy(a[1] == "on"); print("energy", a[1]); return 0
    if a[:1] == ["--volume"] and len(a) > 1: c.set_volume(int(a[1])); return 0
    if a[:1] == ["--brightness"] and len(a) > 1: c.set_brightness(int(a[1])); return 0
    if a[:1] == ["--mute"]: c.toggle_mute(); return 0
    return 1

CSS = b"""
.qs { background: #FAF6EE; }
.tile { background: #FFFFFF; border-radius: 14px; border: 1px solid #DDD6C8; padding: 10px; min-height: 64px; }
.tile-active { background: #0C5B44; color: #FFFFFF; border-radius: 14px; padding: 10px; min-height: 64px; }
.tile-title { font-weight: bold; font-size: 13px; }
.tile-sub { font-size: 11px; }
.chev { background: transparent; border: none; font-size: 16px; }
"""

def gui():
    import gi, shutil
    gi.require_version("Gtk", "3.0")
    from gi.repository import Gtk, Gdk
    prov = Gtk.CssProvider(); prov.load_from_data(CSS)
    Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), prov, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)
    c = Controls()
    try: st = c.state()
    except Exception: st = {"volume": 50, "muted": False, "brightness": 80, "wifi": False, "wifi_name": "", "bluetooth": False, "flight": False, "energy_saver": False, "battery": None}
    w = Gtk.Window(title="JK Quick Settings"); w.set_default_size(430, 560); w.set_position(Gtk.WindowPosition.CENTER)
    w.get_style_context().add_class("qs")
    root = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
    root.set_margin_top(14); root.set_margin_bottom(12); root.set_margin_start(14); root.set_margin_end(14)
    w.add(root)
    grid = Gtk.Grid(); grid.set_row_spacing(10); grid.set_column_spacing(10); grid.set_column_homogeneous(True)
    root.pack_start(grid, False, False, 0)
    def tile(col, row, icon, title, sub, active, on_click, chev_cmd=None):
        b = Gtk.Button(); b.get_style_context().add_class("tile-active" if active else "tile")
        inner = Gtk.Box(spacing=4)
        lab = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        t = Gtk.Label(); t.set_markup(f"<b>{icon}  {title}</b>"); t.set_xalign(0); t.get_style_context().add_class("tile-title")
        lab.pack_start(t, False, False, 0)
        if sub:
            s = Gtk.Label(label=sub); s.set_xalign(0); s.get_style_context().add_class("tile-sub"); lab.pack_start(s, False, False, 0)
        inner.pack_start(lab, True, True, 0)
        if chev_cmd:
            ch = Gtk.Button(label="›"); ch.get_style_context().add_class("chev")
            ch.connect("clicked", lambda _, cmd=chev_cmd: subprocess.Popen(cmd)); inner.pack_end(ch, False, False, 0)
        b.add(inner); b.connect("clicked", lambda _: (on_click(), w.destroy(), gui()))
        grid.attach(b, col, row, 1, 1)
        return b
    tile(0, 0, "WiFi", "WiFi", st.get("wifi_name") or ("Connected" if st["wifi"] else "Off"), st["wifi"],
         lambda: c.set_wifi(not st["wifi"]), ["nm-connection-editor"])
    tile(1, 0, "BT", "Bluetooth", "On" if st["bluetooth"] else "Off", st["bluetooth"],
         lambda: c.set_bluetooth(not st["bluetooth"]), ["blueman-manager"])
    tile(2, 0, "✈", "Airplane mode", "On" if st["flight"] else "Off", st["flight"],
         lambda: c.set_flight(not st["flight"]))
    tile(0, 1, "♿", "Accessibility", "Settings / On-screen keyboard", False,
         lambda: subprocess.Popen(["xfce4-accessibility-settings"]), ["onboard"])
    tile(1, 1, "🔋", "Energy saver", "On" if st["energy_saver"] else "Off", st["energy_saver"],
         lambda: c.set_energy(not st["energy_saver"]))
    tile(2, 1, "CC", "Live captions", "Experimental", False,
         lambda: subprocess.Popen(["jk-live-captions"]))
    def slider(icon, val, cb):
        row = Gtk.Box(spacing=8)
        row.pack_start(Gtk.Label(label=icon), False, False, 0)
        sc = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, 0, 100, 1); sc.set_value(val)
        sc.set_draw_value(False); sc.connect("value-changed", cb); row.pack_start(sc, True, True, 0)
        root.pack_start(row, False, False, 2)
    slider("☀ Brightness", st["brightness"], lambda s: c.set_brightness(s.get_value()))
    slider("🔊 Volume", st["volume"], lambda s: c.set_volume(s.get_value()))
    ex = Gtk.Box(spacing=6)
    mb = Gtk.ToggleButton(label="Mute"); mb.set_active(st["muted"]); mb.connect("toggled", lambda b: c.toggle_mute()); ex.pack_start(mb, True, True, 0)
    mic = Gtk.ToggleButton(label="Mic Mute"); mic.connect("toggled", lambda b: c.toggle_mic()); ex.pack_start(mic, True, True, 0)
    dnd = Gtk.ToggleButton(label="Do Not Disturb")
    dnd.connect("toggled", lambda b: subprocess.run(["xfconf-query", "-c", "xfce4-notifyd", "-p", "/do-not-disturb", "-n", "-t", "bool", "-s", "true" if b.get_active() else "false"]))
    ex.pack_start(dnd, True, True, 0)
    if shutil.which("redshift"):
        nl = Gtk.ToggleButton(label="Night Light")
        nl.connect("toggled", lambda b: subprocess.Popen(["redshift", "-O", "3500"]) if b.get_active() else subprocess.Popen(["redshift", "-x"]))
        ex.pack_start(nl, True, True, 0)
    root.pack_start(ex, False, False, 2)
    bottom = Gtk.Box(spacing=8)
    bat = Gtk.Label(label=f"🔋 {st['battery']}%" if st.get("battery") is not None else "🔌 AC Power")
    bottom.pack_start(bat, False, False, 0)
    gear = Gtk.Button(label="⚙ Settings"); gear.connect("clicked", lambda _: subprocess.Popen(["xfce4-settings-manager"])); bottom.pack_end(gear, False, False, 0)
    pw = Gtk.Button(label="⏻ Power"); pw.connect("clicked", lambda _: subprocess.Popen(["xfce4-session-logout"])); bottom.pack_end(pw, False, False, 0)
    lk = Gtk.Button(label="🔒 Lock"); lk.connect("clicked", lambda _: subprocess.Popen(["xflock4"])); bottom.pack_end(lk, False, False, 0)
    root.pack_start(bottom, False, False, 4)
    w.connect("destroy", Gtk.main_quit); w.show_all(); Gtk.main()

if __name__ == "__main__":
    if len(sys.argv) > 1: sys.exit(cli(sys.argv))
    gui()
