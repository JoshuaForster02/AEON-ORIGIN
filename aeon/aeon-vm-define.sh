#!/bin/bash
SSHOPTS="-i $HOME/.ssh/aeon_ed25519 -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
PC=joshua@192.168.0.160

# 1) XML auf den PC schreiben (by-id = stabil, niemals nvmeXn1)
ssh $SSHOPTS $PC 'cat > /tmp/windows.xml' <<'XML'
<domain type='kvm'>
  <name>windows</name>
  <title>AEON · Windows (Single-GPU-Passthrough)</title>
  <memory unit='MiB'>8192</memory>
  <currentMemory unit='MiB'>8192</currentMemory>
  <vcpu placement='static'>8</vcpu>
  <os>
    <type arch='x86_64' machine='q35'>hvm</type>
    <loader readonly='yes' type='pflash'>/run/libvirt/nix-ovmf/OVMF_CODE.fd</loader>
    <nvram template='/run/libvirt/nix-ovmf/OVMF_VARS.fd'>/var/lib/libvirt/qemu/nvram/windows_VARS.fd</nvram>
    <boot dev='hd'/>
  </os>
  <features>
    <acpi/>
    <apic/>
    <hyperv mode='custom'>
      <relaxed state='on'/>
      <vapic state='on'/>
      <spinlocks state='on' retries='8191'/>
      <vendor_id state='on' value='AEON1234'/>
    </hyperv>
    <kvm><hidden state='on'/></kvm>
    <vmport state='off'/>
  </features>
  <cpu mode='host-passthrough' check='none' migratable='on'>
    <topology sockets='1' dies='1' cores='4' threads='2'/>
    <feature policy='disable' name='hypervisor'/>
  </cpu>
  <clock offset='localtime'>
    <timer name='rtc' tickpolicy='catchup'/>
    <timer name='pit' tickpolicy='delay'/>
    <timer name='hpet' present='no'/>
    <timer name='hypervclock' present='yes'/>
  </clock>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>destroy</on_crash>
  <devices>
    <emulator>__EMU__</emulator>
    <disk type='block' device='disk'>
      <driver name='qemu' type='raw' cache='none' io='native' discard='unmap'/>
      <source dev='/dev/disk/by-id/nvme-WD_BLACK_SN770_1TB_2334HU404337'/>
      <target dev='sda' bus='sata'/>
      <address type='drive' controller='0' bus='0' target='0' unit='0'/>
    </disk>
    <disk type='block' device='disk'>
      <driver name='qemu' type='raw' cache='none' io='native' discard='unmap'/>
      <source dev='/dev/disk/by-id/ata-CT240BX200SSD1_1618F01B4DE6'/>
      <target dev='sdb' bus='sata'/>
      <address type='drive' controller='0' bus='0' target='0' unit='1'/>
    </disk>
    <controller type='sata' index='0'/>
    <controller type='usb' index='0' model='qemu-xhci' ports='8'/>
    <hostdev mode='subsystem' type='pci' managed='yes'>
      <source><address domain='0x0000' bus='0x09' slot='0x00' function='0x0'/></source>
    </hostdev>
    <hostdev mode='subsystem' type='pci' managed='yes'>
      <source><address domain='0x0000' bus='0x09' slot='0x00' function='0x1'/></source>
    </hostdev>
    <hostdev mode='subsystem' type='usb' managed='yes'>
      <source startupPolicy='optional'><vendor id='0x3537'/><product id='0x2106'/></source>
    </hostdev>
    <hostdev mode='subsystem' type='usb' managed='yes'>
      <source startupPolicy='optional'><vendor id='0x048d'/><product id='0x5702'/></source>
    </hostdev>
    <interface type='network'>
      <source network='default'/>
      <model type='e1000e'/>
    </interface>
    <input type='mouse' bus='ps2'/>
    <input type='keyboard' bus='ps2'/>
    <memballoon model='none'/>
  </devices>
</domain>
XML

# 2) Setup + define (NICHT starten)
ssh $SSHOPTS $PC 'cat > /tmp/vmdef.sh' <<'EOF'
#!/bin/bash
export PATH=/run/current-system/sw/bin:/run/wrappers/bin:$PATH
EMU=$(ls /run/libvirt/nix-emulators/qemu-system-x86_64 2>/dev/null || command -v qemu-system-x86_64 || echo /run/current-system/sw/bin/qemu-system-x86_64)
echo "Emulator: $EMU"
sed -i "s#__EMU__#$EMU#" /tmp/windows.xml
mkdir -p /var/lib/libvirt/qemu/nvram
echo "=== default-Netz starten ==="
virsh net-start default 2>/dev/null; virsh net-autostart default 2>/dev/null; virsh net-list
echo "=== XML validieren ==="
virt-xml-validate /tmp/windows.xml 2>&1 || echo "(validate-Warnung – pruefe define)"
echo "=== VM definieren (NICHT starten) ==="
virsh define /tmp/windows.xml 2>&1
echo "=== Status ==="
virsh list --all
virsh dumpxml windows 2>/dev/null | grep -E "source dev|address domain|hostdev|loader" | head
EOF
ssh $SSHOPTS $PC 'echo aeon | sudo -S bash /tmp/vmdef.sh 2>&1'
