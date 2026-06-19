#!/bin/bash
S="-i $HOME/.ssh/aeon_ed25519 -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10"
ssh $S joshua@192.168.0.160 'echo aeon | sudo -S bash -lc "
export PATH=/run/current-system/sw/bin:/run/wrappers/bin:\$PATH
virsh -c qemu:///system destroy windows 2>&1
sleep 3
lsmod | grep -q amdgpu || modprobe amdgpu
systemctl restart display-manager
# ROM an die GPU-Video-Hostdev haengen
virsh -c qemu:///system dumpxml windows > /tmp/w.xml
python3 - <<PY
import re
x=open(\"/tmp/w.xml\").read()
if \"rx6800.rom\" not in x:
    x=re.sub(r\"(<address domain=.0x0000. bus=.0x09. slot=.0x00. function=.0x0./>\s*</source>)\",
             r\"\1\n      <rom file=.PLACEHOLDER./>\", x, count=1)
    x=x.replace(\".PLACEHOLDER.\", \"'\"'/etc/aeon/vbios/rx6800.rom'\"'\")
open(\"/tmp/w.xml\",\"w\").write(x)
PY
virsh -c qemu:///system define /tmp/w.xml 2>&1 | tail -1
echo ROM-Zeilen:; grep -c rx6800 /tmp/w.xml
" 2>/dev/null' 2>&1 | grep -v Warning
