#!/usr/bin/env bash
# AEON Pi-Hub OTA: holt die neueste Version aus Git und startet den Stack neu.
set -euo pipefail
cd "$(dirname "$0")"              # → aeon/pi
git -C .. pull --ff-only
docker compose up -d --build
docker image prune -f >/dev/null 2>&1 || true
echo "✓ AEON-Hub aktualisiert ($(date '+%F %T'))"
