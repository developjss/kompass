# Entscheidungen – Register

Stand: 23. November 2026. Verbindlich ist nur, was der Gründer entschieden hat. Neue Einträge oben in der Tabelle; Details im Fachdokument.

## 1. Entschieden

| Datum | Entscheidung | Fachdokument |
|---|---|---|
| 23.11.2026 | [ENTSCHEIDUNG] Der Chat-Assistent heißt in der App **„Assistent“** (statt „Lotse“; Code-Namen bleiben); jeder App-Start beginnt einen neuen Chat, frühere Chats bleiben erreichbar. Anlegen, Home und Kalender „geführt“ wie Gapless (Personal check, Reel) | `docs/produkt/konzepte/struktur-v3.md` §10 |
| 23.11.2026 | [ENTSCHEIDUNG] Struktur v3: Home statt Heute, Kalender mit Tag/Woche/Monat/Jahr und Ziehen, eigene Termine (zählen für Ziel, erfüllen Habit), Rechenregel Tagesplan (enger Tag ≥ 75 % von 7–22 Uhr oder < 90 Min frei; Überschneidung ≥ 5 Min; kein Platz), Apple-Kalender nur lesen nach Zustimmung (Gründer: „allem selber zustimmen und fortfahren“) | `docs/produkt/konzepte/struktur-v3.md`, `rechenregeln.md` §9 |
| 23.11.2026 | [ENTSCHEIDUNG] Habits v2 Rechenregel: Tagesanteil = Menge ÷ Soll (halb geschafft zählt halb), Serie nur volle Tage, „n-mal pro Woche“ mit Wochen-Serie; Habit-Meilensteine zählen Anteile („Ja, mergen“ PR #11) | `docs/produkt/rechenregeln.md` §6, `docs/produkt/konzepte/habits-v2.md` §5 |
| 23.11.2026 | [ENTSCHEIDUNG] Lotse-Sprachmodell Weg A: Claude über eigenen Server, gestuft (Regeln → Haiku 5.5 Werkzeugwahl → Sonnet 5.5 Gespräch); Modellnamen nur auf dem Server; Kontingent frei/Pro; Tester frei bis Store-Start | `docs/produkt/konzepte/lotse.md` §5, `docs/technik/lotse-server.md` |
| 23.11.2026 | [ENTSCHEIDUNG] Rechnung Fassung 2: Ziele bestehen aus Meilensteinen (gewichtet 1/2/3), nur sie zählen in die Prozente; Termine zählen (Zahl je 1, Zeit Dauer); Habit als Anzahl oder Wochen (Woche = alle geplanten Tage); 90-%-Regel; Lernen nur in Vorschlägen | `docs/produkt/rechenregeln.md` |
| 23.11.2026 | [ENTSCHEIDUNG] Technik-Weg A: SwiftUI zuerst (Auftrag des Gründers, das Xcode-Projekt anzulegen) | `docs/technik/app.md` |
| 23.11.2026 | [ENTSCHEIDUNG] Kompass ist ein eigenes Projekt mit eigenem Repo und Ordner, Aufbau wie Gapless (Roter Faden, Fahrplan, Landkarte, Arbeitsweise) | `docs/team/arbeitsweise.md` §0 |
| 23.11.2026 | [ENTSCHEIDUNG] Design wie Gapless (Harbor 2): Textmenge, Abstände, Schrift, Verläufe, Icons | `docs/produkt/design.md` |
| 23.11.2026 | [ENTSCHEIDUNG] App soll veröffentlicht werden; iPhone/Mac zuerst, später Windows und Android | `docs/leitung/fahrplan.md` |
| 23.11.2026 | [ENTSCHEIDUNG] Planen und Kalender sind **ein** Bereich („Kalender“) | `docs/produkt/grundlage.md` |
| 23.11.2026 | [ENTSCHEIDUNG] Habits und Ziele sind getrennt: Habit = täglich, Serie; Ziel = Datum, Fortschritt | `docs/produkt/grundlage.md` |
| 23.11.2026 | [ENTSCHEIDUNG] Kompass ergänzt Apple- und Google-Kalender, ersetzt sie nicht (kann es aber); Termine sind Zielen und Habits zuordenbar | `docs/produkt/konzepte/kalender-anbindung.md` |
| 23.11.2026 | [ENTSCHEIDUNG] So einfach wie möglich, so intelligent wie möglich, fein anpassbar; Vorschläge direkt übernehmen oder erweitern; **gerechnet wird immer gleich und richtig** | `docs/produkt/rechenregeln.md` |
| 23.11.2026 | [ENTSCHEIDUNG] App soll durch Nutzer dazulernen | `docs/produkt/rechenregeln.md` §7 |
| 23.11.2026 | [ENTSCHEIDUNG] Ziele minimal: Ziel-Seite zeigt nur Kopfkarte, Warum, „Dein nächster Schritt“ und Meilensteine, Rest unter „Verfeinern“; Regel „nächster Schritt“ = offener Meilenstein mit größtem fehlendem Beitrag (PR #17, „Ja, mergen“) | `docs/produkt/rechenregeln.md` §1, `konzepte/struktur-v3.md` §11 |

## 2. Offen (Gründer entscheidet)

| Thema | Vorschlag Claude | Wo |
|---|---|---|
| [OFFEN] App-Name (Arbeitstitel „Kompass“) | – | – |
| [OFFEN] Ort des Lotse-Servers: Supabase Edge Functions (auch für späteren Abgleich) oder anderer Host | Supabase, Region EU | `docs/technik/lotse-server.md` |
| [OFFEN] Kontingent: 5 freie Server-Fragen/Tag, Pro bis 300; Preis von Pro | so starten, Preis offen | `docs/technik/lotse-server.md` §5 |
| [OFFEN] Namen „Fortschritt“ (Tab Ziele · Habits) und „Lotse“ (Assistent) | so lassen | `konzepte/lotse.md` |
| [OFFEN] Sprache der App-Texte | Deutsch zuerst, Englisch zusätzlich ab Phase 3 | `CLAUDE.md` |
| [OFFEN] Nur für dich oder Produkt mit Abo | Produkt mit Abo (B2C, passt zu deinen Ideen-Kriterien) | `fahrplan.md` §1 |
| [OFFEN] Fokusblöcke in Google/Apple zurückschreiben? | optional, ab Phase 3 | `konzepte/kalender-anbindung.md` |
