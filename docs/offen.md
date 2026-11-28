# Offene Liste – Compass

Stand: 27. November 2026. [ENTSCHEIDUNG – 27.11.2026, Gründer]: Zuerst wird das ganze Design gebaut, Funktionen kommen danach. Was beim Design-Bau offen bleibt, kommt hierher. Erledigtes wird gestrichen, nicht abgehakt.

## 1. Design – noch nicht gebaut

- **Tab „Compass“:** Die Seite ist leer („Wird neu gebaut.“).
- **Neuer Habit (Blatt):** Der Hinweis zur Bildschirmzeit („Geräteübergreifend teilen“) stammt noch aus Opals Regel-Blatt.
- **Gehört zu:** Die Karte „Neues Ziel“ ist nur ein Platzhalter („Kommt bald“).
- **Bild wählen:** Es gibt kein Zuschneiden, also kein Verschieben oder Zoomen. Das Bild wird einfach mittig rund abgeschnitten.
- **Mein Weg:** Hinter „Aufgaben ›“, „Ziele ›“, den Aufgaben und den Ziel-Karten liegt noch keine eigene Seite.
- **Home:** Hinter Bildschirmzeit, Erkenntnis, „Immer erlaubt? – Einrichten“, dem PRO-Schild und dem Profil-Schild liegt noch keine eigene Seite.
- **Home:** Die schwebende Leiste („Lernzeit“, „Entsperren“) öffnet nichts.
- **Weitere Bereiche aus `docs/plan.md`:** Onboarding, Entsperren, Meilensteine, Profil/Einstellungen, Paywall.
- **Zustände:** Für jede Ansicht fehlen noch der Lade-, Leer-, Fehler- und Offline-Zustand (Projektregel).
- **Barrierefreiheit:** Dynamic Type, VoiceOver und Reduce Motion sind noch nicht für jede Seite geprüft.

## 2. Funktionen – kommen nach dem Design

**Habits**
- Neuer Habit speichert nichts: Name, Bild, Tage und Werte gehen beim Schließen verloren.
- Das eigene Bild erscheint noch nicht in der Habit-Reihe. Es wird nicht auf dem Gerät gespeichert und ist nicht verkleinert (Speicher).
- „Gedrückt halten zum Festlegen“ schließt nur das Blatt.
- Erledigt und Teilwerte gelten nur, solange die App offen ist (Ring auf „Mein Weg“ zeigt den Stand).
- Fokus gilt nur, solange die App offen ist; wird die App beendet (auch in der Pause), ist der Timer weg und nichts wird gutgeschrieben.
- Live-Aktivität (Erweiterung „CompassLive“): Pause/Weiter/Zurücksetzen auf Sperrbildschirm und in der Dynamic Island gebaut, aber noch nicht am Gerät geprüft (im Simulator blockiert die offene iOS-Abfrage „Live-Aktivitäten erlauben?“ die Knöpfe).
- Andere Apps während Fokus sperren: Family Controls (Block 2).
- Bearbeiten und Löschen ändern die Habits nur, solange die App offen ist. Ein neuer Habit über das Plus wird noch nicht angelegt.
- Die fünf Demo-Habits haben feste Einheiten und Tagesziele (Lesen 20 Seiten, Sport 45m, Meditieren 10m, Lernen 30m, Wasser 2.000 ml).
- „Gehört zu“ wird nicht gespeichert, und auf „Mein Weg“ sieht man noch nicht, welche Habits zu einem Ziel gehören.
- Einheit und Ziel lassen sich wählen, werden aber nicht gespeichert. Eine eigene Einheit gilt nur, solange das Blatt offen ist.
- Mit einer Zeit-Einheit soll später ein Timer mitlaufen (Hinweis im Blatt „Einheit“).
- „Mehr dazu“ führt nirgends hin.
- Habits abhaken, Erfolgsquote berechnen und die Werte auf der Habits-Seite (Habits heute, Weitere Habits, Erfolgsquote) sind feste Demo-Werte.

**Aufgaben und Ziele**
- Aufgaben-Blatt (Schritte abhaken, Compass-Balken, Fokus) gebaut – gilt nur, solange die App offen ist.
- Aufgabe bearbeiten und anlegen (Plus „Neu“ in der Aufgaben-Reihe) fehlen noch; „Bearbeiten“ zeigt nur einen Hinweis.
- Erledigte Aufgaben am nächsten Tag ausblenden, Liste „Erledigt“ über „Aufgaben ›“, Erinnerung bei „Fällig am“.
- Ziele anlegen und löschen, Ziele mit eigenem Bild.

**Home**
- Alle Zahlen (Werte-Reihe, Bildschirmzeit „2h 4m“, Balken, Serie „1“) sind feste Demo-Werte.
- Serie und Meilensteine werden noch nicht gerechnet.

**Bildschirmzeit (Kern)**
- Erlaubnis (Family Controls), App-Auswahl, Messen, Sperren, Sperrbildschirm, Entsperren.

## 3. Rechenregeln (Freigabe „Ja, mergen“ nötig)

- [OFFEN] Wert, Bildschirmzeit, Serie, Erfolgsquote und Meilensteine: Die Regeln werden fest gerechnet, mit Tests, und der Gründer gibt sie frei.

## 4. Platzhalter (brauchen Konto oder Server)

- Anmeldung, Einladungen und Belohnungen, Pro-Kauf (App Store Connect), Family-Controls-Berechtigung für den Store, Geräusche und Geschichten, Community.
- Im Code stehen sie als `// PLATZHALTER: …`, in der App als „Kommt bald“.

## 5. Prüffragen

- [RISIKO] Vor dem Store: Ist Compass eigenständig genug gegenüber dem Vorbild? Das ist eine Prüffrage für einen Anwalt.
- PR #66 (Neustart Compass) wartet auf „Ja, mergen“.
