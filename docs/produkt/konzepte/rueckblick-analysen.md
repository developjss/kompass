# Rückblick – welche Analysen, welche Rechnung, welche Darstellung

Stand: 24. November 2026 · [VORSCHLAG] zur Entscheidung durch den Gründer. Design folgt als nächster Schritt.

## 1. Wozu der Rückblick da ist

Der Rückblick beantwortet drei Fragen – in dieser Reihenfolge:

1. **Komme ich meinen Zielen näher?** (Output – Prinzip „Vertikale Kohärenz“)
2. **Wohin geht meine Zeit – und passt das zu meinen Zielen?** (Input – Prinzip „Input statt Output“)
3. **Was mache ich nächste Woche anders?** (Reflexion – Prinzip „Ritualisierte Reflexion“)

Alles andere ist Beiwerk. Eine Analyse kommt nur hinein, wenn sie eine dieser Fragen beantwortet **und** zu einer Handlung führen kann.

## 2. USP – was nur Kompass zeigen kann

Andere Apps sehen nur ein Stück: Kalender-Apps die Termine, To-do-Apps die Aufgaben, Habit-Tracker die Haken, Zeit-Tracker die Stunden. Kompass hat alles **und die Verbindung zum Ziel**. Daraus entstehen Analysen, die es so nirgends gibt:

| USP-Analyse | Frage | Warum nur Kompass |
|---|---|---|
| **Ziel-Anteil der Zeit** („Kohärenz“) | Wie viel meiner Zeit zahlt auf meine Ziele ein? | braucht Kalender + Fokus + Ziel-Zuordnung zusammen |
| **Einsatz vs. nötiges Tempo** | Reicht mein Einsatz, um das Ziel rechtzeitig zu schaffen? | braucht Frist, Meilensteine und gemessene Zeit |
| **Plan vs. Wirklichkeit** | Schaffe ich, was ich mir vornehme – oder plane ich zu viel? | braucht geplante Aufgaben/Habits und den Kalender (freie Zeit) |
| **Zeitgefühl** | Wie gut schätze ich, wie lange etwas dauert? | braucht geplante Dauer und Fokus-Timer |
| **Ehrliche Prognose** | Wann bin ich bei diesem Tempo fertig – und hat sich das diese Woche verschoben? | braucht den täglichen Verlauf |

**Vorteile, die wir dabei ausspielen:**
- **Nachvollziehbar:** Jede Zahl hat ein „So wird gerechnet“ (i). Keine Black Box.
- **Deterministisch:** Die App rechnet, die KI formuliert höchstens Sätze (Projektregel).
- **Ohne Druck:** Wir zeigen Bewegung und Ursachen, keine Schuld. Rote Farbe nur für „überfällig“.
- **Privat:** Alles wird auf dem Gerät gerechnet; Kalenderdaten verlassen das Gerät nicht.
- **Lernt mit:** Zeitgefühl und Rhythmus verbessern die Vorschläge im Kalender (Empfehlung, §9.1) – der Rückblick ist kein Ende, sondern Eingabe für die nächste Woche.

## 3. Zeiträume

| Zeitraum | Wofür | Standard |
|---|---|---|
| **Woche** (Mo–So, ISO-KW) | Ritual, Reflexion, Plan vs. Wirklichkeit | ✓ Start |
| **Monat** | Trends, Habits, Rhythmus | |
| **Jahr** | große Bewegung der Ziele, Gesamtzeit je Ziel | |
| **Seit Ziel-Anlage** | nur in der Ziel-Analyse (bestehende Seite) | |

Regeln für alle Zeiträume:
- **Vergleich mit dem Vorzeitraum** als Pfeil und Differenz („+1 h 20 min ggü. Vorwoche“). Nie zwei Kurven übereinander.
- **Laufender Zeitraum** heißt „bisher“ und wird nur mit dem *gleichen Stand* des Vorzeitraums verglichen (Mo–Mi mit Mo–Mi), sonst wirkt jede Woche am Montag schlecht.
- **Trends** über 4 Wochen (Woche) bzw. 6 Monate (Monat) als Sparkline, nicht als Einzelwert.
- **Zu wenig Daten** (z. B. < 7 Tage seit Start): Analyse wird ausgeblendet oder sagt „noch zu wenig Daten“ – nie eine wackelige Zahl.

## 4. Die Analysen – nach Wichtigkeit

Kennzeichnung: **vorhanden** = Rechnung gibt es schon · **neu** = neue Auswertung bestehender Daten · **neue Regel** = braucht Eintrag in `rechenregeln.md` und „Ja, mergen“ · **neue Daten** = App muss etwas zusätzlich speichern.

### 4.1 Aussage der Woche (ganz oben)

- **Frage:** Wie war meine Woche – in einem Satz?
- **Inhalt:** ein Satz + zwei Zahlen: **Plan-Quote** („62 % deiner Pläne geschafft“) und **Ziel-Anteil der Zeit** („58 % deiner Zeit für Ziele“), je mit Pfeil zur Vorwoche.
- **Rechnung:** Plan-Quote = (erledigte Aufgaben + Habit-Anteile) ÷ (geplante Aufgaben + geplante Habit-Tage) – **vorhanden** (`Wochenbilanz.quote`). Ziel-Anteil siehe 4.3.
- **Darstellung:** Bordkarte bleibt der Einstieg; dahinter die Aussage-Karte mit großem Satz, zwei Zahlen, darunter 7 Mini-Säulen (Plan-Quote je Tag).
- **Warum oben:** Eine Woche muss sich in 3 Sekunden einordnen lassen. Zwei Zahlen statt einer: Plan-Quote zeigt *Disziplin*, Ziel-Anteil zeigt *Richtung* – man kann viel schaffen und trotzdem am Ziel vorbeiarbeiten.

### 4.2 Einsichten (max. 3 Karten)

- **Frage:** Was fällt auf, was sollte ich tun?
- **Inhalt:** bis zu 3 automatisch erkannte Befunde mit je einer Handlung, z. B.:
  - „‚Fit: 75 kg‘ hatte 14 Tage keinen Einsatz.“ → *Fokus einplanen*
  - „Donnerstags schaffst du nur 30 % – du planst dort 2 h mehr als sonst.“ → *Donnerstag entlasten*
  - „‚Sport‘ wackelt: 3 Wochen in Folge unter Soll.“ → *Soll anpassen*
  - „Die Prognose für den Führerschein ist um 9 Tage nach hinten gerutscht.“ → *Analyse öffnen*
  - „Du brauchst für Aufgaben im Schnitt 1,4× so lange wie geplant.“ → *Dauer beim Planen anpassen*
- **Rechnung:** **neue Regel** – feste Auslöser mit Schwellen (Tabelle in `rechenregeln.md` §11), jede Einsicht bekommt eine Wichtigkeit (Ziel betroffen > Habit > Rhythmus); die 3 wichtigsten werden gezeigt. Die KI darf den Satz schöner formulieren, nie die Zahl ändern.
- **Darstellung:** Karten mit Symbol, einem Satz, einem Knopf. Wegwischbar („passt so“), damit sie nicht nerven – Weggewischtes kommt 4 Wochen nicht wieder.
- **Warum so weit oben:** Hier entsteht der Nutzen. Zahlen allein ändern nichts; ein konkreter Hinweis mit Knopf schon. Das ist auch der Ort, an dem Kompass „intelligent“ wirkt.

### 4.3 Ziel-Anteil der Zeit („Kohärenz“) – USP

- **Frage:** Wie viel meiner Zeit zahlt auf Ziele ein?
- **Rechnung:** **neue Regel**
  `Ziel-Anteil = Zeit für Ziele ÷ erfasste Zeit`
  - Zeit für Ziele = Fokus mit Ziel + Dauer stattgefundener Termine mit Ziel (Kompass, Apple, Google) + Habit-Zeit mit Ziel (Habits mit Menge in Minuten bzw. Dauer im Kalender)
  - erfasste Zeit = alle Fokuszeit + alle stattgefundenen Termine mit Uhrzeit + Habit-Zeit (ohne Schlaf/ganztägige Termine)
- **Darstellung:** gestapelter Balken je Ziel (Ziel-Farben) + grauer Rest „ohne Ziel“; darunter die 3 größten Zeitfresser ohne Ziel (z. B. Kalender „Arbeit“ 12 h). 4-Wochen-Sparkline des Anteils.
- **Warum:** Das ist die Zahl, die es nur bei Kompass gibt, und sie führt direkt zu einer Frage: „Will ich das so?“ Bewusst **kein Sollwert** – 30 % können für jemanden mit Vollzeitjob großartig sein.

### 4.4 Ziele: Bewegung, Lage, Prognose

- **Frage:** Bin ich weitergekommen und reicht es bis zur Frist?
- **Inhalt je aktivem Ziel:** Fortschritt jetzt · **Bewegung im Zeitraum** (+6 Pkt) · Lage (voraus / im Plan / hinterher) · Prognose-Datum und **Verschiebung ggü. Vorwoche** (± Tage).
- **Rechnung:** Bewegung = Fortschritt Ende − Fortschritt Anfang aus `verlauf` – **neu** (bestehende Daten). Lage §4, Prognose §5 – **vorhanden**. Verschiebung = Prognose heute − Prognose vor 7 Tagen – **neu**.
- **Darstellung:** eine Zeile je Ziel: Balken mit **farbig hervorgehobenem Zuwachs** (der Teil, der diese Woche dazukam), rechts „+6 Pkt“ und die Lage als Wort. Sortiert: hinterher zuerst, dann nach Bewegung. Antippen → Ziel-Analyse (gibt es schon).
- **Warum:** Fortschritt als Gesamtwert ändert sich wöchentlich kaum (64 % → 66 %) und frustriert. Der **Zuwachs** macht kleine Schritte sichtbar. Die Prognose-Verschiebung ist ehrlicher als „Auf Kurs“, weil sie das aktuelle Tempo berücksichtigt.

### 4.5 Einsatz vs. nötiges Tempo – USP

- **Frage:** Reicht mein Einsatz, um rechtzeitig fertig zu werden?
- **Rechnung:** **neue Regel**
  - geleistet = Einsatz im Zeitraum je Ziel (Fokus + Termine, wie in der Ziel-Analyse)
  - nötig je Woche = offene Soll-Stunden der Zeit-Meilensteine ÷ verbleibende Wochen bis zur Frist (nur wenn Zeit-Meilensteine mit Soll existieren; mit Zeitfaktor r aus §7, sonst ohne)
  - Ziele ohne Zeit-Meilenstein: nur „geleistet“ + Hinweis, wie man ein Soll bekommt.
- **Darstellung:** je Ziel ein Balken „geleistet“ mit einer senkrechten Markierung „nötig“; Text „2 h 10 von nötigen 3 h“.
- **Warum:** „Auf Kurs“ ist rückwärts gerichtet (Zeitanteil seit Anlage). Das nötige Tempo ist vorwärts gerichtet und sagt konkret, wie viel nächste Woche gebraucht wird – genau das, was man für den Wochenplan braucht.

### 4.6 Plan vs. Wirklichkeit

- **Frage:** Schaffe ich, was ich mir vornehme – oder plane ich zu viel?
- **Inhalt:** geplant → erledigt → verschoben → liegengeblieben; dazu **Überplanung**: geplante Minuten vs. freie Minuten im Kalender.
- **Rechnung:** geplant/erledigt **vorhanden** (`Wochenbilanz`). Verschoben = Aufgaben, deren Datum in diesem Zeitraum nach hinten geändert wurde – **neue Daten** (Zähler `verschoben` je Aufgabe). Überplanung = Σ Dauer geplanter Aufgaben + Habits ÷ freie Zeit (7–22 Uhr minus Termine) – **neue Regel** (nutzt §9 Auslastung).
- **Darstellung:** kleiner Trichter in einer Zeile (12 geplant · 8 erledigt · 3 verschoben · 1 offen). Überplanung als Satz („Du hast 9 h geplant, aber nur 6 h frei“), nur wenn > 110 %.
- **Warum:** Die häufigste Ursache für „nichts geschafft“ ist zu viel geplant, nicht zu wenig getan. Das entlastet – und führt zur Handlung „weniger einplanen“.

### 4.7 Habits

- **Frage:** Welche Gewohnheiten halten, welche wackeln?
- **Inhalt:** Quote im Zeitraum je Habit · aktuelle Serie · **Trend** (4 Wochen) · **bester/schwächster Wochentag**.
- **Rechnung:** Quote, Serie, beste Serie **vorhanden** (`HabitRechnung`). Quote je Wochentag (letzte 8 Wochen) – **neu**. „Wackelt“ = 3 Wochen in Folge unter 70 % – **neue Regel** (für Einsichten).
- **Darstellung:** Liste je Habit: Name · Quote · Sparkline · Serie mit Flamme. Antippen → Habit-Analyse (gibt es schon, mit 12-Wochen-Raster). Kein zweites Raster im Rückblick – nur Überblick.
- **Warum:** Habits leben vom Trend, nicht von der Einzelwoche. Wochentage zeigen, *wann* es scheitert – daraus wird eine konkrete Änderung (Uhrzeit, Tag).

### 4.8 Zeit und Rhythmus

- **Frage:** Wann arbeite ich am besten, und wie voll sind meine Tage?
- **Inhalt:** **Fokus-Uhr** (Fokuszeit je Wochentag × Tageszeit), beste Fokuszeit („Di–Do 9–11 Uhr“), **Auslastung** je Tag mit Linie „eng“ (vorhanden), **Termin-Last** (Anteil Termine an der erfassten Zeit), Zeit je **Kalender/Kategorie** (Arbeit, Familie, Uni …, aus Apple/Google).
- **Rechnung:** Auslastung **vorhanden** (§9). Fokus-Uhr – **neue Daten**: Fokus-Sitzungen speichern bisher nur Tag und Dauer, nicht die Uhrzeit (die Abschnitte des Timers haben sie – beim Buchen übernehmen). Zeit je Kalender – **neue Daten** (Kalendername beim Lesen mitnehmen).
- **Darstellung:** Heatmap 7 × 5 Tageszeit-Blöcke (Morgen, Vormittag, Mittag, Nachmittag, Abend) – lesbar auf dem Handy, nicht 24 Stunden. Auslastung als 7 Säulen (wie jetzt). Kalender-Anteile als ein gestapelter Balken.
- **Warum:** Die beste Fokuszeit fließt direkt in die Empfehlung im Kalender zurück (Vorschläge in die eigenen Hochleistungszeiten) – Rückblick und Planung greifen ineinander.

### 4.9 Zeitgefühl – USP

- **Frage:** Wie gut schätze ich, wie lange etwas dauert?
- **Rechnung:** **neue Regel** – für erledigte Aufgaben mit Fokuszeit: `Faktor = Σ Fokuszeit ÷ Σ geplante Dauer` (letzte 30 Aufgaben, mit derselben Glättung wie §7: `(Σ + 3) ÷ (n + 3)`). Nur Aufgaben mit mindestens 5 Minuten Fokus.
- **Darstellung:** eine Zahl („1,4× so lange wie geplant“) + ein Satz, was Kompass daraus macht („Neue Aufgaben schlagen wir mit 1,4× Dauer vor“). Erst ab 5 Aufgaben.
- **Warum:** Fast alle Menschen unterschätzen Aufgaben (Planungsfehlschluss). Kompass kann das als einzige App messen und automatisch korrigieren – ein greifbarer Nutzen der Zeitmessung.

### 4.10 Geschafft (Done-Liste)

- **Frage:** Was habe ich geschafft?
- **Inhalt:** erreichte Meilensteine und Ziele, erledigte Aufgaben (gruppiert nach Ziel), Serien-Rekorde, Fokus-Rekorde („längste Woche seit August“).
- **Rechnung:** zählen, keine Formel – **neu** (aus `erledigtAm`, Meilenstein-Status, Serien).
- **Darstellung:** oben die 3 Highlights groß (Meilenstein erreicht schlägt Aufgabe), darunter aufklappbare Liste. Die Bordkarte kann die Highlights als „Stempel“ tragen.
- **Warum:** Prinzip 3 „Done-Liste statt To-do-Liste“: Motivation entsteht durch Sichtbarkeit des Geschafften – gerade in Wochen mit niedriger Quote.

### 4.11 Reflexion

- **Frage:** Was nehme ich mit?
- **Inhalt:** Wochenreflexion (3 Fragen, vorhanden), vorbefüllt mit den Einsichten aus 4.2 als Denkanstoß; frühere Antworten zum Nachlesen.
- **Rechnung:** keine. KI darf auf Wunsch eine Zusammenfassung der letzten Reflexionen schreiben (nur Text).
- **Darstellung:** am Ende der Seite, eine Karte, die zur Reflexion führt; nach dem Ausfüllen „✓“ und die eigene Antwort als Zitat.
- **Warum am Ende:** Erst sehen, dann reflektieren. Die Reflexion ist der Abschluss des Rituals.

## 5. Reihenfolge auf der Seite

| # | Block | Zeitraum-Wahl wirkt? |
|---|---|---|
| 0 | Bordkarte (Einstieg, Gadget) | Woche |
| 1 | Aussage: Plan-Quote + Ziel-Anteil | ✓ |
| 2 | Einsichten (max. 3) | ✓ |
| 3 | Ziele: Bewegung, Lage, Prognose | ✓ |
| 4 | Einsatz vs. nötiges Tempo | ✓ |
| 5 | Zeit für Ziele (Kohärenz-Details, Zeitfresser) | ✓ |
| 6 | Plan vs. Wirklichkeit | ✓ |
| 7 | Habits | ✓ |
| 8 | Zeit und Rhythmus | Monat sinnvoll, Woche reicht für Auslastung |
| 9 | Zeitgefühl | immer letzte 30 Aufgaben |
| 10 | Geschafft | ✓ |
| 11 | Reflexion | Woche |

Oben steht, was **entscheidet** (Ziele, Richtung), unten, was **erklärt** (Rhythmus, Zeitgefühl) und **abschließt** (Geschafft, Reflexion).

## 6. Darstellungsregeln (für das spätere Design)

- **Eine Aussage je Karte** als Überschrift (Textregel Gapless): „Diese Woche 58 % für Ziele“ statt „Zeitverteilung“.
- **Deltas statt Rohwerte** wo möglich; Pfeil + Zahl, Farbe nur für Richtung (Seladon besser, Gold neutral-hervorgehoben, nie Rot außer „überfällig“).
- **Balken statt Torten** (Vergleich auf einen Blick, auch für VoiceOver gut sagbar). Torte nur, wenn wirklich Teile eines Ganzen mit ≤ 4 Teilen.
- **Sparklines** für Trends, **Heatmap** nur für Rhythmus.
- **Jede Karte führt weiter:** Ziel → Ziel-Analyse, Habit → Habit-Analyse, Einsicht → Handlung.
- **(i) „So wird gerechnet“** an jeder Zahl, die nicht offensichtlich ist.
- **Leerzustand** je Karte mit Satz und Handlung („Verknüpfe einen Termin mit einem Ziel, dann siehst du hier deine Zeit für Ziele“).

## 7. Was dafür technisch fehlt

| Was | Wofür | Aufwand [SCHÄTZUNG] |
|---|---|---|
| Uhrzeit in `FokusSitzung` (aus Timer-Abschnitten) | Fokus-Uhr, beste Fokuszeit | S |
| Zähler `verschoben` je Aufgabe | Plan vs. Wirklichkeit | S |
| Kalendername bei Apple/Google-Terminen | Zeit je Kalender | S |
| Prognose-Verlauf (Prognose je Tag mitschreiben) oder aus `verlauf` nachrechnen | Prognose-Verschiebung | S |
| `Rueckblick`-Rechnung (rein, testbar) mit allen Kennzahlen je Zeitraum | alles | M |
| Einsichten-Regeln mit Schwellen + Tests | 4.2 | M |
| Neue Rechenregeln §11 (Ziel-Anteil, nötiges Tempo, Überplanung, Zeitgefühl, Einsichten) | Freigabe | – |

Ältere Daten ohne Uhrzeit/Zähler: Analysen starten ab Einführung („ab 1. Dez.“), keine geschätzten Altwerte.

## 8. Offene Fragen an den Gründer [OFFEN]

1. **Zwei Hauptzahlen oben** (Plan-Quote + Ziel-Anteil) – oder nur eine?
2. **Ziel-Anteil:** sollen Arbeitszeiten (Kalender „Arbeit“) mitzählen, oder nur „freie“ Zeit? Vorschlag: alles zählt, man kann einzelne Kalender ausschließen.
3. **Einsichten:** wegwischbar für 4 Wochen – passt das?
4. **Zeitgefühl automatisch anwenden** (Vorschläge × Faktor) oder nur anzeigen?
5. **Zeiträume:** Woche · Monat · Jahr – reicht das, oder auch „Quartal“?
