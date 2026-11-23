# Design – nach Gapless „Harbor 2“

Stand: 23. November 2026. Vorbild ist das Designsystem von Gapless (`Tokens.swift`, `design.md` dort). Werte hier übernommen, damit beide Apps zueinander passen; **kein geteilter Code**. Abgleich per Messung am 23.11.2026 (Screenshots + Texterkennung).

## 1. Textregeln (wie Gapless)

1. ca. ≤ 35 Wörter pro Bildschirmhöhe auf Hauptseiten.
2. Eine Zeile = ein Fakt; höchstens ein „·“.
3. Erklärsätze höchstens einmal pro Seite oder hinter (i).
4. Keine Aussage doppelt.
5. Überschrift = Aussage, kein Etikett darüber, kein Untertitel.
6. Höchstens 3 Flächen-Arten pro Screen (Grund, weiße Karte, Verlaufskarte); keine getönten, gestrichelten oder farbig gerahmten Hinweiskästen.

Gemessen 23.11.2026 (iPhone, Wörter je Bildschirm): Gapless Insights 32, Net worth 35, Bills 37, Overview 56 · Kompass nach Umbau: Heute ~44, Kalender 40, Habits 40, Ziele 33, Rückblick 29.

## 2. Farben (hell / dunkel)

| Token | Hell | Dunkel | Verwendung |
|---|---|---|---|
| background | #F2F2F7 | #000000 | Grund |
| ground (oben) | #D9DFFA | #171D4D | Verlauf oben, läuft bei ~64 % in den Grund |
| card | #FFFFFF | #1C1C1E | Karten, Listen |
| ink | #18233F | #F2F2F7 | Text |
| secondary | #4D5262 | #A1A1A6 | Unterzeilen |
| chevron | #7E8391 | #8E8E93 | Pfeile, Hinweise |
| accent | #3B4CCA | #9AA6FF | Aktionen, Links, Auswahl (nie Daten) |
| accentSoft | #E6E9FC | #262D63 | „+ Neu“, weiche Chips |
| joy / ok | #1F9D55 | #5EE0B5 | gute Momente (erledigt) – nie Text |
| warning | #8A5300 / #FFF3DC | #FFC266 / #2E2614 | „hinterher“ |
| critical | #BA3228 | #FF7A6E | „überfällig“ |

Ziel-Farben (Reihe wie Gapless `chartSeries`): Indigo #3B4CCA, Violett #7A4FD6, Himmel #1F7AC2, Petrol #0E8580, Rose #B8456E, Bernstein #9A6700, Orange #C2410C, Grün #15803D, Fuchsia #A21CAF, Schiefer #6B7285.

## 3. Maße

| Maß | Wert |
|---|---|
| Seitenrand | 16 pt |
| Kartenradius | 22 pt (Verlaufskarten 24) |
| Abstand Überschrift → Inhalt | 12 pt; zwischen Abschnitten 32 pt |
| Zeilenhöhe | min. 64 pt (kompakt 52) |
| Icon in Zeilen | 40 pt rund, weiche Kachel in Zielfarbe |
| Buttons | Kapsel, min. 44 pt |
| Titel-Abstand zur Statusleiste | 14 pt |

## 4. Schrift

SF Pro Rounded (Dynamic Type): Large Title 34 heavy · Abschnitt (Title 2) 22 bold · Text 17 semibold/medium · Unterzeile 15 · Klein 13 semibold. Im Web/Windows/Android: Nunito als Ersatz.

## 5. Bausteine

- **Seitenkopf:** großer Titel links, rechts „+ Neu“ (Kapsel, accentSoft), (i), Einstellungen (runde Knöpfe). Keine App-Kopfleiste auf dem Handy.
- **Abschnitt:** Titel 22 bold, rechts ein kurzer Wert oder Link („Alle ›“).
- **Gruppierte Liste:** Zeilen in einer weißen Karte, Trennlinie ab 66 pt; letzte Zeile „+ Aufgabe“. Je Gruppe 3 Einträge, dann „N weitere ⌄“.
- **Verlaufskarten** (wie „Insights“): Titel, große Zahl (40 heavy), eine Zeile, Mini-Grafik; tief → hell, weicher Lichtschein oben links, farbiger Schatten.
- **Hinzufügen-Kacheln** (wie „Add“): 2×2 Verlaufskacheln, weißes Symbol im Glaskreis.
- **Tab-Leiste:** schwebende Glas-Kapsel, aktives Symbol kräftiger, aktiver Tab mit accentSoft. Fünf Tabs: Heute · Kalender · Fortschritt · Lotse · Rückblick.
- **Umschalter** (Fortschritt: Ziele · Habits): Kapsel in accentSoft, aktives Segment als weiße Kapsel mit leichtem Schatten, unter dem Seitenkopf.
- **Chat (Lotse):** Nutzer-Blasen in accent/weiß rechts, Lotse-Blasen als weiße Karte links mit Sprung-Link und Daumen; Vorschläge als Chips; Eingabe als Kapsel mit rundem Senden-Knopf.
- **Seitenfuß:** Speicherstatus + „Daten & Kalender“ unten auf jeder Seite.

## 6. Bewegung (Reduce Motion: alles aus)

Kurven zeichnen sich in 1,25 s von links nach rechts mit leuchtender Spitze; Zahlen zählen hoch; Balken und Ringe wachsen beim Öffnen; Haken ploppen (Feder) mit kurzer Vibration; Fenster mit iOS-Federkurve. Nur beim ersten Öffnen einer Ansicht, nicht bei jeder Änderung.
