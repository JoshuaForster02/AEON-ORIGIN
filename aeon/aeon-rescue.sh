#!/bin/bash
S="-i $HOME/.ssh/aeon_ed25519 -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
ssh $S joshua@192.168.0.160 'echo aeon | sudo -S bash -lc "
export PATH=/run/current-system/sw/bin:/run/wrappers/bin:\$PATH
virsh destroy windows 2>&1
sleep 3
modprobe amdgpu 2>&1
systemctl start display-manager 2>&1
echo ---LOG---
tail -18 /var/log/libvirt/qemu/windows.log 2>&1
" 2>&1'
