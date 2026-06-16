#!/bin/bash
SSHOPTS="-i $HOME/.ssh/aeon_ed25519 -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
PC=joshua@192.168.0.160
ssh $SSHOPTS $PC 'cat > /tmp/vfck.sh' <<'EOF'
#!/bin/bash
echo "=== /proc/cmdline (IOMMU an?) ==="; cat /proc/cmdline
echo "=== AMD-Vi/IOMMU dmesg ==="; dmesg 2>/dev/null | grep -iE "AMD-Vi|IOMMU enabled|DMAR" | head -3
shopt -s nullglob
for g in /sys/kernel/iommu_groups/*; do
  for d in $g/devices/*; do
    echo "$(basename $g) $(lspci -nns $(basename $d) 2>/dev/null)"
  done
done > /tmp/iommu.txt
GG=$(grep -iE "1002:73bf|Navi.*VGA|VGA.*Navi" /tmp/iommu.txt | awk '{print $1}' | head -1)
echo "=== RX 6800 ist in IOMMU-Gruppe $GG — komplette Gruppe: ==="
grep "^$GG " /tmp/iommu.txt
echo "=== Audio-Funktion der GPU ==="
grep -iE "1002:ab28" /tmp/iommu.txt
echo "=== nvme1n1 (Windows) Layout ==="; lsblk /dev/nvme1n1 -o NAME,SIZE,FSTYPE,MOUNTPOINT,LABEL
echo "=== vfio Module ==="; lsmod | grep -i vfio || echo "vfio nicht geladen"
echo "=== virsh ok? ==="; virsh list --all 2>&1 | head -5
EOF
ssh $SSHOPTS $PC 'echo aeon | sudo -S bash /tmp/vfck.sh 2>&1'
