#!/bin/bash
S="-i $HOME/.ssh/aeon_ed25519 -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10"
ssh $S joshua@192.168.0.160 'echo aeon | sudo -S bash -c "systemctl reset-failed aeon-romdump 2>/dev/null; rm -f /tmp/rom.log; systemd-run --unit=aeon-romdump --collect /run/current-system/sw/bin/bash /home/joshua/romdump.sh" 2>/dev/null' 2>&1 | grep -v Warning
echo "warte 14s..."; sleep 14
ssh $S joshua@192.168.0.160 'echo aeon | sudo -S sh -c "cat /tmp/rom.log 2>&1; echo ===dm===; systemctl is-active display-manager" 2>/dev/null' 2>&1 | grep -v Warning
