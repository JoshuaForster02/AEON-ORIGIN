#!/bin/bash
S="-i $HOME/.ssh/aeon_ed25519 -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10"
ssh $S joshua@192.168.0.160 'echo aeon | sudo -S bash -lc "
cd /sys/bus/pci/devices/0000:09:00.0
echo 1 > rom 2>/dev/null
cat rom > /etc/aeon/vbios/rx6800.rom 2>/dev/null && echo 0 > rom
ls -l /etc/aeon/vbios/rx6800.rom 2>&1
echo HEAD:; xxd /etc/aeon/vbios/rx6800.rom 2>/dev/null | head -2
" 2>/dev/null' 2>&1 | grep -v Warning
