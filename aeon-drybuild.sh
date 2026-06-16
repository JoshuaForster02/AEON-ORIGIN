#!/bin/bash
SSHOPTS="-i $HOME/.ssh/aeon_ed25519 -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
PC=joshua@192.168.0.160
ssh $SSHOPTS $PC 'cat > /tmp/db.sh' <<'EOF'
#!/bin/bash
export PATH=/run/current-system/sw/bin:/run/wrappers/bin:$PATH
FLAKE=$(readlink -f /etc/nixos/aeon 2>/dev/null || echo /etc/nixos/aeon)
echo "Flake: $FLAKE"
echo "=== aeon-vfio.nix Hook-Zeile (soll NICHT auskommentiert sein) ==="
grep -n "libvirtd.hooks.qemu" "$FLAKE/modules/aeon-vfio.nix"
echo "=== git: untracked/changed (Flakes ignorieren untracked!) ==="
cd "$FLAKE" && git add -A 2>/dev/null && git status --short | head
echo "=== DRY-BUILD (validiert, baut/aktiviert NICHT) ==="
nixos-rebuild dry-build --flake "$FLAKE#aeon-rig" 2>&1 | tail -25
echo "EXIT=$?"
EOF
ssh $SSHOPTS $PC 'echo aeon | sudo -S bash /tmp/db.sh 2>&1'
