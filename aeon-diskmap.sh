#!/bin/bash
SSHOPTS="-i $HOME/.ssh/aeon_ed25519 -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
PC=joshua@192.168.0.160
ssh $SSHOPTS $PC 'cat > /tmp/dm.sh' <<'EOF'
#!/bin/bash
export PATH=/run/current-system/sw/bin:/run/wrappers/bin:$PATH
echo "=== ALLE Disks: Name Size Model Serial ==="
lsblk -dno NAME,SIZE,MODEL,SERIAL
echo
echo "=== Partitionen mit FSTYPE/LABEL/SIZE ==="
lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT
echo
echo "=== /dev/disk/by-id (stabile Namen) ==="
ls -l /dev/disk/by-id/ | grep -vE "wwn-|part" | awk '{print $9" -> "$11}'
echo
echo "=== Welche Disk hat die 929G-NTFS (Windows C:)? ==="
for d in /dev/nvme0n1 /dev/nvme1n1 /dev/sda /dev/sdb; do
  [ -b "$d" ] || continue
  sz=$(lsblk -dno SIZE $d); mdl=$(lsblk -dno MODEL $d); ser=$(lsblk -dno SERIAL $d)
  ntfs=$(lsblk -no SIZE,FSTYPE $d | grep -i ntfs | head -1)
  byid=$(ls -l /dev/disk/by-id/ | grep -w "$(basename $d)\$" | grep -iE "nvme-|ata-" | grep -v eui | awk '{print $9}' | head -1)
  echo "$d  size=$sz  model=$mdl  serial=$ser  by-id=$byid  ntfs-part=[$ntfs]"
done
echo
echo "=== Bootloader/EFI vfat-Partitionen (welche ist Windows-EFI?) ==="
for p in $(lsblk -rno NAME,FSTYPE | awk '$2=="vfat"{print $1}'); do
  echo "--- /dev/$p ---"; mkdir -p /tmp/efi; mount -o ro /dev/$p /tmp/efi 2>/dev/null && { ls /tmp/efi/EFI 2>/dev/null; umount /tmp/efi; }
done
EOF
ssh $SSHOPTS $PC 'echo aeon | sudo -S bash /tmp/dm.sh 2>&1'
