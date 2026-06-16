#!/bin/bash
# AEON Push+Validate: Repo Mac -> PC, dann dort dry-build (Eval-Check, ohne sudo).
SRC="/Users/joshuaforster/Library/Application Support/Claude/local-agent-mode-sessions/e343dd3f-a571-48d5-b810-fbe303f9c671/e6563f92-1cf4-4b49-9d05-84bb06906b57/local_b5c92f40-959f-48f1-9917-c09106bb27de/outputs/aeon"
SSHOPTS="-i $HOME/.ssh/aeon_ed25519 -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
PC=joshua@192.168.0.160
echo ">> Sync Mac -> PC ..."
( cd "$SRC" && tar czf - --exclude=.git --exclude=out --exclude=pi/data --exclude='*.iso' --exclude='*.zip' . ) \
  | ssh $SSHOPTS $PC 'rm -rf ~/aeon && mkdir -p ~/aeon && tar xzf - -C ~/aeon' 2>&1
echo ">> Hardware-Profil uebernehmen ..."
ssh $SSHOPTS $PC 'cp -f /etc/nixos/aeon/hosts/aeon-rig/hardware-configuration.nix ~/aeon/hosts/aeon-rig/hardware-configuration.nix 2>/dev/null' 2>&1
echo ">> dry-build (Validierung) ..."
ssh $SSHOPTS $PC 'cd ~/aeon; nixos-rebuild dry-build --flake .#aeon-rig > /tmp/aeon-dry.log 2>&1; echo rc=$status; tail -25 /tmp/aeon-dry.log' 2>&1
echo ">> FERTIG"
exit 0
