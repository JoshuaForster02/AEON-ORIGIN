#!/bin/bash
S="-i $HOME/.ssh/aeon_ed25519 -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10"
ssh $S joshua@192.168.0.160 'echo aeon | sudo -S sh -c "
systemctl is-active aeon-romdump 2>&1
echo ---journal---
journalctl -u aeon-romdump --no-pager -n 15 2>&1
echo ---rom---
ls -l /etc/aeon/vbios/ 2>&1
xxd /etc/aeon/vbios/rx6800.rom 2>/dev/null | head -1
echo ---dm---
systemctl is-active display-manager
" 2>/dev/null' 2>&1 | grep -v Warning
