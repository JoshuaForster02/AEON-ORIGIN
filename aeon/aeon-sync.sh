#!/bin/bash
S="-i $HOME/.ssh/aeon_ed25519 -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10"
B="/Users/joshuaforster/Library/Application Support/Claude/local-agent-mode-sessions/e343dd3f-a571-48d5-b810-fbe303f9c671/e6563f92-1cf4-4b49-9d05-84bb06906b57/local_b5c92f40-959f-48f1-9917-c09106bb27de/outputs/aeon"
# Repo packen (Hardware-Config + git + Build-Reste raus)
tar czf /tmp/aeon-sync.tgz -C "$B" \
  --exclude='hardware-configuration.nix' --exclude='.git' \
  --exclude='result' --exclude='result-*' --exclude='*.iso' --exclude='out' .
cat /tmp/aeon-sync.tgz | ssh $S joshua@192.168.0.160 'cat > /tmp/aeon-sync.tgz'
ssh $S joshua@192.168.0.160 'echo aeon | sudo -S bash -c "
export PATH=/run/current-system/sw/bin:\$PATH
tar xzf /tmp/aeon-sync.tgz -C /etc/nixos/aeon
echo ---vitals da?---; ls /etc/nixos/aeon/modules/aeon-vitals.nix 2>&1
echo ---DRYBUILD---
nixos-rebuild dry-build --flake /etc/nixos/aeon#aeon-rig 2>&1 | tail -8
echo EXIT=\${PIPESTATUS[0]}
" 2>/dev/null' 2>&1 | grep -v Warning
