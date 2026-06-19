#!/bin/bash
SSHOPTS="-i $HOME/.ssh/aeon_ed25519 -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
PC=joshua@192.168.0.160
ssh $SSHOPTS $PC 'cat > /tmp/ubd.sh' <<'EOF'
#!/bin/bash
M=/mnt/ubuntu
mountpoint -q $M || mount -o ro /dev/nvme0n1p3 $M
echo "=== home/joshua Unterordner ==="; du -sh $M/home/joshua/* 2>/dev/null | sort -rh | head -12
echo "=== /usr (64G?) ==="; du -sh $M/usr/* 2>/dev/null | sort -rh | head -8
echo "=== /usr/local & /opt ==="; du -sh $M/usr/local/* $M/opt/* 2>/dev/null | sort -rh | head -8
echo "=== /var (Docker/apt/logs) ==="; du -sh $M/var/* 2>/dev/null | sort -rh | head -8
echo "=== Reclaim-Kandidaten ==="
du -sh $M/var/lib/docker 2>/dev/null
du -sh $M/var/cache/apt 2>/dev/null
du -sh $M/home/joshua/.cache 2>/dev/null
du -sh $M/home/joshua/.local/share/Trash 2>/dev/null
EOF
ssh $SSHOPTS $PC 'echo aeon | sudo -S bash /tmp/ubd.sh 2>&1'
