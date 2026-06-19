#!/usr/bin/env bash
# AEON-Installer-ISO auf dem Mac (M1) via Docker bauen.
# Nutzt einen x86_64-Linux-Nix-Builder im Container (emuliert über Rosetta/QEMU)
# und legt die fertige ISO in ./out ab.
#
# Voraussetzung: Docker Desktop läuft, in den Einstellungen genug Ressourcen
# (empfohlen: 8 GB RAM, 80+ GB Disk-Image) — der Build lädt & baut viel.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILDER_IMAGE="${AEON_BUILDER_IMAGE:-nixos/nix:latest}"
mkdir -p "$REPO_DIR/out"
# Alte ISOs löschen, damit nie versehentlich eine veraltete geflasht wird.
rm -f "$REPO_DIR"/out/*.iso 2>/dev/null || true
echo "  Baue Version: $(cat "$REPO_DIR/VERSION" 2>/dev/null || echo '?')"

echo "════════════════════════════════════════════"
echo "  AEON-ISO Build (Docker · x86_64 emuliert)"
echo "════════════════════════════════════════════"
echo "  Image:   ${BUILDER_IMAGE}"
echo "  Dauer:   ~20–60 Min beim ersten Mal. Lass es laufen."
echo

docker run --rm --platform linux/amd64 \
  -v "$REPO_DIR":/aeon -w /aeon \
  -e NIX_CONFIG=$'experimental-features = nix-command flakes\nfilter-syscalls = false\nsandbox = false' \
  "$BUILDER_IMAGE" \
  sh -lc '
    set -e
    # Stale Lock wegwerfen, damit Input-Änderungen (z.B. stylix-Pin) greifen.
    rm -f /aeon/flake.lock 2>/dev/null || true
    # WICHTIG: Flakes ignorieren untracked Git-Dateien. Falls /aeon ein Git-Repo
    # ist, alle Dateien stagen, damit neue Module wirklich in die ISO kommen.
    if command -v git >/dev/null 2>&1 && [ -e /aeon/.git ]; then
      git config --global --add safe.directory /aeon
      git -C /aeon add -A 2>/dev/null || true
      echo ">> Git: alle Dateien gestaged — Flake sieht jetzt auch neue Module."
    fi
    nix build .#aeon-iso -o /aeon/out/result-iso --print-build-logs
    cp -Lf /aeon/out/result-iso/iso/*.iso /aeon/out/
    rm -f /aeon/out/result-iso
  '

echo
echo "✓ Fertig. ISO liegt in:  ${REPO_DIR}/out/"
ls -lh "$REPO_DIR/out/"*.iso
echo
echo "Nächster Schritt: ISO mit Ventoy/Rufus/dd auf USB → am PC booten → aeon-install"
