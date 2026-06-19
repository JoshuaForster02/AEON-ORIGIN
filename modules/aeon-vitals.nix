# AEON Vitals-Reporter — sendet PC-Metriken an den Pi-Hub.
# Läuft als Systemd-Timer alle 15 Minuten.
# Metriken:
#  - Anki-Streak (wie viele aufeinanderfolgende Tage mit Review)
#  - Focus-Modus aktiv (ja/nein + Dauer heute in Stunden)
{ pkgs, ... }:
let
  hubUrl = "http://aeon-pi:8080/api/ingest-pc";

  # Liest Anki-SQLite-Datenbank + berechnet Review-Streak + sendet an Pi
  vitalsReporter = pkgs.writeShellScriptBin "aeon-vitals-report" ''
    set -u
    HUB="${hubUrl}"
    GOLD=$'\033[38;2;201;164;88m'; DIM=$'\033[38;2;154;147;132m'; R=$'\033[0m'

    # --- Anki-Streak aus SQLite ---
    DB="$HOME/.local/share/Anki2/User 1/collection.anki2"
    STREAK=0
    if [ -f "$DB" ]; then
      STREAK=$(${pkgs.sqlite}/bin/sqlite3 "$DB" "
        WITH days AS (
          SELECT DISTINCT date(id/1000,'unixepoch','localtime') AS day
          FROM revlog WHERE ease > 0 ORDER BY day DESC
        ), streak AS (
          SELECT day, ROW_NUMBER() OVER (ORDER BY day DESC) AS rn
          FROM days
        )
        SELECT COUNT(*) FROM streak
        WHERE DATE('now','localtime', '-' || (rn-1) || ' days') = day;
      " 2>/dev/null || echo 0)
    fi

    # --- Focus-Modus aktiv? ---
    FOCUS_ACTIVE=false
    if [ -f /run/aeon-focus-active ]; then FOCUS_ACTIVE=true; fi

    # --- Focus-Stunden heute ---
    FOCUS_HRS=0
    if [ -f /run/aeon-focus-start ] && $FOCUS_ACTIVE; then
      START=$(cat /run/aeon-focus-start)
      NOW=$(date +%s)
      FOCUS_HRS=$(echo "scale=1; ($NOW - $START) / 3600" | ${pkgs.bc}/bin/bc 2>/dev/null || echo 0)
    fi

    # --- Payload bauen & senden ---
    PAYLOAD=$(${pkgs.jq}/bin/jq -nc \
      --argjson streak "$STREAK" \
      --argjson focus_active "$FOCUS_ACTIVE" \
      --arg focus_hrs "$FOCUS_HRS" \
      '{source:"aeon-rig", ts:(now|todate),
        anki_streak:$streak,
        focus_active:$focus_active,
        focus_hours_today:($focus_hrs|tonumber)}')

    HTTP=$(${pkgs.curl}/bin/curl -s -o /dev/null -w "%{http_code}" \
      -X POST "$HUB" -H "Content-Type: application/json" \
      -d "$PAYLOAD" --max-time 10 2>/dev/null || echo "000")

    if [ "$HTTP" = "200" ]; then
      printf "%sAEON Vitals%s → Pi OK: Streak %s%s%s Tage | Focus %s%s%sh\n" \
        "$GOLD" "$R" "$GOLD" "$STREAK" "$R" "$GOLD" "$FOCUS_HRS" "$R"
    else
      printf "%sAEON Vitals%s → Pi nicht erreichbar (HTTP $HTTP) — lokal OK\n" \
        "$DIM" "$R"
    fi
  '';

in
{
  environment.systemPackages = [ vitalsReporter pkgs.sqlite pkgs.bc pkgs.jq ];

  systemd.services.aeon-vitals = {
    description  = "AEON Vitals Reporter (Anki-Streak + Fokus → Pi)";
    after        = [ "network.target" "tailscaled.service" ];
    serviceConfig = {
      Type           = "oneshot";
      User           = "joshua";
      ExecStart      = "${vitalsReporter}/bin/aeon-vitals-report";
      StandardOutput = "journal";
    };
  };

  systemd.timers.aeon-vitals = {
    description = "AEON Vitals Reporter (alle 15 min)";
    wantedBy    = [ "timers.target" ];
    timerConfig = {
      OnBootSec       = "2min";
      OnUnitActiveSec = "15min";
      Persistent      = true;
    };
  };
}
