#!/bin/bash
SSHOPTS="-i $HOME/.ssh/aeon_ed25519 -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
PC=joshua@192.168.0.160
ssh $SSHOPTS $PC 'echo aeon | sudo -S bash -c "
echo === HM-Log: Zeilen mit Dateinamen ===
grep -iE \"Existing file|would be|already exists|clobber|->|/home/joshua/\" /tmp/aeon-switch.log | head -20
" 2>&1'
echo "------ .bak-Dateien in joshuas Home ------"
ssh $SSHOPTS $PC 'find /home/joshua -maxdepth 4 -name "*.bak" 2>/dev/null | head -20'
