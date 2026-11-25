# Home als intelligenter Überblick – Konzept [VORSCHLAG – 25.11.2026, Entscheidung des Gründers offen]

Auftrag des Gründers: Home soll „das Leben auf einen Blick“ zeigen – gebündelt und ausgewertet aus Zielen, Habits, Aufgaben, Meilensteinen, Kalender, Rückblick und Assistent; dynamisch, je Person das, was gerade wichtig ist. Kompass soll der intelligenteste Tagesplaner sein.

## 1. Befund: was heute schon ineinandergreift

| Baustein | Rechnet | Fließt in |
|---|---|---|
| Aufgaben, Termine, Habits | `Tagesplan` (§9): Blöcke, Als Nächstes, Auslastung, Hinweise | Home, Kalender, Rückblick, Assistent |
| Meilensteine | `Fortschritt` (§1): Gewicht × Stand | Ziel, Rückblick, Assistent |
| Ziele | `Kurs` (§4, §5): Lage, Prognose | Fortschritt, Rückblick, Home (nur indirekt) |
| Habits | `HabitRechnung` (§6): Quote, Serie | Fortschritt, Rückblick |
| Woche | `Wochenwort` (§11), `Statistik` | Rückblick |
| Assistent | 15 Werkzeuge, liest dieselbe Rechnung | Chat |

**Sauber:** eine Rechnung, viele Ansichten – der Assistent rechnet nie selbst. **Lücken:**
1. Home zeigt *eine* Sache und „Als Nächstes“, aber **nichts aus Zielen** (Lage, Prognose) und **nichts aus dem Rückblick**.
2. Hinweise kennen nur drei Arten (enger Tag, Überschneidung, kein Platz) – alle aus dem heutigen Tag. Nichts schaut **voraus** (nächste Tage, Fristen).
3. Der Kalender wird nur als Zeit gelesen, nie als **Bedeutung** („Geburtstag Mama“ → Geschenk).
4. Was oben steht, ist fest verdrahtet – keine Rangfolge nach Wichtigkeit.

## 2. Vorschlag: Signale mit Rang

Home bleibt in drei Ebenen (Bühne mit Wort, Karte vorn mit einer Sache, darunter Liste). Neu ist, **woher** die Zeilen unter der Karte kommen: aus einer Liste von **Signalen**. Jedes Signal ist deterministisch gerechnet, hat einen Rang und genau eine Handlung. Home zeigt die drei mit dem höchsten Rang (Hick), „alle“ führt weiter.

| Signal | Bedingung (deterministisch) | Text (Beispiel) | Handlung |
|---|---|---|---|
| Engpass voraus | ein Tag der nächsten 7 mit Auslastung ≥ 75 % | „Donnerstag ist voll“ | Tag im Kalender |
| Luft | ein Tag der nächsten 3 mit Auslastung ≤ 25 % und offene Aufgaben ohne Datum | „Morgen 4 h frei“ | Vorschläge einplanen (§9.1) |
| Ziel kippt | Lage wechselt auf „hinterher“ oder Prognose nach der Frist (§4, §5) | „Fit: 3 Wochen hinter Plan“ | Ziel-Seite |
| Frist nah | Meilenstein oder Ziel fällig in ≤ 14 Tagen, Stand < 100 % | „Theorieprüfung in 9 Tagen“ | Meilenstein |
| Serie in Gefahr | Habit heute geplant, offen, Serie ≥ 7, nach 18 Uhr | „Sport: Serie 10 – heute offen“ | Abhaken |
| Serie geschafft | Serie erreicht 7 / 30 / 100 | „30 Tage Lesen“ | Analyse |
| Liegengeblieben | Aufgaben mit Datum < heute, offen | „3 von gestern“ | Alle auf heute |
| Anlass | Kalendertermin der nächsten 21 Tage passt auf eine Anlass-Regel (s. u.) | „Mamas Geburtstag in 12 Tagen – Geschenk?“ | Aufgabe anlegen |
| Wochenstart | Montag vor 12 Uhr | Wochenwort der letzten Woche | Rückblick |

**Rang** = Dringlichkeit (Tage bis zum Ereignis) × Gewicht der Art; Gewichte als Tabelle in den Rechenregeln, je Nutzer anpassbar durch „Passt nicht“ (Signal-Art 8 Wochen stumm – wie heute beim Rückblick). Das ist die „individuelle“ Schicht – gelernt wird nur die Rangfolge, nie die Rechnung.

## 3. Anlässe aus dem Kalender

Zwei Stufen, damit es ohne KI funktioniert und Privates privat bleibt:
1. **Regeln auf dem Gerät:** Wortliste je Anlass (Geburtstag, Hochzeit, Weihnachten, Urlaub/Flug, Prüfung, Arzt) → Vorschlag mit fester Vorlaufzeit (Geburtstag: 14 Tage vorher „Geschenk besorgen“; Prüfung: 7 Tage „Lernblöcke einplanen“; Urlaub: 5 Tage „Packliste“). Feste Tage ohne Termin (24.12.) aus einer kleinen Tabelle.
2. **Assistent, nur auf Wunsch:** tippt man das Signal an, darf der Assistent ausformulieren und Ideen liefern. KI macht Text und Vorschläge, sie rechnet nicht und legt nichts ohne Bestätigung an.

[OFFEN – Datenschutz, Prüffrage] Kalendertitel verlassen das Gerät nur, wenn der Nutzer das Signal an den Assistenten weitergibt. Braucht eine Einwilligung und einen Satz in den Einstellungen.

## 4. Was es an Rechenregeln braucht

Neue Regel „§12 Signale“ (Bedingungen, Schwellen, Rang, Stummschalten) mit Tests je Signal und dem Personen-Test (kein Signal ohne Bedingung, höchstens drei auf Home). **Rechenregel = Freigabe des Gründers.**

## 5. Reihenfolge [VORSCHLAG]

1. Signale ohne Kalender-Bedeutung (Engpass, Luft, Ziel kippt, Frist nah, Serie, Liegengeblieben) – reine Rechnung, sofort testbar.
2. Home zeigt die Top 3; „Passt nicht“ stellt stumm.
3. Anlässe per Regeln; danach die Assistent-Stufe mit Einwilligung.
4. Werkzeug `signale` für den Assistenten („Was ist diese Woche wichtig?“) und `AppWissen`.

## 6. Schwächen und Alternativen

- [RISIKO] Zu viele Signale wirken wie Benachrichtigungs-Spam. Gegenmittel: hart auf drei begrenzen, jede Art stummschaltbar, kein Signal ohne Handlung.
- [RISIKO] Anlass-Regeln per Wortliste treffen daneben („Geburtstagsfeier planen“ ist schon die Aufgabe). Gegenmittel: nur vorschlagen, nie anlegen; „Passt nicht“ lernt.
- Alternative: alles dem Assistenten überlassen (ein Aufruf je App-Start). Verworfen – kostet je Start, braucht Netz, ist nicht prüfbar und widerspricht „KI rechnet nie“.
