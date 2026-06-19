#!/bin/bash
S="-i $HOME/.ssh/aeon_ed25519 -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10"
ssh $S joshua@192.168.0.160 'echo aeon | sudo -S bash -c "
cd /etc/nixos/aeon
export PATH=/run/current-system/sw/bin:\$PATH
ls modules/aeon-vitals.nix 2>&1
echo ---gitstatus---; git status --short | head
echo ---istgit?---; git rev-parse --is-inside-work-tree 2>&1
" 2>/dev/null' 2>&1 | grep -v Warning
