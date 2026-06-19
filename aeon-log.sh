#!/bin/bash
S="-i $HOME/.ssh/aeon_ed25519 -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=8"
ssh $S joshua@192.168.0.160 'echo aeon | sudo -S bash -lc "
export PATH=/run/current-system/sw/bin:\$PATH
echo STATE: \$(virsh domstate windows 2>&1)
echo ---ERR---
grep -iE \"error|fail|reset|vfio|cannot|denied|rom|BAR\" /var/log/libvirt/qemu/windows.log 2>/dev/null | tail -15
" 2>/dev/null' 2>&1 | grep -v Warning
