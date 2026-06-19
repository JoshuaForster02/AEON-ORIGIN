#!/bin/bash
SSHOPTS="-i $HOME/.ssh/aeon_ed25519 -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
PC=joshua@192.168.0.160
ssh $SSHOPTS $PC 'cat > /tmp/vmrec.sh' <<'EOF'
#!/bin/bash
export PATH=/run/current-system/sw/bin:/run/wrappers/bin:$PATH
echo "=== vfio-Modul importiert? ==="; grep -r "aeon-vfio" /etc/aeon/hosts/aeon-rig/configuration.nix 2>/dev/null || grep -rl "aeon-vfio" /etc/nixos 2>/dev/null; echo "hook aktiv:"; ls -l /var/lib/libvirt/hooks/qemu 2>/dev/null || ls /etc/libvirt/hooks/ 2>/dev/null
echo "=== CPU / RAM ==="; nproc; free -h | head -2
echo "=== USB-Geraete (Tastatur/Maus suchen) ==="
for d in /sys/bus/usb/devices/*; do
  [ -f "$d/idVendor" ] || continue
  v=$(cat $d/idVendor); p=$(cat $d/idProduct); n=$(cat $d/product 2>/dev/null)
  cls=$(cat $d/bInterfaceClass 2>/dev/null)
  echo "  $v:$p  $n"
done | sort -u
echo "=== input-Geraete (HID) ==="
grep -iE "Name=|Handlers=" /proc/bus/input/devices | grep -iE "keyboard|mouse|Name=" | head -20
echo "=== OVMF Firmware ==="; ls -la /run/libvirt/nix-ovmf/ 2>/dev/null; cat /etc/libvirt/qemu.conf 2>/dev/null | grep -i nvram | head -2
echo "=== libvirt Netze ==="; virsh net-list --all 2>&1
echo "=== nvme1n1 / sda nochmal ==="; lsblk -dno NAME,SIZE,MODEL /dev/nvme1n1 /dev/sda 2>/dev/null
EOF
ssh $SSHOPTS $PC 'echo aeon | sudo -S bash /tmp/vmrec.sh 2>&1'
