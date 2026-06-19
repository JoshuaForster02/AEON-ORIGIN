# AEON auf den PC bringen — Zero to Installed

Der komplette Weg vom Repo zur installierten AEON-OS auf deinem Windows-PC.
Windows bleibt (Dual-Boot). Nimm dir ~1–2 Stunden + Build-Zeit.

---

## Schritt 1 — Repo auf GitHub (einmalig, am Mac)

```bash
cd ~/Downloads/aeon
# DEIN-USER überall ersetzen:
grep -rl 'DEIN-USER' . | xargs sed -i '' 's/DEIN-USER/deingithubname/g'   # macOS
git init && git add -A && git commit -m "AEON: initial"
gh repo create aeon --private --source=. --remote=origin --push
```

## Schritt 2 — ISO bauen lassen

**Einfach (GitHub Actions):** Push hat den Build schon gestartet.
GitHub → Repo → „Actions" → `build-aeon-iso` → unten „Artifacts" → `aeon-installer-iso` laden, entpacken → `aeon-*.iso`.

**Oder am Mac (Docker):** `./build/build-iso.sh` → ISO in `./out/`.

## Schritt 3 — Windows vorbereiten (am PC)

> Reihenfolge wichtig — siehe `AEON-Windows-PC.md` für Details.

1. **Backup** wichtiger Daten.
2. **BitLocker** aussetzen/deaktivieren (Recovery-Key sichern!).
3. **Schnellstart** aus (Energieoptionen).
4. **Datenträgerverwaltung** → C: verkleinern → 200–500 GB „nicht zugeordnet" lassen.
5. **BIOS:** Secure Boot aus.

## Schritt 4 — ISO auf USB

Mit Ventoy (ISO einfach draufkopieren), Rufus oder `dd`. Vom Stick booten.

## Schritt 5 — Installieren

Im AEON-Installer einloggen, dann:

```bash
aeon-install
```

Das geführte Skript: zeigt deine Platten → du legst im freien Raum root (+ optional swap) an → bindet die Windows-EFI ein (ohne sie zu formatieren) → installiert AEON.

## Schritt 6 — Erster Start

- Boot-Menü zeigt **AEON** und **Windows**.
- Login: `joshua` / `aeon` → sofort `passwd` (Passwort ändern).
- Mesh verbinden: `sudo tailscale up`.
- Du landest im KDE-Plasma-Desktop im **AEON-Look** (Stylix-Theme + Wallpaper), mit Firefox, Anki, Steam, Ollama (auf der RX 6800), Sunshine.

---

## Updates später (OTA)

```bash
cd /etc/nixos/aeon && git pull
sudo nixos-rebuild switch --flake .#aeon-rig
```
(Siehe `AEON-Git-OTA.md`.)

---

## Wenn der erste Build hakt

Die Nix-Configs sind sorgfältige Vorlagen, aber erst der echte Build zeigt jedes Detail.
Häufige Stellen: Branch-Namen der Inputs (`flake.nix`), Stylix-Optionen, ein Paketname.
Schick mir einfach die Fehlerausgabe von Actions/`nixos-install` — ich fixe es gezielt,
du machst `git push`, neuer Build. Genau dafür ist die OTA-Schleife da.
