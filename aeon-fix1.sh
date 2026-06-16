#!/bin/bash
S="-i $HOME/.ssh/aeon_ed25519 -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10"
ssh $S joshua@192.168.0.160 'echo aeon | sudo -S bash -lc "
export PATH=/run/current-system/sw/bin:/run/wrappers/bin:\$PATH
echo === LETZTER FEHLER ===
tail -20 /var/log/libvirt/qemu/windows.log 2>/dev/null
echo === vBIOS DUMP (GPU 0000:09:00.0) ===
cd /sys/bus/pci/devices/0000:09:00.0
echo 1 > rom 2>/dev/null
mkdir -p /etc/aeon/vbios
if cat rom > /etc/aeon/vbios/rx6800.rom 2>/dev/null; then
  echo 0 > rom 2>/dev/null
  ls -l /etc/aeon/vbios/rx6800.rom
else
  echo DUMP_FEHLGESCHLAGEN_aus_laufendem_amdgpu
fi
" 2>/dev/null' 2>&1 | grep -v Warning
