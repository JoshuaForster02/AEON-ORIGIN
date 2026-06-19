#!/bin/bash
S="-i $HOME/.ssh/aeon_ed25519 -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10"
B="/Users/joshuaforster/Library/Application Support/Claude/local-agent-mode-sessions/e343dd3f-a571-48d5-b810-fbe303f9c671/e6563f92-1cf4-4b49-9d05-84bb06906b57/local_b5c92f40-959f-48f1-9917-c09106bb27de/outputs/aeon"
cat "$B/hosts/aeon-rig/configuration.nix" | ssh $S joshua@192.168.0.160 'cat > /tmp/config.nix'
cat "$B/modules/aeon-cli.nix" | ssh $S joshua@192.168.0.160 'cat > /tmp/cli.nix'
ssh $S joshua@192.168.0.160 'echo aeon | sudo -S bash -c "
export PATH=/run/current-system/sw/bin:\$PATH
cp /tmp/config.nix /etc/nixos/aeon/hosts/aeon-rig/configuration.nix
cp /tmp/cli.nix /etc/nixos/aeon/modules/aeon-cli.nix
cd /etc/nixos/aeon && git add -A 2>/dev/null
nixos-rebuild dry-build --flake /etc/nixos/aeon#aeon-rig 2>&1 | tail -8
echo EXIT=\${PIPESTATUS[0]}
" 2>/dev/null' 2>&1 | grep -v Warning
