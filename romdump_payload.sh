#!/bin/bash
export PATH=/run/current-system/sw/bin:/run/wrappers/bin:$PATH
mkdir -p /etc/aeon/vbios
systemctl stop display-manager
sleep 1
for c in /sys/class/vtconsole/vtcon*/bind; do echo 0 > "$c" 2>/dev/null; done
echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind 2>/dev/null
modprobe -r amdgpu 2>/tmp/rom.log
sleep 1
cd /sys/bus/pci/devices/0000:09:00.0 || exit 1
echo 1 > rom 2>>/tmp/rom.log
cat rom > /etc/aeon/vbios/rx6800.rom 2>>/tmp/rom.log
echo 0 > rom 2>/dev/null
stat -c "SIZE=%s" /etc/aeon/vbios/rx6800.rom >> /tmp/rom.log 2>&1
xxd /etc/aeon/vbios/rx6800.rom 2>/dev/null | head -1 >> /tmp/rom.log
modprobe amdgpu
sleep 2
systemctl restart display-manager
echo DONE >> /tmp/rom.log
