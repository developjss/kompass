"""Der Rote Faden – das zentrale Dokument des Gründers: wie Kompass funktioniert, Seite für Seite.

Aufbau wie bei Gapless: jede Seite der App = eine Seite im Dokument (Brotkrume oben, Bild, Klicks, Gespeichert,
Kommt noch, Link zurück). Pflege und Prüfung: README.md im selben Ordner. Bauen:

    python3 docs/produkt/roter-faden/roter_faden.py
"""
import json, os, re, subprocess, shutil
from docx_bau import Doc

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
B = lambda n: os.path.join(HERE, "bilder", n)
STAND = "23. November 2026"
VERSION = "1"
SECTIONS = []          # (Kapitel-Anker, Seiten-Anker, Titel) – für Inhalt und Prüfung
NR = {}
GH = "https://github.com/developjss/kompass/blob/main/"
KLICKDUMMY = "https://claude.ai/artifact/WGCELrUQhpXXw83xyqfoyG"
KLICKDUMMY_IPHONE = "https://claude.ai/artifact/8eGuar3yT9cbmESEypVfRq"

d = Doc()


def doc(pfad, text=None):
    """Link in den Arbeitsordner (GitHub, Zweig main)."""
    return f"[[{text or pfad.split('/')[-1]}|{GH}{pfad}]]"


def _inhalt(wozu=None, bilder=(), klicks=(), gespeichert=None, kommt=(), extra=None, breite=None):
    if wozu:
        d.p(wozu)
    if bilder:
        w = breite or {1: 5.6, 2: 5.2, 3: 4.4}[len(bilder)] - (0.8 if extra else 0)
        d.shots([(B(f), c) for f, c in bilder], w)
    if klicks:
        d.p("**Was passiert, wenn du tippst**", space_after=40)
        d.bullets(list(klicks), arrow=True)
    if extra:
        extra()
    if gespeichert:
        d.p("**Gespeichert:** " + gespeichert)
    if kommt:
        d.box("Kommt noch", list(kommt), fill="EEF0FD", edge="3B4CCA")


def kapitel(titel, anker, text, seiten, **inhalt):
    nr = NR[anker] = len(NR)
    d.crumb([("Inhalt", "inhalt"), (f"Kapitel {nr}", None)])
    d.h(f"{nr}  {titel}", 1, anker)
    for t in text:
        d.p(t)
    if seiten:
        d.p("**Seiten in diesem Kapitel:**", space_after=40)
        d.bullets([f"[[{t}|{a}]]" for t, a in seiten], arrow=True)
    if inhalt:
        _inhalt(**inhalt)
    d.p(d.link("↑ Inhalt", "inhalt"), raw=True, style="Small")
    SECTIONS.append((anker, anker, f"{nr}  {titel}"))
    return (titel, anker)


def seite(kap, titel, anker, wozu, **inhalt):
    kap_titel, kap_anker = kap
    d.crumb([("Inhalt", "inhalt"), (f"{NR[kap_anker]} {kap_titel}", kap_anker), (titel, None)])
    d.h(titel, 2, anker)
    _inhalt(wozu, **inhalt)
    d.p(d.link(f"↑ {kap_titel}", kap_anker) + d.run("   ·   ") + d.link("↑ Inhalt", "inhalt"), raw=True, style="Small")
    SECTIONS.append((kap_anker, anker, titel))


LOKAL = "im Klick-Dummy im Browser und privat im Claude-Konto; in der App auf dem Gerät (SwiftData), später per Sync auf allen Geräten."

# =============================================================== Titelseite
d.p("Kompass", style="Title")
d.p("Der rote Faden – wie die App funktioniert, Seite für Seite", style="Subtitle")
d.p(f"Stand {STAND} · Fassung {VERSION} · wird bei jeder Änderung mitgepflegt", style="Small")
d.image(B("heute.jpg"), 4.6, "Die Startseite „Heute“ im Klick-Dummy (erfundene Daten)")
d.box("So liest du dieses Dokument", [
    "Jede Seite hier ist **eine Seite der App**. Oben steht, wo du bist (blaue Wörter führen zurück), unten „↑ Inhalt“.",
    "→ sagt, wohin ein Tipp führt. **Gespeichert** sagt, wo das Ergebnis liegt. **Kommt noch** zeigt, was die echte App zusätzlich braucht.",
    f"Stand ist der **Klick-Dummy** ([[Desktop|{KLICKDUMMY}]] · [[iPhone|{KLICKDUMMY_IPHONE}]]). Die SwiftUI-App ist als erste, grobe Fassung angelegt (" + doc("docs/technik/app.md", "Die App") + ") und wird danach weitergebaut. Dort heißen die Bereiche inzwischen Heute, Kalender, Lotse (Assistent, in der Mitte), Fortschritt (Ziele · Habits) und Rückblick.",
])
INHALT_POS = len(d.body)


# =============================================================== 0 Was gerade ansteht
def fahrplan_zeilen():
    try:
        out = subprocess.run(["python3", os.path.join(REPO, "scripts", "fahrplan.py"), "heute"], capture_output=True, text=True, cwd=REPO, timeout=60).stdout
    except Exception:
        return {}
    teile, akt = {}, None
    for z in out.splitlines():
        if z.startswith("## "):
            akt = re.sub(r"\s*·\s*\d+$", "", z[3:]).strip(); teile[akt] = []
        elif z.startswith("- ") and akt and not z.startswith("- …"):
            wichtig = "❗" in z
            m = re.match(r"- (?:❗ )?(?:\*\*Wenn ([^*]+)\*\* )?\*\*([^*]+)\*\*(?: — (.*?))?(?: `[^`]+`)?$", z)
            if not m:
                continue
            wenn, was, meta = m.groups()
            meta = (meta or "").split(" · ")
            wann = meta[0] if meta and re.search(r"\d|heute", meta[0]) else ""
            wer = " · ".join(x for x in meta if x != wann and not x.startswith("nach "))
            teile[akt].append((was, wann, wer, wichtig))
    return teile


def landkarte_stand():
    try:
        k = json.load(open(os.path.join(REPO, "docs", "landkarte", "landkarte.json")))
    except Exception:
        return []
    def zaehle(n, c):
        c[n.get("s", "")] = c.get(n.get("s", ""), 0) + 1
        for x in n.get("c", []): zaehle(x, c)
        return c
    return [(b["t"], zaehle(b, {})) for b in k["root"].get("c", [])]


K0 = kapitel("Was gerade ansteht", "kap0", [
    "Die Zentrale: hier nur kurze Hinweise. Das Ausführliche liegt im **Fahrplan** (alle Aufgaben), in der **Landkarte** und in den Fachdokumenten – jeweils verlinkt.",
], [("Fahrplan: heute und bald", "fahrplan"), ("Landkarte", "landkarte"), ("Offene Entscheidungen", "offen")])


def _fahrplan():
    t = fahrplan_zeilen()
    rows = [["Was", "Wann", "Wer"]]
    for teil, n in [("Heute zu tun", 6), ("Bald (nächste 14 Tage)", 8), ("Als Nächstes (ohne Datum)", 5)]:
        for was, wann, wer, wichtig in t.get(teil, [])[:n]:
            rows.append([("❗ " if wichtig else "") + was, wann, wer])
    if len(rows) > 1:
        d.table(rows, [5600, 1700, 2338])
    else:
        d.p("Der Fahrplan ließ sich beim Bauen nicht lesen – `/fahrplan` zeigt ihn.")
    d.p("Alles: in Claude Code **/fahrplan** · Quelle " + doc("docs/leitung/aufgaben/aufgaben.json") + ".")


seite(K0, "Fahrplan: heute und bald", "fahrplan", f"Stand beim Bauen ({STAND}). ❗ = wichtig. Neue Aufgaben kommen nur in den Fahrplan.", extra=_fahrplan)


def _landkarte():
    namen = {"built": "gebaut", "partial": "teilweise", "planned": "geplant", "idea": "Idee"}
    rows = [["Bereich", "gebaut", "teilweise", "geplant", "Idee"]]
    for t, c in landkarte_stand():
        rows.append([t] + [str(c.get(k, 0)) for k in namen])
    d.table(rows, [4200, 1350, 1350, 1350, 1388])
    d.p("Quelle " + doc("docs/landkarte/landkarte.json") + " · Seite: " + doc("docs/landkarte/landkarte.html") + ".")


seite(K0, "Landkarte", "landkarte", "App und Projekt als ein Baum: jeder Baustein mit Status und wer zuständig ist. Die Aufgaben im Fahrplan zeigen auf ihre Knoten.", extra=_landkarte)

seite(K0, "Offene Entscheidungen", "offen", "Was du noch entscheidest. Technik-Weg A (SwiftUI zuerst) ist entschieden. Ausführlich: " + doc("docs/leitung/entscheidungen.md", "Entscheidungen") + ".",
      extra=lambda: d.table([
          ["Thema", "Vorschlag Claude"],
          ["App-Name (Arbeitstitel Kompass)", "–"],
          ["Sprache der App-Texte", "Deutsch zuerst, Englisch ab Phase 3"],
          ["Nur für dich oder Abo-Produkt", "Abo-Produkt (B2C)"],
          ["90-%-Regel bei Schritten", "so lassen"],
          ["Habits in den Prozenten nur über Habit-Schritte", "so lassen"],
          ["Fokusblöcke in Google/Apple zurückschreiben", "optional, Phase 3"],
          ["Kalendertermine direkt in Schritte zählen", "ja, Phase 3"],
      ], [4800, 4838]))

# =============================================================== 1 Die Idee
K1 = kapitel("Die Idee", "kap1", [
    "Kompass verbindet **heute** (Aufgaben, Termine), **täglich** (Habits) und **morgen** (Ziele über Monate und Jahre). Jede Aufgabe, jeder Habit und jeder Kalendertermin kann einem Ziel zugeordnet werden – dann sieht man, wie viel Zeit wirklich in „Führerschein“ oder „LAPL(A)“ fließt.",
    "Kompass **ergänzt** Apple- und Google-Kalender, ersetzt sie nicht – kann es aber.",
], [("Drei Ebenen", "ebenen"), ("Die 6 Prinzipien", "prinzipien")])
seite(K1, "Drei Ebenen", "ebenen", "Habits und Ziele bleiben getrennt: ein Habit hat eine Serie, ein Ziel ein Datum und einen Fortschritt.",
      extra=lambda: d.table([
          ["Ebene", "Beispiel", "Zeitraum", "Gemessen über"],
          ["Ziele", "Führerschein, Flugprüfung in 5 Jahren", "Monate bis Jahre", "Schritte oder eine Zahl"],
          ["Habits", "täglich lesen, werktags lernen", "ohne Ende", "Serie, Quote"],
          ["Aufgaben", "Theorie-Fragebogen Kapitel 4", "ein Tag", "erledigt, Fokuszeit"],
      ], [1600, 3600, 1900, 2538]), gespeichert="Quelle " + doc("docs/produkt/grundlage.md") + ".")
seite(K1, "Die 6 Prinzipien", "prinzipien", "Aus deiner Ideen-Word – und wo sie in der App stecken.",
      extra=lambda: d.table([
          ["Prinzip", "In der App"],
          ["1 Nur eine Aufgabe sichtbar", "Karte „Jetzt dran“, Auge-Schalter, Fokus-Modus"],
          ["2 Zeit messen", "Timer mit Pause; nach „Erledigt“ kommt die nächste Aufgabe"],
          ["3 Done-Liste statt To-do-Liste", "„Geschafft“ auf Heute, Rückblick"],
          ["4 Ritualisierte Reflexion", "Tagesabschluss, Wochenreflexion"],
          ["5 Input statt Output", "investierte Stunden je Ziel, „Auf Kurs“"],
          ["6 Vertikale Kohärenz", "Kette Ziel → Schritt → Aufgabe in jeder Aufgabe"],
      ], [3600, 6038]))

# =============================================================== 2 Heute
K2 = kapitel("Heute", "kap2", ["Die Startseite: was jetzt dran ist und was heute zählt."],
             [("Heute", "heute"), ("Fokus-Modus", "fokus"), ("Tagesabschluss", "reflexion"), ("Erklärung (i)", "info")])
seite(K2, "Heute", "heute", "Oben die eine Aufgabe, die jetzt dran ist; darunter Wichtig (zahlt auf Ziele ein), Weitere, Geschafft; daneben bzw. darunter Habits, Termine, Ziele.",
      bilder=[("heute.jpg", "Heute")],
      klicks=["Fokus starten → [[Fokus-Modus|fokus]]", "Kreis links → erledigt, landet unter „Geschafft“", "Aufgabe antippen → Aufgabe bearbeiten (Datum, Uhrzeit, Ziel, Schritt, Wiederholung)",
              "Auge bei „Wichtig“ → nur eine Aufgabe sichtbar (Prinzip 1)", "„Liegen geblieben“ → „Alle auf heute“", "+ Neu → [[Hinzufügen|neu]]", "Tagesabschluss → [[Tagesabschluss|reflexion]]"],
      gespeichert=LOKAL)
seite(K2, "Fokus-Modus", "fokus", "Vollbild mit Timer. Jede Minute zählt für das Ziel und den Schritt der Aufgabe.",
      bilder=[("fokus.jpg", "Fokus")],
      klicks=["Pause / Weiter", "Erledigt → nächste Aufgabe startet automatisch", "Stoppen → Zeit wird gebucht (an Mitternacht geteilt, höchstens 4 Stunden am Stück)"],
      gespeichert="als Fokus-Sitzung je Tag; " + LOKAL)
seite(K2, "Tagesabschluss", "reflexion", "Drei Fragen am Abend, drei am Wochenende (Prinzip 4).",
      bilder=[("reflexion.jpg", "Tagesabschluss")], klicks=["Täglich / Wöchentlich umschalten", "Speichern → erscheint unter „Frühere“"], gespeichert=LOKAL)
seite(K2, "Erklärung (i)", "info", "Jede Seite hat oben ein (i). Erklärungen stehen dort statt auf der Seite (Textregel: ≤ ~35 Wörter je Bildschirm).",
      bilder=[("info.jpg", "Erklärung")])

# =============================================================== 3 Kalender
K3 = kapitel("Kalender", "kap3", ["Planen und Kalender in einem Bereich. Ergänzt Google und Apple."],
             [("Kalender", "kalender"), ("Termin zuordnen", "termin"), ("Einstellungen & Kalender verbinden", "einstellungen")])
seite(K3, "Kalender", "kalender", "Tag oder Woche. Oben je Tag die Aufgaben ohne Uhrzeit, darunter die Stunden mit Terminen. Der Eingang sammelt Ideen ohne Datum.",
      bilder=[("kalender.jpg", "Kalender (Tag)")],
      klicks=["In eine freie Stunde tippen → Aufgabe zu dieser Uhrzeit", "„+“ unter einem Tag → Aufgabe ohne Uhrzeit", "Aufgabe ziehen (am Handy kurz halten) → anderer Tag oder Uhrzeit",
              "Gestreifter Block (Termin) → [[Termin zuordnen|termin]]", "Eingang ⌄ → aufklappen"],
      gespeichert=LOKAL + " Termine selbst bleiben in Google/Apple.",
      kommt=["Echte Anbindung: Apple über EventKit, Google über Anmeldung (OAuth) – " + doc("docs/produkt/konzepte/kalender-anbindung.md")])
seite(K3, "Termin zuordnen", "termin", "Ein Termin aus Google oder Apple kann einem Ziel oder Habit zugeordnet werden – für die ganze Serie, ab heute.",
      bilder=[("termin.jpg", "Termin")],
      klicks=["Ziel wählen → Zeit jeder stattgefundenen Fahrstunde zählt fürs Ziel", "Habit wählen → wird an Termintagen abgehakt", "„Aufgabe daraus machen“ → Vorbereitung"],
      gespeichert="nur die Zuordnung (Serie → Ziel/Habit); " + LOKAL)
seite(K3, "Einstellungen & Kalender verbinden", "einstellungen", "Kalender verbinden, neue Aufgaben oben/unten, Daten exportieren und importieren.",
      bilder=[("einstellungen.jpg", "Einstellungen")],
      klicks=["Schalter Google/Apple → im Klick-Dummy Beispieltermine", "Export kopieren / Import", "Demo-Daten zurücksetzen"],
      gespeichert=LOKAL)

# =============================================================== 4 Habits
K4 = kapitel("Habits", "kap4", ["Das Tägliche: kein Enddatum, sondern eine Serie."], [("Habits", "habits"), ("Ein Habit", "habit")])
seite(K4, "Habits", "habits", "Oben „x von y geschafft“ mit den letzten 7 Tagen; dann Heute (je Habit „12 von 20 min“), Diese Woche (Tage als Punkte, n-mal pro Woche als Balken) und Alle Habits (Soll, Quote, Serie). In der App hat ein Habit eine Menge mit Einheit (Minuten, Seiten, Gramm, km …) oder wird nur abgehakt; halb geschafft zählt halb.",
      bilder=[("habits.jpg", "Habits")], klicks=["Zeile mit Menge → Menge eintragen (Schnellwahl ½, ganz …)", "Haken → ganz erledigt / zurücknehmen", "Name → [[Ein Habit|habit]]"], gespeichert=LOKAL)
seite(K4, "Ein Habit", "habit", "Eigene Seite wie eine Gapless-Transaktion: Kopfkarte (Stand heute, Serie), Heute abhaken oder Menge eintragen, Stand (Serie · beste · Quote), Fakten-Zeilen mit Pfeil (Titel, Menge, Rhythmus, Erinnerung, Ziel, Aussehen – jede öffnet ihren Editor), letzte 14 Tage, „Zählt in“ (Meilensteine), Löschen. Zur Erinnerungszeit kommt eine Mitteilung, solange der Habit an dem Tag offen ist.",
      bilder=[("habit.jpg", "Habit")], klicks=["Fakten-Zeile → Editor (Sichern)", "Tag im Verlauf → Menge nachtragen", "Erinnerung einschalten → einmal Erlaubnis für Mitteilungen", "Habit löschen"], gespeichert=LOKAL)

# =============================================================== 5 Ziele
K5 = kapitel("Ziele", "kap5", ["Wohin du willst – mit ehrlicher, nachvollziehbarer Rechnung."],
             [("Ziele", "ziele"), ("Ein Ziel", "ziel"), ("So wird gerechnet", "rechnung"), ("Ein Schritt", "schritt"), ("Vorschläge", "vorschlaege")])
seite(K5, "Ziele", "ziele", "Oben eine Aussage-Karte („2 von 3 auf Kurs“, wo es hakt, Schnitt). Darunter die Ziele (nach Jahr nur, wenn es mehrere Jahre gibt). Jede Karte: Prozent, „voraus / im Plan / hinterher“, restliche Zeit, Fokuszeit der letzten Wochen.",
      bilder=[("ziele.jpg", "Ziele")], klicks=["Karte → [[Ein Ziel|ziel]]", "Erreicht › → erreichte Ziele", "+ Neu → Ziel: Meilenstein-Vorlagen aus dem Titel (Prüfung, Gewicht, Geld, Ausdauer, Bücher, Sprache, Projekt, Drei Schritte)"], gespeichert=LOKAL)
seite(K5, "Ein Ziel", "ziel", "Kopfkarte mit Prozent, Auf Kurs, Prognose; direkt darunter ein Satz „so wird gerechnet“ (z. B. „32 % = gewichteter Durchschnitt von 4 Meilensteinen · am meisten fehlt bei …“). Dann Meilensteine (schlanke Zeilen mit Pfeil), Aufgaben, Habits, Termine, Einsatz und Fakten-Zeilen (Titel, Bis wann, Bereich, Warum, Aussehen – jede öffnet ihren Editor), erreicht, löschen.",
      bilder=[("ziel.jpg", "Ziel")], klicks=["Satz oder (i) → [[So wird gerechnet|rechnung]]", "Meilenstein → [[Ein Schritt|schritt]]", "Fakten-Zeile → Editor (Sichern)", "✓ Ziel erreicht"], gespeichert=LOKAL)
seite(K5, "So wird gerechnet", "rechnung", "Die Rechnung mit echten Zahlen, für jedes Ziel aufklappbar: Tabelle der Schritte, Auf Kurs, Prognose, gelernter Zeitfaktor.",
      bilder=[("rechnung.jpg", "Rechnung")], gespeichert="Formeln: " + doc("docs/produkt/rechenregeln.md") + " (Kapitel [[Rechenregeln|kap7]])")
seite(K5, "Ein Schritt", "schritt", "Wie der Schritt gemessen wird (Abhaken/Aufgaben, Zeit, Habit, Zahl), Zielwert, Gewicht (klein/mittel/groß), geschafft, Aufgaben im Schritt.",
      bilder=[("schritt.jpg", "Schritt")], klicks=["Messart wechseln", "Gewicht wählen", "Geschafft → 100 %", "Aufgabe hinzufügen → gehört zu diesem Schritt"], gespeichert=LOKAL)
seite(K5, "Vorschläge", "vorschlaege", "Passende Schritte aus Vorlagen – oder von der KI. Alles übernehmen oder vorher ändern. Gerechnet wird danach immer gleich.",
      bilder=[("vorschlaege.jpg", "Vorschläge")], klicks=["Haken → übernehmen ja/nein", "Name, Art, Zielwert, Gewicht ändern", "✨ Mehr Vorschläge von der KI", "x übernehmen"],
      gespeichert="Schritte im Ziel; gelernt wird, was du übernimmst und wie lange Zeit-Schritte wirklich dauern.",
      kommt=["Lernen über alle Nutzer – " + doc("docs/produkt/konzepte/lernen-ueber-alle-nutzer.md")])

# =============================================================== 6 Rückblick & Hinzufügen
K6 = kapitel("Rückblick und Hinzufügen", "kap6", ["Die Woche im Blick – und wie Neues in die App kommt."],
             [("Rückblick", "rueckblick"), ("Hinzufügen", "neu"), ("Aufgabe anlegen", "neu-aufgabe"), ("Erster Start", "willkommen")])
seite(K6, "Rückblick", "rueckblick", "Fokuszeit mit 12-Wochen-Kurve, Zeit pro Ziel als Ring, Habit-Quote, Wochenreflexion.",
      bilder=[("rueckblick.jpg", "Rückblick")], klicks=["‹ › → andere Woche", "Wochenreflexion → [[Tagesabschluss|reflexion]]"])
seite(K6, "Hinzufügen", "neu", "„+ Neu“ oben auf jeder Seite: vier Kacheln.",
      bilder=[("neu.jpg", "Hinzufügen")], klicks=["Aufgabe → [[Aufgabe anlegen|neu-aufgabe]]", "Habit → Name, Rhythmus, Ziel", "Ziel → Name, Datum, dann [[Vorschläge|vorschlaege]]", "Idee → Aufgabe ohne Datum in den Eingang"])
seite(K6, "Aufgabe anlegen", "neu-aufgabe", "Titel, wann (Heute, Morgen, Eingang, Datum, Uhrzeit), wichtig oder weitere, Ziel.",
      bilder=[("neu-aufgabe.jpg", "Aufgabe")], gespeichert="Aufgabe fällt automatisch in den nächsten offenen Schritt ihres Ziels; " + LOKAL)
seite(K6, "Erster Start", "willkommen", "Neue Nutzer wählen: Beispieldaten ansehen oder leer starten.",
      bilder=[("willkommen.jpg", "Willkommen")])

# =============================================================== 7 Rechenregeln
K7 = kapitel("Rechenregeln", "kap7", [
    "Jede Zahl der App folgt festen Formeln – egal ob Vorschlag übernommen, geändert oder selbst angelegt. Die KI schlägt nur vor. Quelle: " + doc("docs/produkt/rechenregeln.md") + ".",
], [("Fortschritt und Schritte", "formeln"), ("Auf Kurs, Prognose, Lernen", "kurs"), ("Wie geprüft wird", "test")])
seite(K7, "Fortschritt und Schritte", "formeln", "**Ziel-Fortschritt = Σ(Gewicht × Stand) ÷ Σ Gewicht** · als Zahl: (aktuell − Start) ÷ (Ziel − Start).",
      extra=lambda: (d.table([
          ["Schritt misst …", "Stand"],
          ["Aufgaben / abhaken", "90 % × erledigte ÷ alle einmaligen Aufgaben; letzte 10 % durch Abhaken"],
          ["Zeit", "Fokusstunden ÷ Soll-Stunden"],
          ["Habit", "erledigte Male seit Anlage ÷ Soll-Anzahl"],
          ["Zahl", "(aktuell − Start) ÷ (Ziel − Start)"],
      ], [3000, 6638]), d.bullets(["Abgehakt = 100 %. Immer zwischen 0 und 100 %. Gewicht klein 1, mittel 2, groß 3.",
                                    "Neue Aufgaben fallen in den nächsten offenen Schritt; wiederkehrende zählen über die Zeit.",
                                    "Beispiel Führerschein: 6,44 ÷ 13 = 49,5 % (siehe [[So wird gerechnet|rechnung]])."])))
seite(K7, "Auf Kurs, Prognose, Lernen", "kurs", "",
      extra=lambda: d.bullets([
          "**Auf Kurs:** erwartet = verstrichene Tage ÷ Tage bis Fälligkeit. Ab +5 Punkten „voraus“, ab −10 „hinterher“, nach Fälligkeit „überfällig“.",
          "**Prognose:** Tempo der letzten ~4 Wochen → voraussichtliches Datum.",
          "**Habits:** Serie ohne Obergrenze; heute zählt erst, wenn abgehakt; Tage vor der Anlage zählen nicht.",
          "**Zeitfaktor:** (Σ tatsächlich÷geplant + 3) ÷ (Anzahl + 3) – passt Zeit-Vorschläge an dein Tempo an.",
          "**Übernahme-Quote:** (übernommen + 1) ÷ (gezeigt + 2) – ab 40 % vorausgewählt.",
          "**Timer:** an Mitternacht geteilt, höchstens 4 Stunden am Stück. **Wiederholung:** ohne Abrutschen (31. bleibt Monatsende).",
      ]))
seite(K7, "Wie geprüft wird", "test", "Vier erfundene Personen über zwei Jahre, Tag für Tag, mit zufälligen Eingriffen – jede Zahl gegen eine zweite, unabhängig geschriebene Rechnung.",
      extra=lambda: d.table([
          ["Person", "Vermögen / Ziele", "Tagesablauf"],
          ["Lena", "12.000 € Schulden, Bachelor", "unregelmäßig, vergisst den Timer"],
          ["Markus", "ETF-Depot, Halbmarathon", "9–17 Uhr, liest 730 Tage am Stück"],
          ["Aylin", "Krypto + Firma, schwankt stark", "arbeitet nachts über Mitternacht"],
          ["Jonas", "Eigenkapital in Sprüngen, LAPL, Führerschein", "Schichtarbeit, wechselnde Lerntage"],
      ], [1400, 4200, 4038]),
      gespeichert="Bericht " + doc("docs/technik/berichte/personen-zwei-jahres-test-2026-11-23.md") + " · Test " + doc("prototyp/tests/run.py") + ". Ergebnis 23.11.2026: grün, 13 Fehler vorher behoben.")

# =============================================================== 8 Über dieses Dokument
K8 = kapitel("Über dieses Dokument", "kap8", ["Wie es aktuell bleibt und was sich geändert hat."], [("Pflege und /roterfaden", "pflege"), ("Änderungsverlauf", "verlauf")])
seite(K8, "Pflege und /roterfaden", "pflege", "Damit hier nie etwas fehlt oder veraltet.",
      extra=lambda: d.bullets([
          "**/roterfaden** in Claude Code: zeigt, wo das Dokument liegt, prüft es gegen Klick-Dummy und Code und bringt es auf Stand.",
          "**Bei jeder sichtbaren Änderung:** Bilder neu (`python3 scripts/bilder.py`), Text in roter_faden.py, bauen, `pruefen.py`.",
          "**Zentraldatei:** hier nur kurz; Ausführliches in Fahrplan, Landkarte, Rechenregeln, Fachdokumenten.",
          "Ablage: " + doc("docs/produkt/roter-faden/kompass-roter-faden.docx") + " und auf dem Mac eine Kopie in iCloud Drive › Kompass.",
      ]))
seite(K8, "Änderungsverlauf", "verlauf", "Neueste oben.",
      extra=lambda: d.table([
          ["Datum", "Fassung", "Was sich geändert hat"],
          ["23.11.2026", "1", "Erste Fassung: Klick-Dummy Seite für Seite, Rechenregeln, Personen-Test, Fahrplan und Landkarte."],
      ], [1600, 1000, 7038]))

# =============================================================== Inhalt einsetzen
start = len(d.body)
d.crumb([("Kompass – Der rote Faden", None)])
d.h("Inhalt", 1, "inhalt")
for kap_anker, anker, titel in SECTIONS:
    if kap_anker == anker:
        d.p(d.link(titel, anker), raw=True, space_after=20)
    else:
        d.body.append(f'<w:p><w:pPr><w:ind w:left="567"/><w:spacing w:after="0"/></w:pPr>{d.link(titel, anker)}</w:p>')
inhalt = d.body[start:]
del d.body[start:]
d.body[INHALT_POS:INHALT_POS] = inhalt

out = os.path.join(HERE, "kompass-roter-faden.docx")
d.save(out, "Kompass – Der rote Faden")
print("geschrieben:", out, "·", len(SECTIONS), "Abschnitte")

ICLOUD = os.path.expanduser("~/Library/Mobile Documents/com~apple~CloudDocs")
if os.path.isdir(ICLOUD):
    ziel = os.path.join(ICLOUD, "Kompass")
    os.makedirs(ziel, exist_ok=True)
    shutil.copy2(out, os.path.join(ziel, "Kompass – Der rote Faden.docx"))
    print("Kopie in iCloud Drive/Kompass/")
