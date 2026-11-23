# Struktur v3 – Home, Kalender, Rückblick und wie alles ineinandergreift

Stand: 23. November 2026 · Auftrag des Gründers vom 23.11. („Home statt Heute, Kalender neu, Rückblick abgestimmt, sehr geführt, Lotse zentral“; [ENTSCHEIDUNG – 23.11.2026] „allem selber zustimmen und fortfahren“). Vorbilder: Gapless (Harbor 2, Screenshots Overview/Bills/Insights), Zeitblock-Apps wie Structured, Sunsama, Amie, Fantastical (Eingang → in den Tag ziehen, Tag als Zeitleiste, Monat mit farbigen Einträgen).

## 1. Vier Dinge – eine Sprache

| Ding | Was es ist | Zeit | Wo man es sieht |
|---|---|---|---|
| **Termin** | etwas mit fester Zeit (von–bis). Kommt aus Apple/Google oder wird in Kompass angelegt | immer | Kalender, Home („Als Nächstes“) |
| **Aufgabe** (To-do) | einmal erledigen (auch wiederkehrend). Ohne Tag = **Eingang** | optional Tag, optional Uhrzeit + Dauer | Kalender (Tag/Eingang), Home |
| **Habit** | regelmäßig tun, mit Menge | Rhythmus; optional feste Uhrzeit + Dauer | Fortschritt › Habits, Kalender, Home |
| **Ziel** | wohin du willst; sammelt die anderen drei über Meilensteine | Datum | Fortschritt › Ziele |

- Jedes der ersten drei kann **einem Ziel** zugeordnet werden. Zählen in die Prozente nur über Meilensteine (Rechnung Fassung 2 bleibt).
- Ein **Termin** kann zusätzlich einen **Habit** erfüllen („Gym 18–19 Uhr“ → Habit Sport ist an diesem Tag erledigt, sobald der Termin vorbei ist).
- **Kategorien** (Arbeit, Schule, Studium, Freizeit, Gesundheit, Familie) geben Farbe, wenn kein Ziel dran hängt. Einstellung „Farben nach“: **Ziel** (Standard) oder **Kategorie**.

## 2. Tabs

Home · Kalender · **Lotse** (Mitte) · Fortschritt (Ziele · Habits) · Rückblick. „Heute“ heißt jetzt **Home**.

## 3. Home – das Werkzeug für jetzt

Oben nach unten, je Block eine Aussage:
1. **Jetzt-Karte** (Verlauf): was gerade läuft oder als Nächstes kommt – Termin, Aufgabe oder Habit. Große Zeile „in 25 Min · Englisch 3“. Knöpfe: *Fokus starten* (Aufgabe/Habit), *Erledigt*, *Menge* (Habit mit Menge). Darunter dünn: „3 von 7 geschafft“.
2. **Hinweis-Zeile(n)** nur wenn nötig (Gapless „To check“): *Enger Tag* (≥ 75 % der wachen Zeit verplant oder < 90 Min frei), *Überschneidung* (zwei Einträge gleichzeitig), *Kein Platz* (Habit/Aufgabe braucht 30 Min, frei sind 20) – heute und die nächsten 7 Tage. Tipp → Tag im Kalender.
3. **Als Nächstes**: die nächsten 3 Einträge mit Zeit (gleiche Zeile wie im Kalender).
4. **Heute offen**: Aufgaben und Habits ohne Uhrzeit – abhaken, Menge, ziehen in den Kalender.
5. **Ziele kompakt** (eine Zeile je Ziel, höchstens 3) und Tagesabschluss.

## 4. Kalender

1. **Als Nächstes** oben: drei Karten nebeneinander (Zeit groß, Titel, Farbe des Ziels/der Kategorie).
2. **Umschalter** Tag · Woche · Monat · Jahr (Kapsel wie Ziele · Habits).
   - **Tag:** Wochenleiste + Zeitleiste 6–23 Uhr, Blöcke in Farbe, rote Jetzt-Linie. Leere Stelle antippen → neuer Termin um diese Zeit. **Ziehen**: Aufgaben/Habits von unten in die Zeitleiste ziehen → bekommen diese Uhrzeit an diesem Tag.
   - **Woche:** 7 Spalten mit Blöcken (Titel kurz), Tipp auf Tag → Tag. Ablegen auf einer Spalte → an diesem Tag ohne Uhrzeit.
   - **Monat:** Raster, je Tag bis 3 farbige Einträge + „+2“; gewählter Tag zeigt darunter seine Liste. Ablegen auf einem Tag → an diesem Tag.
   - **Jahr:** 12 kleine Monate, Tage nach Auslastung eingefärbt; Tipp → Monat.
3. **Unter dem Kalender:** „Ohne Uhrzeit“ (Aufgaben + Habits des gewählten Tags) und **Eingang** (Aufgaben ohne Tag). Alles ziehbar.
4. **+ Termin** (oben rechts und Tipp in der Zeitleiste): Titel, Tag, von–bis (Chips 30 Min/1 h/2 h), Kategorie, **Zählt für** (Ziel → Meilenstein Zeit/Zahl, oder Habit), Wiederholung (nie/täglich/wöchentlich). Ein Bildschirm, Chips statt Räder.

## 5. Rückblick

Eine Aussage oben („Diese Woche: 62 % deiner Pläne geschafft“), dann weiße Karten (Gapless: nicht alles Verlauf): Geplant vs. geschafft (Termine, Aufgaben, Habits), Fokuszeit (Kurve), Zeit je Ziel (Ring), Habits (Quote, Säulen), Auslastung der Woche (Balken je Tag: verplant/frei). Wochenreflexion.

## 6. Rechenregeln (neu, `rechenregeln.md` §9 Tagesplan)

- **Blöcke eines Tages:** Termine mit Zeit + Aufgaben mit Uhrzeit (Dauer) + Habits mit Uhrzeit (Dauer; nur an geplanten Tagen) – erledigte zählen nicht als belegt.
- **Wache Zeit:** 7–22 Uhr (900 Min). **Verplant** = Vereinigung der Blöcke in der wachen Zeit. **Frei** = 900 − verplant.
- **Enger Tag:** verplant ≥ 75 % oder frei < 90 Min.
- **Überschneidung:** zwei Blöcke überlappen ≥ 5 Min.
- **Kein Platz:** Summe der Dauern offener Aufgaben/Habits **ohne** Uhrzeit an dem Tag > längste freie Lücke ab jetzt (heute) bzw. ab 7 Uhr.
- **Als Nächstes:** laufende und kommende Blöcke ab jetzt, nach Start sortiert, bis 7 Tage voraus.
- Alles deterministisch in `Kompass/Rechnung/Tagesplan.swift`, Tests in `TagesplanTests`. Der Lotse liest es, rechnet nie.

## 7. Apple- und Google-Kalender

- **Apple** über EventKit (Systemberechtigung, nur lesen + Termine aus Kompass auf Wunsch schreiben). Einschalten in Einstellungen; Beispieltermine bleiben für Demo. [RISIKO] Datenschutz: Termine bleiben auf dem Gerät, gehen nicht an den Lotse-Server außer Titel/Zeit im Kurzstand – Einwilligung wie Lotse (`l-einwilligung`).
- **Google** braucht ein Google-Cloud-Projekt mit OAuth-Prüfung → [OFFEN] Gründer legt Projekt an; bis dahin Beispieltermine. Wer Google-Kalender in Apple-Kalender eingebunden hat, sieht sie schon über EventKit.

## 8. Geführt und einfach

- Jede Seite: eine Verlaufskarte (Aussage), Rest weiße Karten und Zeilen. Höchstens ein Erklärsatz, Rest hinter (i).
- Leere Zustände sagen, was als Nächstes zu tun ist („Zieh eine Aufgabe in den Tag“).
- Der Lotse kann alles, was die Seiten können: Termin anlegen, Aufgabe/Habit einplanen, „Ist heute noch Platz für Sport?“, „Was steht als Nächstes an?“.

## 9. Gapless – was übernommen wird (nur Gestaltung, kein Code)

- Eine Verlaufskarte je Seite, Zahl/Aussage groß und mittig oder links; weiße Karten mit Titel + Pfeil darunter.
- Glas-Kreis mit Symbol auf Verlaufskarten; breiter weißer Kapsel-Knopf mit Pfeil.
- Helle Hinweis-Karte mit Symbol-Kreis links und Link-Zeile.
- Segment-Umschalter als Kapsel; Zeilen 52–64 pt; Text ≤ 35 Wörter je Bildschirm.

## 10. Geführt v4 (23.11.2026, Nachtrag nach Test des Gründers auf dem iPhone)

- **Assistent** statt „Lotse“ (Name mit KI-Bezug), eigenes Zeichen (Verlauf Indigo → Violett, Glasring, Funken) in Tab, Kopf und Blasen. Jeder Start der App beginnt einen neuen Chat (beim Verlassen wandert der laufende in den Verlauf, höchstens 30); frühere Chats oben links.
- **Anlegen geführt** wie der Personal check in Gapless: Was (vier Verlaufs-Kacheln) → Titel (mit Vorschlag aus dem Titel) → Wann → Details → „Passt das so?“ → Anlegen. Fortschrittsbalken oben, ein großer Knopf unten, Chips statt Räder. Gilt für Aufgabe, Termin, Habit, Ziel.
- **Home als Reel**: Karte „Dein Tag im Blick“ (wie „Your November ahead“) öffnet Slides: Jetzt · Danach · wie voll der Tag ist · Heute offen · Ziele · Los. Home selbst schlanker: Jetzt-Karte, Reel, Hinweise, Heute offen, Liegen geblieben, Tagesabschluss.
- **Kalender**: Zielzonen leuchten beim Darüberziehen, kurze Vibration beim Ablegen; Aufgaben und Habits lassen sich aus der Zeitleiste zurück nach „Ohne Uhrzeit“ und in den Eingang ziehen (Habit mit fester Uhrzeit: an diesem Tag ohne Uhrzeit, `planZeiten = −1`).
- **Fortschritt**: eine Seite für Ziele · Habits (Umschalter wechselt beim ersten Tipp); Habits: Heute nur Offenes, Erledigtes eingeklappt „n erledigt ⌄“, „Alle Habits“ mit Wochenpunkten; der Abschnitt „Diese Woche“ ist darin aufgegangen.

## 11. Ziele minimal (23.11.2026, Auftrag des Gründers: „minimalistischer und geführter, nur das Nötigste, verfeinern wenn man will“)

- **Liste:** weiße Karten nach Frist (keine Jahresgruppen): Ring mit Prozent, Lage-Chip, restliche Zeit, „Als Nächstes: …“.
- **Ziel-Seite:** Kopfkarte (antippen = so wird gerechnet) · Warum · **Dein nächster Schritt** (ein Satz, was zu tun ist, wie viele Punkte es bringt, ein passender Knopf) · Meilensteine.
- **Verfeinern (optional):** Aufgaben, Habits, Termine, Einsatz, Details – je eine eigene Seite, oben ein Satz, was dort passiert und warum. Bearbeiten, erreicht und löschen stehen in Details.
- Rechnung: `Fortschritt.naechsterSchritt` (rechenregeln.md §1); Assistent nennt denselben Schritt.
