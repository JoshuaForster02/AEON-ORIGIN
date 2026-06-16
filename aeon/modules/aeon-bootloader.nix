# Fancy AEON-Bootloader (GRUB mit Noir-Gold-Theme) — OTA-Upgrade NACH dem ersten Boot.
#
# NICHT zusammen mit systemd-boot aktiv! Zum Umschalten in configuration.nix:
#   1) den ganzen "boot.loader.systemd-boot.*"-Block auskommentieren
#   2) diese Datei importieren:  ../../modules/aeon-bootloader.nix
#   3) sudo nixos-rebuild switch --flake /etc/nixos/aeon#aeon-rig
#
# Erkennt Windows automatisch (useOSProber) und zeigt das AEON-Theme.
{ pkgs, ... }:
{
  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    device = "nodev";
    useOSProber = true;              # Windows im Menü
    theme = ../assets/grub;          # background.png + theme.txt
    gfxmodeEfi = "1920x1080";
    configurationLimit = 8;
  };
}
