#!/bin/bash
sleep 8
S="-i $HOME/.ssh/aeon_ed25519 -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10"
ssh $S joshua@192.168.0.160 'echo aeon | sudo -S sh -c "cat /tmp/rom.log 2>/dev/null; echo ---; systemctl is-active display-manager" 2>/dev/null' 2>&1 | grep -v Warning
