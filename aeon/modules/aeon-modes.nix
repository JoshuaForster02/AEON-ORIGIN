# AEON-Modi: `aeon-focus` / `aeon-unfocus` — Live-Wechsel OHNE Reboot.
# Wechselt im Betrieb in die NixOS-Specialisation "focus" (hartes Hosts-Blocking)
# und wieder zurück. Passwortloses sudo dafür ist in configuration.nix konfiguriert.
{ pkgs, ... }:
let
  focus = pkgs.writeShellScriptBin "aeon-focus" ''
    GOLD=$'\033[38;2;201;164;88m'; DIM=$'\033[38;2;154;147;132m'; R=$'\033[0m'
    echo ""
    printf "  %sAEON FOCUS%s — Lern-Umgebung aktivieren\n" "$GOLD" "$R"
    printf "  %s───────────────────────────────────%s\n" "$DIM" "$R"

    # Specialisation live umschalten (passwortloses sudo ist eingerichtet)
    FOCUS_BIN=/run/current-system/specialisation/focus/bin/switch
    if [ -x "$FOCUS_BIN" ]; then
      printf "  Wechsle ins Focus-Profil (Hosts-Sperre aktiv) …\n"
      sudo "$FOCUS_BIN" && printf "  %s✓%s Profil gewechselt\n" "$GOLD" "$R"
    else
      printf "  %s(Focus-Specialisation nicht gefunden — Hosts-Sperre manuell aktiv)%s\n" "$DIM" "$R"
    fi

    # Marker + Startzeit für Vitals-Tracking
    touch /run/aeon-focus-active
    date +%s > /run/aeon-focus-start

    # Lern-Apps starten
    printf "  %s▸%s Starte Lern-Umgebung …\n" "$GOLD" "$R"
    ${pkgs.anki-bin}/bin/anki >/dev/null 2>&1 &
    ${pkgs.firefox}/bin/firefox --new-window \
      https://app.amboss.com \
      https://www.perplexity.ai \
      https://notion.so \
      >/dev/null 2>&1 &

    echo ""
    printf "  %sAktiv:%s Anki · Amboss · Perplexity · Notion\n" "$GOLD" "$R"
    printf "  %sSperren:%s YouTube · Instagram · TikTok · Reddit · X · Netflix\n" "$GOLD" "$R"
    printf "  Beenden:  %saeon unfocus%s\n\n" "$GOLD" "$R"
  '';

  unfocus = pkgs.writeShellScriptBin "aeon-unfocus" ''
    GOLD=$'\033[38;2;201;164;88m'; DIM=$'\033[38;2;154;147;132m'; R=$'\033[0m'
    echo ""
    printf "  %sAEON UNFOCUS%s — Zurück in den Normal-Modus\n" "$GOLD" "$R"

    # Zurück zur Standard-Specialisation
    DEFAULT_BIN=/nix/var/nix/profiles/system/bin/switch
    if [ -x "$DEFAULT_BIN" ]; then
      sudo "$DEFAULT_BIN" && printf "  %s✓%s Profil zurückgesetzt\n" "$GOLD" "$R"
    fi

    # Marker entfernen
    rm -f /run/aeon-focus-active /run/aeon-focus-start

    printf "  %sSperren aufgehoben.%s Viel Erfolg gehabt!\n\n" "$GOLD" "$R"
  '';
in
{
  environment.systemPackages = [ focus unfocus ];
}
