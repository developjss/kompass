#!/usr/bin/env python3
"""Fahrplan – Aufgaben aus docs/leitung/aufgaben/aufgaben.json (eine Quelle für Bausteine, Rhythmus, Stichtage, Ereignisse).

Befehle (nur Python-Standardbibliothek):
  python3 scripts/fahrplan.py heute [--wer ID|alle] [--datum JJJJ-MM-TT] [--tage 14]   Übersicht als Markdown
  python3 scripts/fahrplan.py check                                                   Daten und Landkarten-Bezüge prüfen
  python3 scripts/fahrplan.py export --format csv|xlsx --out DATEI [--wer ID]          für Excel, Numbers, Google Sheets
  python3 scripts/fahrplan.py zuweisen ID WER        Aufgabe einer Person geben
  python3 scripts/fahrplan.py erledigt ID [--datum]  einmalig: Status erledigt · wiederkehrend: erledigtAm setzen
  python3 scripts/fahrplan.py team                   Namen und ids
  python3 scripts/fahrplan.py view --out DATEI       berechnete Ansicht (JSON) für die Seite docs/leitung/aufgaben/fahrplan.html
"""
import argparse, calendar, csv, datetime as dt, json, os, sys, zipfile
from xml.sax.saxutils import escape

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA = os.path.join(ROOT, "docs", "leitung", "aufgaben", "aufgaben.json")
LANDKARTE = os.path.join(ROOT, "docs", "landkarte", "landkarte.json")
STATUS = {"offen", "laeuft", "wartet", "erledigt"}
WOCHENTAG = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]
BUCKETS = [("ueberfaellig", "Überfällig"), ("heute", "Heute"), ("bald", "Bald"), ("naechstes", "Als Nächstes (ohne Datum)"),
           ("blockiert", "Wartet auf andere Aufgaben"), ("ereignis", "Wartet auf ein Ereignis"), ("spaeter", "Später")]


AREA = {"co": "Leitung", "lead": "Leitung", "people": "Team", "hire": "Team", "prod": "Produkt & Design", "tech": "Technik",
        "mkt": "Marketing", "sup": "Support", "fin": "Finanzen", "law": "Recht"}
_AREA_OF = None


def area_of(node_id):
    """Bereich = oberster Ast der Landkarte unter der Firma (so ist der Fahrplan gegliedert wie die Landkarte)."""
    global _AREA_OF
    if _AREA_OF is None:
        _AREA_OF = {}
        if os.path.exists(LANDKARTE):
            root = load(LANDKARTE)["root"]
            def walk(n, area):
                if n.get("id"):
                    _AREA_OF[n["id"]] = area
                for c in n.get("c", []):
                    walk(c, area)
            _AREA_OF[root.get("id", "co")] = AREA["co"]
            for branch in root.get("c", []):           # each top branch is one area
                walk(branch, AREA.get(branch.get("id"), branch.get("t")))
    return _AREA_OF.get(node_id)


def bereich(a):
    return area_of(a.get("landkarte")) or a.get("bereich") or "Leitung"


def load(path=None):
    with open(path or DATA, encoding="utf-8") as f:
        return json.load(f)


def save(data, path=None):
    with open(path or DATA, "w", encoding="utf-8") as f:
        f.write(json.dumps(data, ensure_ascii=False, indent=2) + "\n")


def day(s):
    return dt.date.fromisoformat(s)


def clamp(y, m, d):
    return dt.date(y, m, min(d, calendar.monthrange(y, m)[1]))


def occurrences(w, start, end):
    """Termine einer Wiederholung in [start, end]."""
    out, art = [], w.get("art")
    if art == "woechentlich":
        wd = (w.get("tag", 1) - 1) % 7
        d = start + dt.timedelta(days=(wd - start.weekday()) % 7)
        while d <= end:
            out.append(d); d += dt.timedelta(days=7)
        return out
    months = {"monatlich": list(range(1, 13)), "quartal": w.get("monate", [1, 4, 7, 10]), "jaehrlich": [w.get("monat", 1)]}.get(art)
    if months is None:
        return out
    for y in range(start.year - 1, end.year + 2):
        for m in months:
            d = clamp(y, m, w.get("tag", 1))
            if start <= d <= end:
                out.append(d)
    return sorted(out)


def wiederholung_text(w):
    if not w:
        return ""
    art = w["art"]
    if art == "woechentlich":
        return "wöchentlich (" + WOCHENTAG[(w.get("tag", 1) - 1) % 7] + ")"
    if art == "monatlich":
        return "monatlich ({}.)".format(w.get("tag", 1))
    if art == "quartal":
        return "quartalsweise ({}. · Monate {})".format(w.get("tag", 1), ",".join(map(str, w.get("monate", []))))
    if art == "jaehrlich":
        return "jährlich ({}.{}.)".format(w.get("tag", 1), w.get("monat", 1))
    return art


def classify(data, today, tage=14):
    """Jede offene Aufgabe in genau einen Topf; mit dem Datum, das zählt."""
    phase = data["meta"].get("phase", 0)
    by_id = {a["id"]: a for a in data["aufgaben"]}
    done = {a["id"] for a in data["aufgaben"] if a.get("status") == "erledigt" and not a.get("wiederholung")}
    horizon = today + dt.timedelta(days=tage)
    out = []
    for a in data["aufgaben"]:
        w = a.get("wiederholung")
        if a.get("status") == "erledigt" and not w:
            continue
        blocked = [n for n in a.get("nach", []) if n not in done]
        item = {"a": a, "datum": None, "blockiert_durch": blocked}
        if a.get("phase", 0) > phase:
            item["topf"] = "spaeter"; item["grund"] = "ab Phase {}".format(a["phase"])
        elif a.get("status") == "wartet" and a.get("ausloeser") and not w:
            item["topf"] = "ereignis"; item["grund"] = a["ausloeser"]
        elif w:
            last = day(a["erledigtAm"]) if a.get("erledigtAm") else None
            since = day(a["seit"]) if a.get("seit") else None     # a new duty counts from the day it was added
            due = [d for d in occurrences(w, today - dt.timedelta(days=30), today) if (not last or d > last) and (not since or d >= since)]
            nxt = occurrences(w, today + dt.timedelta(days=1), today + dt.timedelta(days=400))
            if due and due[-1] < today:
                item["topf"], item["datum"] = "ueberfaellig", due[-1]
            elif due and due[-1] == today:
                item["topf"], item["datum"] = "heute", today
            elif nxt and nxt[0] <= horizon:
                item["topf"], item["datum"] = "bald", nxt[0]
            else:
                item["topf"], item["datum"] = "spaeter", nxt[0] if nxt else None
        elif blocked:
            item["topf"] = "blockiert"; item["grund"] = "nach " + ", ".join(blocked)
        elif a.get("faellig"):
            d = day(a["faellig"]); item["datum"] = d
            item["topf"] = "ueberfaellig" if d < today else "heute" if d == today else "bald" if d <= horizon else "spaeter"
        else:
            item["topf"] = "naechstes"
        out.append(item)
    order = {k: i for i, (k, _) in enumerate(BUCKETS)}
    out.sort(key=lambda i: (order[i["topf"]], i["datum"] or dt.date.max, i["a"].get("prio", 3), i["a"]["titel"]))
    return out


def mine(item, wer):
    a = item["a"]
    return wer in (None, "alle") or a.get("wer") == wer or wer in a.get("helfer", [])


def names(data):
    return {p["id"]: p["name"] for p in data["team"]}


def fmt_date(d, today):
    if not d:
        return ""
    if d == today:
        return "heute"
    delta = (d - today).days
    s = "{} {:02d}.{:02d}.".format(WOCHENTAG[d.weekday()], d.day, d.month)
    return s + (" (vor {} T.)".format(-delta) if delta < 0 else " (in {} T.)".format(delta) if delta <= 14 else "")


def markdown(data, today, wer=None, tage=14, limit=8):
    nm = names(data)
    items = [i for i in classify(data, today, tage) if mine(i, wer)]
    who = "alle" if wer in (None, "alle") else nm.get(wer, wer)
    lines = ["# Fahrplan · {} · {}".format(today.strftime("%d.%m.%Y"), who), ""]
    focus = [i for i in items if i["topf"] in ("ueberfaellig", "heute")]
    focus += [i for i in items if i["topf"] == "naechstes" and i["a"].get("prio", 3) == 1][:3]
    lines.append("## Heute zu tun")
    if focus:
        for i in focus:
            lines.append(row(i, nm, today))
    else:
        lines.append("Nichts Dringendes. Nächster Termin siehe „Bald“.")
    for key, title in BUCKETS[2:]:
        group = [i for i in items if i["topf"] == key and i not in focus]
        if not group:
            continue
        head = title + (" (nächste {} Tage)".format(tage) if key == "bald" else "")
        lines += ["", "## {} · {}".format(head, len(group))]
        for i in group[:limit]:
            lines.append(row(i, nm, today))
        if len(group) > limit:
            lines.append("- … und {} weitere (Seite oder Export)".format(len(group) - limit))
    if wer in (None, "alle"):
        lines += ["", "## Überblick je Person", "", "| Person | überfällig | heute | bald | als nächstes | blockiert | bei Ereignis | später |",
                  "|---|---|---|---|---|---|---|---|"]
        for p in data["team"]:
            mineP = [i for i in classify(data, today, tage) if i["a"].get("wer") == p["id"]]
            c = lambda k: sum(1 for i in mineP if i["topf"] == k)
            if mineP:
                lines.append("| {} | {} | {} | {} | {} | {} | {} | {} |".format(p["name"], c("ueberfaellig"), c("heute"), c("bald"), c("naechstes"),
                                                                               c("blockiert"), c("ereignis"), c("spaeter")))
    return "\n".join(lines)


def row(i, nm, today):
    a = i["a"]
    bits = [nm.get(a.get("wer"), a.get("wer", ""))]
    if a.get("helfer"):
        bits.append("mit " + ", ".join(nm.get(h, h) for h in a["helfer"]))
    if i.get("datum"):
        bits.insert(0, fmt_date(i["datum"], today))
    if i.get("grund"):
        bits.append(i["grund"])
    if a.get("wiederholung"):
        bits.append(wiederholung_text(a["wiederholung"]))
    prio = "❗ " if a.get("prio") == 1 else ""
    if i["topf"] == "ereignis":       # "Wenn …: tun" reads better than the action alone
        bits = [b for b in bits if b != i.get("grund")]
        return "- **Wenn {}:** {} — {} `{}`".format(a["ausloeser"], a["titel"], " · ".join(b for b in bits if b), a["id"])
    return "- {}**{}** — {} `{}`".format(prio, a["titel"], " · ".join(b for b in bits if b), a["id"])


def check(data):
    errs = []
    team = {p["id"] for p in data.get("team", [])}
    ids = [a.get("id") for a in data.get("aufgaben", [])]
    if len(ids) != len(set(ids)):
        errs.append("doppelte ids: " + ", ".join(sorted({i for i in ids if ids.count(i) > 1})))
    lk = set()
    if os.path.exists(LANDKARTE):
        def walk(n):
            if "id" in n: lk.add(n["id"])
            for c in n.get("c", []): walk(c)
        walk(load(LANDKARTE)["root"])
    for a in data.get("aufgaben", []):
        where = a.get("id", "?")
        for f in ("id", "titel", "wer", "status"):
            if not a.get(f): errs.append(f"{where}: Feld {f} fehlt")
        if a.get("status") not in STATUS: errs.append(f"{where}: Status {a.get('status')}")
        for p in [a.get("wer")] + a.get("helfer", []):
            if p not in team: errs.append(f"{where}: Person {p} nicht im Team")
        for n in a.get("nach", []):
            if n not in ids: errs.append(f"{where}: nach {n} gibt es nicht")
        if a.get("landkarte") and lk and a["landkarte"] not in lk: errs.append(f"{where}: Landkarten-Knoten {a['landkarte']} fehlt")
        for f in ("faellig", "erledigtAm", "seit"):
            if a.get(f):
                try: day(a[f])
                except ValueError: errs.append(f"{where}: {f} ist kein Datum")
        w = a.get("wiederholung")
        if w and w.get("art") not in ("woechentlich", "monatlich", "quartal", "jaehrlich"): errs.append(f"{where}: Wiederholung {w}")
        if a.get("status") == "wartet" and not a.get("ausloeser") and not a.get("nach"): errs.append(f"{where}: wartet, aber worauf?")
    return errs


def table(data, today, wer=None, tage=14):
    nm = names(data)
    head = ["id", "Titel", "Bereich", "Wer", "Helfer", "Status", "Prio", "Topf", "Datum", "Phase", "Wiederholung", "Auslöser", "Nach", "Landkarte", "Quelle"]
    rows = []
    for i in classify(data, today, tage):
        if not mine(i, wer): continue
        a = i["a"]
        rows.append([a["id"], a["titel"], bereich(a), nm.get(a["wer"], a["wer"]), ", ".join(nm.get(h, h) for h in a.get("helfer", [])),
                     a["status"], a.get("prio", ""), dict(BUCKETS)[i["topf"]], i["datum"].isoformat() if i.get("datum") else "",
                     a.get("phase", ""), wiederholung_text(a.get("wiederholung")), a.get("ausloeser", ""), ", ".join(a.get("nach", [])),
                     a.get("landkarte", ""), a.get("quelle", "")])
    return head, rows


def write_xlsx(path, head, rows, sheet="Fahrplan"):
    """Eine kleine .xlsx ohne Zusatzpakete (eine Tabelle, Text als Inline-Strings, Kopfzeile fett, Filter)."""
    def col(n):
        s = ""
        while n >= 0: s = chr(65 + n % 26) + s; n = n // 26 - 1
        return s
    def cell(r, c, v, style=0):
        ref = col(c) + str(r)
        if isinstance(v, (int, float)) and v != "":
            return f'<c r="{ref}" s="{style}"><v>{v}</v></c>'
        return f'<c r="{ref}" t="inlineStr" s="{style}"><is><t xml:space="preserve">{escape(str(v))}</t></is></c>'
    xml_rows = ['<row r="1">' + "".join(cell(1, c, v, 1) for c, v in enumerate(head)) + "</row>"]
    for r, values in enumerate(rows, start=2):
        xml_rows.append(f'<row r="{r}">' + "".join(cell(r, c, v) for c, v in enumerate(values)) + "</row>")
    last = col(len(head) - 1) + str(len(rows) + 1)
    sheet_xml = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?><worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
                 '<sheetViews><sheetView workbookViewId="0"><pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/></sheetView></sheetViews>'
                 '<cols><col min="2" max="2" width="70" customWidth="1"/></cols>'
                 f'<sheetData>{"".join(xml_rows)}</sheetData><autoFilter ref="A1:{last}"/></worksheet>')
    files = {
        "[Content_Types].xml": '<?xml version="1.0" encoding="UTF-8"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/><Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/><Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/></Types>',
        "_rels/.rels": '<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>',
        "xl/workbook.xml": f'<?xml version="1.0" encoding="UTF-8"?><workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets><sheet name="{escape(sheet)}" sheetId="1" r:id="rId1"/></sheets><definedNames><definedName name="_xlnm._FilterDatabase" localSheetId="0" hidden="1">\'{escape(sheet)}\'!$A$1:${col(len(head)-1)}${len(rows)+1}</definedName></definedNames></workbook>',
        "xl/_rels/workbook.xml.rels": '<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/><Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/></Relationships>',
        "xl/styles.xml": '<?xml version="1.0" encoding="UTF-8"?><styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><fonts count="2"><font><sz val="11"/><name val="Calibri"/></font><font><b/><sz val="11"/><name val="Calibri"/></font></fonts><fills count="2"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill></fills><borders count="1"><border/></borders><cellStyleXfs count="1"><xf/></cellStyleXfs><cellXfs count="2"><xf fontId="0"/><xf fontId="1" applyFont="1"/></cellXfs></styleSheet>',
        "xl/worksheets/sheet1.xml": sheet_xml,
    }
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as z:
        for name, content in files.items():
            z.writestr(name, content)


def main(argv=None):
    p = argparse.ArgumentParser(description="Fahrplan – Aufgaben")
    sub = p.add_subparsers(dest="cmd", required=True)
    h = sub.add_parser("heute"); h.add_argument("--wer"); h.add_argument("--datum"); h.add_argument("--tage", type=int, default=14)
    sub.add_parser("check"); sub.add_parser("team")
    e = sub.add_parser("export"); e.add_argument("--format", choices=["csv", "xlsx"], default="xlsx"); e.add_argument("--out", required=True)
    e.add_argument("--wer"); e.add_argument("--datum")
    v = sub.add_parser("view"); v.add_argument("--out", required=True); v.add_argument("--datum"); v.add_argument("--tage", type=int, default=14)
    z = sub.add_parser("zuweisen"); z.add_argument("id"); z.add_argument("wer")
    d = sub.add_parser("erledigt"); d.add_argument("id"); d.add_argument("--datum")
    args = p.parse_args(argv)
    data = load()
    today = day(args.datum) if getattr(args, "datum", None) else dt.date.today()
    if args.cmd == "heute":
        print(markdown(data, today, args.wer, args.tage))
    elif args.cmd == "check":
        errs = check(data)
        print("ok · {} Aufgaben · {} Personen".format(len(data["aufgaben"]), len(data["team"])) if not errs else "\n".join(errs))
        return 1 if errs else 0
    elif args.cmd == "team":
        for t in data["team"]: print("{:<11} {} – {}".format(t["id"], t["name"], t["rolle"]))
    elif args.cmd == "export":
        head, rows = table(data, today, args.wer)
        if args.format == "csv":
            with open(args.out, "w", encoding="utf-8-sig", newline="") as f:     # BOM + ";" so Excel (DE) opens it right
                w = csv.writer(f, delimiter=";"); w.writerow(head); w.writerows(rows)
        else:
            write_xlsx(args.out, head, rows)
        print("{} Zeilen → {}".format(len(rows), args.out))
    elif args.cmd == "view":
        items = []
        for i in classify(data, today, args.tage):
            a = dict(i["a"])
            a.update(bereich=bereich(i["a"]), topf=i["topf"], datum=i["datum"].isoformat() if i.get("datum") else None, grund=i.get("grund"),
                     blockiertDurch=i["blockiert_durch"], rhythmus=wiederholung_text(a.get("wiederholung")))
            items.append(a)
        done = [a for a in data["aufgaben"] if a.get("status") == "erledigt" and not a.get("wiederholung")]
        view = {"stand": today.isoformat(), "tage": args.tage, "phase": data["meta"].get("phase"), "team": data["team"],
                "toepfe": [{"id": k, "titel": t} for k, t in BUCKETS], "aufgaben": items, "erledigt": done}
        with open(args.out, "w", encoding="utf-8") as f:
            json.dump(view, f, ensure_ascii=False)
        print("{} Aufgaben → {}".format(len(items), args.out))
    elif args.cmd in ("zuweisen", "erledigt"):
        a = next((x for x in data["aufgaben"] if x["id"] == args.id), None)
        if not a: print("keine Aufgabe " + args.id); return 1
        if args.cmd == "zuweisen":
            if args.wer not in {t["id"] for t in data["team"]}: print("unbekannte Person " + args.wer + " (siehe: team)"); return 1
            a["wer"] = args.wer
        elif a.get("wiederholung"):
            a["erledigtAm"] = today.isoformat()
        else:
            a["status"] = "erledigt"; a["erledigtAm"] = today.isoformat()
        save(data); print("gespeichert: " + a["titel"])
    return 0


if __name__ == "__main__":
    sys.exit(main())
