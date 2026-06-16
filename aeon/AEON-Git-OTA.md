# AEON — Git & OTA per Terminal

Das Repo ist dein OTA-System: **push → Geräte ziehen → fertig.** Hier alle Befehle.

> **Wichtig zur Auth:** Git funktioniert für OTA völlig normal. Der Fehler
> „password auth is not supported" kommt **nur von GitHub** — die akzeptieren seit
> 2021 kein Passwort mehr, nur Token/SSH. Drei Wege:
> 1. **Eigenes Git auf dem Pi** (empfohlen, kein GitHub, keine Passwörter — s.u.)
> 2. GitHub mit `gh auth login` (Browser-Login)
> 3. GitHub mit SSH-Key

---

## 0. Empfohlen: eigenes Git auf dem Pi (kein GitHub nötig)

Der Pi wird deine OTA-Quelle. **Tailscale-SSH** authentifiziert dich automatisch
über deine Tailnet-Identität — keine Schlüssel, keine Passwörter.

```bash
# 1) auf dem Pi: leeres Repo anlegen
ssh aeon-pi 'git init --bare ~/aeon.git'

# 2) am Mac (im aeon-Ordner): Pi als Remote + erster Push
git init && git add -A && git commit -m "AEON: initial"
git remote add origin aeon-pi:aeon.git
git push -u origin main

# 3) OTA-Alltag: ändern → veröffentlichen
git add -A && git commit -m "…" && git push

# 4) auf einem Gerät (z.B. Flaggschiff): Update holen
cd /etc/nixos/aeon && git pull && sudo nixos-rebuild switch --flake .#aeon-rig
```

Damit läuft OTA komplett über deine eigene Hardware — unabhängig von Big Tech.
*(GitHub bleibt als Variante unten möglich, falls du es doch willst.)*

---

## 1. Einmalig: Repo anlegen & pushen

Auf dem Mac, im entpackten `aeon/`-Ordner:

```bash
cd ~/Downloads/aeon          # dorthin, wo du aeon.zip entpackt hast

git init
git add -A
git commit -m "AEON: initial"
```

**Variante A — mit GitHub CLI (am schnellsten):**

```bash
brew install gh              # falls noch nicht da
gh auth login                # einmal anmelden
gh repo create aeon --private --source=. --remote=origin --push
```

**Variante B — manuell:** Auf github.com ein **privates** Repo `aeon` anlegen (ohne README), dann:

```bash
git branch -M main
git remote add origin git@github.com:DEIN-USER/aeon.git
git push -u origin main
```

> Danach in `installer/iso.nix`, `installer/aeon-install.sh` und `.github/workflows`/Skripten `DEIN-USER` durch deinen GitHub-Namen ersetzen, dann committen & pushen.

---

## 2. Der OTA-Alltag (etwas ändern → veröffentlichen)

```bash
# … Dateien ändern …
git add -A
git commit -m "kurz was geändert wurde"
git push
```

Das ist die „Veröffentlichung". Ab hier können alle Geräte die Änderung ziehen.

---

## 3. Wenn ICH (Claude) später etwas ändere

Ich kann nicht direkt in dein privates Repo schreiben. Der Weg:

1. Ich gebe dir die geänderten Dateien (neues `aeon.zip` oder einzelne Files).
2. Du legst sie über deinen lokalen `aeon/`-Ordner (gleiche Pfade überschreiben).
3. Veröffentlichen:
   ```bash
   cd ~/Downloads/aeon
   git add -A
   git diff --cached --stat      # zeigt, was sich ändert (Kontrolle)
   git commit -m "AEON: Update von Claude"
   git push
   ```

> Optional später: Wenn du den **GitHub-Connector** freigibst, kann ich Änderungen direkt als Commit/Pull-Request einstellen — dann entfällt das manuelle Kopieren.

---

## 4. Geräte ziehen die Updates

**Pi-Hub (Docker):**
```bash
ssh aeon-pi
cd ~/aeon && ./pi/update.sh        # = git pull + docker compose up -d --build
```

**Flaggschiff (NixOS):**
```bash
cd ~/aeon && git pull
sudo nixos-rebuild switch --flake .#aeon-rig
```

**Installer-ISO:** GitHub Actions baut bei jedem Push automatisch eine neue ISO (Artifacts), oder lokal `./build/build-iso.sh`.

---

## 5. Auto-OTA (optional, später)

Pi alle 15 Min selbst aktualisieren lassen — `crontab -e`:
```
*/15 * * * * /home/USER/aeon/pi/update.sh >> /var/log/aeon-update.log 2>&1
```
(Erst aktivieren, wenn du dem Stack vertraust — sonst lieber manuell `update.sh`.)

---

## Spickzettel

```bash
git status            # was ist geändert?
git add -A            # alles vormerken
git commit -m "..."   # festschreiben
git push              # veröffentlichen (OTA)
git pull              # auf einem Gerät: Update holen
git log --oneline -5  # letzte Änderungen
git revert HEAD       # letzten Commit sicher rückgängig (Rollback)
```
