#!/bin/bash
# QEMU boot test: BIOS boot of the ISO, -m 4096 (4GB baseline), screendumps -> PNG
ISO=$(ls -t ~/workspace/your_files/JK-OS*.iso ~/workspace/your_files/JKOS*.iso 2>/dev/null | head -1)
if [ -z "$ISO" ] || [ ! -f "$ISO" ]; then echo "FATAL: JK OS ISO not found in ~/workspace/your_files (build not finished?) - aborting test, NOT booting an empty VM"; exit 2; fi
SZ=$(stat -c%s "$ISO"); if [ "$SZ" -lt 1000000000 ]; then echo "FATAL: ISO suspiciously small: $SZ bytes ($ISO) - aborting"; exit 2; fi
echo "ISO under test: $ISO ($SZ bytes)"
rm -f /tmp/qemu-mon.sock /tmp/shot1.ppm /tmp/shot2.ppm
KVM=""; [ -w /dev/kvm ] && KVM="-enable-kvm -cpu host" || KVM="-cpu qemu64"
echo "KVM mode: $KVM"
qemu-system-x86_64 -m 4096 -smp 2 $KVM -cdrom "$ISO" -boot d -vga std -display none \
  -monitor unix:/tmp/qemu-mon.sock,server,nowait -serial file:/tmp/serial.log &
QPID=$!
echo "qemu pid $QPID"
mon() { python3 -c "
import socket,sys,time
s=socket.socket(socket.AF_UNIX); s.connect('/tmp/qemu-mon.sock')
s.sendall(b'$1\n'); time.sleep(1); s.close()
"; }
sleep 100; mon "screendump /tmp/shot1.ppm"; ls -lh /tmp/shot1.ppm 2>/dev/null
sleep 75;  mon "screendump /tmp/shot2.ppm"; ls -lh /tmp/shot2.ppm 2>/dev/null
mon "info status"
python3 - <<'EOF'
from PIL import Image
import os
for n in (1,2):
    p=f"/tmp/shot{n}.ppm"
    if os.path.exists(p) and os.path.getsize(p)>10000:
        im=Image.open(p); im.save(f"/home/hatch/workspace/jk-os/qemu-boot-test{n}.png"); print("saved shot", n, im.size)
    else: print("shot missing/small", p)
EOF
mon "quit"; sleep 2; kill $QPID 2>/dev/null
echo "=== QEMU TEST DONE ==="; ls -lh ~/workspace/jk-os/qemu-boot-test*.png 2>/dev/null
