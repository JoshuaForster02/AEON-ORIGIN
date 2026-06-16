#!/bin/bash
SSHOPTS="-i $HOME/.ssh/aeon_ed25519 -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
PC=joshua@192.168.0.160
ssh $SSHOPTS $PC 'cat > /tmp/gg.sh' <<'EOF'
#!/bin/bash
# Reine /sys-Auswertung, kein lspci noetig
echo "=== Display-Controller (Klasse 0300) ==="
for d in /sys/bus/pci/devices/*; do
  cls=$(cat $d/class 2>/dev/null)
  ven=$(cat $d/vendor 2>/dev/null)
  dev=$(cat $d/device 2>/dev/null)
  case "$cls" in
    0x030000|0x038000) echo "GPU  $(basename $d)  vendor=$ven device=$dev  grp=$(basename $(readlink $d/iommu_group))" ;;
  esac
done
echo "=== Vollstaendige IOMMU-Gruppe der ersten AMD-GPU ==="
GPU=""
for d in /sys/bus/pci/devices/*; do
  cls=$(cat $d/class 2>/dev/null); ven=$(cat $d/vendor 2>/dev/null)
  if [ "$cls" = "0x030000" ] && [ "$ven" = "0x1002" ]; then GPU=$(basename $d); break; fi
done
echo "AMD-GPU=$GPU"
if [ -n "$GPU" ]; then
  GRP=$(basename $(readlink /sys/bus/pci/devices/$GPU/iommu_group))
  echo "IOMMU-Gruppe=$GRP — Geraete:"
  for x in /sys/kernel/iommu_groups/$GRP/devices/*; do
    a=$(basename $x); cls=$(cat $x/class); ven=$(cat $x/vendor); dev=$(cat $x/device)
    echo "   $a  class=$cls vendor=$ven device=$dev"
  done
fi
echo "=== modaliases (fuer vfio bind) ==="
for d in /sys/bus/pci/devices/*; do
  cls=$(cat $d/class 2>/dev/null); ven=$(cat $d/vendor 2>/dev/null)
  if [ "$ven" = "0x1002" ] && { [ "$cls" = "0x030000" ] || [ "$cls" = "0x040300" ]; }; then
    echo "$(basename $d): vendor=$ven device=$(cat $d/device) class=$cls driver=$(basename $(readlink $d/driver 2>/dev/null) 2>/dev/null)"
  fi
done
EOF
ssh $SSHOPTS $PC 'bash /tmp/gg.sh 2>&1'
