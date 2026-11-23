# Lotse – der Assistent in Kompass

Stand: 23. November 2026 · Arbeitstitel „Lotse“ (Tab 4). Gebaut: Grundversorgung ohne Sprachmodell. [OFFEN] Anbieter des Sprachmodells (Abschnitt 5).

## 1. Was der Lotse ist

Ein Chat, über den man **alles** in der App erfährt und erledigt: Fragen zum Tag, zur Woche, zur freien Zeit, zu Zielen, Habits und zur Analyse; Aufgaben anlegen; Fragen zur App selbst (Onboarding, „Wo finde ich …“, „Wie wird gerechnet?“). Er wächst mit der App und lernt aus den Nutzern.

Drei Grundsätze:
1. **Er rechnet nie.** Jede Zahl kommt aus `Kompass/Rechnung/` über ein Werkzeug. Ein Sprachmodell wählt höchstens das Werkzeug und formuliert.
2. **Er ändert nur über Werkzeuge.** Was er anlegt oder umstellt, geht durch dieselben Funktionen wie ein Fingertipp in der App (`Zustand`-Aktionen).
3. **Er funktioniert ohne Netz.** Ohne Sprachmodell antwortet das regelbasierte Verstehen; mit Modell wird er flüssiger, nicht anders.

## 2. Aufbau (`Kompass/Lotse/`)

| Baustein | Aufgabe |
|---|---|
| `AppWissen` | Beschreibung der App **aus dem Code**: Tabs (`Bereich`), Fenster (`Navigation.Blatt`), Rechenregeln (`SchrittArt.erklaerung` + Sätze aus `rechenregeln.md`), erste Schritte, Werkzeuge. Wird dem Sprachmodell als Systemwissen mitgegeben. |
| `Werkzeuge` | Zehn Werkzeuge mit Beschreibung, Parametern und Beispielfragen: heute, woche, freieZeit, aufgabeAnlegen, ziele, ziel, fortschrittErklaeren, habits, analyse, hilfe. Beispielfragen sind zugleich die Vorschläge im leeren Chat. |
| `Verstehen` | Regeln (Deutsch): Frage → Werkzeug + Parameter (Datum: heute/morgen/Wochentag/TT.MM., wichtig, Ziel per Wortabgleich). Offline, deterministisch, getestet. |
| `Sprachmodell` | Schnittstelle: bekommt Wissen, Werkzeuge, Verlauf, Frage; antwortet mit Werkzeugaufruf oder Text. `Sprachmodelle.aktiv` ist die Steckdose – heute leer. |
| `Lotse` | Steuerung: Frage → (Modell oder Regeln) → Werkzeug → Antwort in den Chat → Lernen. Fällt bei Modellfehler auf Regeln zurück. |
| `LotseAnsicht` | Chat: Begrüßung mit Vorschlägen, Blasen, Sprung in die App („Ziel öffnen ›“), Daumen hoch/runter, Verlauf löschen, Hinweis womit geantwortet wird. |

Gespeichert wird der Chat (letzte 200) in `Zustand.chat`, das Lernen in `Lernen.lotse`.

## 3. Laufend erweitern – so bleibt der Lotse auf Stand

Der Lotse soll die App „hundertprozentig verstehen“, auch wenn sie sich ändert. Dafür drei Mechanismen, die nicht auf Disziplin bauen:

1. **Wissen aus dem Code, nicht aus Prosa.** Tabs, Fenster, Meilenstein-Arten und Erklärtexte sind dieselben Typen, die die App zeigt. Ein neuer Tab ohne Beschreibung kompiliert, aber …
2. **… ein Test erzwingt Vollständigkeit** (`AppWissenTests`): jeder `Bereich`, jedes `Blatt`, jede `SchrittArt`, jedes Werkzeug mit Beschreibung und Beispielen; jedes Beispiel trifft sein Werkzeug. Wer etwas baut, ohne den Lotsen mitzuziehen, bekommt einen roten Test.
3. **Projektregel** (CLAUDE.md): neuer Screen, neues Fenster, neue Rechenregel oder neue Fähigkeit → App-Wissen und Werkzeuge ergänzen, Beispielfragen in die Tests.

Neue Fähigkeit = ein Werkzeug: Eintrag in `Werkzeuge.alle`, Fall in `ausfuehren`, Regel in `Verstehen`, Test. Das Sprachmodell bekommt die neue Fähigkeit automatisch, weil `AppWissen.text()` die Werkzeuge auflistet.

## 4. Lernen durch Nutzer

Grundsatz wie bei den Rechenregeln: **Lernen ändert nie, was der Lotse ausrechnet** – nur was er versteht und vorschlägt.

| Signal | Gespeichert | Wirkung |
|---|---|---|
| Frage ohne Werkzeug | `lotse.unbeantwortet` (50) | zeigt, welche Werkzeuge oder Regeln fehlen → nächste Erweiterung |
| Daumen runter | `lotse.schlecht` (Frage, 50) | Fehlzuordnungen finden, Regeln schärfen |
| Daumen hoch | `lotse.gut` | Qualitätsmaß |
| Werkzeugnutzung | `lotse.genutzt` | Reihenfolge der Vorschläge, Priorität beim Ausbau |

Heute nur auf dem Gerät. [VORSCHLAG] Später anonym aggregiert (nur Zähler und Fragetexte ohne Daten des Nutzers, Einwilligung), wie in `lernen-ueber-alle-nutzer.md`: häufige unbeantwortete Fragen werden zu neuen Werkzeugen; Beispielfragen ordnen sich nach Nutzung. Mit Sprachmodell zusätzlich: Daumen-runter-Fälle werden Beispiele im Systemwissen („so nicht“).

## 5. Sprachmodell – Entscheidung des Gründers [OFFEN]

| Weg | Für | Gegen |
|---|---|---|
| **A · Claude-API über eigenen Server** | sehr gutes Verstehen und Formulieren; Werkzeugwahl zuverlässig; Server kann anonymes Lernen bündeln | Kosten je Anfrage; Server nötig (Schlüssel nie in der App); Datenschutz-Prüffragen (Fragen enthalten Zieltitel); Netz nötig |
| **B · Apple-Modell auf dem Gerät** (Foundation Models) | keine Kosten, offline, privat; keine neue Abhängigkeit (Systemrahmen) | nur Geräte mit Apple Intelligence (iPhone 15 Pro aufwärts, nicht das iPhone 15 des Gründers); schwächer bei komplexen Fragen |
| **C · B, Rückfall A** | privat wo möglich, stark wo nötig | am meisten Aufwand |
| **D · Nur Regeln** (heute) | kostenlos, offline, deterministisch | versteht nur, was programmiert ist; kein Gespräch |

[VORSCHLAG] **A zuerst** (ein kleiner Server, Claude Haiku für Werkzeugwahl, Sonnet für Gespräche), weil die Werkzeugwahl das Kernproblem ist und der Server das anonyme Lernen trägt; B später für Geräte, die es können. Rechtlich als Prüffrage: Auftragsverarbeitung, welche Daten die Frage enthält, Opt-in.

## 6. Noch nicht gebaut

- Sprachmodell-Anbindung (nach Entscheidung) · Aufgabe `l-anbieter`, `l-sprachmodell`
- Weitere Werkzeuge [VORSCHLAG]: Ziel anlegen mit Meilenstein-Vorschlägen, Habit anlegen, Aufgabe verschieben/erledigen, Termin zuordnen, Fokus starten, Reflexion führen
- Mehrschrittige Gespräche (Rückfragen: „Für welches Ziel?“ merkt sich die Frage) – mit Sprachmodell einfacher
- Sprache: Diktat über die Tastatur geht schon; eigener Mikrofon-Knopf [OFFEN]
- Anonymes Lernen über alle Nutzer (Abschnitt 4)
