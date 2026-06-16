#!/bin/bash
S="-i $HOME/.ssh/aeon_ed25519 -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10"
ssh $S joshua@192.168.0.160 'echo aeon | sudo -S bash -c "
export PATH=/run/current-system/sw/bin:\$PATH
rm -f /tmp/boot.log; systemctl reset-failed aeon-boot 2>/dev/null
systemd-run --unit=aeon-boot --collect /run/current-system/sw/bin/bash -c \"nixos-rebuild boot --flake /etc/nixos/aeon#aeon-rig > /tmp/boot.log 2>&1; echo DONE rc=\\\$? >> /tmp/boot.log\"
echo gestartet
" 2>/dev/null' 2>&1 | grep -v Warning
echo "--- 25s ---"; sleep 25
ssh $S joshua@192.168.0.160 'echo aeon | sudo -S tail -3 /tmp/boot.log 2>/dev/null' 2>&1 | grep -v Warning
