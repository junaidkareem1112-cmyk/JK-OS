#!/bin/bash
# Live-session evidence test: idle RAM (free -m) + Jarvis daemon process + tray,
# captured via terminal screendump in the booted live session.
ISO=$(ls -t ~/workspace/your_files/JK-OS*.iso ~/workspace/your_files/JKOS*.iso 2>/dev/null | head -1)
if [ -z "$ISO" ] || [ ! -f "$ISO" ]; then echo "FATAL: JK OS ISO not found in ~/workspace/your_files (build not finished?) - aborting test, NOT booting an empty VM"; exit 2; fi
SZ=$(stat -c%s "$ISO"); if [ "$SZ" -lt 1000000000 ]; then echo "FATAL: ISO suspiciously small: $SZ bytes ($ISO) - aborting"; exit 2; fi
echo "ISO under test: $ISO ($SZ bytes)"
rm -f /tmp/qemu-mon4.sock /tmp/ram*.ppm
KVM=""; [ -w /dev/kvm ] && KVM="-enable-kvm -cpu host" || KVM="-cpu qemu64"
mon() { python3 -c "
import socket,time
s=socket.socket(socket.AF_UNIX); s.connect('/tmp/qemu-mon4.sock')
s.sendall(b'''$1'''+b'\n'); time.sleep(0.35); s.close()
" 2>/dev/null; }
type_text() { python3 - "$1" <<'PYEOF'
import socket, sys, time
text = sys.argv[1]
KEYS = {' ': 'spc', '-': 'minus', '.': 'dot', '/': 'slash', '|': 'shift-backslash', '>': 'shift-dot'}
s = socket.socket(socket.AF_UNIX); s.connect('/tmp/qemu-mon4.sock')
def send(k):
    s.sendall(f"sendkey {k}\n".encode()); time.sleep(0.06)
for ch in text:
    if ch in KEYS: send(KEYS[ch])
    elif ch.isupper(): send('shift-' + ch.lower())
    elif ch.isalnum(): send(ch)
    else: send(ch)
    time.sleep(0.05)
s.close()
PYEOF
}
qemu-system-x86_64 -m 4096 -smp 2 $KVM -cdrom "$ISO" -boot d \
  -vga std -display none -monitor unix:/tmp/qemu-mon4.sock,server,nowait &
QPID=$!
sleep 150
mon "sendkey alt-f2"; sleep 2; type_text "terminal"; sleep 1; mon "sendkey ret"; sleep 3
type_text "free -m"; mon "sendkey ret"; sleep 2
type_text "pgrep -af jarvis"; mon "sendkey ret"; sleep 2
type_text "ls /usr/share/jk-assistant/models"; mon "sendkey ret"; sleep 2
mon "screendump /tmp/ram1.ppm"
type_text "neofetch"; mon "sendkey ret"; sleep 4
mon "screendump /tmp/ram2.ppm"
mon "quit"; sleep 2; kill $QPID 2>/dev/null
python3 - <<'EOF'
from PIL import Image
import os
for n in (1,2):
    p=f"/tmp/ram{n}.ppm"
    if os.path.exists(p) and os.path.getsize(p)>10000:
        im=Image.open(p); im.save(f"/home/hatch/workspace/jk-os/qemu-ram-{n}.png"); print("saved ram", n, im.size)
    else: print("missing ram", n)
EOF
echo "=== RAM TEST DONE ==="
