# Rechenregeln – so rechnet Kompass

Stand: 23. November 2026 · **Fassung 2** (Meilensteine) [ENTSCHEIDUNG – 23.11.2026]. Quelle der Wahrheit für jede Zahl in der App. Umgesetzt in Swift (`Kompass/Rechnung/`, Tests in `KompassTests/`); der Klick-Dummy rechnet noch Fassung 1. Analyse und Begründung: `docs/produkt/konzepte/ziele-und-rechnung.md`. Jede Änderung hier braucht „Ja, mergen“ des Gründers.

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

### 9.1 Empfehlung im Kalender [ENTSCHEIDUNG – 23.11.2026, Gründer: „Ja, mergen“]

- **Was:** offene Aufgaben ohne Uhrzeit, die überfällig, im Zeitraum der Ansicht fällig oder ohne Tag (Eingang) sind; in der Tagesansicht zusätzlich Habits, die an dem Tag geplant, ohne Uhrzeit und noch nicht voll sind.
- **Punkte:** überfällig 100 + Tage (max. 30) · im Zeitraum fällig 80 − Tage bis fällig · Eingang 30 · Habit 60 (+20 mit Ziel) · Aufgabe des nächsten Schritts eines Ziels (§1) +40 · Ziel hinterher/überfällig +20 · wichtig +25. Sortiert nach Punkten, dann Titel. Ein Grund je Karte (der stärkste).
- **Platz, der Reihe nach** (jeder Vorschlag belegt seinen Platz): Tag → erste Lücke ≥ Dauer ab 8 Uhr (heute ab jetzt, auf Viertelstunden), bis 22 Uhr; passt nichts mehr, Aufgabe auf den nächsten Tag. Woche/Monat → der freieste Tag ab heute im Zeitraum, **nie nach der Frist**; bei Gleichstand der frühere. Vergangene Tage: kein Platz.
- Assistent („Womit soll ich anfangen?“) nennt die ersten zwei mit Platz.
- Swift: `Kompass/Rechnung/Empfehlung.swift`, Tests `KompassTests/EmpfehlungTests.swift`.

## 10. Prüfung

Swift: `KompassTests/RechnungTests.swift` (Randfälle aus `unit.py` und Fassung 2) muss grün sein. Klick-Dummy (Fassung 1): `prototyp/tests/run.py` und `unit.py`; letzter Lauf `docs/technik/berichte/personen-zwei-jahres-test-2026-11-23.md`. [OFFEN] Personen-Test für Fassung 2 als Swift-Test (`s-personentest`).
