"""Prüft den Roten Faden. Schnell (immer): Links, Bilder, Abdeckung gegen den Klick-Dummy (später: Swift-Code).
Voll (mit --pdf, nur Mac mit Pages): rendert zu PDF und prüft jede Seite (jeder Abschnitt genau eine Seite).

    python3 docs/produkt/roter-faden/pruefen.py          # schnell
    python3 docs/produkt/roter-faden/pruefen.py --pdf    # voll
"""
import io, json, os, re, subprocess, sys, contextlib, zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
sys.path.insert(0, HERE)
with contextlib.redirect_stdout(io.StringIO()):
    import roter_faden as rf
fehler = []

# 1 Links und Bilder
for a in set(rf.d.links):
    if a not in rf.d.anchors: fehler.append(f"Link ohne Ziel: {a}")
for p in rf.d.images:
    if not os.path.exists(p): fehler.append(f"Bild fehlt: {p}")
if len(set(rf.d.anchors)) != len(rf.d.anchors): fehler.append("Sprungmarke doppelt")

# 2 Abdeckung: jede Ansicht und jedes Fenster des Klick-Dummys hat eine Seite (Anker) im Dokument
xml = zipfile.ZipFile(os.path.join(HERE, "kompass-roter-faden.docx")).read("word/document.xml").decode()
text = re.sub(r"<[^>]+>", "", xml)
ausnahmen = {l.split("|")[0].strip() for l in open(os.path.join(HERE, "abdeckung-ausnahmen.txt"), encoding="utf-8") if l.strip() and not l.startswith("#")}
app = open(os.path.join(ROOT, "prototyp", "index.html"), encoding="utf-8").read()
ansichten = set(re.findall(r"\['(\w+)','[^']+','\w+'\]", app[app.index("const ROUTES="):app.index("const ROUTES=") + 400]))
fenster = set(re.findall(r"function sheet(\w+)\(", app))
gebraucht = {"ansicht:" + a for a in ansichten} | {"fenster:" + f for f in fenster}
ANKER = {"ansicht:heute": "heute", "ansicht:kalender": "kalender", "ansicht:habits": "habits", "ansicht:ziele": "ziele", "ansicht:rueckblick": "rueckblick",
         "fenster:Goal": "ziel", "fenster:Step": "schritt", "fenster:Suggest": "vorschlaege", "fenster:Task": "neu-aufgabe", "fenster:Habit": "habit",
         "fenster:Event": "termin", "fenster:Settings": "einstellungen", "fenster:New": "neu-aufgabe", "fenster:Chooser": "neu",
         "fenster:Reflect": "reflexion", "fenster:Info": "info"}
for g in sorted(gebraucht - ausnahmen):
    if ANKER.get(g) not in rf.d.anchors:
        fehler.append(f"Fehlt im Dokument: {g} (steht im Klick-Dummy) – Seite anlegen oder in ANKER/abdeckung-ausnahmen.txt eintragen")

# 3 Seiten (nur mit --pdf, Mac)
if "--pdf" in sys.argv:
    import tempfile
    tmp = os.path.join(tempfile.gettempdir(), "roter-faden-pruefung")
    os.makedirs(tmp, exist_ok=True)
    src, pdf = os.path.join(tmp, "rf.docx"), os.path.join(tmp, "rf.pdf")
    subprocess.run(["cp", os.path.join(HERE, "kompass-roter-faden.docx"), src], check=True)
    if os.path.exists(pdf): os.remove(pdf)
    subprocess.run(["open", "-a", "Pages"]); subprocess.run(["sleep", "5"])
    skript = f'tell application "Pages"\nset d to open (POSIX file "{src}")\ndelay 5\nexport d to (POSIX file "{pdf}") as PDF\nclose d saving no\nend tell'
    for versuch in range(3):
        if subprocess.run(["osascript", "-e", skript]).returncode == 0: break
        subprocess.run(["sleep", "5"])
    else:
        sys.exit("Pages konnte das PDF nicht erzeugen")
    pages = json.loads(subprocess.run(["swift", os.path.join(HERE, "seiten.swift"), pdf], capture_output=True, text=True, check=True).stdout)
    body = pages[2:]
    while body and "Kapitel 0" not in body[0][:120]: body = body[1:]
    if len(body) != len(rf.SECTIONS): fehler.append(f"Seiten: {len(body)} statt {len(rf.SECTIONS)} – ein Abschnitt passt nicht auf eine Seite")
    print(f"PDF: {len(pages)} Seiten, gespeichert in {pdf}")

print(f"{len(rf.SECTIONS)} Abschnitte, {len(set(rf.d.links))} Link-Ziele, {len(rf.d.images)} Bilder, {len(gebraucht - ausnahmen)} Ansichten/Fenster aus dem Klick-Dummy geprüft")
if fehler:
    print("FEHLER:"); [print(" -", f) for f in fehler]; sys.exit(1)
print("OK")
