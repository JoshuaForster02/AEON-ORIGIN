#!/bin/bash
SSHOPTS="-i $HOME/.ssh/aeon_ed25519 -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
PC=joshua@192.168.0.160
ssh $SSHOPTS $PC 'cat > /tmp/aeon-switch-run.sh' <<'EOF'
#!/bin/bash
export PATH=/run/current-system/sw/bin:/run/wrappers/bin:/nix/var/nix/profiles/default/bin:$PATH
exec > /tmp/aeon-switch.log 2>&1
echo "=== START $(date) ==="
umount /dev/nvme0n1p3 2>/dev/null || true
umount /data 2>/dev/null || true
nixos-rebuild switch --flake /home/joshua/aeon#aeon-rig
echo "=== SWITCH-EXIT=$? ==="
systemctl is-active ollama
EOF
ssh $SSHOPTS $PC 'echo aeon | sudo -S systemd-run --unit=aeon-switch2 --collect bash /tmp/aeon-switch-run.sh 2>&1; echo STARTED'
echo ">> switch laeuft; Log: /tmp/aeon-switch.log"
