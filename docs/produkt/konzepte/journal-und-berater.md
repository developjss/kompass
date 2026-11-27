# Journal und Berater – Kompass rechnet und berät, Apple und Google planen [ENTSCHEIDUNG – 27.11.2026: Richtung; Einzelheiten VORSCHLAG]

Idee des Gründers (27.11.2026): Den Kalender-Tab streichen. An seine Stelle kommt ein Journal (täglich, wöchentlich). Kompass wird ein Analyse-Werkzeug und Berater: Es liest die Kalender, legt aber selbst keine Termine an. Aus Journal, Habits und Zielen entsteht ein Bild der Person.

## 1. Positionierung in einem Satz

**Kompass sagt dir, wie es läuft und was als Nächstes passt – planen tust du in deinem Kalender.** Mit Apple, Google und Fantastical konkurrieren wir nicht als Kalender. Wir lesen sie. [HYPOTHESE]

Den Unterschied zu reinen Journal-Apps (Rosebud, Reflectly, Stoic, Day One) macht die Verbindung. Das Journal steht nicht allein: Wir rechnen Stimmung gegen Habits, Ziele und Auslastung, fest und nachvollziehbar. [HYPOTHESE, im Personen-Test prüfen]

## 2. Befund heute

| Baustein | Stand im Code | Was passiert |
|---|---|---|
| Kalender-Tab | Tag · Woche · Monat · Jahr, Ziehen, Empfehlungs-Stapel (§9.1), eigene Termine (`EigenerTermin`) | entfällt |
| Apple-Kalender lesen | EventKit nach Zustimmung (`einstellungen.appleKalender`) | bleibt, wird Pflicht-Schritt im Onboarding |
| Freie Zeit | `Zeitfenster`, `Tagesplan` (§9) | bleibt, Grundlage des Beraters |
| Reflexion | Tagesabschluss und Wochenreflexion, je 3 Fragen, nur Text (`reflexionen`) | zieht ins Journal, bekommt Stimmung als Zahl |
| Assistent | Werkzeuge lesen Kalender, Claude formuliert | wird der Berater |

## 3. Tabs

Home · **Journal** · Assistent · Habits · Ziele. Home zeigt weiter „Als Nächstes“, jetzt aus dem Apple-Kalender (nur lesen).

## 4. Journal

- **Täglich, ≤ 30 Sekunden:** Stimmung 1–5 (fünf Symbole), ein Satz „Was war heute?“. Frei weiterschreiben geht, ist aber keine Pflicht. Optional abends eine Erinnerung.
- **Wöchentlich:** die bisherigen drei Fragen der Wochenreflexion, dazu Stimmung der Woche 1–5.
- **Oben im Tab:** eine Aussage, z. B. „Gute Woche – Stimmung 3,9“. Darunter die Einträge als Zeitleiste und, sobald genug Daten da sind, die **Muster** (§5).
- **Zustände:** Leer („Dein erster Eintrag dauert 30 Sekunden“), Laden, Fehler, Offline (Journal geht immer offline).

## 5. Muster – neue Rechenregel [VORSCHLAG, Freigabe nötig]

Fest gerechnet, nie von der KI:

| Muster | Bedingung | Text (Beispiel) |
|---|---|---|
| Habit und Stimmung | ≥ 14 Tage mit Stimmung, je Gruppe (Habit erledigt / nicht) ≥ 5 Tage, Unterschied der Mittelwerte ≥ 0,5 | „An Tagen mit Sport: Stimmung 4,1 statt 3,2“ |
| Auslastung und Stimmung | wie oben, Gruppen: Auslastung ≥ 75 % / < 75 % (§9) | „Volle Tage: Stimmung 2,8“ |
| Ziel und Woche | ≥ 4 Wochen, Wochen mit / ohne Fortschritt am Ziel | „Wochen mit Fortschritt bei Fit: Stimmung 3,9“ |

- Immer „Zusammenhang, keine Ursache“ hinter (i).
- Jedes Muster kann man **bestätigen** oder mit „Passt nicht“ verwerfen (8 Wochen ausgeblendet, wie §12).
- **KI nur als Text:** Sie fasst die Woche in einem kurzen Brief zusammen und schlägt Themen aus dem Freitext vor („Schlaf kommt oft vor“). Sie bewertet nichts und stellt keine Diagnose.
- [VORSCHLAG] Statt „Bild über den Menschen“ sagen wir „**Deine Muster**“: Sie sind prüfbar, man kann sie selbst bestätigen, und sie wirken weniger unheimlich.

## 6. Berater

| Frage | Rechnung (fest) | Handlung |
|---|---|---|
| „Wann habe ich nächste Woche Zeit?“ | `Zeitfenster` je Tag aus allen gelesenen Kalendern | Tag antippen → Apple-Kalender an diesem Tag öffnen |
| „Wann mache ich heute Sport?“ | freies Fenster ≥ Dauer des Habits, bevorzugt zur Erinnerungszeit | „Eintragen“ → Apple-Fenster, vorbefüllt |
| „Wann habe ich in den nächsten Monaten viel Zeit?“ | Tage/Wochen mit Auslastung ≤ 25 % | Liste der Wochen |
| „Wann erledige ich meine Aufgaben?“ | Empfehlung §9.1, ohne Ziehen | „Eintragen“ als Zeitblock |

- **Eintragen** öffnet Apples eigenes Termin-Fenster (EventKitUI) mit Titel, Tag und Uhrzeit. Gespeichert wird im Kalender, den die Person wählt, auch in Google, wenn das Konto im iPhone ist. Kompass speichert keinen Termin.
- **Öffnen:** Apple-Kalender am gewünschten Tag (`calshow:`-Link, nicht offiziell dokumentiert → [RISIKO], Ersatz: Kalender ohne Tag öffnen). Google-Kalender-App nur, wenn installiert; sonst nur Apple.
- Die KI formuliert die Antwort, die Zahlen kommen aus den Werkzeugen.

## 7. Kalender-Anbindung

- **Onboarding:** ein Schritt „Kalender verbinden“ → Zugriff auf Apple-Kalender. Damit sieht Kompass alles, was im iPhone eingerichtet ist (iCloud, Google, Outlook, Exchange). Hilfe-Link: „Google-Kalender fehlt? So fügst du ihn im iPhone hinzu.“
- **Kein eigenes Google-Login zu Beginn.** Es bräuchte Google-Anmeldung, Server-Tokens, Googles App-Prüfung für Kalender-Zugriff und eine eigene Datenschutz-Prüfung. Erst wenn der Personen-Test zeigt, dass vielen Google auf dem iPhone fehlt. Spätestens für Android/Windows kommt es ohnehin. [SCHÄTZUNG: Aufwand mehrere Blöcke]

## 8. Aufgaben bleiben in Kompass

Aufgaben hängen an Zielen und Meilensteinen – das rechnet nur Kompass. Ein Abgleich mit Apple Erinnerungen in beide Richtungen bringt Doppel und Konflikte. Später möglich: Erinnerungen **einmalig importieren** (nur lesen). [VORSCHLAG]

## 9. Was wegfällt

Kalender-Tab mit Tag/Woche/Monat/Jahr, Ziehen in die Zeitleiste, Empfehlungs-Stapel, eigene Termine samt Editor, Farben nach Ziel/Kategorie. Termin-Verknüpfungen (Termin erfüllt Habit, zählt für Ziel) bleiben für gelesene Termine. Vorhandene eigene Termine sind nur Demo-Daten, sie entfallen ohne Übernahme.

## 10. Prüffragen Recht und Datenschutz [OFFEN]

- Sind Journaltexte und Stimmungswerte Gesundheitsdaten (Art. 9 DSGVO)? Was folgt für Einwilligung, Speicherort, Löschung?
- Ab wann sind Muster oder Ratschläge eine Medizinprodukt-Software? Grenze: keine Diagnose, keine Therapie-Hinweise, bei Krisen-Wörtern nur Verweis auf Hilfe.
- Darf Freitext zum Sprachmodell (Claude, Supabase EU)? [VORSCHLAG] Standard: Journal bleibt auf dem Gerät. An den Server geht es nur nach eigener Einwilligung. Alternative: Apples Sprachmodell direkt auf dem iPhone (Foundation Models) → neues Apple-Framework, Rückfrage.

## 11. Reihenfolge [VORSCHLAG]

1. **Journal-Tab ersetzt Kalender:** Stimmung + Satz täglich, Wochenreflexion zieht um, Home liest weiter Apple. Assistent mitziehen (`AppWissen`, Werkzeug `journal`, `LotseTests`).
2. **Berater:** Werkzeuge „freie Zeit“ (Tage, Wochen, Monate) und „Wann mache ich X“, Apple-Fenster zum Eintragen, Onboarding-Schritt Kalender.
3. **Muster:** neue Rechenregel §15 mit Tests und Freigabe.
4. **Design und Statistiken neu:** Home, Rückblick-Karten und Journal aus einem Guss.

Vor Schritt 1 der **Personen-Test**: 4 Personen × 3 Wochen. Trägt man täglich ein? Ab wann entsteht das erste Muster?

## 12. Schwächen und Alternativen

- [RISIKO] **Kaltstart:** Muster brauchen ≥ 14 Tage. In den ersten zwei Wochen tragen Berater und Habits die App.
- [RISIKO] **Journale werden aufgegeben.** Gegenmittel: 30 Sekunden, Erinnerung, Serie zählt wie ein Habit (eintragen = erledigt).
- [RISIKO] **Ohne Kalender-Zugriff ist der Berater blind.** Dann rechnet er nur mit Aufgaben und Habits und sagt das offen.
- **Alternative A:** Kalender-Tab als reine Leseansicht behalten. Verworfen – doppelt zu Apple und verwässert die Positionierung.
- **Alternative B:** Journal nur als Teil des Rückblicks, ohne eigenen Tab. Weniger Aufwand, aber dann ist es kein täglicher Anlaufpunkt.

## 13. Entscheidungen des Gründers

1. ~~Kalender-Tab streichen und Journal an seine Stelle~~ – [ENTSCHEIDUNG – 27.11.2026]
2. Aufgaben bleiben in Kompass (§8) – ja?
3. Google zuerst nur über das iPhone (§7) – ja?
4. Journal standardmäßig nur auf dem Gerät, Server nur mit Einwilligung (§10) – ja?
