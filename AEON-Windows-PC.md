# AEON auf dem Windows-PC — das Flaggschiff (Dual-Boot)

*Ryzen + RX 6800 · echtes NixOS neben Windows · Stand 12. Juni 2026*

Der PC ist die *einzige* Maschine, auf der AEON ein **vollwertiges, eigenes OS** wird (NixOS). Windows bleibt per Dual-Boot erhalten — für Anti-Cheat-Games und als Sicherheitsnetz. Nichts wird gelöscht: wir verkleinern nur die Windows-Partition und installieren AEON in den freien Raum.

Hier laufen alle AEON-Säulen nativ zusammen: Design via Stylix, lokale LLM auf der GPU, Gaming via Proton, Streaming via Sunshine.

---

## 0. Warum dieser PC?

- **RX 6800 = AMD** → unter Linux erstklassig: `amdgpu` ist im Kernel, **RADV/Mesa** für Gaming, **ROCm** für LLM-Beschleunigung. Kein Treiber-Drama wie bei manchen NVIDIA-Setups.
- **Ryzen** → schnelle CPU für Builds & Container.
- Damit wird der PC AEONs **Denkzentrum** (lokale LLM für TRON) *und* die Referenz-Implementierung von „AEON, das OS".

---

## 1. Pre-Flight in Windows (BEVOR irgendwas passiert)

> ⚠️ Diese Reihenfolge ist wichtig. Punkt 1 und 2 sind nicht verhandelbar.

1. **Backup** der wichtigen Daten (extern/Cloud). Dual-Boot ist sicher — aber ein Backup ist Pflicht.
2. **BitLocker aussetzen oder deaktivieren** (Systemsteuerung → BitLocker). Sonst kann der Bootloader die Windows-Partition nicht sauber handhaben → Boot-Probleme. Recovery-Key notieren!
3. **Schnellstart deaktivieren** (Energieoptionen → „Schnellstart aktivieren" aus). Sonst bleibt die Windows-Partition (NTFS) gelockt und unmountbar.
4. **Windows-Updates abschließen** und einmal sauber neu starten.
5. **Secure Boot**: vorerst im BIOS deaktivieren (NixOS + Secure Boot geht später via `lanzaboote`, aber für die Installation ist „aus" der einfachste Weg).

---

## 2. Sichere Partitionierung (nichts löschen)

Der Schlüssel: wir schaffen **freien (unallocated) Speicher** und fassen die Windows-Partition selbst nicht an.

**Weg A — sicherster Weg (empfohlen):** in Windows
- `Datenträgerverwaltung` öffnen → Windows-Partition (C:) → **Volume verkleinern**
- 200–500 GB freigeben (je nach Platte). Der freigegebene Bereich wird **„nicht zugeordnet"** — leer, nichts gelöscht.
- Fertig. NixOS bekommt *nur* diesen freien Bereich.

**Weg B — wenn das Verkleinern klemmt:** ein Partitionsmanager
- GParted (Live-USB) oder ein Tool deiner Wahl nutzen, um C: zu verkleinern. **Nur verkleinern, nicht löschen/formatieren.** Unbewegliche Dateien (Auslagerung, Hibernation) ggf. vorher in Windows deaktivieren, dann klappt das Shrinken.

**Wichtig zur EFI-Partition:** Windows hat bereits eine kleine EFI-System-Partition (ESP, oft ~100 MB). Zwei Optionen:
- **ESP mitnutzen** (einfach): NixOS legt seinen Bootloader dort ab — *nicht formatieren!* Wegen der geringen Größe `configurationLimit` klein halten (s.u.).
- **Eigene ESP anlegen** (sauber): im freien Raum eine neue 512-MB-ESP erstellen und NixOS darauf booten. Windows-ESP bleibt komplett unberührt.

---

## 3. NixOS installieren

1. NixOS-ISO (x86_64) auf USB schreiben (Ventoy/Rufus/`dd`).
2. Vom USB booten (Boot-Menü; Secure Boot ist aus).
3. Im Installer **nur den freien Speicher** partitionieren:
   - `root` → btrfs oder ext4 (btrfs erlaubt Snapshots)
   - `swap` → je nach RAM
   - ESP → bestehende einbinden (**nicht formatieren**) oder neue mounten
4. `configuration.nix` aus dem AEON-Repo verwenden (Template unten).
5. `nixos-install`, neu starten.
6. **systemd-boot** zeigt beim Start automatisch *NixOS* **und** *Windows Boot Manager*. Fertig — du wählst beim Booten.

---

## 4. configuration.nix — der Flaggschiff-Build (Template)

> Startvorlage. Wird auf echter Hardware verfeinert (v.a. `hardware-configuration.nix` generiert der Installer selbst).

```nix
{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/aeon-theme.nix     # AEON-Design (Stylix)
    ../../modules/tailscale.nix      # Fleet-Mesh
  ];

  # ── Dual-Boot: Windows wird automatisch erkannt ──
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 8;   # ESP-Platz schonen
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "aeon-rig";

  # ── AMD Ryzen ──
  hardware.cpu.amd.updateMicrocode = true;

  # ── RX 6800 (amdgpu) + 32-bit für Gaming ──
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [ rocmPackages.clr.icd amdvlk ];
  };

  # ── Gaming ──
  programs.steam.enable = true;
  programs.gamemode.enable = true;
  environment.systemPackages = with pkgs; [ mangohud protonup-qt lutris ];

  # ── Lokale LLM auf der RX 6800 (TRONs Gehirn) ──
  services.ollama = {
    enable = true;
    acceleration = "rocm";
    # RX 6800 = gfx1030; falls ROCm zickt, einkommentieren:
    # environmentVariables.HSA_OVERRIDE_GFX_VERSION = "10.3.0";
  };

  # ── Game-Streaming an Mac/iPhone (Moonlight) ──
  services.sunshine = { enable = true; openFirewall = true; };

  # ── Pi kann den PC für Inferenz aufwecken ──
  networking.interfaces.eth0.wakeOnLan.enable = true;

  # ── Desktop (Beispiel: KDE Plasma; Hyprland geht auch) ──
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  users.users.joshua = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
  };

  system.stateVersion = "25.05";
}
```

---

## 5. Wie der PC ins AEON-System passt

- **Host im Repo:** `hosts/aeon-rig/` — hier ist der Nix-Flake wirklich „das OS". Änderungen = Commit → `nixos-rebuild switch`.
- **Design:** Stylix greift hier **systemweit** (Terminal, Editor, Plasma) — der einzige Ort, wo das volle „ein Design überall" nativ läuft.
- **TRON:** Ollama auf der RX 6800 ist die starke LLM; der Pi orchestriert und weckt den PC per Wake-on-LAN, wenn Rechenpower gebraucht wird. PC aus → Cloud-Fallback.
- **Gaming:** nativ via Steam/Proton auf AEON, oder du bootest Windows für Anti-Cheat-Titel. In beiden Fällen per Sunshine auf Mac/iPhone streambar.

---

## 6. Checkliste & Stolperfallen

- [ ] Backup gemacht
- [ ] BitLocker aus + Recovery-Key gesichert
- [ ] Schnellstart aus
- [ ] Secure Boot im BIOS aus
- [ ] Windows-Partition verkleinert (freier Raum sichtbar)
- [ ] Windows-ESP **nicht** formatiert
- [ ] `configurationLimit` gesetzt (kleine ESP)
- [ ] Nach Install: Windows erscheint im Boot-Menü

**Häufige Fehler:** ESP zu klein → Generationen begrenzen oder eigene ESP. NTFS gelockt → Schnellstart war noch an. Windows bootet nicht mehr → fast immer BitLocker oder Fast Startup übersehen.

---

*Nächster Schritt: Sobald du Phase 0 (Tailscale) & den Pi-Hub stehen hast, ist dieser PC die lohnendste Maschine — hier wird AEON zum ersten Mal als echtes OS erlebbar.*
