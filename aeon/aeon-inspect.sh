#!/bin/bash
SSHOPTS="-i $HOME/.ssh/aeon_ed25519 -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
PC=joshua@192.168.0.160
ssh $SSHOPTS $PC 'cat > /tmp/aeon-inspect-run.sh' <<'EOF'
#!/bin/bash
mountpoint -q /data || mount /dev/nvme0n1p3 /data 2>/dev/null
echo "=== /data top-level ==="
ls -la /data 2>/dev/null
echo "=== Groessen (top-level) ==="
du -sh /data/* /data/.[!.]* 2>/dev/null | sort -rh | head -20
EOF
ssh $SSHOPTS $PC 'echo aeon | sudo -S bash /tmp/aeon-inspect-run.sh 2>&1'
