# AEON — Design-System

*Noir Gold · clean · modern · medizinisch · Stand 12. Juni 2026*

Die visuelle Designsprache von AEON. Diese Tokens sind die Single Source of Truth — sie fließen später direkt in **Stylix** (NixOS) ein und steuern damit systemweit jede App.

---

## 1. Farb-Tokens

| Token | Hex | Verwendung |
|---|---|---|
| `canvas` | `#0E0D0B` | Haupt-Hintergrund (warmes Fast-Schwarz) |
| `surface-1` | `#15130F` | Karten, Panels |
| `surface-2` | `#1B1813` | erhöhte Flächen, Hover |
| `hairline` | `#221E16` | feine Trennlinien / Borders |
| `hairline-strong` | `#2E2920` | betonte Border |
| `text-primary` | `#ECE6D8` | Haupttext (warmes Off-White) |
| `text-secondary` | `#9C9384` | sekundärer Text |
| `text-tertiary` | `#6A6356` | Labels, Hints |
| `gold` | `#C9A458` | **Akzent — sparsam**: aktive States, Linien, Daten |
| `gold-dark` | `#8A7338` | gedämpftes Gold |
| `sage` | `#6FA98C` | positiv / „ok" / aktiv-Indikator |
| `terra` | `#C26B5A` | Warnung / Alert |

**Gold-Regel:** Gold ist ein Instrument, kein Anstrich. Nur für aktive Zustände, dünne Linien, Datenwerte und kleine Icons — nie als große Füllfläche.

---

## 2. Typografie

| Rolle | Font | Einsatz |
|---|---|---|
| Display / Serif | **Newsreader** | Begrüßung, große Momente, Headlines |
| UI / Sans | **Inter** | gesamte Oberfläche, Fließtext, Labels |
| Data / Mono | **IBM Plex Mono** | Zahlen, Uhrzeiten, Vitals — der „Messgerät"-Look |

**Skala:** Display 24/500 · H2 18/500 · Body 14/400 · Small 12/400 · Data 20/500 (mono) · Mono-Label 11–12/400.
Nur zwei Gewichte: 400 & 500. Immer Satzanfang-Groß, nie ALL CAPS außer als gespaltete Labels (`HEUTE`, `VITALS`).

---

## 3. Form & Raum

- **Radius:** Container 18px · Karten/Tiles 12px · Buttons/Pills 8px
- **Border:** 1px `hairline`
- **Padding:** Container 18px · Karten 12–14px
- **Gaps:** 8–12px zwischen Komponenten · 26px zwischen Modus-Tabs
- **Tiefe entsteht durch Ebenen** (`canvas` → `surface-1` → `surface-2`) + Hairlines, nicht durch Schatten.
- **Signatur:** der feine **Puls-Strich** (Gold, ~0.55 Deckkraft) als wiederkehrendes Identitätselement.

---

## 4. Kernkomponenten

- **Modus-Tab (aktiv):** Text in `text-primary`, 2px Gold-Unterstrich, Icon in Gold. Inaktiv: `text-tertiary`, kein Strich.
- **Vitals-Tile:** `surface-1`, Gold-Icon oben, Mono-Zahl, darunter 11px-Label, unten 2px Fortschritts-Hairline (Track `hairline`, Fill `gold`).
- **Briefing-Zeile:** Mono-Uhrzeit (Gold für „nächstes", sonst `text-secondary`) + Label in `text-primary`, getrennt durch Hairlines.
- **Button:** transparent, 1px Gold-Border, Gold-Text; Hover: `surface-2`.
- **TRON-Eingabe:** `surface-1`, Gold-Sparkles-Icon links, Placeholder „Frag TRON …", Mikrofon rechts.

---

## 5. base16-Schema (für Stylix)

Direkt in `stylix.base16Scheme` verwendbar — steuert damit Terminal, Editor, GTK/Qt, etc. systemweit.

```
base00: "0E0D0B"   # canvas / bg
base01: "15130F"   # surface-1
base02: "1B1813"   # surface-2 / selection
base03: "6A6356"   # comments / tertiary
base04: "9C9384"   # secondary text
base05: "ECE6D8"   # primary text
base06: "F2EDE2"   # light
base07: "FBF8F1"   # lightest
base08: "C26B5A"   # terra (red)
base09: "C9A458"   # gold (orange slot)
base0A: "D8A84B"   # amber gold (yellow)
base0B: "6FA98C"   # sage (green)
base0C: "8FB3AE"   # muted teal (cyan)
base0D: "B9925A"   # warm tan (blue slot → kept warm)
base0E: "A98B6F"   # taupe (purple slot)
base0F: "8A7338"   # gold-dark (brown)
```

*Hinweis: base0C/0D/0E sind bewusst warm gehalten statt klassisch kühl, damit nichts aus der Noir-Gold-Welt ausbricht.*
