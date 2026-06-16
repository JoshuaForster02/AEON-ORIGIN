#!/bin/bash
S="-i $HOME/.ssh/aeon_ed25519 -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10"
# Headless ROM-Dump als detached Job (damit SSH-Timeout egal ist), self-recovering
ssh $S joshua@192.168.0.160 'echo aeon | sudo -S bash -lc "
cat > /tmp/romdump.sh <<\"RD\"
#!/bin/bash
export PATH=/run/current-system/sw/bin:/run/wrappers/bin:\$PATH
mkdir -p /etc/aeon/vbios
systemctl stop display-manager
sleep 1
for c in /sys/class/vtconsole/vtcon*/bind; do echo 0 > \$c 2>/dev/null; done
echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind 2>/dev/null
modprobe -r amdgpu 2>/tmp/rom.log
sleep 1
cd /sys/bus/pci/devices/0000:09:00.0
echo 1 > rom 2>>/tmp/rom.log
cat rom > /etc/aeon/vbios/rx6800.rom 2>>/tmp/rom.log
echo 0 > rom 2>/dev/null
stat -c \"SIZE=%s\" /etc/aeon/vbios/rx6800.rom >> /tmp/rom.log
xxd /etc/aeon/vbios/rx6800.rom | head -1 >> /tmp/rom.log
modprobe amdgpu
sleep 2
systemctl restart display-manager
echo DONE >> /tmp/rom.log
RD
chmod +x /tmp/romdump.sh
systemd-run --unit=aeon-romdump --collect /tmp/romdump.sh
echo gestartet
" 2>/dev/null' 2>&1 | grep -v Warning
