#!/bin/bash
S="-i $HOME/.ssh/aeon_ed25519 -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=8"
ssh $S joshua@192.168.0.160 'echo aeon | sudo -S sh -c "
export PATH=/run/current-system/sw/bin:\$PATH
echo ===STATE===; virsh domstate windows 2>&1
echo ===was macht aeon win===; type -a aeon 2>/dev/null; awk \"/win\\)/,/;;/\" \$(command -v aeon) 2>/dev/null | head -20
echo ===letzter qemu-fehler===; tail -3 /var/log/libvirt/qemu/windows.log 2>/dev/null
" 2>/dev/null' 2>&1 | grep -v Warning
