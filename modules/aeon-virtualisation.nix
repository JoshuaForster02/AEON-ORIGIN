# AEON als Hypervisor-Basis — vollständige, produktionsreife Konfiguration.
# Implementiert Single-GPU-Passthrough für RX 6800 (Navi 21) ohne Reboot.
#
# Wie es funktioniert:
#  aeon win → virsh startet "windows" in System-libvirt
#           → libvirt-Hook (prepare) wird aufgerufen
#           → SDDM wird beendet, amdgpu entladen, vfio-pci geladen
#           → GPU gehört der Windows-VM, Monitor zeigt Windows
#  aeon stop → virsh shutdown → Hook (release) kehrt alles um → KDE startet
{ config, pkgs, lib, ... }:
{
  # ── Kernel ────────────────────────────────────────────────────────────────
  boot.kernelPackages = pkgs.linuxPackages_zen;

  boot.kernelParams = [
    "amd_iommu=on"
    "iommu=pt"           # Pass-Through Modus — volle PCIe-Bandbreite
    "kvm.ignore_msrs=1"  # verhindert BSOD in Windows-VMs
    "kvm_amd.nested=1"   # Nested Virtualisation (schadet nicht)
  ];

  # Normalbetrieb: amdgpu treibt die GPU (Desktop). VFIO/vendor_reset nur im Gaming-Profil.
  boot.kernelModules = [ "kvm_amd" ];

  # ── KVM / libvirt ─────────────────────────────────────────────────────────
  virtualisation.libvirtd = {
    enable    = true;
    onBoot    = "ignore";
    onShutdown = "shutdown";
    qemu = {
      package    = pkgs.qemu_kvm;
      runAsRoot  = true;          # nötig für GPU-Detach als root
      swtpm.enable = true;        # TPM 2.0 für Windows 11
      ovmf = {
        enable   = true;
        packages = [ pkgs.OVMFFull.fd ];  # mit SecureBoot-Support
      };
    };

    # ── GPU-Passthrough Hook ───────────────────────────────────────────────
    # NixOS verlinkt das Skript automatisch nach /var/lib/libvirt/hooks/qemu
    hooks.qemu."aeon-gpu" = pkgs.writeShellScript "aeon-gpu-hook" ''
      GUEST="$1"
      OP="$2"

      # Nur für die VM namens "windows" aktiv
      [ "$GUEST" = "windows" ] || exit 0

      # Absolute Pfade (Hook läuft als root ohne $PATH)
      LSPCI="${pkgs.pciutils}/bin/lspci"
      VIRSH="${pkgs.libvirt}/bin/virsh"
      MODPROBE="${pkgs.kmod}/bin/modprobe"
      SYSTEMCTL="${pkgs.systemd}/bin/systemctl"

      # PCI-Adressen der RX 6800 dynamisch ermitteln
      vaddr=$($LSPCI -Dn -d "1002:73bf" | awk 'NR==1{print $1}')
      aaddr=$($LSPCI -Dn -d "1002:ab28" | awk 'NR==1{print $1}')

      if [ -z "$vaddr" ]; then
        logger -t aeon-gpu "FEHLER: RX 6800 (1002:73bf) nicht gefunden — Passthrough abgebrochen"
        exit 0
      fi

      # libvirt erwartet PCI-Namen im Format pci_0000_01_00_0
      vid="pci_$(echo "$vaddr" | tr ':.' '_')"
      aud="pci_$(echo "$aaddr" | tr ':.' '_')"

      detach() {
        logger -t aeon-gpu "GPU detach START — Desktop pausiert"

        # 1. Display-Manager beenden (KDE Plasma)
        $SYSTEMCTL stop display-manager.service
        sleep 2

        # 2. Framebuffer-Konsolen freigeben
        for fb in /sys/class/vtconsole/vtcon*/bind; do
          echo 0 > "$fb" 2>/dev/null || true
        done
        echo efi-framebuffer.0 \
          > /sys/bus/platform/drivers/efi-framebuffer/unbind 2>/dev/null || true

        # 3. amdgpu-Treiber entladen (vendor-reset kümmert sich um sicheren Reset)
        $MODPROBE -r amdgpu         || true
        $MODPROBE -r drm_kms_helper || true
        sleep 1

        # 4. vfio-pci aktivieren & GPU an VM übergeben
        $MODPROBE vfio-pci || true
        $VIRSH nodedev-detach "$vid" || true
        [ -n "$aaddr" ] && $VIRSH nodedev-detach "$aud" || true

        logger -t aeon-gpu "GPU detach DONE — Windows-VM übernimmt"
      }

      attach() {
        logger -t aeon-gpu "GPU attach START — Linux-Desktop kehrt zurück"

        # 1. GPU von VM zurückgeben
        $VIRSH nodedev-reattach "$vid" || true
        [ -n "$aaddr" ] && $VIRSH nodedev-reattach "$aud" || true

        # 2. vfio-pci entladen, amdgpu neu laden
        $MODPROBE -r vfio-pci       || true
        sleep 1
        $MODPROBE amdgpu             || true

        # 3. Framebuffer zurück
        for fb in /sys/class/vtconsole/vtcon*/bind; do
          echo 1 > "$fb" 2>/dev/null || true
        done

        # 4. KDE Plasma starten
        $SYSTEMCTL start display-manager.service
        logger -t aeon-gpu "GPU attach DONE — Linux-Desktop aktiv"
      }

      case "$OP" in
        prepare) detach  ;;
        release) attach  ;;
        *) exit 0 ;;
      esac
    '';
  };

  # ── Benutzer & Dienste ────────────────────────────────────────────────────
  programs.virt-manager.enable = true;

  # Joshua braucht libvirtd + input (für USB-Geräte-Passthrough in der VM)
  users.users.joshua.extraGroups = [ "libvirtd" "kvm" "input" ];

  # libvirtd muss laufen bevor aeon win aufgerufen wird
  systemd.services.libvirtd.wantedBy = [ "multi-user.target" ];

  # ── Pakete ────────────────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    pciutils        # lspci — GPU-Debugging
    virtiofsd       # schneller Host↔VM Datei-Share
    virt-viewer     # leichtgewichtiger VM-Viewer (Backup-Display)
    looking-glass-client  # VM-Bild im Linux-Fenster (erfordert IVSHMEM in XML)

    # GPU-Info Werkzeug (aeon gpu)
    (pkgs.writeShellScriptBin "aeon-gpu-info" ''
      G=$'\033[38;2;201;164;88m'; D=$'\033[38;2;154;147;132m'; R=$'\033[0m'
      printf "\n  %sRX 6800 IOMMU-Status%s\n" "$G" "$R"
      printf "  %s──────────────────────%s\n" "$D" "$R"

      echo ""
      printf "  %sGPU PCI-Geräte:%s\n" "$G" "$R"
      ${pkgs.pciutils}/bin/lspci -Dnnk | grep -iA3 -E "1002:73bf|1002:ab28" | \
        sed 's/^/  /'

      echo ""
      printf "  %sIOMMU-Gruppen (GPU + Audio müssen allein oder zusammen sein):%s\n" "$G" "$R"
      for d in /sys/kernel/iommu_groups/*/devices/*; do
        grp=$(basename "$(dirname "$(dirname "$d")")")
        dev=$(basename "$d")
        desc=$(${pkgs.pciutils}/bin/lspci -s "$dev" 2>/dev/null | cut -d' ' -f2- | head -1)
        printf "  Gruppe %02d: %s  %s%s%s\n" "$grp" "$dev" "$D" "$desc" "$R"
      done | sort -V

      echo ""
      printf "  %sKernel-Module (sollte vendor_reset + vfio_pci sehen):%s\n" "$G" "$R"
      lsmod | grep -E "vfio|vendor_reset|amdgpu" | awk '{printf "  %-20s %s\n", $1, $3}' || \
        printf "  %s(keine VFIO/vendor_reset Module geladen)%s\n" "$D" "$R"
      echo ""
    '')
  ];
}
