#!/usr/bin/env bash
export PATH=/run/current-system/sw/bin:/run/wrappers/bin:$PATH
LOG=/tmp/vmtest.log; : > $LOG

# ROM in die GPU-Video-Hostdev (function 0x0) einhaengen
virsh dumpxml windows > /tmp/w.xml 2>>$LOG
python3 - <<'PY'
import re
x=open("/tmp/w.xml").read()
if "rx6800.rom" not in x:
    # in den hostdev-Block mit function='0x0' eine <rom .../> nach </source> einfuegen
    def repl(m):
        b=m.group(0)
        if "function='0x0'" in b and "type='pci'" in b:
            return b.replace("</source>", "</source>\n      <rom file='/etc/aeon/vbios/rx6800.rom'/>",1)
        return b
    x=re.sub(r"<hostdev mode='subsystem' type='pci'.*?</hostdev>", repl, x, flags=re.S)
open("/tmp/w.xml","w").write(x)
PY
virsh define /tmp/w.xml >>$LOG 2>&1

# Watchdog: in 90s alles zurueckholen, egal was passiert
systemd-run --on-active=90 --unit=aeon-vmwatch --collect /run/current-system/sw/bin/bash -c \
 'export PATH=/run/current-system/sw/bin:$PATH; virsh destroy windows 2>/dev/null; sleep 2; modprobe amdgpu; systemctl restart display-manager' >>$LOG 2>&1

# GPU sauber freigeben (Desktop + Sessions toeten, amdgpu entladen)
systemctl stop display-manager >>$LOG 2>&1
loginctl terminate-user joshua >>$LOG 2>&1 || true
sleep 2
for c in /sys/class/vtconsole/vtcon*/bind; do echo 0 > "$c" 2>/dev/null; done
echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind 2>/dev/null
modprobe -r amdgpu 2>>$LOG
sleep 1

echo "START:" >> $LOG
virsh start windows >>$LOG 2>&1
echo "rc=$?" >> $LOG
