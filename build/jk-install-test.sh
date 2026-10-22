#!/bin/bash
# JK OS QEMU install-payload test - SIRF QEMU ke andar chalta hai (guard neeche).
# Calamares jo payload deploy karta hai (filesystem.squashfs) usi ko disk par
# scripted tareeqe se install karke boot-test karta hai.
exec > /tmp/install-test-result.txt 2>&1
echo "INSTALLTEST START $(date)"
V=$(cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null)
echo "product: $V"
case "$V" in *QEMU*|*Virtual*|*KVM*) : ;; *) echo "REFUSED: not a VM ($V)"; exit 1;; esac
DISK=/dev/sda
[ -b "$DISK" ] || DISK=/dev/vda
echo "disk: $DISK"
echo "--- guest smoke (live booted system — chroot nahi, asal mahol) ---"
pwsh --version && echo "PWSH OK (QEMU live)" || echo "PWSH FAIL (QEMU live)"
wine --version && echo "WINE OK (QEMU live)" || echo "WINE FAIL (QEMU live)"
sudo -n true 2>/dev/null || SUDO="sudo"; SUDO=${SUDO:-}
set -x
echo -e "label: gpt\n,512M,U\n,,L" | $SUDO sfdisk "$DISK"
$SUDO mkfs.vfat "${DISK}1" && $SUDO mkfs.ext4 -F "${DISK}2"
mkdir -p /tmp/target; $SUDO mount "${DISK}2" /tmp/target
mkdir -p /tmp/sq; $SUDO mount -o loop /run/live/medium/live/filesystem.squashfs /tmp/sq 2>/dev/null || $SUDO mount -o loop /lib/live/mount/medium/live/filesystem.squashfs /tmp/sq
$SUDO cp -a /tmp/sq/. /tmp/target/
$SUDO mkdir -p /tmp/target/boot/efi; $SUDO mount "${DISK}1" /tmp/target/boot/efi
for d in dev proc sys run; do $SUDO mount --bind /$d /tmp/target/$d; done
$SUDO chroot /tmp/target grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=JKOS --removable || \
$SUDO chroot /tmp/target grub-install "${DISK}"
$SUDO chroot /tmp/target update-grub
echo "jk-os" | $SUDO tee /tmp/target/etc/hostname
ls /tmp/target/boot/vmlinuz-* && echo "KERNEL OK"
ls /tmp/target/usr/bin/xfce4-session && echo "DESKTOP OK"
echo "INSTALLTEST DONE"
sync
