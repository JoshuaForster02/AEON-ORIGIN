#!/bin/bash
SSHOPTS="-i $HOME/.ssh/aeon_ed25519 -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
PC=joshua@192.168.0.160
ssh $SSHOPTS $PC 'cat > /tmp/sw.sh' <<'EOF'
#!/bin/bash
export PATH=/run/current-system/sw/bin:/run/wrappers/bin:$PATH
systemctl reset-failed aeon-switch 2>/dev/null
rm -f /tmp/aeon-switch.log
systemd-run --unit=aeon-switch --collect --setenv=PATH=/run/current-system/sw/bin:/run/wrappers/bin \
  bash -c 'nixos-rebuild switch --flake /etc/nixos/aeon#aeon-rig > /tmp/aeon-switch.log 2>&1; echo "DONE rc=$?" >> /tmp/aeon-switch.log'
echo "switch gestartet (detached)"
EOF
ssh $SSHOPTS $PC 'echo aeon | sudo -S bash /tmp/sw.sh 2>&1'
echo "--- 25s warten ---"; sleep 25
ssh $SSHOPTS $PC 'echo aeon | sudo -S bash -c "tail -6 /tmp/aeon-switch.log 2>&1; echo; echo HOOK:; ls -lL /var/lib/libvirt/hooks/qemu 2>&1"'
