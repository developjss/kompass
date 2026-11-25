# Stand und nächste Schritte – Kompass

Stand: 25. November 2026 (Europe/Berlin) · **Lebendes Dokument:** nach jedem gemergten Block und nach jeder Entscheidung aktualisieren. Wo welches Dokument liegt: `docs/README.md`. Wie wir arbeiten: `docs/team/arbeitsweise.md`.

## 1. Worum es geht

- **Kompass** (Arbeitstitel) verbindet **heute** (Aufgaben, Termine), **täglich** (Habits) und **morgen** (Ziele über Monate und Jahre) in einer App. Jede Aufgabe, jeder Habit und jeder Kalendertermin kann einem Ziel zugeordnet werden.
- **USP** [VORSCHLAG]: ergänzt Google- und Apple-Kalender (ersetzt sie nicht, kann es aber) und zeigt ehrlich, wie viel vom Alltag wirklich auf große Ziele einzahlt – mit nachvollziehbarer Rechnung („So wird gerechnet“).
- Ziel: veröffentlichen. Zuerst iPhone und Mac, danach Windows und Android (`docs/leitung/fahrplan.md`).
- Ausgangspunkt: Word „Idee“ des Gründers mit 6 Prinzipien (liegt beim Gründer, nicht im Repo), Inhalt in `docs/produkt/grundlage.md`.
- Repo: `kompass` (privat), getrennt von Gapless. Lokal: `~/Developer/Kompass` (Gapless bleibt in `~/Developer/UpcomingAPP-git`).

## 2. Aktueller Stand

**Phase 0 – Klick-Dummy: fertig (23.11.2026)** – alles in `prototyp/`:
- Fünf Bereiche: Heute, Kalender (Planen und Kalender in einem), Habits, Ziele, Rückblick. (In der App seit 23.11.2026: Fortschritt = Ziele · Habits, dazu Lotse.) Fokus-Timer, Hinzufügen-Kacheln, Einstellungen mit Kalender-Verbindung (Beispieltermine).
- Design wie Gapless (Harbor 2): Indigo, SF Pro Rounded, Verlaufskarten, gruppierte Listen, Text ≤ ~35 Wörter je Bildschirm (`docs/produkt/design.md`).
- **Fortschritts-Rechnung** mit Schritten (Aufgaben/abhaken, Zeit, Habit, Zahl), Gewichten, „Auf Kurs“, Prognose und Lernen; Vorschläge aus Vorlagen und KI (`docs/produkt/rechenregeln.md`).
- Speicherung: Browser + privat im Claude-Konto (nur Prototyp).
- **Personen-Test** (4 Personen × 2 Jahre, ~46.000 Vergleiche, 324 zufällige Eingriffe): grün. 13 Fehler gefunden und behoben (`docs/technik/berichte/personen-zwei-jahres-test-2026-11-23.md`).
- Veröffentlichte Klick-Dummys: Desktop https://claude.ai/artifact/WGCELrUQhpXXw83xyqfoyG · iPhone https://claude.ai/artifact/8eGuar3yT9cbmESEypVfRq
- Plan-Dokument (erste Fassung, teils überholt): https://claude.ai/artifact/C4GGc8iQmAQj542WrpLP9b

**Phase 2 begonnen – erste SwiftUI-Fassung (23.11.2026):** `Kompass.xcodeproj` mit Schemes Kompass und Kompass Beta. Rechen-Logik als Swift-Port mit 42 Tests, fünf Bereiche grob wie im Klick-Dummy, Speicherung als Datei auf dem Gerät, Beispieltermine. Kein Server, keine echte Kalender-Anbindung. Details und Lücken: `docs/technik/app.md`.

**Tabs und Lotse (23.11.2026, gemergt):** Fünf Tabs: Heute · Kalender · **Lotse** (Mitte) · **Fortschritt** (Ziele · Habits per Umschalter, getrennt) · Rückblick. Lotse = Chat-Assistent: App-Wissen aus dem Code, elf Werkzeuge, regelbasiertes Verstehen offline, Lernen aus Rückmeldungen, Steckdose für ein Sprachmodell. Sprachmodell entschieden (Weg A, Claude gestuft): Server-Code `supabase/functions/lotse/`, App-Anbindung mit Kontingent und Pro – Server läuft auf Supabase-Projekt „kompass“ (EU) und ist live gegen Claude geprüft (`docs/technik/lotse-server.md`).

**Habits v2, Block 1 (23.11.2026, gemergt PR #11):** Habits mit Menge und Einheit (halb geschafft zählt halb), Rhythmus inkl. n-mal pro Woche, Erinnerungszeit, Vorschläge aus dem Titel; Habits-Seite neu nach Gapless-Vorbild (Heute · Diese Woche · Alle), Menge eintragen. **Block 2 (23.11.2026, PR #13):** Habit als eigene Seite im Tab Fortschritt (Kopfkarte, Heute, Stand, Fakten-Zeilen mit Editor je Zeile, letzte 14 Tage, „Zählt in“), Erinnerungen als lokale Mitteilungen (UserNotifications, 7 Tage voraus, nur offene Tage). Konzept: `docs/produkt/konzepte/habits-v2.md`.

**Ziele v2 (23.11.2026, PR #14):** Aussage-Karte über alle Ziele, Satz „so wird gerechnet“ unter der Kopfkarte, schlanke Meilenstein-Zeilen, Fakten-Zeilen mit Editor je Zeile, Ziel löschen auf der Seite, Meilenstein-Vorlagen aus dem Titel beim Anlegen (Regeln, keine KI). Befund und Stand: `docs/produkt/konzepte/habits-v2.md` §9.

**Struktur v3 (23.11.2026, PR #15):** Home statt Heute (Jetzt-Karte für Termin, Aufgabe oder Habit; Hinweise bei engen Tagen, Überschneidungen, zu wenig Zeit), Kalender neu (Als Nächstes, Tag · Woche · Monat · Jahr, Ziehen in die Zeitleiste, eigene Termine mit Ziel/Habit, Farben nach Ziel oder Kategorie), Rückblick neu (Plan geschafft, Auslastung), Apple-Kalender lesen (EventKit, nach Zustimmung), Lotse mit „Als Nächstes“, „Wie voll ist mein Tag?“, „Termin eintragen“. Neue Rechenregel §9 Tagesplan (Gründer: „allem selber zustimmen“). Personen-Test (6 Personen × 3,5 Jahre) als Swift-Test, UI-Tests über die ganze App. Konzept: `docs/produkt/konzepte/struktur-v3.md`.

**Geführt v4 (23.11.2026, PR #16):** „Lotse“ heißt Assistent (KI-Zeichen, neuer Chat je App-Start, frühere Chats oben links); Anlegen in Schritten (Was → Titel → Wann → Details → Fertig); Home mit Reel „Dein Tag im Blick“; Kalender-Ziehen mit leuchtenden Zielzonen und Herausziehen; Fortschritt schlanker (Umschalter-Fehler behoben, Erledigtes eingeklappt). Konzept: `docs/produkt/konzepte/struktur-v3.md` §10.

**Ziele minimal (23.11.2026, PR #17):** Zielliste als weiße Karten mit Ring und „Als Nächstes“; Ziel-Seite nur Kopfkarte, Warum, „Dein nächster Schritt“ (ein Knopf) und Meilensteine; alles Weitere unter „Verfeinern“ auf eigenen Seiten mit Erklärsatz. Neue Rechenregel „nächster Schritt“ (rechenregeln.md §1), vom Gründer freigegeben. Konzept: `struktur-v3.md` §11.

**Kalender-Empfehlungen (23.11.2026, PR #18):** „Empfehlung“ ersetzt „Ohne Uhrzeit“ und „Eingang“: Kartenstapel mit Vorschlägen je Ansicht (Tag: freie Uhrzeit; Woche/Monat: freiester Tag bis zur Frist), Grund je Karte, Tippen erklärt das Ziehen, „Um 14:00 einplanen“. „Als Nächstes“ im selben Stapel-Stil. Umschalter Ziele/Habits und Tag/Woche/Monat/Jahr reagieren auf der ganzen Fläche. Rechenregel §9.1, freigegeben.

**Assistent mit Claude (23./24.11.2026, PR #19, #20):** Mit Server beantwortet Claude jede Frage – auch allgemeine und aktuelle (Websuche mit Quellen). Werkzeugschleife: Claude holt Daten über die Werkzeuge der App (die App rechnet) und formuliert selbst; Antworten mit Absätzen, Überschriften, Listen. Werkzeuge sehen den Apple-Kalender. „merken“: Vorlieben nur auf dem Gerät, in den Einstellungen löschbar. Ladeanzeige wie Gemini (Frage oben, animiertes Zeichen, Status). Regeln auf dem Gerät nur noch offline. [RISIKO] Kosten ≈ 1–2 Cent je Frage plus Websuche (`docs/technik/lotse-server.md` §6). [OFFEN] Lernen über alle Nutzer (anonyme Rückmeldungen mit Einwilligung) – Datenschutz-Entscheidung des Gründers.

**Ziele neu (24.11.2026, PR #22–#25):** Übersicht mit Filter-Kacheln (Weiß → Farbe) und Sortieren (Frist, Jahr, Fortschritt, Hinterher zuerst, Bereich, Name), Zielkarten nur mit Ring und vollem Titel, umlaufender Lichtrand. Ziel-Seite: Stand minimal (Analyse im Rückblick), Einstellungs-Kacheln, Meilensteine als Karten. Meilensteine geführt (Fragen statt Formular, Live-Anteil, Neuverteilung beim Löschen). Rechnung unverändert (Anteil = Gewicht ÷ Σ Gewicht, §1).

**Habits geführt, Analyse (24.11.2026, PR #26–#30):** Meilensteine aus Bestehendem (Aufgabe, Termine, Habit; Bisheriges zählt mit). Habits mit Kacheln Heute/Alle, Habit-Seite wie Ziel-Seite. „+ Neu“ verbindet beim Anlegen Bestehendes. Rückblick mit Analyse je Ziel (Verlauf, Prognose, Einsatz) und je Habit (Serie, Quote, 12-Wochen-Raster). Aufgaben: „Zählt in“ wählbar. Logik-Test 24.11.: offen sind Datensicherung [RISIKO], Habit pausieren, Erinnerungen für Aufgaben, Ziel-Status pausiert/Frist verpasst, Rückgängig, Erster Start, Suche. Nächster Block: Kalender.

**Nachtflug (24.11.2026):** neues Aussehen in Indigo, Seladon und Gold, hell und dunkel; Kalender mit Termin-Seite und Vorschlags-Leiste (PR #31). Gadgets Fokus als Flug (PR #33) und Rückblick als Bordkarte (PR #34) eingebaut.

**Nachtblau (25.11.2026, Block 1):** Palette Nachtblau · Creme · Schwarz, Messing nur als „jetzt“; Bühne mit Verlauf, Lichtkegel und weichem Saum, Karte vorn −44/Radius 28; keine Objekte mehr auf den Seiten, nur vier echte Fotos (747, Landebahnen). Offen: Block 2 Easter Eggs (Überflug, 747-Timer ohne Flugwörter, Bordkarte als Statistik zum Herausziehen) und Block 3 (Fokus, Rückblick, Assistent, Einstellungen in drei Ebenen). Prototyp: https://claude.ai/artifact/RQGm6b7z7stGnGBBEi8TwT

**Rechnung Fassung 2 (23.11.2026, entschieden und gemergt):** Ziele bestehen nur aus Meilensteinen; Aufgaben, Habits, Termine fließen über Meilensteine ein, der Rest zählt als Einsatz. Ziel-Detail zum Bearbeiten. Analyse: `docs/produkt/konzepte/ziele-und-rechnung.md`.

## 3. Nächste Schritte

Reihenfolge: `/fahrplan` (Phase 1).
1. **Entscheidungen des Gründers** (`docs/leitung/entscheidungen.md`, [OFFEN]): App-Name, Sprache der App-Texte, nur für sich oder verkaufen (Abo), Ort des Lotse-Servers, Preis von Pro.
2. Klick-Dummy eine Woche selbst nutzen, Funde in `/fahrplan` sammeln.
3. Phase 2 weiter: SwiftData, Google-Kalender (braucht Google-Cloud-Projekt des Gründers), Termine in den Apple-Kalender schreiben, Onboarding, StoreKit für Pro.
