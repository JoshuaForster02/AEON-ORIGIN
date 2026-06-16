#!/bin/bash
SSHOPTS="-i $HOME/.ssh/aeon_ed25519 -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
PC=joshua@192.168.0.160
ssh $SSHOPTS $PC 'cat > /tmp/hmc.sh' <<'EOF'
#!/bin/bash
export PATH=/run/current-system/sw/bin:/run/wrappers/bin:$PATH
# stale Backups entfernen (Originale bleiben unberuehrt)
rm -f /home/joshua/.gtkrc-2.0.bak /home/joshua/.config/gtk-3.0/gtk.css.bak /home/joshua/.local/share/user-places.xbel.bak
systemctl reset-failed aeon-switch2 2>/dev/null; rm -f /tmp/aeon-switch2.log
systemd-run --unit=aeon-switch2 --collect --setenv=PATH=/run/current-system/sw/bin:/run/wrappers/bin \
  bash -c 'nixos-rebuild switch --flake /etc/nixos/aeon#aeon-rig > /tmp/aeon-switch2.log 2>&1; echo "DONE rc=$?" >> /tmp/aeon-switch2.log'
echo "switch2 gestartet"
EOF
ssh $SSHOPTS $PC 'echo aeon | sudo -S bash /tmp/hmc.sh 2>&1'
echo "--- 40s warten ---"; sleep 40
ssh $SSHOPTS $PC 'echo aeon | sudo -S bash -c "tail -4 /tmp/aeon-switch2.log; echo; echo VM:; export PATH=/run/current-system/sw/bin:\$PATH; virsh list --all; echo HOOK:; ls /var/lib/libvirt/hooks/qemu.d/" 2>&1'
