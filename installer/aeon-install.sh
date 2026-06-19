#!/usr/bin/env bash
# AEON · grafischer Installer (dialog) — dual-boot-sicher, ohne Befehle merken.
set -u
if [ "$(id -u)" -ne 0 ]; then exec sudo -E "$0" "$@"; fi

AEON_REPO="${AEON_REPO:-https://github.com/DEIN-USER/aeon}"
VER="$( [ -f /etc/aeon/VERSION ] && cat /etc/aeon/VERSION || echo 'AEON' )"
BT="AEON · ${VER}"

# dialog-Wrapper: Auswahl kommt auf stdout
pick(){ dialog --backtitle "$BT" "$@" 3>&1 1>&2 2>&3; }
die(){ dialog --backtitle "$BT" --title "Abbruch" --msgbox "$1" 10 72; clear; exit 1; }

dialog --backtitle "$BT" --title "AEON Installer" --yesno \
"Dual-Boot-Installation — Windows bleibt unangetastet.\n\nVoraussetzung: du hast in Windows bereits freien Speicher\ngeschaffen (C: verkleinert).\n\nJetzt starten?" 14 72 || { clear; exit 0; }

ping -c1 -W3 nixos.org >/dev/null 2>&1 || die "Kein Internet.\nVerbinde dich (Befehl: nmtui) und starte neu."

[ -e /etc/aeon/modules/aeon-cli.nix ] || die \
"Diese ISO ist veraltet (Module fehlen).\n\nBitte ISO neu bauen (build/build-iso.sh),\nneu auf USB schreiben und davon booten."

# 1) Festplatte wählen
mapfile -t DL < <(lsblk -dno NAME,SIZE,MODEL | grep -vE '^(loop|sr)')
[ "${#DL[@]}" -gt 0 ] || die "Keine Festplatte gefunden."
dargs=(); for l in "${DL[@]}"; do n=${l%% *}; d=${l#* }; dargs+=("$n" "$d"); done
DISK=$(pick --menu "Festplatte mit dem freien Speicher:" 20 72 10 "${dargs[@]}") || { clear; exit 0; }
DISK="/dev/$DISK"

# 2) Partitionen anlegen (cfdisk = Pfeiltasten-Editor)
dialog --backtitle "$BT" --msgbox \
"Gleich öffnet der Partitions-Editor (cfdisk).\n\nIm FREIEN Bereich anlegen:\n  • 1x  'Linux filesystem'  -> AEON-root\n  • optional 1x  'Linux swap'\n\nBestehende Windows-/EFI-Partitionen NICHT anfassen.\nDanach:  [Write] -> 'yes'  ->  [Quit]." 17 72
cfdisk "$DISK"

# 3) Partitionen zuordnen (aus Liste wählen)
mapfile -t PL < <(lsblk -lno NAME,SIZE,FSTYPE "$DISK" | tail -n +2)
[ "${#PL[@]}" -gt 0 ] || die "Keine Partitionen gefunden."
pargs=(); for l in "${PL[@]}"; do n=$(awk '{print $1}' <<<"$l"); r=$(awk '{$1="";sub(/^ /,"");print}' <<<"$l"); pargs+=("$n" "$r"); done

ROOT=$(pick --menu "AEON-root (wird FORMATIERT):" 20 72 10 "${pargs[@]}") || { clear; exit 0; }
ESP=$(pick --menu "EFI-Partition (vfat, NICHT formatiert):" 20 72 10 "${pargs[@]}") || { clear; exit 0; }
SWAP=$(pick --menu "Swap (oder 'keine'):" 20 72 11 keine "— kein Swap —" "${pargs[@]}") || { clear; exit 0; }
ROOT="/dev/$ROOT"; ESP="/dev/$ESP"
[ "$SWAP" = "keine" ] && SWAP="" || SWAP="/dev/$SWAP"

# Sicherheits-Warnung, falls root schon ein Dateisystem hat
if blkid "$ROOT" >/dev/null 2>&1; then
  EX=$(blkid -o value -s TYPE "$ROOT" 2>/dev/null || echo '?')
  dialog --backtitle "$BT" --title "Achtung" --yesno \
"$ROOT enthält bereits ein Dateisystem ($EX)!\n\nNur fortfahren, wenn das die LEERE AEON-Partition ist\n(keine Windows-Daten). Überschreiben?" 12 72 || { clear; exit 0; }
fi

# 4) Bestätigen
dialog --backtitle "$BT" --title "Bestätigen" --yesno \
"root :  $ROOT   (wird FORMATIERT)\nEFI  :  $ESP   (nur eingebunden)\nswap :  ${SWAP:-keine}\n\nWirklich installieren?" 12 72 || { clear; exit 0; }

# 5) Installation mit Live-Ausgabe
( set -e
  umount -R /mnt 2>/dev/null || true
  [ -n "$SWAP" ] && swapoff "$SWAP" 2>/dev/null || true
  echo ">> [1/5] Formatiere $ROOT"; mkfs.ext4 -FL aeon-root "$ROOT"
  echo ">> [2/5] Montiere"; mount "$ROOT" /mnt; mkdir -p /mnt/boot; mount "$ESP" /mnt/boot
  [ -n "$SWAP" ] && { mkswap -L aeon-swap "$SWAP"; swapon "$SWAP"; }
  echo ">> [3/5] Erkenne Hardware"; nixos-generate-config --root /mnt
  echo ">> [4/5] Kopiere AEON"; rm -rf /mnt/etc/nixos/aeon
  cp -aL "$(readlink -f /etc/aeon)" /mnt/etc/nixos/aeon; chmod -R u+w /mnt/etc/nixos/aeon
  cp -f /mnt/etc/nixos/hardware-configuration.nix \
        /mnt/etc/nixos/aeon/hosts/aeon-rig/hardware-configuration.nix
  echo ">> [5/5] Installiere AEON — das dauert ein paar Minuten ..."
  nixos-install --no-root-passwd --flake /mnt/etc/nixos/aeon#aeon-rig
  echo ">> FERTIG."
) 2>&1 | dialog --backtitle "$BT" --title "Installation laeuft …" --programbox 28 96
rc=${PIPESTATUS[0]}

[ "$rc" -eq 0 ] || die "Installation fehlgeschlagen.\nWechsle mit Strg+Alt+F2 zu einer Shell für Details,\noder schick die Ausgabe oben."

dialog --backtitle "$BT" --title "AEON installiert ✓" --yesno \
"AEON ist installiert.\n\nNach dem Reboot:  Login  joshua / aeon  (dann: passwd)\nBoot-Menü zeigt AEON und Windows.\n\nJetzt neu starten?" 13 72 && { clear; reboot; }
clear
