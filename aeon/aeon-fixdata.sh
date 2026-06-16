#!/bin/bash
SSHOPTS="-i $HOME/.ssh/aeon_ed25519 -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
PC=joshua@192.168.0.160
ssh $SSHOPTS $PC 'cat > /tmp/aeon-fixdata-run.sh' <<'EOF'
#!/bin/bash
for m in $(findmnt -rno TARGET -S /dev/nvme0n1p3 2>/dev/null); do umount "$m" 2>/dev/null; done
umount /run/media/joshua/* 2>/dev/null
mount /data 2>/dev/null || mount /dev/disk/by-label/aeon-data /data
mkdir -p /data/ollama/models && chown -R ollama:ollama /data/ollama
mkdir -p /data/vms /data/games
chown root:libvirtd /data/vms 2>/dev/null; chmod 0775 /data/vms
chown joshua:users /data/games 2>/dev/null; chmod 0775 /data/games
systemctl restart ollama
sleep 2
echo "===OLLAMA==="; systemctl is-active ollama
echo "===DF-DATA==="; df -h /data | tail -1
echo "===MOUNT==="; findmnt /data 2>/dev/null
EOF
ssh $SSHOPTS $PC 'echo aeon | sudo -S bash /tmp/aeon-fixdata-run.sh 2>&1'
