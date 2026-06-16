#!/bin/bash
S="-i $HOME/.ssh/aeon_ed25519 -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10"
P=/Users/joshuaforster/Library/Application\ Support/Claude/local-agent-mode-sessions/e343dd3f-a571-48d5-b810-fbe303f9c671/e6563f92-1cf4-4b49-9d05-84bb06906b57/local_b5c92f40-959f-48f1-9917-c09106bb27de/outputs/romdump_payload.sh
cat "$P" | ssh $S joshua@192.168.0.160 'cat > /home/joshua/romdump.sh'
ssh $S joshua@192.168.0.160 'echo aeon | sudo -S bash -c "chmod +x /home/joshua/romdump.sh; systemctl reset-failed aeon-romdump 2>/dev/null; rm -f /tmp/rom.log; systemd-run --unit=aeon-romdump --collect /home/joshua/romdump.sh" 2>/dev/null' 2>&1 | grep -v Warning
echo "gestartet, warte 12s..."; sleep 12
ssh $S joshua@192.168.0.160 'echo aeon | sudo -S sh -c "cat /tmp/rom.log 2>&1; echo ===; systemctl is-active display-manager" 2>/dev/null' 2>&1 | grep -v Warning
