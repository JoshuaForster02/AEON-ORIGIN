"""AEON Hub API v2.
- nimmt Apple-Health-Daten (Health Auto Export) entgegen   → POST /ingest
- nimmt PC-Vitals (Anki-Streak, Fokus) entgegen            → POST /ingest-pc
- liefert normalisierte Vitals fürs Dashboard               → GET  /vitals
- baut ein kurzes Tagesbriefing                             → GET  /briefing
- TRON: leitet Prompts an die lokale LLM (Ollama, RX 6800)  → POST /tron
- Modus-Steuerung: PC über SSH schalten                     → POST /mode
"""
import os, json, subprocess
from datetime import datetime, timezone
from fastapi import FastAPI, Request, HTTPException

# Getrennte Datenbankdateien pro Datenquelle
DATA_HEALTH  = os.environ.get("AEON_HEALTH_DATA",  "/data/apple_health.jsonl")
DATA_PC      = os.environ.get("AEON_PC_DATA",      "/data/pc_vitals.jsonl")
OLLAMA_URL   = os.environ.get("OLLAMA_URL",   "http://aeon-rig:11434")
OLLAMA_MODEL = os.environ.get("OLLAMA_MODEL", "qwen2.5:14b")
PC_HOST      = os.environ.get("PC_HOST",      "aeon-rig")   # Tailscale-Hostname

app = FastAPI(title="AEON Hub API", version="2.0.0")


# ─── Helpers ────────────────────────────────────────────────────────────────

def _read_last(path: str):
    """Liest den letzten JSON-Eintrag aus einer .jsonl-Datei."""
    if not os.path.exists(path):
        return None
    with open(path) as f:
        lines = [l for l in f if l.strip()]
    return json.loads(lines[-1]) if lines else None


def _append(path: str, payload: dict):
    """Hängt einen JSON-Eintrag an eine .jsonl-Datei."""
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "a") as f:
        f.write(json.dumps({"ts": datetime.now(timezone.utc).isoformat(),
                             "data": payload}) + "\n")


def _metric(payload, names):
    """Liest einen Wert aus Apple Health-Daten (Health Auto Export Format)."""
    try:
        metrics = payload["data"]["metrics"]
    except Exception:
        return None
    for m in metrics:
        if m.get("name") in names and m.get("data"):
            d = m["data"][-1]
            for k in ("qty", "Avg", "avg", "value", "total"):
                if k in d:
                    return d[k]
    return None


# ─── Endpunkte ──────────────────────────────────────────────────────────────

@app.get("/")
def root():
    return {"service": "aeon-hub", "version": "2.0.0", "status": "ok"}


@app.post("/ingest")
async def ingest_health(request: Request):
    """Apple Health Auto Export → Schlaf, Schritte, Training."""
    payload = await request.json()
    _append(DATA_HEALTH, payload)
    return {"received": True, "source": "apple_health"}


@app.post("/ingest-pc")
async def ingest_pc(request: Request):
    """PC-Vitals → Anki-Streak, Fokus-Stunden."""
    payload = await request.json()
    _append(DATA_PC, payload)
    return {"received": True, "source": "aeon-rig"}


@app.get("/vitals")
def vitals():
    """Kombinierte Vitals aus Apple Health + PC-Metriken."""
    # Apple Health
    health_rec  = _read_last(DATA_HEALTH)
    health_data = health_rec["data"] if health_rec else {}
    sleep    = _metric(health_data, {"sleep_analysis"})
    steps    = _metric(health_data, {"step_count"})
    exercise = _metric(health_data, {"apple_exercise_time"})

    # PC-Vitals
    pc_rec  = _read_last(DATA_PC)
    pc_data = pc_rec["data"] if pc_rec else {}
    streak      = pc_data.get("anki_streak")
    focus_hrs   = pc_data.get("focus_hours_today")
    focus_act   = pc_data.get("focus_active", False)

    return {
        "updated_health": health_rec["ts"] if health_rec else None,
        "updated_pc":     pc_rec["ts"]     if pc_rec     else None,
        "streak":   {"value": streak,                              "unit": "Tage", "source": "anki"},
        "focus":    {"value": round(focus_hrs, 1) if focus_hrs else None, "unit": "h", "source": "aeon", "active": focus_act},
        "sleep":    {"value": round(sleep, 1) if sleep else None,  "unit": "h",    "source": "apple health"},
        "training": {"value": int(exercise) if exercise else None, "unit": "min",  "source": "apple health"},
        "steps":    int(steps) if steps else None,
    }


@app.get("/briefing")
def briefing():
    """Tages-Zusammenfassung für das Dashboard."""
    v = vitals()
    parts = []
    if v["sleep"]["value"]:
        parts.append(f'{v["sleep"]["value"]} h Schlaf')
    if v["steps"]:
        parts.append(f'{v["steps"]:,} Schritte')
    if v["training"]["value"]:
        parts.append(f'{v["training"]["value"]} min Training')
    if v["streak"]["value"]:
        parts.append(f'Anki-Streak {v["streak"]["value"]} Tage')
    line = " · ".join(parts) if parts else \
        "Noch keine Daten — sende Health-Daten an /ingest."
    return {"line": line}


@app.post("/tron")
async def tron(request: Request):
    """TRON: Prompt an Ollama auf dem PC weiterleiten."""
    body   = await request.json()
    prompt = (body or {}).get("prompt", "").strip()
    if not prompt:
        return {"reply": "Sag mir, was ich tun soll.", "via": "noop"}
    try:
        import httpx
        async with httpx.AsyncClient(timeout=60) as c:
            r = await c.post(f"{OLLAMA_URL}/api/generate",
                             json={"model": OLLAMA_MODEL, "prompt": prompt, "stream": False})
            r.raise_for_status()
            return {"reply": r.json().get("response", "").strip(), "via": "ollama"}
    except Exception as e:
        return {"reply": f"(TRON offline — der PC mit der RX 6800 ist nicht erreichbar: {type(e).__name__})",
                "via": "fallback"}


@app.post("/mode")
async def set_mode(request: Request):
    """Steuert den PC-Modus aus der Ferne über Tailscale SSH.
    Body: {"mode": "focus" | "unfocus" | "game" | "windows"}
    """
    body = await request.json()
    mode = (body or {}).get("mode", "").strip().lower()

    allowed = {
        "focus":   "aeon focus",
        "unfocus": "aeon unfocus",
        "game":    "aeon game",
        "windows": "aeon win",
    }
    if mode not in allowed:
        raise HTTPException(status_code=400, detail=f"Ungültiger Modus: {mode}. Erlaubt: {list(allowed)}")

    cmd = allowed[mode]
    try:
        result = subprocess.run(
            ["ssh", "-o", "StrictHostKeyChecking=no", "-o", "ConnectTimeout=5",
             f"joshua@{PC_HOST}", cmd],
            capture_output=True, text=True, timeout=15
        )
        ok = result.returncode == 0
        return {
            "mode": mode,
            "ok": ok,
            "stdout": result.stdout.strip(),
            "stderr": result.stderr.strip() if not ok else "",
        }
    except subprocess.TimeoutExpired:
        raise HTTPException(status_code=504, detail="PC nicht erreichbar (Timeout)")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
