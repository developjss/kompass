# Rechenregeln – so rechnet Kompass

Stand: 27. November 2026 · **Fassung 2** (Meilensteine) [ENTSCHEIDUNG – 23.11.2026]. Quelle der Wahrheit für jede Zahl in der App. Umgesetzt in Swift (`Kompass/Rechnung/`, Tests in `KompassTests/`). Jede Änderung hier braucht „Ja, mergen“ des Gründers.

Grundsatz [ENTSCHEIDUNG – 23.11.2026]: Egal ob Vorschlag übernommen, geändert oder selbst angelegt – es wird immer gleich gerechnet. KI schlägt nur vor.

## 1. Ziel-Fortschritt

Ein Ziel besteht aus **Meilensteinen**. `Fortschritt = Σ(Gewicht × Stand) ÷ Σ Gewicht` über alle Meilensteine.
- **Als erreicht markiert:** 100 %. **Keine Meilensteine:** 0 % und Hinweis „Wie misst du das?“.
- **Ziel als Zahl** (Vermögen, Gewicht) = ein Zahl-Meilenstein. **Zwischenstände** (z. B. 100.000 €) gehören zum Zahl-Meilenstein, werden automatisch erreicht, sobald der Stand sie erreicht, und zählen nicht extra.
- „So wird gerechnet“ zeigt je Meilenstein den Beitrag in Prozentpunkten: `Gewicht × Stand ÷ Σ Gewicht`. Die Beiträge ergeben zusammen den Fortschritt.
- **Dein nächster Schritt** (Ziel-Seite, Zielkarte, Assistent): der offene Meilenstein mit dem größten fehlenden Beitrag `Gewicht × (1 − Stand) ÷ Σ Gewicht`; bei Gleichstand der frühere. Dazu die erste offene Aufgabe dieses Meilensteins (nach Tag, dann Reihenfolge). Erreichtes Ziel oder alles geschafft → keiner. Umsetzung `Fortschritt.naechsterSchritt`, Test `NaechsterSchrittTests`. [ENTSCHEIDUNG – 23.11.2026, Gründer: „Ja, mergen“]

## 2. Stand eines Meilensteins (0–100 %)

| Art | Stand |
|---|---|
| Abhaken | mit Aufgaben: **90 % × erledigte ÷ alle einmaligen Aufgaben** dieses Meilensteins; ohne Aufgaben 0 %. Die letzten 10 % durch Abhaken. |
| Zahl | (Ist − Start) ÷ (Ziel − Start), in beide Richtungen (86 → 75 kg). Ist = zuletzt eingetragener Stand **+ 1 je zugeordnetem, stattgefundenem Termin**. Start = Ziel → 100 % wenn erreicht. |
| Zeit | (Fokusstunden dieses Meilensteins **+ Dauer zugeordneter, stattgefundener Termine**) ÷ Soll-Stunden |
| Habit · Anzahl | Σ Tagesanteile des Habits seit Anlage des Meilensteins ÷ Soll-Anzahl (halb geschafft zählt halb) |
| Habit · Wochen | erfüllte Wochen seit Anlage ÷ Soll-Wochen. **Woche erfüllt** = an allen geplanten Tagen dieser Woche (ab Anlage) erledigt; Wochen ohne geplanten Tag zählen nicht; die laufende Woche zählt erst, wenn sie erfüllt ist. |

- Abgehakt („Geschafft“) = 100 %, egal welche Art. Ein Meilenstein bei 100 % wird nicht automatisch abgehakt.
- Immer begrenzt auf 0–100 %. Ungültige Werte (Soll ≤ 0, Text, leer) → 0 %.
- **Gewicht:** 1 klein, 2 mittel, 3 groß; alles andere zählt als 1. Standard 1.
- **90-%-Regel** [ENTSCHEIDUNG – 23.11.2026]: verhindert, dass ein Meilenstein wie „Theorieprüfung“ durch eine einzige Vorbereitungsaufgabe auf 100 % springt.

## 3. Was in welche Zahl zählt

**Grundsatz:** In die Prozente zählt nur, was über einen Meilenstein einfließt. Alles andere am Ziel (Aufgaben ohne Meilenstein, verknüpfte Habits ohne Habit-Meilenstein, Termine „nur Einsatz“, Fokuszeit) ist **Einsatz**: sichtbar im Ziel und im Rückblick, ohne die Prozente zu ändern.

- **Aufgaben** fallen beim Anlegen automatisch in den **nächsten offenen Meilenstein** ihres Ziels (Art Abhaken oder Zeit, noch nicht 100 %). Im Ziel bzw. Meilenstein angelegte Aufgaben gehören genau dorthin. Umstellbar; „Keiner – nur Einsatz“ möglich.
- **Wiederkehrende Aufgaben** zählen nicht in „erledigte ÷ alle“ (sonst sinkt der Stand bei jeder neuen Wiederholung), sondern über Fokuszeit und „Auf Kurs“.
- **Habits** zählen über Habit-Meilensteine (Anzahl oder Wochen) in die Prozente; beim Verknüpfen mit einem Ziel ist „zählt in die Prozente“ vorausgewählt.
- **Fokuszeit** einer Aufgabe zählt in ihren Zeit-Meilenstein und in die investierte Zeit des Ziels.
- **Kalendertermine:** Eine Serie wird einem Ziel zugeordnet (Einsatz: Dauer) und optional einem Zahl- oder Zeit-Meilenstein (je 1 bzw. Dauer). Es zählen nur stattgefundene Termine ab der Zuordnung (wahlweise 4 Wochen rückwirkend; beim Meilenstein aus Terminen wahlweise alle bisherigen, soweit der Kalender sie liefert; heutige zählen erst nach ihrem Ende). Gespeichert werden nur Tag und Dauer.
- **Meilenstein aus Bestehendem** [ENTSCHEIDUNG – 24.11.2026, Gründer: „Ja, mergen“]: *Aufgabe* → Abhaken-Meilenstein mit dieser Aufgabe (schon erledigt → Meilenstein geschafft). *Termin-Serie* → Zahl (jeder Termin = 1) oder Zeit (Dauer), Soll wird gefragt (Vorschlag: bisherige + geplante). *Habit* → Anzahl oder Wochen; „Bisherige mitzählen“ setzt den Start auf die Anlage des Habits bzw. den ersten Termin. Vorschau = bisher ÷ Soll (max. 100 %). Umsetzung `MeilensteinQuelle`, Tests `MeilensteinQuelleTests`.
- Gelöschte Aufgaben fallen aus der Rechnung; erledigte bleiben. Gelöschter Meilenstein: seine Aufgaben, Fokuszeiten und Termine werden „nur Einsatz“. Habit vom Ziel lösen entfernt seine Habit-Meilensteine in diesem Ziel. Gelöschtes Ziel: Aufgaben, Habits und Fokuszeiten bleiben ohne Zuordnung.

## 4. Auf Kurs

`erwartet = verstrichene Tage seit Anlage ÷ Tage von Anlage bis Fälligkeit`
- Fortschritt − erwartet ≥ +5 Punkte → **voraus**; ≤ −10 Punkte → **hinterher**; sonst **im Plan**.
- Fälligkeit vorbei und < 100 % → **überfällig**. Erreicht → **erreicht**.
- Tage in ganzen Kalendertagen (sommerzeitfest).

## 5. Prognose

Aus dem täglichen Verlauf des Fortschritts (ein Wert pro Tag): Tempo = (heute − Stand vor ~28 Tagen) ÷ Tage. Weniger als 7 Tage Verlauf → keine Prognose. Tempo ≤ 0 → „kein messbarer Fortschritt“. Sonst `Rest-Tage = (1 − Fortschritt) ÷ Tempo` → voraussichtliches Datum.

## 6. Habits (Habits v2) [ENTSCHEIDUNG – 23.11.2026]

- **Menge und Einheit:** Ein Habit kann ein Soll je Tag haben (20 Minuten, 300 g, 5 km, 30 Mal). Ohne Soll ist er ein Abhaken.
- **Tagesanteil** = eingetragene Menge ÷ Soll, begrenzt auf 0–1 („halb geschafft zählt halb“). Abhaken = ganze Menge = 1. Ohne Soll: 0 oder 1.
- **Rhythmus:** täglich · feste Wochentage · **n-mal pro Woche** (jeder Tag gilt als geplant, bis die Woche voll ist).
- **Serie:** Tages-Habits – geplante Tage rückwärts bis zum ersten nicht vollen Tag (nur Anteil ≥ 1 zählt; heute erst, wenn voll). „n-mal pro Woche“ – erfüllte Wochen rückwärts. Keine Obergrenze.
- **Beste Serie:** über die ganze Historie seit Anlage.
- **Quote (30 Tage / Woche):** Σ Tagesanteile ÷ geplante Tage; Tage vor der Anlage zählen nicht; heute erst, wenn etwas eingetragen ist. „n-mal pro Woche“: Mittel der Wochen-Anteile (Σ ÷ n, höchstens 1); die laufende Woche nur, wenn erfüllt.
- **Woche erfüllt** (für Meilenstein „Wochen“): alle geplanten Tage voll bzw. n erreicht.
- **Meilenstein „Habit · Anzahl“:** Σ Tagesanteile seit Anlage des Meilensteins ÷ Soll.
- **Erinnerung:** Uhrzeit je Habit; nur Hinweis, keine Rechnung.
- [RISIKO] Werden Rhythmus oder Soll eines Habits geändert, rechnet die Historie mit dem neuen Plan.
- Vorschläge für Einheit und Menge aus dem Titel sind Regeln (`HabitVorschlag`), keine Rechnung – der Nutzer übernimmt oder ändert sie.

## 7. Lernen

**Grundsatz:** Lernen ändert nie bestehende Prozente – nur Vorschläge beim Anlegen und die Prognose.

- **Zeitfaktor** `r = (Σ tatsächlich÷geplant + 3) ÷ (Anzahl + 3)` aus abgehakten Zeit-Meilensteinen (die letzten 30; gespeichert beim Abhaken). Vorschlag für neue Zeit-Meilensteine: Schätzung × r, auf ganze Stunden. Die „+3“ ziehen bei wenig Erfahrung Richtung 1.
- **Habit-Soll (Anzahl):** geplante Tage bis zur Fälligkeit des Ziels × 30-Tage-Quote des Habits (ohne Verlauf × 1), mindestens 1.
- **Habit-Soll (Wochen):** Wochen bis zur Fälligkeit × (erfüllte der letzten 8 Wochen + 1) ÷ 10, mindestens 1.
- **Übernahme-Quote** je Vorschlag `q = (übernommen + 1) ÷ (gezeigt + 2)`; vorausgewählt, wenn q ≥ 40 %.
- **Eigene Meilensteine**, die zu einer Vorlage ergänzt werden, werden beim nächsten ähnlichen Ziel mit vorgeschlagen.
- Über alle Nutzer: gleiche Formeln mit anonymen Summen – Konzept `docs/produkt/konzepte/lernen-ueber-alle-nutzer.md`.

## 8. Zeit, Termine, Wiederholungen

- **Fokus-Timer** in Abschnitten; beim Stoppen an Mitternacht geteilt und dem richtigen Tag gebucht. Mehr als 4 Stunden am Stück zählen nicht (vergessener Timer) – gebucht werden die ersten 4 Stunden, mit Hinweis.
- **Wiederholung:** täglich +1 Tag; werktags nächster Mo–Fr; wöchentlich +7; monatlich gleicher Tag, sonst Monatsletzter, ohne Abrutschen (Anker-Tag, z. B. 31.). Nur eine offene Folge je Serie. „Nur diesen löschen“ lässt die Serie weiterlaufen, „Serie beenden“ stoppt sie.
- **Kalenderwoche** nach ISO 8601 (KW 53 möglich).
- Kalendertermine zählen in Zahl- und Zeit-Meilensteine (§2, §3).

## 9. Tagesplan (Struktur v3) [ENTSCHEIDUNG – 23.11.2026, Gründer: „allem selber zustimmen“]

- **Blöcke eines Tages:** Termine mit Zeit (Beispiel, Kompass, Apple) + Aufgaben mit Uhrzeit (Dauer, min. 5 Min) + Habits mit Uhrzeit an geplanten Tagen (Dauer: eingestellt, sonst Menge in Minuten/Stunden, sonst 30 Min). Ein in den Tag gezogener Habit hat nur an diesem Tag eine Uhrzeit.
- **Wache Zeit** 7–22 Uhr. **Verplant** = Vereinigung offener Blöcke darin; **frei** = 900 Min − verplant; **enger Tag** = verplant ≥ 75 % oder frei < 90 Min.
- **Überschneidung:** zwei offene Blöcke überlappen ≥ 5 Min (heute nur noch nicht vorbei).
- **Kein Platz:** Dauer offener Aufgaben und Habits ohne Uhrzeit > freie Minuten (heute ab jetzt).
- **Als Nächstes:** laufende und kommende offene Blöcke, nach Start, bis 7 Tage voraus.
- **Eigene Termine:** zählen für ein Ziel wie verknüpfte Termin-Serien (§8); mit Habit ist der Habit an dem Tag erfüllt, sobald der Termin vorbei ist (nur wenn noch nichts eingetragen ist).
- Farben: nach Ziel (Standard) oder Kategorie (Einstellung).
- Swift: `Kompass/Rechnung/Tagesplan.swift`, Tests `KompassTests/TagesplanTests.swift`.

### 9.1 Empfehlung im Kalender [ENTSCHEIDUNG – 23.11.2026, Gründer: „Ja, mergen“; entfällt mit dem Kalender-Tab, die Rechnung wird zum Berater (`docs/produkt/konzepte/journal-und-berater.md` §6)]

- **Was:** offene Aufgaben ohne Uhrzeit, die überfällig, im Zeitraum der Ansicht fällig oder ohne Tag (Eingang) sind; in der Tagesansicht zusätzlich Habits, die an dem Tag geplant, ohne Uhrzeit und noch nicht voll sind.
- **Punkte:** überfällig 100 + Tage (max. 30) · im Zeitraum fällig 80 − Tage bis fällig · Eingang 30 · Habit 60 (+20 mit Ziel) · Aufgabe des nächsten Schritts eines Ziels (§1) +40 · Ziel hinterher/überfällig +20 · wichtig +25. Sortiert nach Punkten, dann Titel. Ein Grund je Karte (der stärkste).
- **Platz, der Reihe nach** (jeder Vorschlag belegt seinen Platz): Tag → erste Lücke ≥ Dauer ab 8 Uhr (heute ab jetzt, auf Viertelstunden), bis 22 Uhr; passt nichts mehr, Aufgabe auf den nächsten Tag. Woche/Monat → der freieste Tag ab heute im Zeitraum, **nie nach der Frist**; bei Gleichstand der frühere. Vergangene Tage: kein Platz.
- Assistent („Womit soll ich anfangen?“) nennt die ersten zwei mit Platz.
- Swift: `Kompass/Rechnung/Empfehlung.swift`, Tests `KompassTests/EmpfehlungTests.swift`.

## 11. Rückblick: das Wochenwort [ENTSCHEIDUNG – 25.11.2026, PR #52, „Ja, mergen“]

Über dem Rückblick steht ein bis zwei Wörter zur Lage der Woche – deterministisch aus vier Zahlen, keine KI. Erste passende Regel gewinnt:

| Nr | Bedingung | Wort |
|---|---|---|
| 1 | kein Tag der Woche mit Daten | Neue Woche. |
| 2 | höchste Tagesauslastung ≥ 75 % (verplant ÷ wach 7–22 Uhr) | Volle Woche. |
| 3 | Pläne ≥ 80 % geschafft und Habits ≥ 80 % (oder keine Habits geplant) | Starke Woche. |
| 4 | weniger als die Hälfte der aktiven Ziele im Plan oder voraus (§4) | Kurs halten. |
| 5 | Pläne < 40 % geschafft | Luft holen. |
| 6 | Habits ≥ 80 % | Gut dabei. |
| 7 | sonst | Im Fluss. |

Pläne = Aufgaben + Habit-Tage (§9 Wochenbilanz). Die vier Kacheln darunter – Erledigt, Habits, Ziele, Zeit – rechnen nur mit §1, §4, §6 und §9; Monat = 4 Wochen, Jahr = 52 Wochen, jeweils zurück ab dem Montag der Woche. Swift: `Kompass/Rechnung/Wochenwort.swift`, Tests `KompassTests/WochenwortTests.swift`.

## 12. Home: Signale [ENTSCHEIDUNG – 26.11.2026, PR #55, „Ja, mergen“]

Home zeigt unter der Karte, was gerade wichtig ist – höchstens drei Zeilen, jede mit genau einer Handlung. Alles deterministisch, keine KI.

| Signal | Bedingung | Gewicht | Handlung |
|---|---|---|---|
| Serie in Gefahr | Habit heute geplant und offen, Serie ≥ 7 Tage, ab 18 Uhr (nicht bei „n-mal pro Woche“) | 100 | Habit |
| Liegengeblieben | offene Aufgaben mit Datum vor heute | 90 | alle auf heute |
| Überschneidung | zwei Blöcke ≥ 5 Min gleichzeitig, heute bis in 6 Tagen (§9) | 85 | Tag im Kalender |
| Voller Tag | Auslastung ≥ 75 % (verplant ÷ wach 7–22 Uhr), heute bis in 7 Tagen | 80 | Tag im Kalender |
| Zu wenig Zeit | Offenes ohne Uhrzeit braucht mehr als frei ist (§9) | 75 | Tag im Kalender |
| Ziel hinter Plan | Lage „hinterher“ oder „überfällig“ (§4) oder Prognose nach der Frist (§5) | 70 | Ziel |
| Frist nah | aktives Ziel unter 100 %, fällig in 0–14 Tagen | 60 | Ziel |
| Freier Tag | Auslastung ≤ 25 % morgen bis in 3 Tagen **und** offene Aufgaben ohne Datum | 40 | Tag im Kalender |
| Serie geschafft | Serie steht heute genau bei 7, 30 oder 100 | 30 | Analyse |

- **Rang = Gewicht ÷ (1 + Tage bis zum Ereignis)**; heute = 0 Tage. Bei Gleichstand gewinnt das höhere Gewicht.
- **Je Art höchstens ein Signal:** der früheste Tag, das Ziel mit dem größten Rückstand (erwartet − Fortschritt), die früheste Frist, die längste Serie.
- **Home zeigt die drei mit dem höchsten Rang.**
- **„Passt nicht“** stellt die Art 56 Tage stumm (nur auf dem Gerät, `lernen.signaleStumm`). Gelernt wird nur, was gezeigt wird – nie die Rechnung.
- Noch nicht gebaut: Anlässe aus dem Kalender (Geburtstag, Prüfung …) und Wochenstart.
- Swift: `Kompass/Rechnung/Signale.swift`, Tests `KompassTests/SignaleTests.swift`.
## 13. Rückblick konkret: Listen, Auslastung, Vorschläge, Erkenntnis [ENTSCHEIDUNG – 26.11.2026, PR #57, „Ja, mergen“]

Jede Statistik-Seite zeigt oben **einen Satz zum Mitnehmen**, unten „Was zählt hier?“. Alles deterministisch, keine KI.

- **Erledigt:** Aufgaben mit Datum im Zeitraum bis heute. „Noch offen“: hohe Priorität zuerst, dann mit Ziel, dann älter. „Erledigt“: mit Ziel zuerst, dann mehr Fokuszeit, dann neuer. Je drei Zeilen, der Rest klappt auf.
- **Zeit:** „Im Fokus“ = Timer-Sitzungen im Zeitraum je Aufgabe, längste zuerst; Sitzungen ohne Aufgabe als „Ohne Aufgabe“. „Ohne Timer erledigt“ = erledigte Aufgaben ohne jede gemessene Zeit.
- **Auslastung:** Ø = Mittel der sieben Tagesanteile (verplant ÷ wach 7–22 Uhr, §9); voll ab 75 %. Darunter Minuten je Art (Termine · Aufgaben · Habits; Überschneidungen zählen doppelt), vollster und leerster Tag.
- **Vorschläge** (nur laufende Woche, für heute + 6 Tage, höchstens einer je Art):

| Art | Bedingung | Übernehmen |
|---|---|---|
| Entlasten | ein Tag ≥ 75 %; seine längste offene Aufgabe passt auf den leersten anderen Tag ab morgen, der danach ≤ 60 % hat | Aufgabe auf diesen Tag, ohne Uhrzeit |
| Luft nutzen | ein Tag ab morgen ≤ 25 % und es gibt Aufgaben ohne Datum | wichtigste Aufgabe ohne Datum (Priorität, dann mit Ziel) auf diesen Tag |

- **Lernen:** „Übernehmen“ und „Passt nicht“ zählen je Art (`lernen.vorschlaege["auslastung.…"]`). Übernahme-Quote wie §7: (übernommen + 1) ÷ (entschieden + 2). Unter 25 % wird die Art nicht mehr gezeigt (drei Ablehnungen ohne Übernahme); höhere Quote steht zuerst.
- **Erkenntnis**, erste passende Regel:

| Analyse | Regeln der Reihe nach |
|---|---|
| Erledigt | nichts geplant · unter 60 % → „Mehr geplant als geschafft“ (geplant und geschafft je Tag) · schwächster Wochentag, wenn ≥ 30 Punkte unter dem besten (der laufende Tag zählt nicht) · ab 80 % „Fast alles geschafft“ · sonst „Solide“ |
| Habits | kein Habit geplant · schwächster Habit unter 60 % → „… fällt zurück“ · sonst „Alle Habits stabil“ |
| Ziele | kein Ziel · größter Rückstand bei „hinterher“/„überfällig“ (§4) → „… braucht dich“ · aktives Ziel ohne Zeit im Zeitraum (früheste Frist) · sonst „Alle Ziele im Plan“ |
| Zeit | kein Fokus · unter 50 % der Fokuszeit für Ziele → „Wenig Fokus für Ziele“ · sonst der Anteil |

- Swift: `Kompass/Rechnung/Rueckschau.swift`, Tests `KompassTests/RueckschauTests.swift`.

## 14. Rückblick auf Home: Karten, das Auffälligste vorn [ENTSCHEIDUNG – 26.11.2026, PR #58, „Ja, mergen“]

Der Rückblick ist kein eigener Tab mehr. Home zeigt vier Karten zum Wischen (Erledigt · Habits · Ziele · Zeit) für die laufende Woche; antippen öffnet die Statistik (§13).

- Jede Karte trägt die Zahl der Analyse und ihre Erkenntnis (§13). Jede Erkenntnis-Regel hat eine **Stufe**:

| Stufe | Regeln |
|---|---|
| handeln | „Mehr geplant als geschafft“ · „… fällt zurück“ · „… braucht dich“ |
| Hinweis | schwächster Wochentag · „Keine Zeit für …“ · „Wenig Fokus für Ziele“ |
| gut | alle übrigen Aussagen mit Daten |
| leer | noch nichts geplant · kein Habit · kein Ziel · kein Fokus |

- **Reihenfolge:** Stufe absteigend (handeln · Hinweis · gut · leer); bei Gleichstand die feste Folge Erledigt · Habits · Ziele · Zeit. Die erste Karte ist die vordere (nachtblau, mit dem ganzen Satz).
- Innerhalb einer Stufe wird nicht nach Größe des Abstands gewichtet – bewusst einfach.
- Swift: `Rueckschau.reels`, `Rueckschau.ordnen`; Tests `KompassTests/RueckschauTests.swift`.

## 15. Muster: Stimmung, Habits, Fokus, Ablenkung [VORSCHLAG – 27.11.2026, Freigabe des Gründers offen]

Grundlage: Journal-Eintrag je Tag mit **Stimmung 1–5**. Betrachtet werden die letzten 56 Tage.
| Muster | Gruppe A / Gruppe B | Wert |
|---|---|---|
| Habit und Stimmung | Tage, an denen Habit H geplant und erledigt war (Tagesanteil = 1) / geplant, nicht erledigt | Ø Stimmung |
| Fokus und Stimmung | Fokus ≥ 30 Min / < 30 Min | Ø Stimmung |
| Ablenkung und Stimmung | Ablenkung über Ziel / unter Ziel (§17) | Ø Stimmung |
| Ablenkung und Habit | Ablenkung über Ziel / unter Ziel | Ø Tagesanteil von Habit H |
| Auslastung und Stimmung | Auslastung ≥ 75 % / < 75 % (§9, gelesene Kalender) | Ø Stimmung |
- **Bedingung:** je Gruppe ≥ 5 Tage, insgesamt ≥ 14 Tage mit Wert; Unterschied ≥ 0,5 Stimmungspunkte bzw. ≥ 20 Prozentpunkte.
- **Rang:** größter Unterschied (in Stimmung: ×20, damit beide Arten vergleichbar sind) zuerst; Gleichstand → mehr Tage. Höchstens 3 sichtbar.
- **Text:** „An Tagen mit Sport: Stimmung 4,1 statt 3,2“ (eine Nachkommastelle). Hinter (i): „Zusammenhang, keine Ursache. 23 Tage verglichen.“
- **„Passt nicht“** blendet das Muster 56 Tage aus (nur auf dem Gerät). Die KI darf Muster in Worte fassen, nie selbst finden.

## 16. Handy-Jahre (Onboarding) [VORSCHLAG – 27.11.2026]

- **Stunden je Tag** = Mitte der gewählten Spanne: unter 1 h → 0,5 · 1–3 → 2 · 3–4 → 3,5 · 4–5 → 4,5 · 5–7 → 6 · über 7 → 8 · „weiß nicht“ → kein Zahlen-Bildschirm.
- **Wache Tage je Jahr** = Stunden × 365 ÷ 16 (16 wache Stunden je Tag), ganzzahlig gerundet.
- **Wache Jahre bis 80** = Stunden × 365 ÷ 16 × (80 − Alter) ÷ 365, ganzzahlig gerundet; Alter < 10 oder > 79 → nur Tage je Jahr.
- **„Zurück“** = dieselbe Rechnung mit 30 % der Stunden (Ziel: 30 % weniger, §17).
- Beispiel: 2 h, 21 Jahre → 46 Tage im Jahr, 7 Jahre bis 80; zurück 2 Jahre. Fußnote zeigt den Rechenweg.

## 17. Bildschirmzeit: Ablenkung, Ziel, Sperre [VORSCHLAG – 27.11.2026]

- **Gemessen** wird nur die Zeit in den Apps und Kategorien, die die Person als Ablenkung gewählt hat. Apple meldet erreichte **Schwellen** (15, 30, 45 … 480 Min je Tag); **Ablenkung heute = höchste erreichte Schwelle** (auf 15 Min genau, eher zu wenig als zu viel). Ohne Erlaubnis oder ohne Überwachung an dem Tag: „keine Daten“, nie 0.
- **Ziel Ablenkung je Tag** = Stunden aus §16 × 0,7, auf 15 Min gerundet, mindestens 15 Min; frei änderbar. „Über Ziel“ = Ablenkung > Ziel.
- **Hinweise** (Mitteilung, Häufigkeit wählbar): niedrig bei 100 % des Ziels · mittel bei 50 % und 100 % · hoch bei 25, 50, 75 und 100 %. Höchstens einer je Schwelle und Tag.
- **Sperre nur im Fokus** [ENTSCHEIDUNG – 27.11.2026, Gründer]: Während einer Fokus-Sitzung mit Sperre sind die gewählten Apps gesperrt; sie endet mit der Sitzung. Vorzeitig beenden: **Leicht** 10 s Warteraum · **Steigend** 10 s + 10 s je weiterem Abbruch am selben Tag · **Durchziehen** (Pro) nicht möglich.
- **Notfall-Pass:** hebt die Sperre für 60 Min auf, einmal je Kalenderwoche (Mo–So).
- **Nie gesperrt:** die Apps unter „Immer erlaubt“ (Standard: Telefon, Health, Wallet, Uhr, Einstellungen).

## 18. Serie und Meilensteine [VORSCHLAG – 27.11.2026]

- **Kompass-Serie** (Flamme): Ein Tag zählt, wenn mindestens eines davon geschafft ist: eine Fokus-Sitzung ≥ 10 Min abgeschlossen · alle an dem Tag geplanten Habits erledigt (mindestens einer geplant) · Journal-Eintrag. Heute zählt erst, wenn erfüllt; ein Tag ohne bricht die Serie. **Urlaub:** Tage im Urlaubsmodus zählen nicht und brechen nicht.
- **Meilensteine** (Sammelstücke): Serie 7 · 30 · 100 · 150 · 300 Tage; Fokusstunden gesamt 10 · 50 · 100 · 500 · 1.000 · 2.000 h. Fortschritt = min(Wert ÷ Schwelle, 1). Einmal erreicht, bleibt erreicht. Prozent anderer Nutzer werden nicht gezeigt (keine Daten).

## 19. Tageswert (0–100) [VORSCHLAG – 27.11.2026]

| Teil | Wert 0–1 | Gewicht |
|---|---|---|
| Habits | Ø Tagesanteil der heute geplanten Habits (§6) | 40 |
| Fokus | Fokusminuten ÷ Fokusziel, höchstens 1. Fokusziel aus der Lebenslage: Schule/Ausbildung/Studium 90, Job/selbstständig 60, sonst 45 Min; änderbar | 25 |
| Ablenkung | 1 bei ≤ Ziel, 0 bei ≥ 2 × Ziel, dazwischen linear (§17) | 25 |
| Journal | 1 mit Eintrag heute | 10 |
- **Fehlt ein Teil** (kein Habit geplant, keine Bildschirmzeit-Erlaubnis), werden die übrigen Gewichte anteilig auf 100 hochgerechnet. Ganzzahlig gerundet.
- **Erster Tag:** „Wird ausgewertet“ mit Rest bis Mitternacht; der erste Wert erscheint nach dem ersten vollen Tag.
- Je Tag gespeichert; Verlauf und Wochen-Ø im Rückblick.

## 20. Onboarding: Profil und erste Vorschläge [VORSCHLAG – 27.11.2026]

- **Gespeichert:** Name, Alter, Lebenslage, „Was willst du verbessern?“ (mehrere), Bildschirmzeit-Spanne. Daraus: Ziel Ablenkung (§17), Fokusziel (§19), Handy-Jahre (§16).
- **Habit-Vorschläge** (höchstens 4 Karten, Reihenfolge der Antworten): Ziele erreichen → „Fokus für dein Ziel“ 30 Min werktags · Gewohnheiten → „Lesen“ 20 Min täglich · Weniger Handy → „Handyfreier Morgen“ Fokus mit Sperre 07–09 Uhr · Besser schlafen → „Handy weg ab 22 Uhr“ täglich · Mehr Ruhe → „Atmen“ 5 Min täglich · Anderes → „Spaziergang“ 20 Min 3× je Woche. Uhrzeit je Lebenslage: Schule/Ausbildung 15–17, Studium 09–11, Job 18–19, sonst 10–11.
- Keine Erfolgsquoten anderer Nutzer – stattdessen der Grund: „Weil du ‚besser schlafen‘ gewählt hast“.

## 10. Prüfung

Swift: alle Tests in `KompassTests/` müssen grün sein, dazu der Personen-Test `KompassTests/PersonenTests.swift` (sechs Personen × 3,5 Jahre, Bericht `docs/technik/berichte/personen-test-struktur-v3-2026-11-23.md`).
