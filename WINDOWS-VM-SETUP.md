# AEON Windows VM — Setup-Guide

> Dieser Guide führt dich Schritt für Schritt durch das einmalige Setup.
> Danach läuft `aeon win` zuverlässig wie Proxmox.

---

## Schritt 1: Update einspielen (auf dem PC)

```bash
cd /etc/nixos/aeon
git pull
sudo nixos-rebuild switch --flake .#aeon-rig
# Reboot nötig wegen Kernel-Modulen (vendor-reset, vfio)
sudo reboot
```

---

## Schritt 2: Nach dem Reboot — Passthrough prüfen

```bash
aeon gpu
```

Du solltest sehen:
- **vendor_reset** und **vfio_pci** in der Modulliste
- RX 6800 in einer eigenen IOMMU-Gruppe (oder nur mit der GPU-Audio zusammen)

> [!IMPORTANT]
> Falls die IOMMU-Gruppe andere Geräte enthält (z.B. PCIe-Bridges), musst du **alle** Geräte aus der Gruppe in die VM durchreichen — das geht mit ACS-Patch-Kernel.

---

## Schritt 3: VM-Festplatte erstellen

```bash
sudo mkdir -p /var/lib/libvirt/images
# 120 GB für Windows + Spiele (qcow2 = wächst bei Bedarf, spart Platz)
sudo qemu-img create -f qcow2 /var/lib/libvirt/images/windows.qcow2 120G
```

---

## Schritt 4: ISOs herunterladen

| Datei | Quelle |
|-------|--------|
| `windows11.iso` | [microsoft.com/de-de/software-download/windows11](https://www.microsoft.com/de-de/software-download/windows11) |
| `virtio-win.iso` | [fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso) |

```bash
# ISOs ablegen
sudo mv ~/Downloads/Win11*.iso   /var/lib/libvirt/images/windows11.iso
sudo mv ~/Downloads/virtio-*.iso /var/lib/libvirt/images/virtio-win.iso
```

---

## Schritt 5: PCI-Adressen deiner GPU ermitteln

```bash
aeon gpu
# oder direkter:
lspci -nnvv | grep -A5 "1002:73bf"
```

Notiere die Adresse — z.B. `03:00.0` → Bus `0x03`, Slot `0x00`.

**Dann die XML-Datei anpassen:**

```bash
sudo nano /etc/aeon/assets/windows-vm.xml
# Zeilen mit <address domain="0x0000" bus="0x01" slot="0x00"...>
# auf deine echten Werte ändern:
# Bus 0x01 → 0x03 (wenn GPU bei 03:00.0 liegt)
```

---

## Schritt 6: VM-Definition importieren

```bash
sudo virsh define /etc/aeon/assets/windows-vm.xml
# Prüfen:
sudo virsh -c qemu:///system list --all
# Ausgabe: windows   shut off
```

---

## Schritt 7: Ersten Start + Windows installieren

```bash
aeon win
```

Der Monitor wird schwarz → KDE pausiert → Windows-VM übernimmt die GPU.

**Beim ersten Start:** BIOS/UEFI-Screen erscheint, dann Windows-Installer.

Wenn der Installer die Festplatte nicht sieht:
1. „Treiber laden" klicken
2. Auf der VirtIO-CD: `viostor\w11\amd64` → OK
3. Festplatte erscheint

Nach der Installation Windows booten lassen, dann:
- **VirtIO-Treiber installieren**: Gerätemanager → gelbe Ausrufezeichen → alle mit VirtIO-CD lösen
- **AMD-Treiber installieren**: [amd.com/de/support](https://www.amd.com/de/support)

---

## Schritt 8: VM sauber stoppen

```bash
aeon stop
# oder in Windows: Start → Herunterfahren
```

Monitor wird schwarz → KDE startet wieder in ~10 Sekunden.

---

## Alltagsnutzung

| Befehl | Aktion |
|--------|--------|
| `aeon win` | Windows-VM starten (GPU-Passthrough) |
| `aeon stop` | Windows-VM sauber herunterfahren |
| `aeon gpu` | GPU-Status & IOMMU-Gruppen prüfen |
| `journalctl -u libvirtd -f` | Live-Log des Passthrough-Hooks |

---

## Troubleshooting

### Black Screen nach VM-Stop (kein Desktop-Rückkehr)
```bash
# In TTY wechseln: Strg+Alt+F2
sudo systemctl restart display-manager
```

### "VM 'windows' nicht gefunden"
```bash
sudo virsh define /etc/aeon/assets/windows-vm.xml
```

### GPU nicht in eigener IOMMU-Gruppe
Boot-Parameter `pcie_acs_override=downstream,multifunction` in `boot.kernelParams` hinzufügen (weniger sicher, aber funktioniert).

### vendor-reset nicht geladen
```bash
lsmod | grep vendor
# Falls leer:
sudo modprobe vendor_reset
# Permanent: ist schon in boot.kernelModules — Reboot nötig
```
