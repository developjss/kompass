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

## 1a. Hick’s Law [VORSCHLAG – 24.11.2026]

Höchstens 3–5 Wahlmöglichkeiten je Entscheidung, eine Hauptaktion je Bildschirm, Voreinstellung statt Frage, Stufen statt Listen („Mehr“, „Details“). Analyse je Bereich und Plan: `konzepte/hicks-law.md`.

## 2. Farben „Blattwerk“ (hell / dunkel) [ENTSCHEIDUNG – 24.11.2026, Gründer: „Ja, so bauen“]

Rosé trägt, Weinrot spricht, Kellygrün ist die eine Handlung. Löst „Nachtflug“ (Indigo, Seladon, Gold; 24.11.2026 vormittags) ab. Prototyp mit allen Seiten, Bildern und Maßen: https://claude.ai/artifact/HzWoB8fnKe61TxXBUjEUrf (Code: `Kompass/Design/Farben.swift`, `Buehne.swift`; Tests `KompassTests/BlattwerkTests.swift`).

| Token | Hell | Dunkel | Verwendung |
|---|---|---|---|
| grund | #FBEDF1 | #2E0816 | Seitengrund |
| buehne (= grundOben) | #F6CBD4 Rosé | #4A0F24 Weinrot | Ebene 1, Chips, Zeichen-Kreise |
| karte | #FFFFFF | #5A1C33 | Karten, Listen, Tabbar |
| text / wort | #4A0F24 | #F6CBD4 | Text, Bühnen-Wort, Marke |
| zweitrangig | #85536A | #D4A3B4 | Unterzeilen, Etiketten |
| akzent (Text) | #1B7A1A | #2DC92A | Handlung als Text und Zeichen |
| handlung (Fläche) | #2DC92A | #2DC92A | Hauptknopf, Ring, Haken, heutiger Tag, letztes Wort |
| aufFarbe | #2E0816 | #2E0816 | Schrift auf Grün |
| akzentWeich | #DDF5DC | #3B4D30 | Tab-Pille, Vorschläge, Band „dein Normal“, Pille „im Plan“ |
| linie | #E6D2D8 | #4E2734 | Trennlinien, Rahmen |
| warnung / warnungGrund | Weinrot / Rosé | Rosé / Weinrot | „hinterher“ als Pille |
| kritisch | #8E1B3C | #FF9FB8 | „überfällig“ |

Alte Namen `gold`, `goldText`, `seladon`, `nacht` zeigen auf die neuen Rollen, bis alle Seiten umgebaut sind.

Ziel-, Habit- und Kalenderfarben: `Farbe.tonArt` legt jede bunte Hex-Farbe nach Farbton auf weinrot, beere, rosa, wein, gruen oder gruenTief (je hell/dunkel).

Kontraste (WCAG): Weinrot auf Grund 13 : 1, auf Rosé 10 : 1; Grün tief als Text 4,8 : 1; Schrift auf Grün 8,2 : 1. Grün ist nie Text auf Rosé (2,1 : 1) – das grüne Bühnen-Wort gilt als Dekoration ≥ 48 pt, die Zahl steht immer zusätzlich in der Karte.

### 2a. Drei Ebenen: Bühne · Objekt · Karte

Jede Hauptseite ist wie ein Produktbild aufgebaut (`Buehne.swift`):
1. **Bühne** (Rosé): Marke bei y 62 (Name in Versalien, New York 17, Laufweite; rechts Datum oder Knöpfe 36 pt mit Rahmen), **Wort** bei y 118 / x 20 (New York, Großbuchstaben, 72 pt; klein 56, mittel 64, riesig 98; Zeilenabstand 0,86; das letzte Wort in Grün). Das Wort ist die Aussage der Seite, nie ein Etikett. Höhe 360, kurz 250, lang 430; Fokus: Foto Landebahn über die ganze Höhe.
2. **Objekt**: ein echtes, freigestelltes Foto je Seite, nie mittig, nie antippbar; Platzierung je Seite in `Platz` (rechts/oben/Breite/Drehung aus dem Prototyp); Schatten 0 24 26 bei 28 %. Flugzeug = Tun (Home, Aufgabe, Fokus, Ziel), Bordkarte = Woche (Kalender, Habits, Rückblick), Kompass-Kugel = Kurs (Fortschritt, Neu), Tower = Assistent und Einstellungen.
3. **Karte vorn** (`VornKarte`): Radius 24, Innen 16, Versatz −38 über die Bühne, Schatten 0 18 40; darin genau eine grüne Hauptaktion (`.buttonStyle(.haupt)`, 50 pt) und höchstens eine leise Zweitaktion (`.leise`); Löschen `.rot`. Karten-Titel New York 26, Etikett 12 heavy Versalien.

Die Seiten, Stand Block 4: Home (Bühne „Jetzt dran“, 747 im Anflug), Kalender (kurz, Bordkarte), + Neu und Aufgabe (747 beim Abflug), Termin (ohne Objekt), Fortschritt · Ziele und Ziel-Seite (Messing-Kompass bzw. A380), Fortschritt · Habits (Bordkarte), Habit-Seite (Messing-Kompass). Noch offen: Fokus (Landebahn bei Nacht), Rückblick (Bordkarte zum Abreißen), Assistent und Einstellungen (Tower).

Bilder: `Assets.xcassets/blattwerk-*` (A380, 747 im Anflug, 747 beim Abflug, zwei Tower, Kompass-Kugel, Messing-Kompass, Bordkarte, Landebahn, Landebahn bei Nacht; einzeln skaliert, 1024–2100 px). Entstanden aus Vorlagen des Gründers: freigestellt mit Vision, Schriftzüge entfernt, Leitwerke in Weinrot. [RISIKO] Rechte an den Foto-Vorlagen vor dem Store klären (Presse-/Stock-Fotos); Bordkarte und Messing-Kompass sind erzeugt.

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

Seitentitel und große Zahlen in Serif (New York, Dynamic Type); sonst SF Pro Rounded: Large Title 34 · Abschnitt (Title 2) 22 bold · Text 17 semibold/medium · Unterzeile 15 · Klein 13 semibold. Im Web/Windows/Android: Nunito als Ersatz.

## 5. Bausteine

- **Seitenkopf:** großer Titel links, rechts „+ Neu“ (Kapsel, accentSoft), (i), Einstellungen (runde Knöpfe). Keine App-Kopfleiste auf dem Handy.
- **Abschnitt:** Titel 22 bold, rechts ein kurzer Wert oder Link („Alle ›“).
- **Gruppierte Liste:** Zeilen in einer weißen Karte, Trennlinie ab 66 pt; letzte Zeile „+ Aufgabe“. Je Gruppe 3 Einträge, dann „N weitere ⌄“.
- **Verlaufskarten** (wie „Insights“): Titel, große Zahl (40 heavy), eine Zeile, Mini-Grafik; tief → hell, weicher Lichtschein oben links, farbiger Schatten.
- **Hinzufügen-Kacheln** (wie „Add“): 2×2 Verlaufskacheln, weißes Symbol im Glaskreis.
- **Tab-Leiste:** schwebende Glas-Kapsel, aktives Symbol kräftiger, aktiver Tab mit accentSoft. Fünf Tabs: Heute · Kalender · **Lotse** (Mitte) · Fortschritt · Rückblick.
- **Umschalter** (Fortschritt: Ziele · Habits): Kapsel in accentSoft, aktives Segment als weiße Kapsel mit leichtem Schatten, unter dem Seitenkopf.
- **Chat (Lotse):** Nutzer-Blasen in accent/weiß rechts, Lotse-Blasen als weiße Karte links mit Sprung-Link und Daumen; Vorschläge als Chips; Eingabe als Kapsel mit rundem Senden-Knopf.
- **Seitenfuß:** Speicherstatus + „Daten & Kalender“ unten auf jeder Seite.

## 6. Bewegung (Reduce Motion: alles aus)

Kurven zeichnen sich in 1,25 s von links nach rechts mit leuchtender Spitze; Zahlen zählen hoch; Balken und Ringe wachsen beim Öffnen; Haken ploppen (Feder) mit kurzer Vibration; Fenster mit iOS-Federkurve. Nur beim ersten Öffnen einer Ansicht, nicht bei jeder Änderung.

## 6a. Kalender (24.11.2026)

- „Als Nächstes“ steht auf Home; der Kalender beginnt mit Tag · Woche · Monat · Jahr.
- Tag: 64 pt je Stunde, überlappende Einträge brechen um. Woche: breite Spalten (~3 Tage sichtbar), waagerecht wischen.
- Ziehen: halten 0,3 s, Eintrag bleibt groß, gestrichelte Vorschau mit Uhrzeit (15-Min-Raster), Woche auch über Tage, über den oberen Rand = ohne Uhrzeit.
- Apple/Google (EventKit): live aktualisiert (`EKEventStoreChanged`), verschieben/bearbeiten/löschen/anlegen direkt im Kalender des Geräts; Google über das iOS-Konto (keine eigene Google-Anbindung).

## 7. Gadgets (Nachtflug)

- **Fokus als Flug** (`FokusBlatt`, `FlugRechnung`): Nachthimmel, Route KMP → Kürzel des Ziels, Flugzeug an der Stelle Fokuszeit ÷ geplante Dauer der Aufgabe (mind. 5 Min). Phasen: Boarding, Steigflug (< 15 %), Reiseflughöhe, Landeanflug (≥ 80 %), Gelandet, Warteschleife (Pause). Instrumente Höhe (FL, Sinusbogen bis FL350), Strecke, Ankunft. Haptik beim Abheben und Landen. Reduce Motion: Wolken stehen, Flugzeug springt ohne Gleiten. Nur Anzeige – gebucht wird wie bisher (`FokusRechnung`).
- **Rückblick als Bordkarte** (`Bordkarte`): oben im Rückblick die Bordkarte der Woche (Woche, KMP + KW, MO → SO, Von/Nach, Gate = aktive Ziele, Fokuszeit). Goldenen Abschnitt nach rechts ziehen (> 60 pt) oder antippen: er reißt ab und fällt, dahinter erscheint die Aussage-Karte. Je Woche gemerkt (höchstens 26 Wochen). Haptik beim Abreißen; Reduce Motion: ohne Fallen.
