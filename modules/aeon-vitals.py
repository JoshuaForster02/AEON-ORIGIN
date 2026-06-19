#!/usr/bin/env python3
"""AEON Vitals-Reporter (läuft auf dem PC).
Liest die echte Anki-Review-Streak aus collection.anki2, misst die heutige
Fokus-Zeit aus focus.log und meldet beides an den Pi-Hub."""
import os, glob, sqlite3, json, time, urllib.request
from datetime import datetime, date, timedelta

PI_URL = os.environ.get("AEON_PI_URL", "http://aeon-pi:8080/api/pc")
HOME = os.path.expanduser("~")


def anki_streak():
    paths = sorted(glob.glob(os.path.join(HOME, ".local/share/Anki2/*/collection.anki2")))
    if not paths:
        return None
    try:
        con = sqlite3.connect(f"file:{paths[0]}?immutable=1", uri=True)
        days = {datetime.fromtimestamp(rid / 1000).date()
                for (rid,) in con.execute("SELECT id FROM revlog")}
        con.close()
    except Exception:
        return None
    if not days:
        return 0
    today = date.today()
    cur = today if today in days else today - timedelta(days=1)
    if cur not in days:
        return 0
    streak = 0
    while cur in days:
        streak += 1
        cur -= timedelta(days=1)
    return streak


def focus_hours_today():
    log = os.path.join(HOME, ".local/share/aeon/focus.log")
    if not os.path.exists(log):
        return None
    today = date.today()
    total, start = 0, None
    try:
        for line in open(log):
            p = line.split()
            if len(p) != 2:
                continue
            ev, ts = p[0], int(p[1])
            if ev == "start":
                start = ts
            elif ev == "stop" and start is not None:
                if datetime.fromtimestamp(start).date() == today:
                    total += ts - start
                start = None
        if start is not None and datetime.fromtimestamp(start).date() == today:
            total += int(time.time()) - start
    except Exception:
        return None
    return round(total / 3600, 1)


def main():
    payload = {"streak": anki_streak(),
               "focus_h": focus_hours_today(),
               "ts": int(time.time())}
    try:
        req = urllib.request.Request(PI_URL, data=json.dumps(payload).encode(),
                                     headers={"Content-Type": "application/json"})
        urllib.request.urlopen(req, timeout=10).read()
        print("AEON vitals gesendet:", payload)
    except Exception as e:
        print("AEON vitals: Pi nicht erreichbar:", e, "—", payload)


if __name__ == "__main__":
    main()
