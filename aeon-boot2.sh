#!/bin/bash
S="-i $HOME/.ssh/aeon_ed25519 -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10"
ssh $S joshua@192.168.0.160 'echo aeon | sudo -S bash -c "
rm -f /tmp/boot.log; systemctl reset-failed aeon-boot 2>/dev/null
systemd-run --unit=aeon-boot --collect --setenv=PATH=/run/current-system/sw/bin:/run/wrappers/bin /run/current-system/sw/bin/nixos-rebuild boot --flake /etc/nixos/aeon#aeon-rig
echo gestartet
" 2>/dev/null' 2>&1 | grep -v Warning
echo "--- 25s ---"; sleep 25
ssh $S joshua@192.168.0.160 'echo aeon | sudo -S bash -c "systemctl is-active aeon-boot; journalctl -u aeon-boot --no-pager -n 4 2>/dev/null | tail -4" 2>/dev/null' 2>&1 | grep -v Warning
