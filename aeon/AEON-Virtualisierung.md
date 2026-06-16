# AEON als GrundOS / Hypervisor

Die Idee: AEON ist nicht nur ein Desktop, sondern die **leistungsfähige Basis**, auf
der alles andere als VM läuft. Distro wechseln = VM tauschen. Windows ohne Dual-Boot.
Basis bleibt OTA-verwaltet über dein Repo.

```
        ┌──────────────────────────────────────────────┐
        │      AEON GrundOS  (NixOS · Zen-Kernel · KVM) │  ← deine Basis, OTA
        ├───────────────┬───────────────┬──────────────┤
        │  AEON-Desktop │   Windows-VM  │  beliebige   │
        │   (nativ/VM)  │  (ohne Reboot)│  Distro-VM   │  ← austauschbar
        └───────────────┴───────────────┴──────────────┘
                         RX 6800 · Ryzen
```

## Was schon eingebaut ist (`modules/aeon-virtualisation.nix`)

- **Zen-Performance-Kernel** — responsiver Desktop/Gaming-Kernel mit KVM.
- **KVM/QEMU + libvirt + virt-manager** — VMs per GUI erstellen & verwalten.
- **OVMF (UEFI) + swTPM (TPM 2.0)** — Voraussetzungen für eine **Windows-11-VM**.
- **IOMMU an** (`amd_iommu=on`) — GPU-Passthrough ist damit vorbereitet.

## Windows als VM (ohne Dual-Boot)

```bash
virt-manager        # GUI: neue VM → Windows-ISO → OVMF + TPM auswählen
```
Gut für Office, Programme, schnelles „mal eben Windows". **Ohne** GPU-Passthrough
keine Gaming-Leistung — dafür der Passthrough-Weg (unten) oder weiterhin Dual-Boot.

> Die *bereits installierte* Bare-Metal-Windows-Partition direkt als VM zu booten ist
> möglich, aber heikel (Windows mag Hardware-Wechsel nicht: BSOD/Aktivierung). Sauberer:
> eine eigene Windows-VM. Für volles Gaming bleibt Dual-Boot die einfachste Option.

## Beliebige Distro als VM

Einfach eine ISO in virt-manager starten — Ubuntu, Arch, was du testen willst.
So bleibt AEON die Basis und du bist maximal flexibel.

## Die GPU-Frage (RX 6800, einzeln)

| Weg | Gaming in Windows | Host gleichzeitig nutzbar | Aufwand |
|---|---|---|---|
| VM ohne Passthrough | ❌ | ✅ | minimal (fertig) |
| Single-GPU-Passthrough | ✅ (fast nativ) | ❌ (Host pausiert) | mittel |
| Zweite GPU / iGPU | ✅ | ✅ | Hardware nötig |

**Offen:** Hat deine Ryzen-CPU eine iGPU (ein „G"-Modell, z.B. 5600G/8700G)? Dann ist
„beides gleichzeitig" easy. Falls nicht, ist Single-GPU-Passthrough der Weg zu
„Windows-Gaming ohne echten Reboot".

## Single-GPU-Passthrough — schon vorkonfiguriert (RX 6800)

Deine Hardware: **RX 6800 (1002:73bf + 1002:ab28)**, Ryzen 5 5600 (**keine iGPU**).
Daher: die GPU wandert beim Start der Windows-VM in die VM (Host-Desktop pausiert)
und kommt beim Herunterfahren zurück — ohne echten Reboot. Das ist mit nur einer
GPU der einzige Weg zu „Windows-Gaming ohne Dual-Boot".

Die IDs sind in `modules/aeon-vfio.nix` schon eingetragen — der Hook löst die
PCI-Adresse selbst auf. Du musst nur **eine VM exakt `windows` nennen**:

```bash
aeon vm           # virt-manager: neue VM → Name "windows" → OVMF + TPM → Windows-ISO
aeon win          # startet die VM und schaltet die GPU um
```

Beim Start: Display-Manager stoppen → amdgpu lösen → GPU an vfio-pci → in die VM.
Beim Herunterfahren der VM: alles automatisch zurück.

> ⚠️ Erster Durchlauf = Test. Single-GPU-Passthrough ist hardware-sensibel.
> Falls der Host nach VM-Stop schwarz bleibt: Navi 21 hat selten einen Reset-Bug —
> dann ergänzen wir das `vendor-reset`-Kernelmodul. Solange keine VM `windows`
> existiert, ist alles inaktiv und ungefährlich.

## Empfehlung

Starte **hybrid**: AEON als GrundOS mit Virtualisierung (✅ schon drin) für Windows &
Distros im Alltag — und Dual-Boot bleibt als Reserve fürs volle GPU-Gaming. Wenn du
später eine zweite GPU einbaust oder dich für Single-GPU-Passthrough entscheidest,
schalten wir VFIO scharf und du brauchst Windows bare-metal gar nicht mehr.
