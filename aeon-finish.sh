#!/bin/bash
SSHOPTS="-i $HOME/.ssh/aeon_ed25519 -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
PC=joshua@192.168.0.160
ssh $SSHOPTS $PC 'bash -s' <<'EOF'
mkdir -p ~/Desktop
APPDIR=/run/current-system/sw/share/applications
for f in aeon-dashboard aeon-focus aeon-unfocus aeon-vm aeon-win aeon-update firefox kitty steam org.kde.dolphin; do
  [ -f "$APPDIR/$f.desktop" ] && cp "$APPDIR/$f.desktop" ~/Desktop/ && chmod +x ~/Desktop/"$f.desktop"
done
echo "=== Desktop-Icons ==="; ls ~/Desktop
pkill -f "ollama pull" 2>/dev/null; sleep 1
setsid sh -c 'ollama pull qwen2.5:3b > /tmp/aeon-pull.log 2>&1' >/dev/null 2>&1 </dev/null &
sleep 5
echo "=== TRON-Modell-Download ==="; pgrep -af "ollama pull" | head -1; tail -n2 /tmp/aeon-pull.log
EOF
