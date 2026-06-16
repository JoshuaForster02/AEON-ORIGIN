#!/bin/bash
S="-i $HOME/.ssh/aeon_ed25519 -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10"
ssh $S joshua@192.168.0.160 'echo aeon | sudo -S bash -lc "
export PATH=/run/current-system/sw/bin:/run/wrappers/bin:\$PATH
virsh dumpxml windows > /tmp/w.xml 2>/dev/null
python3 - <<PY
import re
x=open(\"/tmp/w.xml\").read()
x=re.sub(r\"\s*<hostdev[^>]*type=.usb.*?</hostdev>\", \"\", x, flags=re.S)
open(\"/tmp/w2.xml\",\"w\").write(x)
PY
virsh define /tmp/w2.xml 2>&1 | tail -1
echo USB-Bloecke uebrig: \$(grep -c \"type=.usb.\" /tmp/w2.xml)
" 2>/dev/null' 2>&1 | grep -v Warning
