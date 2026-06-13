# AEON — Roadmap

*Von null zum laufenden Life-OS. Stand 12. Juni 2026*

Jede Phase ist abgeschlossen nutzbar („Definition of Done" = DoD). Reihenfolge bewusst risikoarm: erst Netz, dann der Pi als Spielwiese, dann Design, dann die Alltagsgeräte, dann Intelligenz.

---

## Phase 0 — Fundament: das Mesh · ~1 Abend
Alle Geräte in *ein* privates Netz.

- Tailscale-Account anlegen, App auf **Pi, Mac, Windows-PC, iPhone** installieren & einloggen
- MagicDNS aktivieren, Geräte sinnvoll benennen (`aeon-pi`, `aeon-mac`, `aeon-win`, `aeon-phone`)
- Tailscale-SSH auf dem Pi aktivieren

**DoD:** Von jedem Gerät erreichst du jedes andere per Name (z.B. `ssh aeon-pi`). 🔓 Blockiert alles Weitere.

---

## Phase 1 — Pi als Hub (Raspberry Pi OS bleibt!) · ~1 Wochenende
Der Pi bleibt **genau wie er ist** — AEON kommt als Container-Stack *obendrauf*. Kein Flashen, nichts wird überschrieben.

- Docker (+ Compose) auf dem bestehenden Raspberry Pi OS installieren (falls noch nicht da)
- AEON-Repo initialisieren: `docker-compose` + Configs = „dein OS als Code" → *Scaffold liegt bereits vor*
- Repo privat nach GitHub pushen
- Basis-Dienste hochfahren: `docker compose up -d` (startet mit Tailscale + Vitals-API)

**DoD:** Der Container-Stack läuft neben deinen bestehenden Diensten; nichts Vorhandenes wurde angetastet; Repo steht. *Abhängig von Phase 0.*

---

## Phase 2 — Design wird real · ~1 Wochenende
Deine Designsprache verlässt das Mockup — ohne Stylix-Zwang.

- **AEON-Dashboard** (Web-App, vom Pi serviert) trägt das volle Design → Hauptträger der Identität
- Terminal/Editor-Theming via **Dotfiles** (base16-Tokens aus dem Design-System) — auf dem Mac über home-manager verwaltet, auf dem Pi als Config-Files
- Fonts (Newsreader, Inter, IBM Plex Mono) installieren
- *(Stylix nur, falls ein Gerät später freiwillig NixOS bekommt — kein Muss.)*

**DoD:** Das Dashboard sieht aus wie das Design-System; Terminal trägt die AEON-Farben. *Abhängig von Phase 1.*

---

## Phase 3 — Mac einbinden · ~1 Wochenende
Dein Alltagsgerät kommt ins System.

- nix-darwin + home-manager installieren
- geteilte Module (Tools, Dotfiles, Theme) aus dem Repo importieren
- AEON-Look auf Terminal/Editor des Macs
- optional: UTM-Linux-VM als „echtes NixOS to go"

**DoD:** Mac fühlt sich wie der Pi an — gleiche Tools, gleicher Look, eine Config. *Abhängig von Phase 2.*

---

## Phase 4 — Windows-PC: das Flaggschiff (Dual-Boot NixOS) · ~1–2 Wochenenden
Der Power-Node wird zur ersten echten AEON-OS-Maschine. **Windows bleibt** per Dual-Boot. → *Details: `AEON-Windows-PC.md`*

- Pre-Flight: Backup · BitLocker aus · Schnellstart aus · Secure Boot aus
- Windows-Partition **sicher verkleinern** (nichts löschen), freien Raum schaffen
- NixOS in den freien Raum installieren (`hosts/aeon-rig`), systemd-boot erkennt Windows
- RX 6800 nativ: amdgpu, Steam/Proton (Gaming), ROCm/Ollama (lokale LLM)
- **Sunshine** auf dem PC + **Moonlight** auf Mac/iPhone → Streaming testen

**DoD:** Du bootest wahlweise AEON oder Windows; auf AEON laufen ein Proton-Game und Ollama auf der GPU; Streaming aufs iPhone klappt. *Abhängig von Phase 1 (für Repo/Theme/Tailscale).*

---

## Phase 5 — Die Modi · ~1 Wochenende
Focus / Gaming / Work als echte Zustände.

- Profile/Specialisations für die drei Modi
- **Focus-Modus:** App-Whitelist (Anki, Notion, Amboss, Browser, Perplexity) + DNS-Block ablenkender Domains via Pi-hole auf dem Pi
- Schneller Moduswechsel (Shortcut/Befehl)

**DoD:** Ein Befehl schaltet den Modus; im Focus-Modus sind Ablenkungen real blockiert. *Abhängig von Phase 2–3.*

---

## Phase 6 — TRON & Daten (das Gehirn) · ~2 Wochenenden
Aus dem System wird ein Assistent.

- **Ollama** auf dem Windows-PC (RX 6800), Modell laden (z.B. Qwen 2.5 14B); Wake-on-LAN vom Pi
- **Vitals-Pipeline:** Health Auto Export (iPhone) → Webhook an den Pi → kleine DB; AnkiConnect für Streak; Fokus-Zeit aus Modus-Sessions
- **TRON:** Agent-Layer auf dem Pi, der die LLM nutzt, Tasks an Sub-Agents delegiert, Briefings baut
- **Dashboard** mit echten Live-Vitals (das finale Design)
- Daily Briefing automatisch (Kalender via iCloud-CalDAV + To-dos + Lernpensum)

**DoD:** Morgens kommt ein echtes Briefing; das Dashboard zeigt Live-Werte; TRON beantwortet Fragen & erledigt eine erste Routine. *Abhängig von Phase 1, 4, 5.*

---

## Phase 7 — OTA & Veredelung · laufend
Das System wartet & verbessert sich selbst.

- **Forgejo** (eigenes Git) auf dem Pi + **comin** → Git-Push deployt automatisch (echte OTA-Updates mit Rollback)
- **Nextcloud** auf dem Pi → iPhone-Sync (Dateien, Kalender, Kontakte)
- **Apple Shortcuts** als Trigger („Hey Siri, Lernmodus an")
- Automatische Backups & nächtliche Updates

**DoD:** Du commitest eine Änderung → alle Geräte ziehen sie automatisch. AEON läuft. *Abhängig von Phase 6.*

---

## Reihenfolge auf einen Blick

```
0 Mesh ─▶ 1 Pi+Repo ─▶ 2 Design ─▶ 3 Mac ─▶ 5 Modi ─▶ 6 TRON+Daten ─▶ 7 OTA
                       └─▶ 4 Windows+Gaming ─┘                ▲
                                  └───────────────────────────┘
```

**Jetzt zuerst:** Phase 0 (Mesh) + Phase 1 (Pi + Repo). Das Repo-Scaffold liegt bereit — du musst es nur auf echte Hardware bringen.
