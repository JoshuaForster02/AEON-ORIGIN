#!/bin/bash
S="-i $HOME/.ssh/aeon_ed25519 -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=8"
ssh $S joshua@192.168.0.160 'echo aeon | sudo -S bash -c "
export PATH=/run/current-system/sw/bin:\$PATH
echo UPTIME:; uptime
echo VENDOR-RESET:; lsmod | grep vendor_reset || echo NICHT_GELADEN
echo RESET-METHOD:; cat /sys/bus/pci/devices/0000:09:00.0/reset_method 2>&1
echo GRUPPE:; ls /sys/bus/pci/devices/0000:09:00.0/iommu_group/devices/
echo VM:; virsh -c qemu:///system domstate windows 2>&1
echo LIBVIRT-GRP:; groups joshua | tr \" \" \"\n\" | grep -E \"libvirtd|kvm\" | tr \"\n\" \" \"; echo
" 2>/dev/null' 2>&1 | grep -v Warning
