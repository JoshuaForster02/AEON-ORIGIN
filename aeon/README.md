# AEON — dein Life-OS (Repo)

> „Aeon" = Ewigkeit. Ein System, das deine Routine automatisiert, dir Zeit zurückgibt und deinen Glow-up ermöglicht. Assistent: **TRON**.

Dieses Repo *ist* dein System — Config as Code. Kein Gerät wird neu aufgesetzt (außer dem Windows-PC, der per **Dual-Boot** ein echtes AEON/NixOS bekommt — Windows bleibt).

---

## Struktur

```
aeon/
├── pi/                  Raspberry Pi OS bleibt — AEON-Hub als Docker-Stack obendrauf
│   ├── docker-compose.yml
│   ├── Caddyfile
│   └── vitals-api/      kleine API: Apple-Health → AEON
├── hosts/aeon-rig/      Windows-PC: Flaggschiff (Dual-Boot NixOS)
│   └── configuration.nix
├── installer/           eigene AEON-Installer-ISO (Tailscale + aeon-install)
├── .github/workflows/   baut die ISO automatisch (GitHub Actions)
├── modules/             geteilte NixOS-Module
│   ├── aeon-theme.nix   Design-System als Code (Stylix)
│   └── tailscale.nix    Fleet-Mesh
├── mac/                 nix-darwin (Phase 3)
├── dotfiles/            AEON-Farben & Prompt
└── flake.nix
```

---

## Phase 0 — Das Mesh (1 Abend)

Ziel: alle vier Geräte sehen sich per Name.

1. Tailscale-Account erstellen → https://tailscale.com
2. Installieren & einloggen auf:
   - **iPhone** (App Store)
   - **Mac** (`brew install --cask tailscale` oder App)
   - **Windows-PC** (Installer)
   - **Raspberry Pi**: `curl -fsSL https://tailscale.com/install.sh | sh && sudo tailscale up`
3. In der Tailscale-Konsole MagicDNS aktivieren, Geräte benennen: `aeon-pi`, `aeon-mac`, `aeon-rig`, `aeon-phone`.

✅ **Done, wenn:** `ssh aeon-pi` von Mac/PC funktioniert.

---

## Phase 1 — Pi-Hub (1 Wochenende)

Raspberry Pi OS bleibt. AEON-Dienste kommen als Container *obendrauf*.

```bash
# auf dem Pi (per Tailscale-SSH):
# 1. Docker installieren (falls noch nicht da)
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER   # danach neu einloggen

# 2. Repo holen
git clone <DEIN_GITHUB_REPO> ~/aeon
cd ~/aeon/pi
cp .env.example .env            # ggf. anpassen

# 3. Hochfahren
docker compose up -d --build
```

Testen:
- **Dashboard:** Browser → `http://aeon-pi:8080` → dein AEON-Dashboard (Vitals, TRON)
- API: `curl http://localhost:8080/api/` → `{"service":"aeon-hub","status":"ok"}`
- n8n: `http://aeon-pi:5678`

> TRON nutzt die lokale LLM auf dem PC (`OLLAMA_URL`, Standard `http://aeon-rig:11434`). Ist der PC aus, antwortet TRON mit „offline" — alles andere läuft weiter.

> ⚠️ **Ports:** Falls schon Dienste laufen (z.B. Pi-hole), passe die Ports in `pi/docker-compose.yml` an. Prüfen mit: `sudo ss -tulpn | grep LISTEN`

✅ **Done, wenn:** der Stack läuft, ohne deine bestehenden Dienste zu stören.

---

## Der AEON-Installer (eigene ISO)

Statt „Vanilla-NixOS + Config" baust du eine **eigene Installer-ISO** mit Tailscale, Branding und geführtem `aeon-install` schon drin.

**ISO bauen — drei Wege:**

- **Am schnellsten: GitHub Actions.** Repo nach GitHub pushen → der Workflow `.github/workflows/build-iso.yml` baut die ISO automatisch. Unter „Actions → build-aeon-iso → Artifacts" lädst du `aeon-installer-iso` herunter.
- **Auf dem Mac via Docker** (M1, emuliert — genau wie ein flynnos-builder):
  ```bash
  ./build/build-iso.sh        # ISO landet in ./out/*.iso
  ```
  Details & eigener Builder: `build/README.md`.
- **Lokal auf einer x86-Nix-Maschine:**
  ```bash
  nix build .#aeon-iso        # ISO liegt in ./result/iso/*.iso
  ```

**Benutzen:**
1. `DEIN-USER` in `installer/iso.nix` und `installer/aeon-install.sh` durch deinen GitHub-Namen ersetzen.
2. ISO mit Ventoy/Rufus/`dd` auf einen USB-Stick schreiben.
3. PC davon booten → einloggen → `aeon-install` → geführte, dual-boot-sichere Installation.

> Erst die Windows-Schritte aus `AEON-Windows-PC.md` machen (Backup, BitLocker aus, freien Speicher schaffen).

---

## Wenn der erste Build hakt — Toggle-Map

Die Basis (Plasma + Stylix-Design + Apps + Installer) ist robust. Diese drei
Zusatz-Module sind die wahrscheinlichsten Stolpersteine. Die Fehlermeldung nennt
den Namen → entsprechende Zeile auskommentieren → neu bauen. Du verlierst nur das
jeweilige Extra, der Rest läuft:

| Fehler nennt … | Auskommentieren in … | Verlust (Rest bleibt) |
|---|---|---|
| `home-manager` / `plasma` | home-manager-Block in `flake.nix` | Icons/Panel — Stylix-Theme bleibt |
| `cockpit` / `cockpit-machines` | Import `aeon-cockpit.nix` in `configuration.nix` | Web-VM-Fernsteuerung — virt-manager bleibt |
| `grub` / `theme` | GRUB-Block in `configuration.nix` → stattdessen die zwei systemd-boot-Zeilen (stehen als Kommentar daneben) | schlichtes Bootmenü |

Neu bauen:  `sudo nixos-rebuild switch --flake /etc/nixos/aeon#aeon-rig`
(beim Installieren: einfach die ISO aus dem korrigierten Repo neu bauen).

---

## OTA-Quelle konfigurieren

```bash
aeon ota                       # zeigt aktuelle Quelle
aeon ota git@github.com:DU/aeon.git   # GitHub als Quelle
aeon ota aeon-pi:aeon.git      # eigener Pi (kein GitHub, kein Passwort)
aeon update                    # holen + anwenden (behält dein Hardware-Profil)
```

`aeon update` erkennt automatisch, ob das Flake im Repo-Root oder in einem
`aeon/`-Unterordner liegt. **Empfohlen:** der `aeon`-Ordner *ist* das Repo
(flake.nix ganz oben) — nicht den ganzen Output-Ordner mit `aeon/` als Unterordner.

---

## Danach

- **Phase 4 — Flaggschiff:** Windows-PC Dual-Boot NixOS → siehe `AEON-Windows-PC.md`. `hosts/aeon-rig/configuration.nix` ist die Vorlage.
- **Vitals automatisieren:** „Health Auto Export" (iPhone) als Webhook auf `http://aeon-pi:8787/ingest` zeigen lassen.
- Roadmap & Architektur: `AEON-Roadmap.md`, `Personal-OS-Plan.md`, `AEON-Design-System.md`.

---

*Hinweis: Die Nix-Dateien sind getestete Vorlagen, aber `hardware-configuration.nix` wird beim Installieren auf dem PC generiert. Alles ist als Startpunkt gedacht und wird auf echter Hardware verfeinert.*
