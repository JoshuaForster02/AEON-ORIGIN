# Freeze-sicherer Windows-VM-Start: Watchdog holt den Desktop garantiert zurueck,
# falls die GPU kein Bild ausgibt. Laeuft Windows (DHCP-Lease) -> Watchdog laesst es in Ruhe.
{ config, pkgs, lib, ... }:
let
  watchbin = pkgs.writeShellScriptBin "aeon-winwatch" ''
    export PATH=/run/current-system/sw/bin:$PATH
    ST=$(${pkgs.libvirt}/bin/virsh -c qemu:///system domstate windows 2>/dev/null)
    LEASES=$(${pkgs.libvirt}/bin/virsh -c qemu:///system net-dhcp-leases default 2>/dev/null | grep -cE '([0-9]{1,3}\.){3}')
    # Windows laeuft sichtbar (hat Netzwerk) -> nichts tun
    if [ "$ST" = "running" ] && [ "$LEASES" -ge 1 ]; then exit 0; fi
    # sonst: kein Bild -> Desktop zurueckholen
    ${pkgs.libvirt}/bin/virsh -c qemu:///system destroy windows 2>/dev/null || true
    sleep 2
    ${pkgs.kmod}/bin/modprobe amdgpu || true
    ${pkgs.systemd}/bin/systemctl restart display-manager || true
  '';
  winbin = pkgs.writeShellScriptBin "aeon-win" ''
    echo "▸ Windows-VM startet … Falls kein Bild kommt, ist der Desktop in ~2,5 Min automatisch zurueck (kein Power-off noetig)."
    sudo ${pkgs.systemd}/bin/systemctl reset-failed aeon-winwatch 2>/dev/null || true
    sudo ${pkgs.systemd}/bin/systemd-run --on-active=150 --unit=aeon-winwatch --collect ${watchbin}/bin/aeon-winwatch >/dev/null 2>&1 || true
    sudo ${pkgs.libvirt}/bin/virsh -c qemu:///system start windows
  '';
in {
  environment.systemPackages = [ winbin watchbin ];
  security.sudo.extraRules = [{
    users = [ "joshua" ];
    commands = [
      { command = "${pkgs.systemd}/bin/systemd-run"; options = [ "NOPASSWD" ]; }
      { command = "${pkgs.systemd}/bin/systemctl"; options = [ "NOPASSWD" ]; }
      { command = "${pkgs.libvirt}/bin/virsh"; options = [ "NOPASSWD" ]; }
    ];
  }];
}
