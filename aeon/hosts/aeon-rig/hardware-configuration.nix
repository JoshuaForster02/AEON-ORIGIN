# PLATZHALTER — NICHT verwenden wie er ist.
# Auf dem PC beim Installieren generieren mit:
#   sudo nixos-generate-config --root /mnt
# Das überschreibt diese Datei mit den echten Disk-/Filesystem-UUIDs deiner Hardware.
{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [ ];
  # boot.initrd.availableKernelModules = [ ... ];   # ← wird generiert
  # fileSystems."/" = { ... };                       # ← wird generiert
  # swapDevices = [ ... ];                            # ← wird generiert
}
