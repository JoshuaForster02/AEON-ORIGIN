#!/bin/bash
S="-i $HOME/.ssh/aeon_ed25519 -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10"
ssh $S joshua@192.168.0.160 'echo aeon | sudo -S bash -lc "
export PATH=/run/current-system/sw/bin:/run/wrappers/bin:\$PATH
virsh destroy windows >/tmp/r.txt 2>&1
sleep 2
lsmod | grep -q amdgpu || modprobe amdgpu >>/tmp/r.txt 2>&1
systemctl restart display-manager >>/tmp/r.txt 2>&1
echo STATE: \$(virsh domstate windows 2>&1) >>/tmp/r.txt
echo ---LOG--- >>/tmp/r.txt
grep -iE \"error|fail|reset|vfio|BAR|cannot|denied\" /var/log/libvirt/qemu/windows.log 2>/dev/null | tail -12 >>/tmp/r.txt
cat /tmp/r.txt
" 2>/dev/null'
echo "EXIT=$?"
