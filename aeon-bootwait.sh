#!/bin/bash
S="-i $HOME/.ssh/aeon_ed25519 -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10"
for i in 1 2 3 4 5 6; do
  st=$(ssh $S joshua@192.168.0.160 'echo aeon | sudo -S systemctl is-active aeon-boot 2>/dev/null' 2>/dev/null | grep -v Warning | tr -d '[:space:]')
  [ "$st" != "active" ] && break
  sleep 15
done
ssh $S joshua@192.168.0.160 'echo aeon | sudo -S bash -c "systemctl is-active aeon-boot; journalctl -u aeon-boot --no-pager -n 3 | tail -3; echo ---boot-gen---; ls -l /nix/var/nix/profiles/system | tail -1" 2>/dev/null' 2>&1 | grep -v Warning
