#!/bin/bash
SSHOPTS="-i $HOME/.ssh/aeon_ed25519 -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
PC=joshua@192.168.0.160
ssh $SSHOPTS $PC "echo aeon | sudo -S bash -c 'rm -f /var/lib/ollama/models/blobs/*partial* 2>/dev/null; echo ===GC===; nix-collect-garbage -d 2>&1 | tail -3; echo ===DF===; df -h /'"
