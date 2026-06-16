#!/bin/bash
SSHOPTS="-i $HOME/.ssh/aeon_ed25519 -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
PC=joshua@192.168.0.160
ssh $SSHOPTS $PC 'echo aeon | sudo -S bash -c "
export PATH=/run/current-system/sw/bin:\$PATH
echo === HM-FEHLER \(welche Datei kollidiert\) ===
grep -iE \"exist|clobber|overwrit|backup|would be\" /tmp/aeon-switch.log | head -15
echo
echo === Hook irgendwo? ===
find /var/lib/libvirt/hooks /etc/libvirt/hooks -maxdepth 2 2>/dev/null
echo
echo === System-Generation aktuell? ===
ls -l /nix/var/nix/profiles/system | tail -1
" 2>&1'
