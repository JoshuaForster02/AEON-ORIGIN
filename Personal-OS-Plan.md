# Personal-OS / Fleet — Plan & Brainstorm

*Stand: 12. Juni 2026 · Joshua*

---

## 1. Wofür? (Die Mission)

> **AEON — ein persönliches Life-OS.** Ein System, das deine Routine automatisiert, dir Zeit für die wichtigen Dinge zurückgibt und deinen Glow-up aktiv ermöglicht. *(„Aeon" = Ewigkeit — etwas bauen, das bleibt.)*

> Der Assistent darin heißt **TRON** — der Agent, der Tasks erledigt und dafür eigene Sub-Agents starten kann.

Technisch dahinter: ein **persönliches Geräte-Ökosystem**, in dem Mac (M1 Pro / ARM), Windows-PC (Ryzen + RX 6800 / x86), iPhone und Raspberry Pi *eine* einheitliche, selbstverwaltete Umgebung teilen — über Tailscale vernetzt, mit zentralem Sync, Remote-Zugriff auf die Power-Hardware und **selbst veröffentlichten OTA-Software-Updates** (mit automatischem Rollback).

Es geht **nicht** darum, einen Kernel from scratch zu schreiben. Es geht darum, dass sich alle deine Geräte wie *ein System* anfühlen, das *für dich arbeitet* — ein Mini-Fleet-Management plus Assistenz-Schicht für dein eigenes Leben.

**Die Schichten dienen alle der Mission:**
- Der **Agent (TRON)** automatisiert, brieft & erledigt Tasks → *gibt Zeit zurück*
- Die **Modi** (Focus/Gaming/Work) schützen deinen Fokus → *Glow-up*
- Das **Design** macht es zu *deinem* System → *Identität & Freude an der Nutzung*
- Die **Infrastruktur** (Nix/Tailscale/Sync) macht alles robust & überall verfügbar

### Deine zwei Haupttreiber (deine Antwort: „1 und 2")
1. **Überall die gleiche Umgebung + Daten** → Konsistenz & Sync
2. **Von überall auf die Power-Hardware** → Remote-Zugriff auf PC & Pi

### Konkrete Zwecke (das, wofür du es täglich nutzt)
- 🎯 **Lernen** im abgeschotteten Focus-Modus (Anki, Notion, Amboss, Browser, Perplexity)
- 🎮 **Gaming** von Windows-Games — lokal auf dem PC oder gestreamt auf Mac/iPhone
- 🎨 **Eigene Design-Identität**, die auf allen Geräten konsistent & richtig gut aussieht

Beides + alles liefert die unten beschriebene Architektur direkt.

---

## 2. Warum? (Die 3 Wege — Vor- & Nachteile)

Du wolltest „ein bisschen von allem" und kennst die Trade-offs noch nicht. Hier sind sie, ehrlich:

### Weg A — Reproduzierbare Umgebung (NixOS / deklarative Config)
**Idee:** Eine einzige Text-Config (in Git) beschreibt *jedes* Gerät komplett. Ein Befehl baut den exakten Zustand. macOS/Windows bleiben als Host bestehen, aber deine *Umgebung* ist überall identisch.

| ✅ Vorteile | ⚠️ Nachteile |
|---|---|
| Echte „OTA-Updates": du pushst nach Git, Geräte ziehen & bauen atomar um | Nix hat eine steile Lernkurve (eigene Sprache) |
| Atomares Rollback — kaputtes Update? Ein Reboot zurück | macOS/Windows lassen sich nicht *ersetzen*, nur der Layer drüber |
| Kostenlos, extrem mächtig, ein Repo = „dein OS" | Anfangs mehr Tüfteln als Klick-Komfort |

### Weg B — Echtes eigenes OS / Distro from scratch
**Idee:** Eigener Kernel-Build, eigene Distro, eigene Images für ARM + x86.

| ✅ Vorteile | ⚠️ Nachteile |
|---|---|
| Maximales Lernen, volle Kontrolle | Realistisch unbezahlbar an Zeit |
| „Cool"-Faktor | Du müsstest Treiber neu erfinden — die **RX 6800** bräuchte funktionierende GPU-Treiber (riesig) |
| | Kein praktischer Alltagsnutzen |

**Verdikt:** Nicht als Hauptprojekt. Wenn dich der OS-Bau-Juckreiz packt → als abgekapselte Lern-Spielwiese in einer VM (z.B. ein OS-Dev-Tutorial), getrennt vom Alltagssystem.

### Weg C — Self-hosted Personal-Cloud-Layer
**Idee:** OS bleibt macOS/Windows. Du baust eigene Dienste drüber: zentrale Daten, Sync, Apps, Zugriff — deine private Cloud (auf dem Pi).

| ✅ Vorteile | ⚠️ Nachteile |
|---|---|
| Einfacher Handy-Zugriff (fertige Apps) | Weniger „ein einheitliches OS", eher Service-Sammlung |
| Schnelle sichtbare Ergebnisse | Kein gemeinsamer „OTA"-Update-Mechanismus für die Geräte selbst |

### 👉 Empfehlung: **Hybrid** (= dein „bisschen von allem")
- **Konsistenz-Gefühl & OTA-Updates** → Weg A (Nix als Herzstück)
- **Handy-Zugriff & private Cloud** → Weg C (Dienste auf dem Pi)
- **OS-Bau-Lernen** → Weg B nur als optionale Seitenquest in einer VM

Nix ist deshalb so passend, weil „selbst Updates veröffentlichen mit Rollback" bei NixOS *eingebaut* ist: Du pushst einen Git-Commit, die Geräte konvergieren auf den neuen Zustand. Das **ist** dein OTA-System.

---

## 3. Wie? (Die Architektur in 6 Schichten)

```
                ┌─────────────────────────────────────────────┐
   Git-Repo ───▶│  „DEIN OS" = 1 Nix-Flake (alle Geräte drin)  │
 (OTA-Quelle)   └─────────────────────────────────────────────┘
                                  │  push → pull → atomarer Switch
        ┌─────────────┬───────────┼───────────┬─────────────┐
        ▼             ▼           ▼           ▼             ▼
   Raspberry Pi   Mac M1 Pro   Windows-PC    Linux-VM    iPhone
  (RasPiOS+Docker)(nix-darwin)(NixOS⇄Windows)(UTM, opt.) (Client)
                              ★ Flaggschiff
        └──────────────── alle im selben Tailscale-Mesh ──────┘
              + Syncthing/Nextcloud (Daten)  + SSH/Remote (Zugriff)
```

### Schicht 1 — Netzwerk: **Tailscale** (das Rückgrat)
Alle Geräte in einem privaten Mesh (Tailnet). MagicDNS (Geräte per Name erreichbar), Tailscale-SSH, ACLs. Funktioniert durch NAT/Firewalls hindurch, egal wo du bist. Der Pi kann als „Exit Node" / Subnet-Router dienen.

### Schicht 2 — Config: **Ein Git-Repo = dein OS**
Dein Repo enthält pro Gerät die Config: **docker-compose** für den Pi (Raspberry Pi OS bleibt!), **Nix-Flake/home-manager** für Mac & (optional) WSL, geteilte **Dotfiles** (Terminal, Tools, AEON-Farben) für alle. Kein Gerät wird neu aufgesetzt — AEON liegt *obendrauf*. Das Repo IST das System.

### Schicht 3 — OTA-Updates: **GitOps**
Du commitest eine Änderung → Geräte ziehen sie & wenden sie an.
- **Pi (Docker):** Git-Pull + `docker compose up -d` (per Cron/Webhook oder Watchtower) → Dienste aktualisieren sich automatisch.
- **Mac/WSL (Nix):** `home-manager switch` bzw. optional `comin`/`deploy-rs` für NixOS-Geräte.
- **Rollback:** Docker per Image-Tag/Git-Revert; Nix per Generation. Immer ein Schritt zurück möglich.

### Schicht 4 — Sync/Daten: **Syncthing** (+ optional **Nextcloud** auf dem Pi)
- **Syncthing:** P2P-Datei-Sync zwischen allen Geräten, läuft über Tailscale, keine fremde Cloud.
- **Nextcloud auf dem Pi:** falls du fürs Handy eine bequeme App + Kalender/Kontakte willst (cloud-like, aber deins).

### Schicht 5 — Zugriff: **SSH + Remote Desktop**
- **Tailscale-SSH** überall → Terminal von jedem Gerät.
- **Windows-PC (RX 6800):** RDP, oder für GPU-Desktop/Streaming **Sunshine + Moonlight** (latenzarm, nutzt die GPU).
- **Pi** als Always-on-Hub / Sprungbrett.

### Schicht 6 — Handy
Tailscale-App + Syncthing/Nextcloud-App + SSH-Client (+ Moonlight, falls du den PC-Desktop streamst). Damit ist das Handy vollwertiger Client im Mesh.

---

## 3a. Agenten- & Automatisierungs-Schicht (TRON)

Die oberste Schicht — orchestriert auf dem **Pi** (24/7 an), erreichbar von überall per iPhone. Sie nimmt dir Arbeit ab und unterstützt aktiv deinen Glow-up.

**Bausteine:**
- **TRON (Primär-Agent):** dein Assistent, der Briefings gibt, Modi schaltet, Fragen beantwortet — und **Tasks an Sub-Agents delegiert** (Recherche, Aufräumen, Daten holen, Routinen).
- **Lokale LLM auf der RX 6800:** TRONs Denkzentrum. **Ollama / LM Studio** auf dem Windows-PC (16 GB VRAM → Qwen 2.5 14B/32B-quant, Llama 3.1 8B). Pi weckt den PC bei Bedarf (Wake-on-LAN); PC aus → Fallback auf Cloud-API.
- **Automatisierungs-Engine:** n8n / Home Assistant auf dem Pi → Workflows („07:00 & Wochentag → Focus-Modus + Briefing"), Routinen, Trigger.
- **Glow-up-Dashboard (Vitals):** Lern-Streak, Fokus-Zeit, Schlaf, Training, Ziele — automatisch zusammengetragen.
- **Daily Briefing:** morgens automatisch — Kalender, To-dos, Lernpensum, „Fokus heute".

**Datenquellen für die Vitals (alles automatisiert):**
| Vital | Quelle | Weg |
|---|---|---|
| Schlaf, Training, HRV, Schritte, Gewicht | **Apple Health** (Strong schreibt Workouts dort rein) | **Health Auto Export** App → REST/Webhook an AEON, oder Apple Shortcut (zeitgesteuert) |
| Lern-Streak / Karten | **Anki** | AnkiConnect-API → AEON |
| Fokus-Stunden | **AEON selbst** | misst Focus-Modus-Sessions automatisch |
| Hantel-Detail (PRs, Volumen) | **Strong** | CSV-Export (optional, für Tiefenstatistik) |

**Apple-Ökosystem-Integration:**
- ✅ **Kalender · Erinnerungen · Kontakte** → via CalDAV/CardDAV über iCloud (App-spezifisches Passwort). JARVIS liest & schreibt → Termine im Briefing, automatische Reminder.
- ✅ **Apple Shortcuts** → der Glue: ein Kurzbefehl triggert JARVIS-Webhooks („Hey Siri, Lernmodus an" → Pi schaltet Focus-Modus).
- ✅ **Push aufs iPhone** → ntfy/Pushover für JARVIS-Benachrichtigungen.
- ⚠️ **Apple Notizen** → keine offene API. Lösung: Mac-Agent (AppleScript) ODER Notion als JARVIS-Wissensebene (Empfehlung), Apple Notes für Privates/Schnelles.

**Beispiel-Automationen, die Zeit zurückgeben:**
- Auto-Sync & Backup im Hintergrund · OTA-Updates nachts einspielen
- „Lern-Block startet" → Focus-Modus an, Ablenkungen aus, Anki-Reminder
- Wochenrückblick: „Du hast X Karten gelernt, Y h fokussiert" → Selbstreflexion
- Abwesenheits-/Anwesenheits-Trigger (Standort iPhone) → Geräte vorbereiten

---

## 3b. Modi / Profile (die Seele des Systems)

Ein Gerät, mehrere Kontexte. Jeder Modus ist ein vordefinierter Zustand (über Nix-Specialisations bzw. Session-Profile umschaltbar).

| Modus | Was läuft | Was ist blockiert | Wo |
|---|---|---|---|
| 🎯 **Focus / Lernen** | Anki · Notion · Amboss · Browser · Perplexity | Games, Social, ablenkende Domains (DNS-/Firewall-Block) | Jedes Gerät |
| 🎮 **Gaming** | Steam/Proton, Game-Launcher, Discord | — | PC (lokal) · gestreamt auf Mac/iPhone via Moonlight |
| 💻 **Normal / Work** | Volle Umgebung, alle Tools | — | Jedes Gerät |

**Focus-Modus konkret:** eigene Session/User-Profil mit App-Whitelist + Sperre ablenkender Domains auf Netzwerkebene (z.B. via Pi-hole/DNS auf dem Pi). „Aus dem Lernen ausbrechen" wird bewusst unbequem.

---

## 3c. Design-System (deine visuelle Identität)

Das Herz: **Stylix** (NixOS). Du definierst *einmal* zentral:
- **Farbpalette** (base16-Schema, 16 Farben) → wird auf *alle* Apps angewandt
- **Typografie** (Mono- & UI-Schrift)
- **Wallpaper / Akzente / Iconographie**
- **Window-Manager-Look** (Abstände, Rundungen, Leiste)

Stylix propagiert das systemweit: Terminal, Editor, Browser-Theme, GTK/Qt-Apps, Login-Screen — alles aus *einer* Quelle. Ergebnis: jedes NixOS-Gerät trägt dieselbe Handschrift. Auf macOS theme'n wir Terminal + Editor passend mit, sodass auch der Mac sich „nach dir" anfühlt.

**Noch zu definieren (= das, was wir zusammen ausarbeiten):**
Name/Vibe · Stimmung (hell/dunkel/kontrastreich) · Leitfarbe(n) · Schrift-Charakter · Ästhetik-Richtung. → siehe Design-Frage unten.

---

## 4. Reality-Check zur RX 6800 (wichtig!)

Wenn die RX 6800 unter deiner *einheitlichen Linux-Umgebung* nutzbar sein soll, gibt es zwei saubere Wege:
- **Dual-Boot NixOS** auf dem Windows-PC → volle GPU-Power nativ unter Linux. (Empfohlen, wenn die GPU unter Linux laufen soll.)
- **Windows bleibt** + du remotest rein / streamst → GPU bleibt bei Windows.

**Nicht empfohlen:** GPU-Passthrough in eine VM auf einem Single-GPU-Desktop — das ist fummelig und frustrierend. Auf dem Mac läuft eine Linux-VM (UTM) gut für die *Umgebung*, aber **ohne** echte GPU-Beschleunigung der RX (die steckt ja im PC, nicht im Mac).

---

## 5. Roadmap (Phasen — jede ein abgeschlossenes Etappenziel)

| Phase | Ziel | Aufwand |
|---|---|---|
| **0 — Fundament** | Tailscale auf allen 4 Geräten, alle sehen sich per Name | 1 Abend |
| **1 — Pi als Hub** | NixOS auf dem Pi, Config in Git → wird die Vorlage | 1 Wochenende |
| **2 — Mac rein** | nix-darwin + home-manager, Module mit Pi teilen; UTM-VM optional | 1 Wochenende |
| **3 — Windows rein** | NixOS-WSL für die Dev-Umgebung; Windows bleibt für Gaming/GPU (oder Dual-Boot NixOS) | 1 Wochenende |
| **4 — OTA-Pipeline** | Self-hosted Forgejo/Gitea auf dem Pi + `comin` → du „veröffentlichst Updates" | 1 Wochenende |
| **5 — Sync & Dienste** | Syncthing/Nextcloud, Remote-Desktop, Feinschliff | laufend |

Reihenfolge bewusst so: erst Vernetzung, dann der Pi als ungefährlichste Lernfläche, dann die Alltagsgeräte, **dann** die OTA-Pipeline (wenn du Nix schon ein bisschen kennst).

---

## 6. Entscheidungen

**Bereits geklärt:**
- ✅ **Handy = iPhone / iOS** → Sync über **Nextcloud** (statt Syncthing, das auf iOS eingeschränkt ist) + SSH-App (z.B. Termius/Blink) + Tailscale-App.
- ✅ **Windows-PC = Dual-Boot NixOS (Flaggschiff)**, sichere Partitionierung, Windows bleibt für Anti-Cheat-Games. RX 6800 läuft nativ unter AEON (Gaming via Proton, LLM via ROCm). → Details: `AEON-Windows-PC.md`.

**Noch offen:**
1. **Git-Quelle: self-hosted auf dem Pi (max. unabhängig) oder GitHub (einfacher Start)?**
2. **Updates: lieber Pull (automatisch) oder Push (du drückst den Knopf)?**
3. **Wie tief soll's gehen?** Reicht „fühlt sich überall gleich an", oder willst du den vollen GitOps-OTA-Mechanismus mit Auto-Deploy?

*(Vorschlag für 1 & 2: mit GitHub starten + Push-Modus — am einfachsten zum Lernen; später auf self-hosted Forgejo + Pull umstellen, wenn Nix sitzt.)*

---

## 7. Stack auf einen Blick

| Funktion | Tool |
|---|---|
| Agent (TRON) + Sub-Agents | Agent-Framework auf dem Pi |
| Lokale LLM | **Ollama / LM Studio** (RX 6800) + Cloud-Fallback |
| Automatisierung | **n8n / Home Assistant** |
| Health-/Vitals-Daten | **Apple Health** + Health Auto Export · AnkiConnect |
| Netzwerk-Mesh | **Tailscale** |
| Deklarative Config / „OS" | **Nix Flakes** (NixOS, nix-darwin, NixOS-WSL, home-manager) |
| OTA / GitOps | **comin** (pull) · **deploy-rs / colmena** (push) |
| Datei-Sync | **Syncthing** |
| Private Cloud (Handy) | **Nextcloud** (auf dem Pi) |
| Remote-Terminal | **Tailscale-SSH** |
| Remote-Desktop / GPU | **Sunshine + Moonlight** / RDP |
| Git-Hosting (eigen) | **Forgejo / Gitea** (auf dem Pi) |

---

*Nächster Schritt: Die 5 offenen Entscheidungen klären — dann bauen wir Phase 0+1 konkret aus (inkl. erster Nix-Config fürs Repo).*
