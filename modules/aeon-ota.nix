# AEON OTA: zieht automatisch Updates aus GitHub (AEON-ORIGIN) und baut um.
# hardware-configuration.nix bleibt lokal (gitignored) und wird nie überschrieben.
{ config, pkgs, lib, ... }:
let
  repo = "https://github.com/JoshuaForster02/AEON-ORIGIN.git";
  otaScript = pkgs.writeShellScript "aeon-ota-pull" ''
    set -e
    export PATH=${lib.makeBinPath [ pkgs.git pkgs.gnused ]}:/run/current-system/sw/bin:$PATH
    cd /etc/nixos/aeon || exit 0
    git remote set-url origin ${repo} 2>/dev/null || git remote add origin ${repo}
    git fetch --depth 1 origin main || exit 0
    LOCAL=$(git rev-parse HEAD 2>/dev/null || echo none)
    REMOTE=$(git rev-parse origin/main)
    [ "$LOCAL" = "$REMOTE" ] && { echo "AEON: aktuell"; exit 0; }
    echo "AEON: Update $LOCAL -> $REMOTE"
    git reset --hard origin/main           # hardware-configuration.nix ist gitignored -> bleibt
    nixos-rebuild switch --flake /etc/nixos/aeon#aeon-rig
  '';
in {
  systemd.services.aeon-ota = {
    description = "AEON OTA – Update aus GitHub ziehen und umbauen";
    serviceConfig = { Type = "oneshot"; ExecStart = otaScript; };
  };
  systemd.timers.aeon-ota = {
    description = "AEON OTA Timer";
    wantedBy = [ "timers.target" ];
    timerConfig = { OnBootSec = "5min"; OnUnitActiveSec = "1h"; Persistent = true; };
  };
}
