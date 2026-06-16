#!/bin/bash
SSHOPTS="-i $HOME/.ssh/aeon_ed25519 -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
PC=joshua@192.168.0.160
ssh $SSHOPTS $PC 'cat > /tmp/hk.sh' <<'EOF'
#!/bin/bash
export PATH=/run/current-system/sw/bin:/run/wrappers/bin:$PATH
echo "=== Hook-Datei ==="
for p in /var/lib/libvirt/hooks/qemu /etc/libvirt/hooks/qemu; do
  [ -e "$p" ] && { echo "$p:"; ls -lL "$p"; echo "--- referenziert aeon-gpu? ---"; grep -l aeon "$p" 2>/dev/null && echo JA || cat "$p" 2>/dev/null | grep -i aeon | head -2; }
done
echo "=== gpu.conf ==="; cat /etc/aeon/gpu.conf 2>/dev/null
echo "=== aeon win Befehl vorhanden? ==="; command -v aeon && aeon 2>&1 | grep -i win | head -2
echo "=== amdgpu aktuell gebunden (Soll) ==="; ls -l /sys/bus/pci/devices/0000:09:00.0/driver 2>/dev/null
echo "=== aeon-vfio import in config ==="; grep -n "aeon-vfio" /etc/nixos/aeon/hosts/aeon-rig/configuration.nix 2>/dev/null
EOF
ssh $SSHOPTS $PC 'echo aeon | sudo -S bash /tmp/hk.sh 2>&1'
