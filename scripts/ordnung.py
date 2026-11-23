#!/usr/bin/env python3
"""Ordnung im Arbeitsordner – findet, was aufgeräumt, erneuert oder archiviert werden sollte.

  python3 scripts/ordnung.py            Bericht (Fehler und Hinweise); Rückgabe 1, wenn es Fehler gibt
  python3 scripts/ordnung.py --heute JJJJ-MM-TT

Fehler (müssen weg): kaputte Pfadverweise, Dokumente außerhalb des Wegweisers, Archiv-Dateien ohne Index-Zeile,
Fehler in den Aufgaben. Hinweise (ansehen): alte „Stand:“-Angaben, alte Konzepte, lose Dateien, lange Erledigtes.
Monatlich (Aufgabe r-aufraeumen in /fahrplan) und vor jedem PR mit Doku-Änderungen laufen lassen.
"""
import argparse, datetime as dt, importlib.util, os, re, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOCS = os.path.join(ROOT, "docs")
ALT_STAND_TAGE = 60          # „Stand:“ älter → erneuern oder archivieren?
ALT_KONZEPT_TAGE = 45        # Konzept so lange ungebaut → noch aktuell?
ERLEDIGT_ARCHIV_TAGE = 90    # erledigte Aufgaben so lange her → aus der Liste nehmen?
HISTORIE = ("docs/archiv/", "docs/technik/bauprotokoll.md")   # alte Pfade dort sind Geschichte, kein Fehler
GEWOLLT_FEHLEND = ("Kompass/", "KompassTests/", ".claude/settings.local.json", ".claude/settings.json",
                   ".claude/worktrees", "prototyp/tests/ergebnis.json")   # nur lokal, Test-Ausgabe oder noch nicht angelegt – darf fehlen
PATH_RE = re.compile(r"(?<![\w/.-])((?:docs|scripts|prototyp|Kompass|KompassTests|KompassUITests|\.claude)/[\w./-]*[\w/])")
MONATE = {m: i + 1 for i, m in enumerate(["Januar", "Februar", "März", "April", "Mai", "Juni", "Juli", "August", "September", "Oktober", "November", "Dezember"])}


def tracked():
    out = subprocess.run(["git", "ls-files"], cwd=ROOT, capture_output=True, text=True).stdout.split("\n")
    return [f for f in out if f]


def text_files(files):
    return [f for f in files if (f.endswith((".md", ".json", ".swift", ".py", ".html")) or f == ".gitignore") and not f.endswith(".xcstrings")]


def broken_refs(files):
    errs, warns = [], []
    for f in text_files(files):
        try:
            with open(os.path.join(ROOT, f), encoding="utf-8") as fh:
                s = fh.read()
        except (UnicodeDecodeError, OSError):
            continue
        if f == "scripts/ordnung.py" or os.path.basename(f).startswith("test_"):   # tests use made-up paths on purpose
            continue
        for m in PATH_RE.finditer(s):
            p = m.group(1).rstrip(".")
            if any(ch in p for ch in "*<>{}") or p.endswith("/…") or p in GEWOLLT_FEHLEND or s[m.end():m.end() + 2].startswith((".{", "{")):
                continue
            if not os.path.exists(os.path.join(ROOT, p)):
                (warns if f.startswith(HISTORIE) and not f.endswith("archiv/README.md") else errs).append(f"{f}: Verweis auf `{p}` – gibt es nicht")
    return errs, sorted(set(warns))


def outside_signpost(files):
    """Jedes Dokument steht im Wegweiser docs/README.md oder im README seines Ordners."""
    errs = []
    for f in files:
        if not (f.startswith("docs/") and f.endswith(".md")) or f.startswith("docs/archiv/") or f.endswith("README.md") or f == "docs/stand.md":
            continue
        name, folder = os.path.basename(f), os.path.dirname(f)
        hubs = [os.path.join(DOCS, "README.md")]
        d = folder
        while d.startswith("docs"):
            hubs.append(os.path.join(ROOT, d, "README.md")); d = os.path.dirname(d)
        text = " ".join(open(h, encoding="utf-8").read() for h in hubs if os.path.exists(h))
        rel = os.path.relpath(f, "docs")
        if name not in text and rel not in text and os.path.basename(folder) + "/" not in text:
            errs.append(f"{f}: steht in keinem Wegweiser (docs/README.md oder README des Ordners)")
    return errs


def archive_index(files):
    idx = os.path.join(DOCS, "archiv", "README.md")
    text = open(idx, encoding="utf-8").read() if os.path.exists(idx) else ""
    return [f"{f}: fehlt im Archiv-Index docs/archiv/README.md" for f in files
            if f.startswith("docs/archiv/") and not f.endswith("README.md") and os.path.basename(f) not in text]


def stand_date(text):
    m = re.search(r"Stand:\s*(\d{1,2})\.\s*([A-Za-zä]+)\s*(\d{4})", text) or re.search(r"Stand:\s*(\d{1,2})\.(\d{1,2})\.(\d{4})", text)
    if not m:
        return None
    d, mo, y = m.groups()
    mo = MONATE.get(mo) if not mo.isdigit() else int(mo)
    try:
        return dt.date(int(y), mo, int(d)) if mo else None
    except ValueError:
        return None


def old_docs(files, today):
    hints = []
    for f in files:
        if not (f.startswith("docs/") and f.endswith(".md")) or f.startswith(("docs/archiv/", "docs/technik/berichte/")):
            continue
        d = stand_date(open(os.path.join(ROOT, f), encoding="utf-8").read()[:600])
        limit = ALT_KONZEPT_TAGE if "/konzepte/" in f else ALT_STAND_TAGE
        if d and (today - d).days > limit:
            what = "Konzept noch aktuell? bauen, anpassen oder archivieren" if "/konzepte/" in f else "Stand erneuern oder archivieren"
            hints.append(f"{f}: Stand {d.strftime('%d.%m.%Y')} ({(today - d).days} Tage) – {what}")
    return hints


def loose_files():
    out = subprocess.run(["git", "status", "--porcelain", "--untracked-files=normal"], cwd=ROOT, capture_output=True, text=True).stdout
    skip = ("Kompass.xcodeproj/xcshareddata/",)
    return [f"lose Datei (nicht im Repo, nicht ignoriert): {l[3:]}" for l in out.splitlines() if l.startswith("??") and not l[3:].startswith(skip)]


def tasks(today):
    spec = importlib.util.spec_from_file_location("fahrplan", os.path.join(ROOT, "scripts", "fahrplan.py"))
    F = importlib.util.module_from_spec(spec); spec.loader.exec_module(F)
    data = F.load()
    errs = [f"Aufgaben: {e}" for e in F.check(data)]
    old = [a for a in data["aufgaben"] if a.get("status") == "erledigt" and not a.get("wiederholung") and a.get("erledigtAm")
           and (today - F.day(a["erledigtAm"])).days > ERLEDIGT_ARCHIV_TAGE]
    hints = [f"Aufgaben: {len(old)} seit über {ERLEDIGT_ARCHIV_TAGE} Tagen erledigt – ins Archiv (docs/archiv/aufgaben-erledigt.json) verschieben"] if old else []
    return errs, hints


def report(today):
    files = tracked()
    errs, hints = [], []
    e, w = broken_refs(files); errs += e; hints += w
    errs += outside_signpost(files)
    errs += archive_index(files)
    e, h = tasks(today); errs += e; hints += h
    hints += old_docs(files, today)
    hints += loose_files()
    return errs, hints


def main(argv=None):
    p = argparse.ArgumentParser(description="Ordnung im Arbeitsordner")
    p.add_argument("--heute")
    args = p.parse_args(argv)
    today = dt.date.fromisoformat(args.heute) if args.heute else dt.date.today()
    errs, hints = report(today)
    print(f"# Ordnung · {today.strftime('%d.%m.%Y')}")
    print(f"\n## Fehler · {len(errs)}" + ("" if errs else "\nKeine."))
    for x in errs: print("- " + x)
    print(f"\n## Hinweise · {len(hints)}" + ("" if hints else "\nKeine."))
    for x in hints: print("- " + x)
    return 1 if errs else 0


if __name__ == "__main__":
    sys.exit(main())
