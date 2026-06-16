#!/bin/bash
SSHOPTS="-i $HOME/.ssh/aeon_ed25519 -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
PC=joshua@192.168.0.160
ssh $SSHOPTS $PC 'echo aeon | sudo -S bash -c "
export PATH=/run/current-system/sw/bin:/run/wrappers/bin:\$PATH
echo ---SWITCH2---; tail -4 /tmp/aeon-switch2.log 2>/dev/null
echo ---HM---; systemctl is-active home-manager-joshua.service
echo ---VM---; virsh list --all
echo ---HOOK---; ls /var/lib/libvirt/hooks/qemu.d/
" 2>&1'
