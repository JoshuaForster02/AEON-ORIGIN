# Single-GPU-Passthrough (VFIO) — RX 6800 (Navi 21) in die Windows-VM, ohne Reboot.
# Vorkonfiguriert für deine Karte (1002:73bf + 1002:ab28). Der Hook reagiert NUR
# auf eine VM namens "windows"; ohne diese VM passiert nichts.
{ pkgs, ... }:
let
  lspci = "${pkgs.pciutils}/bin/lspci";
  virsh = "${pkgs.libvirt}/bin/virsh";
  modprobe = "${pkgs.kmod}/bin/modprobe";
  systemctl = "${pkgs.systemd}/bin/systemctl";

  aeon-gpu-info = pkgs.writeShellScriptBin "aeon-gpu-info" ''
    G=$'\033[38;2;201;164;88m'; R=$'\033[0m'
    echo "''${G}GPU & Audio''${R}:"
    ${lspci} -Dnnk | grep -iA3 -E "VGA|3D|Display|Audio device"
    echo; echo "''${G}IOMMU-Gruppen''${R} (GPU + Audio sollten ~allein in einer Gruppe sein):"
    for d in /sys/kernel/iommu_groups/*/devices/*; do
      grp=$(basename "$(dirname "$(dirname "$d")")")
      printf "  Gruppe %s: %s\n" "$grp" "$(basename "$d")"
    done | sort -V
  '';

  gpuHook = pkgs.writeShellScript "aeon-gpu-hook" ''
    GUEST="$1"; OP="$2"
    [ "$GUEST" = "windows" ] || exit 0
    [ -f /etc/aeon/gpu.conf ] || { logger "aeon: gpu.conf fehlt — Passthrough inaktiv"; exit 0; }
    . /etc/aeon/gpu.conf

    vaddr=$(${lspci} -Dn -d "$GPU_VID_VIDEO" | awk 'NR==1{print $1}')
    aaddr=$(${lspci} -Dn -d "$GPU_VID_AUDIO" | awk 'NR==1{print $1}')
    [ -n "$vaddr" ] || { logger "aeon: GPU $GPU_VID_VIDEO nicht gefunden"; exit 0; }
    vid="pci_$(echo "$vaddr" | tr ':.' '__')"
    aud="pci_$(echo "$aaddr" | tr ':.' '__')"

    detach() {
      ${systemctl} stop display-manager || true
      sleep 2
      for c in /sys/class/vtconsole/vtcon*/bind; do echo 0 > "$c" 2>/dev/null || true; done
      echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind 2>/dev/null || true
      ${modprobe} -r amdgpu || true
      ${modprobe} vfio-pci || true
      ${virsh} nodedev-detach "$vid" || true
      [ -n "$aaddr" ] && ${virsh} nodedev-detach "$aud" || true
    }
    attach() {
      ${virsh} nodedev-reattach "$vid" || true
      [ -n "$aaddr" ] && ${virsh} nodedev-reattach "$aud" || true
      ${modprobe} -r vfio-pci || true
      ${modprobe} amdgpu || true
      for c in /sys/class/vtconsole/vtcon*/bind; do echo 1 > "$c" 2>/dev/null || true; done
      ${systemctl} start display-manager || true
    }

    case "$OP" in
      prepare) detach ;;
      release) attach ;;
    esac
  '';
in
{
  boot.kernelModules = [ "vfio_pci" "vfio_iommu_type1" "vfio" ];

  environment.systemPackages = [ aeon-gpu-info ];

  # Vorkonfiguriert für deine RX 6800 (XFX). Adressen löst der Hook selbst auf.
  environment.etc."aeon/gpu.conf".text = ''
    # AMD RX 6800 (Navi 21) — vendor:device IDs
    GPU_VID_VIDEO=1002:73bf
    GPU_VID_AUDIO=1002:ab28
  '';

  virtualisation.libvirtd.hooks.qemu.aeon-gpu = gpuHook;
}
