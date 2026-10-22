JK = '/home/hatch/workspace/jk-os'
p = f'{JK}/jarvis/jk-assistant.py'; s = open(p).read()

# Router: radio rules sab se pehle (warna 'band karo' alias wifi wali command kha jayega)
old = '''        t = norm(text)
        if not t: return None'''
new = '''        t = norm(text)
        if not t: return None
        # radios (Quick Settings backend; reversible, no confirmation)
        low0 = text.lower()
        m = re.search(r"(wifi|wi-fi|bluetooth) (on|off)", t)
        if m: return {"action": "radio", "args": {"kind": m.group(1).replace("wi-fi", "wifi"), "on": m.group(2) == "on"}, "say": f"{m.group(1)} {m.group(2)} kar diya"}
        m = re.search(r"(flight mode|airplane mode) (on|off)", t)
        if m: return {"action": "radio", "args": {"kind": "flight", "on": m.group(2) == "on"}, "say": "Flight mode ON - WiFi aur Bluetooth band kar diye hain." if m.group(2) == "on" else "Flight mode off - radio wapas chalu kar diye hain."}
        if re.search(r"\\b(wifi|wi-fi) (band|chalu)", low0): return {"action": "radio", "args": {"kind": "wifi", "on": "chalu" in low0}, "say": "WiFi setting kar di"}
        if re.search(r"\\bbluetooth (band|chalu)", low0): return {"action": "radio", "args": {"kind": "bluetooth", "on": "chalu" in low0}, "say": "Bluetooth setting kar di"}
        if "flight mode lagao" in low0: return {"action": "radio", "args": {"kind": "flight", "on": True}, "say": "Flight mode ON - WiFi aur Bluetooth band kar diye hain."}
        if "flight mode hatao" in low0: return {"action": "radio", "args": {"kind": "flight", "on": False}, "say": "Flight mode off - radio wapas chalu kar diye hain."}'''
assert old in s; s = s.replace(old, new, 1)

# Executor: radio branch
old2 = '''            elif a == "screenshot": run(["xfce4-screenshooter", "-f", "-s", str(Path.home() / f"Screenshot-{int(time.time())}.png")])'''
new2 = '''            elif a == "radio":
                flag = {"wifi": "--wifi", "bluetooth": "--bluetooth", "flight": "--flight"}[args.get("kind", "wifi")]
                run(["jk-quick-settings", flag, "on" if args.get("on") else "off"])
            elif a == "screenshot": run(["xfce4-screenshooter", "-f", "-s", str(Path.home() / f"Screenshot-{int(time.time())}.png")])'''
assert old2 in s; s = s.replace(old2, new2, 1)
open(p, 'w').write(s); print("radio router+executor patched")

# Tests: 2-tuple format
p = f'{JK}/jarvis/test_intents.py'; s = open(p).read()
old3 = '''    ("firefox kholo", "open_app"),
]'''
new3 = '''    ("firefox kholo", "open_app"),
    ("turn wifi off", "radio"), ("wifi on", "radio"),
    ("bluetooth on", "radio"), ("bluetooth off", "radio"),
    ("flight mode on", "radio"), ("airplane mode off", "radio"),
    ("flight mode lagao", "radio"), ("wifi band karo", "radio"),
    ("bluetooth chalu karo", "radio"),
]'''
assert old3 in s; s = s.replace(old3, new3, 1)
open(p, 'w').write(s); print("radio tests added")
