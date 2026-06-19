#!/bin/bash
SSHOPTS="-i $HOME/.ssh/aeon_ed25519 -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
PC=joshua@192.168.0.160
ssh $SSHOPTS $PC 'cat > /tmp/sda.sh' <<'EOF'
#!/bin/bash
echo "=== sda Info ==="; blkid /dev/sda1 2>/dev/null
mkdir -p /mnt/sda
mountpoint -q /mnt/sda || mount -o ro /dev/sda1 /mnt/sda 2>&1
echo "=== df sda ==="; df -h /mnt/sda 2>/dev/null | tail -1
echo "=== Inhalt (top-level) ==="; ls -la /mnt/sda 2>/dev/null | head -25
echo "=== Groessen ==="; du -sh /mnt/sda/* 2>/dev/null | sort -rh | head -12
umount /mnt/sda 2>/dev/null
EOF
ssh $SSHOPTS $PC 'echo aeon | sudo -S bash /tmp/sda.sh 2>&1'
