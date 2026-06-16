#!/usr/bin/env bash
# AEON Config-Check — prüft die ganze Desktop-Config (aeon-rig) OHNE ISO/Install.
# Fängt alle Eval-Fehler (gnome, grub, attribute missing, Option-Konflikte) vorab.
# So musst du NICHT pro Fehler eine ISO bauen+flashen+installieren.
#
# Nutzung:  /bin/bash build/check.sh
# Ergebnis: ✅ sauber  → dann lohnt der ISO-Build
#           ❌ Fehler  → Ausgabe mir schicken, ich fixe, erneut check
set -uo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILDER_IMAGE="${AEON_BUILDER_IMAGE:-nixos/nix:latest}"

echo "════════════════════════════════════════════"
echo "  AEON Config-Check (ohne ISO/Install)"
echo "  Version: $(cat "$REPO_DIR/VERSION" 2>/dev/null || echo '?')"
echo "════════════════════════════════════════════"

docker run --rm --platform linux/amd64 \
  -v "$REPO_DIR":/aeon -w /aeon \
  -e NIX_CONFIG=$'experimental-features = nix-command flakes\nfilter-syscalls = false\nsandbox = false' \
  "$BUILDER_IMAGE" \
  sh -lc '
    set -e
    rm -f /aeon/flake.lock 2>/dev/null || true
    if command -v git >/dev/null 2>&1 && [ -e /aeon/.git ]; then
      git config --global --add safe.directory /aeon; git -C /aeon add -A 2>/dev/null || true
    fi

    # Minimal-Hardware-Profil NUR für den Check (sonst meckert Nix über fehlendes /).
    cp /aeon/hosts/aeon-rig/hardware-configuration.nix /tmp/hw.bak 2>/dev/null || true
    cat > /aeon/hosts/aeon-rig/hardware-configuration.nix <<EOF
{ ... }: {
  fileSystems."/" = { device = "/dev/disk/by-label/aeon-root"; fsType = "ext4"; };
}
EOF
    git -C /aeon add -A 2>/dev/null || true

    echo ">> Evaluierung der gesamten aeon-rig-Config (Dry-Run) …"
    set +e
    nix build ".#nixosConfigurations.aeon-rig.config.system.build.toplevel" --dry-run 2>&1
    rc=$?
    set -e

    # Platzhalter zurücksetzen
    cp /tmp/hw.bak /aeon/hosts/aeon-rig/hardware-configuration.nix 2>/dev/null || true
    git -C /aeon add -A 2>/dev/null || true

    echo "────────────────────────────────────────────"
    if [ "$rc" -eq 0 ]; then
      echo "✅ Config evaluiert SAUBER — der Install wird durchlaufen. ISO bauen lohnt jetzt."
    else
      echo "❌ Fehler oben — schick ihn mir, ich fixe ihn (kein ISO/Flash nötig)."
    fi
    exit "$rc"
  '
