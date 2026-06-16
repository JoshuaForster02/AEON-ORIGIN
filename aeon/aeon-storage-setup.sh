#!/bin/bash
SSHOPTS="-i $HOME/.ssh/aeon_ed25519 -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
PC=joshua@192.168.0.160
ssh $SSHOPTS $PC "echo aeon | sudo -S bash -c 'mkdir -p /mnt/p3; mount -o ro /dev/nvme0n1p3 /mnt/p3 2>&1; echo ===INHALT===; ls -A /mnt/p3 | head; echo ===ANZAHL===; ls -A /mnt/p3 | wc -l; umount /mnt/p3 2>/dev/null; echo ===LABEL===; e2label /dev/nvme0n1p3 aeon-data && e2label /dev/nvme0n1p3'"
