# Hick’s Law in Kompass – Analyse und Plan

Stand: 24. November 2026 · [VORSCHLAG] · Auftrag des Gründers: „Alles geführt, nicht zu viel Auswahl.“

## 1. Die Regel

Hick’s Law: Die Zeit für eine Entscheidung wächst mit der Zahl der Wahlmöglichkeiten – etwa `T = a + b · log₂(n + 1)`. Doppelt so viele Optionen kosten nicht doppelt, aber spürbar mehr Zeit und Überwindung. Daraus folgen vier Regeln für Kompass (Ergänzung zu `design.md` §1):

1. **Höchstens 3–5 Wahlmöglichkeiten je Entscheidung.** Mehr nur, wenn sie geordnet und bekannt sind (Wochentage, Uhrzeiten).
2. **Eine Hauptaktion je Bildschirm**, farbig; alles andere zweitrangig oder versteckt.
3. **Voreinstellung statt Frage.** Was Kompass vorschlagen kann, ist vorgewählt; der Nutzer korrigiert nur.
4. **Stufen statt Listen.** Seltene Dinge hinter „Mehr“, „Details“, „Verfeinern“ – eine Taste, nicht sieben Optionen.

Gezählt wird je Bildschirm: *sichtbare Entscheidungen* (Knöpfe, Chips, antippbare Zeilen, die jetzt eine Wahl verlangen). Ziel: ≤ 7 auf den ersten Blick, ≤ 5 je Gruppe.

## 2. Befund je Bereich

| Bereich | Heute sichtbar (Entscheidungen) | Urteil | Änderung |
|---|---|---|---|
| **Tabbar** | 5 Tabs | ✓ | – |
| **Home** | Jetzt-Karte 2 + Als Nächstes 3 Karten + „Alle 5“ + Reel 1 + Hinweise 3 + Heute offen 6 (+ Fokus je Zeile) + Liegen geblieben + Tagesabschluss ≈ **18–22** | ✗ zu viel | Home wird ohnehin umgebaut (Gründer). Vorschlag: Jetzt-Karte (1 Hauptaktion) · Als Nächstes (3) · ein Reel · Heute offen auf 3 + „alle“ · Hinweise nur 1 (der wichtigste) |
| **Kalender** | Tag/Woche/Monat/Jahr 4 + Wochenleiste 7 + Vorschläge 8 Chips + Einträge (je: tippen, Haken, ziehen) + „+ Neu“ ≈ **25+** | ✗ | Vorschläge auf **3** kürzen („mehr“ öffnet den Rest); Jahr unter Monat verstecken (3 statt 4); Wochenleiste bleibt (Wochentage sind bekannt) |
| **+ Neu · Was** | 4 Kacheln | ✓ | – |
| **+ Neu · Wann (Aufgabe)** | Tag 4 + Uhrzeit 5 + Dauer 4 = **13** | ✗ | Uhrzeit und Dauer erst nach Tag zeigen (Stufe); Uhrzeit 3 (Vormittag/Nachmittag/Abend + „genau“) |
| **+ Neu · Verbinden (Ziel)** | Habits 5 + Serien ~6 + Aufgaben ~4 + Toggle ≈ **16** | ✗ | Kompass **schlägt vor** (passende Habits/Serien vorgewählt, Rest unter „weitere“), nur 3 je Gruppe sichtbar |
| **+ Neu · Verbinden (Habit)** | Ziele 4 + Toggle + 7 Tage + Termine ≈ **14** | ✗ | Ziel vorgewählt (letztes/ähnliches), 7 Tage nur bei „schon angefangen“ |
| **+ Neu · Termin** | Speichern in 3–4 + Ziel 4 + Meilenstein 3 + Habit 5 + Wiederholung 5 ≈ **20** | ✗ | Kalender vorgewählt (Standard); Ziel und Habit als **eine** Frage „Zählt für?“ mit 3 Vorschlägen; Wiederholung unter „Mehr“ |
| **Aufgabe (Seite)** | Haken, Wichtig, Fokus 3 + Ziel 4 + Meilenstein 5 + Tag 4 + Uhrzeit 5 + Dauer 5 + Wiederholen 5 + Kategorie 6 ≈ **37** | ✗✗ | Zählt für: Ziel vorgewählt, Meilenstein nur 3 + „weitere“; Wann: Tag 4, Uhrzeit/Dauer erst nach Wahl; **Mehr** zugeklappt (Wiederholen, Kategorie, Notizen) |
| **Termin bearbeiten (Apple/Google)** | Erinnerung 6 + Wiederholung 6 + Kalender n + Toggle ≈ **16** | ✗ | Erinnerung 3 (15 Min, 1 Std, 1 Tag + „andere“); Wiederholung als Picker (1 Entscheidung); Kalender vorbelegt |
| **Fortschritt · Ziele** | Segment 2 + Filter 4 + Sortieren 6 + Karten | ○ | Sortieren auf **3** (Frist, Fortschritt, Hinterher zuerst); Jahr/Bereich-Gruppen als Umschalter „Gruppieren“ |
| **Ziel-Seite** | Stand 2 + Kacheln 4 + Meilensteine n + „hinzufügen“ ≈ 7 + n | ✓ | Meilensteine über 5 → „alle anzeigen“ |
| **Verfeinern (Ziel)** | 6 Kacheln | ✓ | – |
| **Habit-Seite** | Stand 2 + Kacheln 4 | ✓ | – |
| **Habit · Wie viel** | Einheiten **11** Chips | ✗ | 3 Vorschläge aus dem Titel („Minuten“ bei „lesen“) + „andere“ |
| **Meilenstein geführt** | je Schritt 2–4 | ✓ | – |
| **Assistent** | 3 Beispielfragen + Eingabe | ✓ | – |
| **Rückblick (heute)** | 7 Karten + Woche ‹ › + Reflexion ≈ 10 | ○ | neu (unten) |
| **Rückblick (Entwurf 3)** | 13 Karten × i + Tower 3 × 2 + Zeitraum 3 ≈ **35** | ✗ | → Entwurf 4 |
| **Einstellungen** | ~8 Zeilen | ✓ | – |

Legende: ✓ passt · ○ grenzwertig · ✗ zu viele Entscheidungen auf einmal.

## 3. Rückblick nach Hick (Entwurf 4)

- **5 Karten auf einen Blick:** Flugbericht · Tower · Flugplan · Logbuch · Debriefing. Die übrigen 8 (Treibstoff, Flugzeit, Checkliste, Habits, Radar, ETA, Testflug, Crew) liegen hinter **einer** Taste „Details“.
- **Tower: höchstens 2 Hinweise, je genau 1 Knopf.** Erfolge gehören ins Logbuch, der Tower meint nur „tun“.
- **Zeitraum: 3** (Woche vorgewählt). **Warum-Blatt: 2 Knöpfe** (Hilfreich · Passt nicht), Schließen durch Wischen.
- Die Karten in „Details“ ordnet Kompass nach Nutzen (§7 des Rückblick-Konzepts) – Lernen senkt die Auswahl weiter, weil das Wichtige nach oben kommt.

## 4. Allgemeine Muster für die ganze App

| Muster | Statt | So |
|---|---|---|
| **Vorschlag zuerst** | 11 Einheiten | 3 passende + „andere“ |
| **Stufe** | Tag + Uhrzeit + Dauer auf einmal | erst Tag, dann (falls gewählt) Uhrzeit, dann Dauer |
| **Eine Frage** | „Ziel?“ und „Habit?“ und „Meilenstein?“ | „Zählt für?“ mit 3 Vorschlägen, Kompass ergänzt den Rest |
| **Mehr-Taste** | 6 Chips Kategorie immer sichtbar | zugeklappt unter „Mehr“ |
| **Kürzen + „alle“** | 8 Vorschläge, 6 Aufgaben | 3 + „alle 8“ |
| **Picker statt Chips** ab 5 Optionen | Wiederholung 6 Chips | eine Zeile mit Picker (1 Entscheidung jetzt, Liste erst beim Antippen) |
| **Hauptaktion farbig** | zwei gleich starke Knöpfe | eine Seladon, eine Glas |

## 5. Reihenfolge der Umsetzung [SCHÄTZUNG]

1. **Rückblick neu** nach Entwurf 4 (ohnehin geplant).
2. **Aufgabe + „+ Neu“** – größter Hebel (37 → ~10): Stufen, Vorschläge, Mehr-Taste. (M)
3. **Kalender**: Vorschläge 3 + „alle“, Jahr versteckt, Termin-Blätter mit Picker. (S)
4. **Habit Wie viel, Sortieren, Erinnerung**: Vorschläge statt Vollliste. (S)
5. **Home** – beim geplanten Umbau. (M)

Jede Änderung: `AppWissen` nachziehen, UI-Tests anpassen, Roter Faden.

## 6. Offen [OFFEN]

- Zählt die Wochenleiste (7 Tage) als Auswahl? Vorschlag: nein – bekannte, geordnete Menge.
- Beim Termin „Speichern in“: Standardkalender vorwählen oder zuletzt genutzten?
