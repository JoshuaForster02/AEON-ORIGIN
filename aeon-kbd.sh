#!/bin/bash
S="-i $HOME/.ssh/aeon_ed25519 -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10"
ssh $S joshua@192.168.0.160 'echo aeon | sudo -S bash -lc "
export PATH=/run/current-system/sw/bin:/run/wrappers/bin:\$PATH
echo === USB Geraete ===
for d in /sys/bus/usb/devices/*; do [ -f \$d/idVendor ] || continue; echo \$(cat \$d/idVendor):\$(cat \$d/idProduct) drv=\$(for i in \$d/*/driver; do basename \$(readlink \$i) 2>/dev/null; done | tr \"\n\" \" \") \$(cat \$d/product 2>/dev/null); done | sort -u
echo === input devices ===
grep -iE \"Name=|Handlers=\" /proc/bus/input/devices | grep -iE \"key|Name=\" | head
echo === vfio haelt USB? ===
ls -l /sys/bus/pci/drivers/vfio-pci/ 2>/dev/null | grep 00
echo === VM Status ===
virsh domstate windows 2>&1
" 2>/dev/null' 2>&1 | grep -v Warning
