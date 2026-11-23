# Habits v2 – Konzept für den Tab „Fortschritt · Habits“

Stand: 23. November 2026 · Grundlage: Screenshots der App (Simulator), Gapless (Harbor 2: `design.md`, Transaktions-Seite, Listen), Vorgaben des Gründers vom 23.11. [ENTSCHEIDUNG – 23.11.2026] „Ja, so bauen“. Block 1 gebaut (Modell, Rechnung, Habits-Seite, Menge eintragen, Anlegen mit Chips); Block 2 gebaut (Habit-Seite mit Fakten-Zeilen und Editor je Zeile, Verlauf, „Zählt in“; Erinnerungen als lokale Mitteilungen, `ErinnerungRechnung` + `Erinnerungen`). Rechenregel §5 in `rechenregeln.md` §6 übernommen [ENTSCHEIDUNG – 23.11.2026, PR #11].

## 1. Befund – so ist es heute

| Was | Problem |
|---|---|
| Kopfkarte „1 von 5 · 65 % in 30 Tagen · Serie 2“ | Zahl ohne Aussage; Säulen ohne Beschriftung; keine Trennung heute / Woche |
| Eine Liste „Diese Woche“ mit 7 Tages-Punkten je Habit | Zeile ist überladen (Titel abgeschnitten, 7 Kreise, Flamme, Prozent); Wochentag-Kreise sind klein (28 pt) und sehen auf allen Habits gleich aus; heute ist nicht erkennbar |
| Habit = abgehakt oder nicht | Keine Menge: „20 Minuten lesen“ ist entweder 0 oder 100 %; 10 Minuten lassen sich nicht eintragen |
| Nur feste Wochentage | „3× pro Woche, egal wann“ geht nicht |
| Keine Erinnerung | Ein Habit ohne Uhrzeit wird vergessen |
| Detail-Blatt = vier Zeilen Fakten + Löschen | Nichts bearbeitbar; kein Verlauf; keine Verbindung zum Ziel sichtbar |
| Anlegen: Titel + Wochentage | Keine Menge, keine Einheit, keine Uhrzeit, kein Vorschlag |

## 2. Was wir von Gapless übernehmen (und was nicht)

**Übernehmen (Aufbau, nicht Inhalt):**
- **Gruppierte Listen mit 64-pt-Zeilen**: links Kachel (40 pt, Symbol in Habit-Farbe), Titel + eine Unterzeile, rechts ein Wert, Chevron nur bei Zeilen ohne Wert.
- **Eine dunkle, ruhige Kopfkarte mit einer Aussage** („Heute 3 von 5 geschafft“) und darunter ein Satz, dazu kleine Mini-Grafik – keine Zahlenreihe.
- **Detail-Seite wie die Transaktions-Seite**: oben Kachel groß + Name, dann eine Karte mit **Fakten je Zeile, Label links, Wert rechts, Chevron** – jede Zeile öffnet einen kleinen Editor (Blatt mit Auswahl-Chips oder einem Feld und „Sichern“). Darunter „Verlauf“ (letzte Tage), dann „Einstellungen“ (Erinnerung, Ziel), zuletzt Löschen.
- **Auswahl als Chips** (How often: Weekly / Every 2 weeks …) statt Picker-Räder: Rhythmus, Einheit, Erinnerungszeit.
- **Flächen-Regel**: höchstens 3 Flächen-Arten pro Screen (Grund, weiße Karte, Verlaufskarte); Status nur als Text oder Chip.
- **Kompakte Zeilen 52 pt** für Verlaufslisten (Tage).

**Nicht übernehmen:** Finanz-Semantik (grün = Geld rein, rot = unter 0), Mint-Licht, Monogramme, Pending-Logik. Für Kompass gilt: **Farbe = Habit-/Zielfarbe**, Grün nur für „erledigt“, Bernstein für „heute noch offen und spät“.

## 3. Die Habits-Seite (Fortschritt · Habits)

```
Fortschritt                            + Neu  (i)  ⚙
[ Ziele | Habits ]

┌ Verlaufskarte (grün → dunkelgrün) ───────────────┐
│ Heute                                             │
│ 3 von 5 geschafft              ▁▃▅▆▅▇█  (7 Tage) │
│ Noch offen: Lesen und Sport · Serie bis zu 12     │
└───────────────────────────────────────────────────┘

Heute                                      2 offen
┌ Karte ─────────────────────────────────────────────┐
│ ◉ 20 Minuten lesen        12 von 20 min    ○      │   ← Haken rechts; Tipp auf Zeile = Menge eintragen
│ ◉ Sport                   heute offen · 18:00 🔔   ○ │
│ ✓ LAPL-Theorie lernen     erledigt · Serie 4       ●  │   ← erledigte unten, grau
└────────────────────────────────────────────────────┘

Diese Woche                              Mo–So
┌ Karte ─────────────────────────────────────────────┐
│ ◉ 3× Sport pro Woche      2 von 3 · noch Fr/Sa    ▒▒░ │  ← Wochen-Habits: Fortschritt der Woche
│ ◉ Kein Handy nach 22 Uhr  M D M D F S S           5/7 │  ← Tages-Habits: kleine Wochenpunkte, heute hervorgehoben
└────────────────────────────────────────────────────┘

Alle Habits                               Bearbeiten ›
┌ Karte ─────────────────────────────────────────────┐
│ ◉ 20 Minuten lesen         täglich · 77 % · Serie 1  › │
│ ◉ Sport                    Mo Mi Fr · 67 % · Serie 2 › │
│ …                                                      │
│ + Habit                                                │
└────────────────────────────────────────────────────┘
```

- **Heute**: nur die heute geplanten Habits, offene zuerst. Rechts der **Haken** (ganze Menge). Tipp auf die Zeile öffnet **Menge eintragen** (Blatt: große Zahl, Einheit, Schnellwahl „halb · ganz · +5“, Tastatur). Teilmenge zeigt die Zeile als „12 von 20 min“ mit dünnem Balken in Habit-Farbe.
- **Diese Woche**: Wochen-Habits („3× pro Woche“) mit „2 von 3 · noch Fr/Sa“ und Segment-Balken; Tages-Habits mit sieben kleinen Punkten (heute mit Ring). Hier wird nicht abgehakt, nur gezeigt – abhaken passiert unter „Heute“ oder im Habit.
- **Alle Habits**: eine Zeile je Habit mit Rhythmus · Quote · Serie, Chevron → Detail. Letzte Zeile „+ Habit“.
- Textmenge: ≤ 35 Wörter je Bildschirmhöhe; jede Zeile ein Fakt.

## 4. Datenmodell (Erweiterung, alte Daten lesbar)

| Feld | Bedeutung |
|---|---|
| `menge: Double?` | Soll je Tag, z. B. 20. `nil` = einfach abhaken (wie heute) |
| `einheit: Einheit?` | `minuten, stunden, sekunden, gramm, kilogramm, milliliter, liter, seiten, mal, kilometer, schritte` – mit Kurzzeichen und Umrechnung in die Basis (min, g, ml, m) nur für die Anzeige |
| `rhythmus` | `.taeglich` · `.wochentage(Set)` · `.proWoche(n)` (n-mal, egal wann) |
| `erinnerung: Uhrzeit?` | Minuten seit Mitternacht; lokale Mitteilung an geplanten Tagen |
| `eintraege: [Tag: Double]` | statt `erledigt: Set<Tag>`: eingetragene Menge je Tag (bei Abhaken ohne Menge = 1) |
| `notiz`, `farbe`, `symbol`, `zielID` | wie bisher |

Migration: `erledigt: Set<Tag>` → `eintraege[tag] = 1`; `wochentage` → `.wochentage(…)` bzw. `.taeglich` bei allen sieben.

## 5. Rechenregeln (in `rechenregeln.md` §6 übernommen) [ENTSCHEIDUNG – 23.11.2026]

- **Anteil eines Tages** = eingetragene Menge ÷ Soll, begrenzt auf 0–1. Ohne Menge: 0 oder 1. Abhaken = 1.
- **Wochen-Habit „n-mal pro Woche“**: Anteil der Woche = Σ Tagesanteile ÷ n, begrenzt auf 1; geplanter Tag = jeder Tag der Woche, solange die Woche noch nicht voll ist.
- **Quote (30 Tage / Woche)** = Σ Tagesanteile ÷ geplante Tage (Teilmengen zählen anteilig – „zur Hälfte geschafft zählt halb“).
- **Serie**: ein Tag zählt, wenn Anteil ≥ 1 (voll). [VORSCHLAG] Alternative: ≥ 0,8 – offen.
- **Meilenstein „Habit · Anzahl“**: Σ Tagesanteile seit Anlage ÷ Soll. **„Wochen“**: Woche zählt, wenn alle geplanten Tage voll sind (bei „n-mal“: n erreicht).
- Alles deterministisch, mit Tests (Teilmengen, Einheiten, Wochen-Habits, Migration).

## 6. Einheiten – intelligente Vorschläge (Regeln, keine KI)

Beim Tippen des Titels schlägt die App Einheit und Menge vor (als Chips unter dem Feld, antippen übernimmt):

| Wörter im Titel | Vorschlag |
|---|---|
| lesen, lernen, üben, meditieren, dehnen, Theorie, Vokabeln | Minuten (20) |
| laufen, joggen, spazieren, Rad, schwimmen | Kilometer (5) oder Minuten (30) |
| essen, trinken, Erdnüsse, Protein, Gemüse, Obst | Gramm (300) · trinken: Liter (2) |
| Wasser | Liter (2) |
| Seiten, Buch | Seiten (20) |
| Liegestütze, Klimmzüge, Kniebeugen, Sätze | Mal (30) |
| Schritte | Schritte (8.000) |
| schlafen | Stunden (8) |
| kein/nicht/ohne (Verzicht: „Kein Handy nach 22 Uhr“) | ohne Menge, einfach abhaken |

Zahl im Titel („20 Minuten lesen“, „300 g Erdnüsse“) → Menge und Einheit direkt übernommen. Später lernt die App aus Übernahmen (Übernahme-Quote wie bei Vorschlägen, §7).

## 7. Anlegen und Bearbeiten

**Anlegen (Blatt):** Titel → darunter Vorschlags-Chips (Einheit/Menge) → Menge + Einheit-Chips → Rhythmus-Chips (Täglich · Werktags · Wochentage wählen · n-mal pro Woche) → Erinnerung (aus / Uhrzeit-Chips 7:00 · 12:00 · 18:00 · 21:00 · andere) → Ziel (optional) → Farbe. Ein Screen, Chips statt Räder, „Anlegen“ unten als breiter Knopf (wie Gapless „Add“).

**Detail-Seite (wie Transaktion):**
1. Kachel groß, Name, Chips „täglich · 20 min“.
2. Karte **Fakten**: Menge · Einheit · Rhythmus · Erinnerung · Ziel · Farbe – jede Zeile mit Chevron öffnet ihren Editor.
3. Karte **Heute**: Menge eintragen (Schnellwahl), Haken.
4. **Verlauf**: letzte 14 Tage als kompakte Zeilen (Tag · Menge · Anteil), darüber Serie · beste Serie · Quote als drei Werte.
5. **Zählt in**: Meilensteine, die diesen Habit nutzen (→ Ziel öffnen).
6. Löschen.

## 8. Erinnerungen

`UserNotifications` (Apple, keine neue Abhängigkeit). Beim ersten Einschalten einer Erinnerung fragt die App um Erlaubnis. Je Habit eine wiederholende lokale Mitteilung je geplantem Wochentag (bei „n-mal pro Woche“: täglich bis die Woche voll ist – Planung neu beim Eintragen). Text: Titel des Habits, darunter „Heute noch offen: 20 min.“ Tipp öffnet die Habit-Seite. **Gebaut (Block 2):** statt wiederholender Mitteilungen werden die nächsten 7 Tage einzeln geplant (`ErinnerungRechnung.termine`, Test) – nur geplante, noch nicht volle Tage, heute nur vor der Uhrzeit; nach jeder Änderung neu, höchstens 60 (iOS-Grenze 64). Erlaubnis verweigert → Zeile „Erinnerung“ zeigt „Mitteilungen aus“ mit Sprung in die iOS-Einstellungen. [OFFEN] Ruhezeiten.

## 9. Ziele – erstes Screening (nächster Schritt)

- Die Ziel-Karten sind gut (Verlauf, Prozent, Kurs), aber die Seite hat **keine Zusammenfassung** oben (Gapless: eine Aussage-Karte); Jahr-Gruppen wirken leer bei 1 Ziel.
- Ziel-Detail: Meilenstein-Zeilen tragen zu viel (Titel, ×2, Prozent, Text, Balken); Bearbeiten nur über langes Drücken (unsichtbar) oder das Blatt – **Fakten-Zeilen mit Chevron wie bei Gapless** fehlen.
- „So wird gerechnet“ ist gut, aber als (i) versteckt; Vorschlag: ein Satz direkt unter der Kopfkarte.
- Fehlt: Ziel anlegen mit Meilenstein-Vorlagen; Zahl-Stand eintragen direkt aus der Liste; Prognose je Meilenstein (bekanntes Risiko).

## 10. Offene Entscheidungen

| [OFFEN] | Vorschlag |
|---|---|
| Serie zählt nur volle Tage (≥ 100 %) | ja; Alternative ≥ 80 % |
| Wochen-Habits unter „Heute“ zeigen, solange die Woche nicht voll ist | ja |
| Erinnerung Standard beim Anlegen | aus |
| Einheiten-Liste | wie §6, erweiterbar |
