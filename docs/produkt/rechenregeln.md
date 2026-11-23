# Rechenregeln – so rechnet Kompass

Stand: 23. November 2026 · Quelle der Wahrheit für jede Zahl in der App. Umgesetzt im Klick-Dummy (`prototyp/index.html`, Abschnitt „Fortschritts-Rechnung“), geprüft durch `prototyp/tests/` (unabhängige zweite Rechnung). In Swift genauso umsetzen; jede Änderung hier braucht „Ja, mergen“ des Gründers.

Grundsatz [ENTSCHEIDUNG – 23.11.2026]: Egal ob Vorschlag übernommen, geändert oder selbst angelegt – es wird immer gleich gerechnet. KI schlägt nur vor.

## 1. Ziel-Fortschritt

**Ziel mit Schritten:** `Fortschritt = Σ(Gewicht × Stand) ÷ Σ Gewicht`
**Ziel als Zahl:** `Fortschritt = (aktuell − Start) ÷ (Ziel − Start)`, begrenzt auf 0–100 %. Start = Ziel → 100 %, wenn erreicht, sonst 0 %. Schritte sind dann nur Planungshilfe.
**Als erreicht markiert:** 100 %. **Keine Schritte:** 0 % und Hinweis „Wie misst du das?“.

## 2. Stand eines Schritts (0–100 %)

| Art | Stand |
|---|---|
| Aufgaben / abhaken | mit Aufgaben: **90 % × erledigte ÷ alle einmaligen Aufgaben** dieses Schritts; ohne Aufgaben 0 %. Die letzten 10 % durch Abhaken. |
| Zeit | Fokusstunden dieses Schritts ÷ Soll-Stunden |
| Habit | erledigte Male des Habits seit Anlage des Schritts ÷ Soll-Anzahl |
| Zahl | (aktuell − Start) ÷ (Ziel − Start); Start = Ziel → 100 % wenn erreicht |

- Abgehakt („Geschafft“) = 100 %, egal welche Art.
- Immer begrenzt auf 0–100 %. Ungültige Werte (Soll ≤ 0, Text, leer) → 0 %.
- **Gewicht:** 1 klein, 2 mittel, 3 groß; alles andere zählt als 1. Standard 1.
- **90-%-Regel** [VORSCHLAG, OFFEN]: verhindert, dass ein Schritt wie „Theorieprüfung“ durch eine einzige Vorbereitungsaufgabe auf 100 % springt.

## 3. Was in welche Zahl zählt

- **Aufgaben** fallen beim Anlegen automatisch in den **nächsten offenen Schritt** ihres Ziels (Art Aufgaben oder Zeit, noch nicht 100 %). Umstellbar; „Keiner – nur Einsatz“ möglich.
- **Wiederkehrende Aufgaben** zählen nicht in „erledigte ÷ alle“ (sonst sinkt der Stand bei jeder neuen Wiederholung), sondern über Fokuszeit und „Auf Kurs“.
- **Habits** zählen über Habit-Schritte in die Prozente; immer in „Auf Kurs“ und die Wochen-Quote [VORSCHLAG, OFFEN].
- **Fokuszeit** einer Aufgabe zählt in ihren Zeit-Schritt und in die investierte Zeit des Ziels.
- **Kalendertermine**, die einem Ziel zugeordnet sind (ganze Serie, ab Zuordnung, nur stattgefundene), zählen in die investierte Zeit des Ziels – noch nicht in Schritte (§8).
- Gelöschte Aufgaben fallen aus der Rechnung; erledigte bleiben. Gelöschter Schritt: seine Aufgaben werden „Keiner – nur Einsatz“.

## 4. Auf Kurs

`erwartet = verstrichene Tage seit Anlage ÷ Tage von Anlage bis Fälligkeit`
- Fortschritt − erwartet ≥ +5 Punkte → **voraus**; ≤ −10 Punkte → **hinterher**; sonst **im Plan**.
- Fälligkeit vorbei und < 100 % → **überfällig**. Erreicht → **erreicht**.
- Tage in ganzen Kalendertagen (sommerzeitfest).

## 5. Prognose

Aus dem täglichen Verlauf des Fortschritts (ein Wert pro Tag): Tempo = (heute − Stand vor ~28 Tagen) ÷ Tage. Weniger als 7 Tage Verlauf → keine Prognose. Tempo ≤ 0 → „kein messbarer Fortschritt“. Sonst `Rest-Tage = (1 − Fortschritt) ÷ Tempo` → voraussichtliches Datum.

## 6. Habits

- **Serie:** geplante Tage rückwärts bis zum ersten verpassten; der heutige Tag zählt erst, wenn abgehakt. Keine Obergrenze.
- **Beste Serie:** über die ganze Historie seit Anlage.
- **Quote:** erledigte ÷ geplante Tage (letzte 30 Tage bzw. Woche); Tage vor der Anlage zählen nicht; der heutige Tag erst, wenn abgehakt.
- [RISIKO] Werden die Wochentage eines Habits geändert, rechnet die Historie mit dem neuen Plan.

## 7. Lernen

- **Zeitfaktor** `r = (Σ tatsächlich÷geplant + 3) ÷ (Anzahl + 3)` aus abgeschlossenen Zeit-Schritten (die letzten 30). Neue Zeit-Vorschläge × r. Die „+3“ ziehen bei wenig Erfahrung Richtung 1.
- **Übernahme-Quote** je Vorschlag `q = (übernommen + 1) ÷ (gezeigt + 2)`; vorausgewählt, wenn q ≥ 40 %.
- **Eigene Schritte**, die zu einer Vorlage ergänzt werden, werden beim nächsten ähnlichen Ziel mit vorgeschlagen.
- Über alle Nutzer: gleiche Formeln mit anonymen Summen – Konzept `docs/produkt/konzepte/lernen-ueber-alle-nutzer.md`.

## 8. Zeit, Termine, Wiederholungen

- **Fokus-Timer** in Abschnitten; beim Stoppen an Mitternacht geteilt und dem richtigen Tag gebucht. Mehr als 4 Stunden am Stück zählen nicht (vergessener Timer) – gebucht werden die ersten 4 Stunden, mit Hinweis.
- **Wiederholung:** täglich +1 Tag; werktags nächster Mo–Fr; wöchentlich +7; monatlich gleicher Tag, sonst Monatsletzter, ohne Abrutschen (Anker-Tag, z. B. 31.). Nur eine offene Folge je Serie. „Nur diesen löschen“ lässt die Serie weiterlaufen, „Serie beenden“ stoppt sie.
- **Kalenderwoche** nach ISO 8601 (KW 53 möglich).
- [OFFEN] Kalendertermine direkt in Zeit-/Zahl-Schritte zählen (z. B. jede Fahrstunde → „Fahrstunden 6 von 30“).

## 9. Prüfung

`prototyp/tests/run.py` (4 Personen × 2 Jahre, zufällige Eingriffe, unabhängige Referenz) und `prototyp/tests/unit.py` (Randfälle) müssen grün sein. Letzter Lauf: `docs/technik/berichte/personen-zwei-jahres-test-2026-11-23.md`.
