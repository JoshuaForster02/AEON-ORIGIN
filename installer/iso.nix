# AEON Installer-ISO — bootfähiges USB-Image mit allem an Bord.
# Baut auf der offiziellen NixOS-Installer-CD auf und ergänzt:
#  - Tailscale (schon im Installer drin)
#  - Tools für die Dual-Boot-Installation (parted, gptfdisk, git)
#  - AEON-Branding + geführtes Skript `aeon-install`
{ pkgs, lib, ... }:
let
  aeon-install = pkgs.writeShellScriptBin "aeon-install" (builtins.readFile ./aeon-install.sh);

  # Gefilterte Repo-Quelle: ohne gebaute ISOs (out/), Runtime-Daten, .git, Archive.
  repoSrc = lib.cleanSourceWith {
    src = ../.;
    filter = path: type:
      let b = baseNameOf path; in
      b != "out" && b != "result" && b != ".git" && b != "data"
      && !(lib.hasSuffix ".iso" b) && !(lib.hasSuffix ".zip" b);
  };
in
{
  # Flakes im Live-Installer aktivieren — sonst schlägt `nixos-install --flake` fehl!
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Tailscale bereits im Live-Installer verfügbar
  services.tailscale.enable = true;

  # Netzwerk im Installer komfortabel: NetworkManager statt wpa_supplicant.
  # Die Installer-CD aktiviert wireless — das kollidiert mit NM, daher abschalten:
  networking.wireless.enable = lib.mkForce false;
  networking.networkmanager.enable = true;
  networking.hostName = "aeon-installer";

  # Alles, was der Installer braucht (inkl. dem geführten Skript `aeon-install`)
  environment.systemPackages = with pkgs; [
    git vim curl
    parted gptfdisk ntfs3g   # Partitionen anfassen / NTFS lesen
    dialog                   # grafische Menüs im Installer
    tailscale
    aeon-install
  ];

  # Installer startet automatisch beim Booten (tty1) — kein Befehl nötig.
  programs.bash.interactiveShellInit = ''
    if [ "$(tty)" = "/dev/tty1" ] && [ -z "''${AEON_STARTED:-}" ]; then
      export AEON_STARTED=1
      aeon-install || true
    fi
  '';

  # AEON-Begrüßung im Login-Screen der Konsole (ENCOM-Vibe)
  services.getty.greetingLine = lib.mkForce ''

      A E O N  ·  installer
      ──────────────────────────────────────────
      Geführte Dual-Boot-Installation. Windows bleibt.
      Starte mit:   aeon-install
  '';

  # Repo-URL fürs Install-Skript (Fallback, falls keine lokale Kopie da ist)
  environment.variables.AEON_REPO = "https://github.com/DEIN-USER/aeon";

  # Self-contained: das ganze AEON-Repo in die ISO backen → Installieren ohne
  # GitHub/Internet. Der Installer nutzt bevorzugt diese Kopie unter /etc/aeon.
  environment.etc.aeon.source = repoSrc;

  # ISO-Branding & schlankere Kompression
  isoImage.volumeID = lib.mkForce "AEON";
  isoImage.squashfsCompression = "zstd -Xcompression-level 6";
}
