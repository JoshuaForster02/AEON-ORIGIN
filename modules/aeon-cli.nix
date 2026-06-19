# Das AEON Command-Center: EIN intuitiver Befehl für alles.
#   aeon focus|unfocus|game|win|vm|dash|gpu|tron "…"
#   aeon ota <git-url>   → OTA-Quelle setzen (welches GitHub/Git)
#   aeon update          → Updates holen + anwenden (behält dein Hardware-Profil)
{ pkgs, ... }:
let
  aeon = pkgs.writeShellScriptBin "aeon" ''
    G=$'\033[38;2;201;164;88m'; D=$'\033[38;2;154;147;132m'; T=$'\033[38;2;236;230;216m'; R=$'\033[0m'; B=$'\033[1m'
    REPO=/etc/nixos/aeon
    cmd="''${1:-help}"; shift 2>/dev/null || true
    case "$cmd" in
      focus)        aeon-focus ;;
      unfocus)      aeon-unfocus ;;
      game)         steam >/dev/null 2>&1 & echo "''${G}▸''${R} Steam startet …" ;;

      win|windows)
        printf "\n  ''${G}AEON WINDOWS''${R}\n"
        printf "  ''${D}GPU-Passthrough: Desktop pausiert, Monitor schaltet auf Windows um.''${R}\n\n"

        # Prüfen ob VM in System-libvirt bekannt ist
        if ! ${pkgs.libvirt}/bin/virsh -c qemu:///system domstate windows >/dev/null 2>&1; then
          printf "  ''${G}⚠''${R}  VM 'windows' nicht gefunden in qemu:///system.\n"
          printf "  Erstelle sie zuerst mit:  ''${G}aeon vm''${R}  (virt-manager, XML-Import)\n\n"
          exit 1
        fi

        STATE=$(${pkgs.libvirt}/bin/virsh -c qemu:///system domstate windows 2>/dev/null)
        if [ "$STATE" = "running" ]; then
          printf "  Windows-VM läuft bereits. Zum Stoppen:  ''${G}aeon stop''${R}\n\n"
          exit 0
        fi

        printf "  ''${G}▸''${R} Starte Windows-VM … (GPU wird in ~5s übergeben)\n"
        printf "  ''${D}Log: journalctl -u libvirtd -f''${R}\n\n"
        printf "  ''${D}Watchdog aktiv: Desktop kommt automatisch zurueck, falls kein Bild (kein Power-off noetig).''${R}\n\n"
        sudo ${pkgs.systemd}/bin/systemctl reset-failed aeon-winwatch 2>/dev/null || true
        sudo ${pkgs.systemd}/bin/systemd-run --on-active=150 --unit=aeon-winwatch --collect /run/current-system/sw/bin/aeon-winwatch >/dev/null 2>&1 || true
        ${pkgs.libvirt}/bin/virsh -c qemu:///system start windows || {
          printf "\n  ''${G}✗''${R} Start fehlgeschlagen. Logs:\n"
          printf "    journalctl -u libvirtd -n 30\n"
          printf "    aeon gpu   (IOMMU-Gruppen prüfen)\n\n"
          exit 1
        }
        ;;

      stop)
        printf "  ''${G}▸''${R} Windows-VM wird sauber heruntergefahren …\n"
        ${pkgs.libvirt}/bin/virsh -c qemu:///system shutdown windows 2>/dev/null || \
          ${pkgs.libvirt}/bin/virsh -c qemu:///system destroy  windows 2>/dev/null || true
        printf "  ''${D}GPU kehrt zurück, Desktop startet in ~10 s.''${R}\n"
        ;;

      vm)           virt-manager >/dev/null 2>&1 & echo "''${G}▸''${R} VM-Manager …" ;;
      dash|dashboard) ${pkgs.firefox}/bin/firefox http://aeon-pi:8080 >/dev/null 2>&1 & echo "''${G}▸''${R} AEON-Dashboard …" ;;
      gpu)          aeon-gpu-info ;;
      tron|ask)     tron "$@" ;;

      ota)
        url="''${1:-}"
        if [ -z "$url" ]; then
          printf "  ''${D}Aktuelle OTA-Quelle:''${R} "
          sudo git -C "$REPO" remote get-url origin 2>/dev/null || echo "(keine gesetzt)"
          echo "  Setzen mit:  ''${G}aeon ota <git-url>''${R}"
          echo "  Beispiele:   aeon ota git@github.com:DEINUSER/aeon.git"
          echo "               aeon ota aeon-pi:aeon.git   ''${D}(eigener Pi, kein GitHub)''${R}"
        else
          sudo git -C "$REPO" init -q 2>/dev/null || true
          sudo git -C "$REPO" remote remove origin 2>/dev/null || true
          sudo git -C "$REPO" remote add origin "$url"
          echo "''${G}✓''${R} OTA-Quelle gesetzt: $url"
          echo "  Jetzt holen:  ''${G}aeon update''${R}"
        fi
        ;;

      update)
        if [ -d "$REPO/.git" ] && sudo git -C "$REPO" remote get-url origin >/dev/null 2>&1; then
          src=$(sudo git -C "$REPO" remote get-url origin)
          echo "''${G}▸''${R} Hole Updates von: $src"
          # Hardware-Profil dieser Maschine sichern (wird nie überschrieben)
          HW=$(sudo find "$REPO" -name hardware-configuration.nix -path '*aeon-rig*' 2>/dev/null | head -1)
          [ -n "$HW" ] && sudo cp "$HW" /tmp/aeon-hw.nix 2>/dev/null || true
          sudo git -C "$REPO" fetch --depth 1 origin main && sudo git -C "$REPO" reset --hard origin/main
          HW2=$(sudo find "$REPO" -name hardware-configuration.nix -path '*aeon-rig*' 2>/dev/null | head -1)
          [ -n "$HW2" ] && [ -f /tmp/aeon-hw.nix ] && sudo cp /tmp/aeon-hw.nix "$HW2" 2>/dev/null || true
        else
          echo "''${D}Keine OTA-Quelle gesetzt — baue lokalen Stand neu. (aeon ota <url> zum Verbinden)''${R}"
        fi
        # Auto-Erkennung: Flake im Repo-Root ODER im aeon/-Unterordner
        FLAKEDIR="$REPO"; [ -f "$REPO/flake.nix" ] || FLAKEDIR="$REPO/aeon"
        sudo nixos-rebuild switch --flake "$FLAKEDIR#aeon-rig"
        ;;

      help|*)
        printf "\n  ''${G}''${B}A E O N''${R}  ''${D}· command-center''${R}\n"
        printf "  ''${D}──────────────────────────────────────────''${R}\n"
        printf "  ''${G}aeon focus''${R}        Lern-Umgebung (Anki·Amboss·Perplexity)\n"
        printf "  ''${G}aeon game''${R}         Steam / Gaming\n"
        printf "  ''${G}aeon win''${R}          Windows-VM starten (GPU-Passthrough)\n"
        printf "  ''${G}aeon stop''${R}         Windows-VM sauber herunterfahren\n"
        printf "  ''${G}aeon vm''${R}           VM-Manager (virt-manager)\n"
        printf "  ''${G}aeon dash''${R}         AEON-Dashboard im Browser\n"
        printf "  ''${G}aeon gpu''${R}          GPU-/IOMMU-Infos\n"
        printf "  ''${G}aeon tron \"…\"''${R}    Frag die lokale LLM\n"
        printf "  ''${G}aeon ota <url>''${R}    OTA-Quelle setzen (welches Git)\n"
        printf "  ''${G}aeon update''${R}       Updates holen + anwenden\n\n"
        ;;
    esac
  '';
in
{
  environment.systemPackages = [ aeon ];
}
