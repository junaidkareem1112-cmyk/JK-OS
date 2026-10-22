#!/usr/bin/env python3
"""JK Live Captions (EXPERIMENTAL) - offline live captions.
Bundled Vosk small EN model se mic speech ko live text me badalta hai
(always-on-top chhoti window). English only, accuracy model par munhasir -
yehi wajah hai ke isay EXPERIMENTAL label diya gaya hai. Agar Whisper model
user ne download kiya ho to future me usay use hoga; v1 me Vosk streaming hai."""
import gi, json, sys, threading
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, GLib
from pathlib import Path
MODEL = Path("/usr/share/jk-assistant/models/vosk-model-small-en-us-0.15")
class Win(Gtk.Window):
    def __init__(self):
        super().__init__(title="JK Live Captions (Experimental)")
        self.set_default_size(640, 130); self.set_keep_above(True)
        self.set_position(Gtk.WindowPosition.CENTER)
        self.label = Gtk.Label(label="Live Captions (Experimental) - bolna shuru karein (English)…")
        self.label.set_line_wrap(True)
        self.label.set_markup("<span size='14000'>Live Captions (Experimental) — bolna shuru karein (English)…</span>")
        self.add(self.label); self.connect("destroy", Gtk.main_quit)
        threading.Thread(target=self.listen, daemon=True).start()
    def set_text(self, t, final=False):
        esc = t.replace("&", "&amp;").replace("<", "&lt;")
        self.label.set_markup(f"<span size='14000'>{esc}</span>")
    def listen(self):
        try:
            import sounddevice as sd, queue
            from vosk import Model, KaldiRecognizer
            if not MODEL.exists(): raise RuntimeError("Vosk model nahi mila")
            model = Model(str(MODEL)); rec = KaldiRecognizer(model, 16000); rec.SetWords(False)
            q = queue.Queue()
            def cb(indata, frames, t_, s_): q.put(bytes(indata))
            text = ""
            with sd.RawInputStream(samplerate=16000, blocksize=4000, dtype="int16", channels=1, callback=cb):
                while True:
                    data = q.get()
                    if rec.AcceptWaveform(data):
                        r = json.loads(rec.Result()).get("text", "")
                        if r: text = (text + " " + r).strip()[-300:]
                    else:
                        p = json.loads(rec.PartialResult()).get("partial", "")
                        GLib.idle_add(self.set_text, (text + " " + p).strip())
        except Exception as e:
            GLib.idle_add(self.set_text, f"Live Captions ruk gaya: {e} (mic/model check karein - ye feature Experimental hai)")
if __name__ == "__main__":
    Win().show_all(); Gtk.main()
