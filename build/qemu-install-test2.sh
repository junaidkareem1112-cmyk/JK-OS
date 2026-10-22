#!/bin/bash
# QEMU install test v2: disk workspace par (tmpfs 512M par 24G qcow2 nahi banta),
# TCG (no KVM) ke liye lambi waits. Live boot -> terminal -> jk-install-test
# (payload install) -> disk-only reboot -> screenshots.
ISO=$(ls -t ~/workspace/your_files/JK-OS*.iso ~/workspace/your_files/JKOS*.iso 2>/dev/null | head -1)
if [ -z "$ISO" ] || [ ! -f "$ISO" ]; then echo "FATAL: JK OS ISO not found in ~/workspace/your_files (build not finished?) - aborting test, NOT booting an empty VM"; exit 2; fi
SZ=$(stat -c%s "$ISO"); if [ "$SZ" -lt 1000000000 ]; then echo "FATAL: ISO suspiciously small: $SZ bytes ($ISO) - aborting"; exit 2; fi
echo "ISO under test: $ISO ($SZ bytes)"
JK=~/workspace/jk-os
DISK=$JK/qemu-install.qcow2
rm -f "$DISK" /tmp/qemu-mon3.sock /tmp/inst*.ppm
qemu-img create -f qcow2 "$DISK" 24G
KVM=""; [ -w /dev/kvm ] && KVM="-enable-kvm -cpu host" || KVM="-cpu qemu64"
echo "KVM mode: $KVM"
mon() { python3 -c "
import socket,time
s=socket.socket(socket.AF_UNIX); s.connect('/tmp/qemu-mon3.sock')
s.sendall(b'''$1'''+b'\n'); time.sleep(0.35); s.close()
" 2>/dev/null; }
type_text() { python3 - "$1" <<'PYEOF'
import socket, sys, time
text = sys.argv[1]
KEYS = {' ': 'spc', '-': 'minus', '_': 'shift-minus', '.': 'dot', '/': 'slash', '\n': 'ret'}
s = socket.socket(socket.AF_UNIX); s.connect('/tmp/qemu-mon3.sock')
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
echo "booting live with blank disk (TCG, wait 240s)..."
qemu-system-x86_64 -m 4096 -smp 2 $KVM -cdrom "$ISO" -boot order=d \
  -drive file="$DISK",format=qcow2,if=ide \
  -vga std -display none -monitor unix:/tmp/qemu-mon3.sock,server,nowait &
QPID=$!
sleep 240
mon "screendump /tmp/inst1.ppm"
echo "opening terminal via appfinder..."
mon "sendkey alt-f2"; sleep 3; type_text "terminal"; sleep 2; mon "sendkey ret"; sleep 5
mon "screendump /tmp/inst2.ppm"
echo "running jk-install-test (payload copy, wait 600s)..."
type_text "jk-install-test"; mon "sendkey ret"
sleep 420
mon "screendump /tmp/inst3.ppm"
sleep 240
mon "screendump /tmp/inst4.ppm"
type_text "cat /tmp/install-test-result.txt | tail -5"; mon "sendkey ret"; sleep 3
mon "screendump /tmp/inst4b.ppm"
mon "quit"; sleep 2; kill $QPID 2>/dev/null; sleep 2
echo "rebooting from installed disk only (wait 240s)..."
rm -f /tmp/qemu-mon3.sock
qemu-system-x86_64 -m 4096 -smp 2 $KVM -boot order=c \
  -drive file="$DISK",format=qcow2,if=ide \
  -vga std -display none -monitor unix:/tmp/qemu-mon3.sock,server,nowait &
QPID=$!
sleep 240
mon "screendump /tmp/inst5.ppm"
sleep 60
mon "screendump /tmp/inst6.ppm"
mon "quit"; sleep 2; kill $QPID 2>/dev/null
python3 - <<'EOF'
from PIL import Image
import os
for n in ("1","2","3","4","4b","5","6"):
    p=f"/tmp/inst{n}.ppm"
    if os.path.exists(p) and os.path.getsize(p)>10000:
        im=Image.open(p); im.save(f"/home/hatch/workspace/jk-os/qemu-install-{n}.png"); print("saved", n, im.size)
    else: print("missing", n)
EOF
echo "=== INSTALL TEST2 DONE ==="; ls -lh ~/workspace/jk-os/qemu-install-*.png 2>/dev/null
