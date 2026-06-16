#!/bin/bash
S="-i $HOME/.ssh/aeon_ed25519 -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10"
ssh $S joshua@192.168.0.160 'echo aeon | sudo -S bash -lc "
export PATH=/run/current-system/sw/bin:/run/wrappers/bin:\$PATH
systemctl restart display-manager
sleep 4
systemctl is-active display-manager
" 2>/dev/null' 2>&1 | grep -v Warning
