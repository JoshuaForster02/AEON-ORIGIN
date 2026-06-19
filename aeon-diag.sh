#!/bin/bash
SSHOPTS="-i $HOME/.ssh/aeon_ed25519 -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
PC=joshua@192.168.0.160
ssh $SSHOPTS $PC 'cat > /tmp/aeon-diag-run.sh' <<'EOF'
#!/bin/bash
echo "=== blkid p3 ==="; blkid /dev/nvme0n1p3
echo "=== by-label ==="; ls -l /dev/disk/by-label/ 2>/dev/null
echo "=== ollama-user ==="; getent passwd | grep -i ollama || echo "kein ollama-user (DynamicUser?)"
echo "=== current mounts p3 ==="; findmnt -rno TARGET -S /dev/nvme0n1p3 2>/dev/null || echo nicht-gemountet
echo "=== mount-test ==="
for m in $(findmnt -rno TARGET -S /dev/nvme0n1p3 2>/dev/null); do umount "$m" 2>/dev/null; done
mkdir -p /data && mount /dev/nvme0n1p3 /data && echo "mount per Geraet OK" || echo "mount fehlgeschlagen"
df -h /data | tail -1
EOF
ssh $SSHOPTS $PC 'echo aeon | sudo -S bash /tmp/aeon-diag-run.sh 2>&1'
