---
name: roterfaden
description: Öffnet den Roten Faden von Kompass (das zentrale Word-Dokument des Gründers), prüft, ob er zum aktuellen Klick-Dummy bzw. Code passt, und bringt ihn auf Stand, wenn nicht. Nutzen bei "/roterfaden", "roter Faden", "ist das Dokument aktuell", "wo ist die Word".
---

# /roterfaden

Der Rote Faden erklärt Kompass Seite für Seite (eine App-Seite = eine Dokument-Seite) und enthält die Rechenregeln, den Fahrplan („Was gerade ansteht“) und die Landkarte.
Quelle: `docs/produkt/roter-faden/roter_faden.py` (Text), `bilder/` (Bildschirmfotos aus dem Klick-Dummy). Pflege-Regeln: `docs/produkt/roter-faden/README.md`.

## Ablauf

1. **Wo er liegt sagen:** `docs/produkt/roter-faden/kompass-roter-faden.docx` und nach jedem Bauen auf dem Mac eine Kopie in iCloud Drive › Kompass › „Kompass – Der rote Faden.docx“. Fassung und Stand stehen oben in `roter_faden.py` (`VERSION`, `STAND`).
2. **Prüfen, ob er aktuell ist:**
   - `python3 docs/produkt/roter-faden/pruefen.py` – Links, Bilder und ob jede Ansicht und jedes Fenster aus dem Klick-Dummy (später: jede Seite aus dem Swift-Code) im Dokument steht.
   - Was sich seit der letzten Änderung am Dokument geändert hat: `git log --oneline $(git log -1 --format=%H -- docs/produkt/roter-faden/roter_faden.py)..HEAD -- prototyp Kompass docs/produkt/rechenregeln.md`.
3. **Ergebnis kurz melden:** „aktuell“ oder die Liste, was fehlt.
4. **Wenn nicht aktuell:** Bilder neu (`python3 scripts/bilder.py`), Text in `roter_faden.py` anpassen, neue Fassung im Änderungsverlauf, bauen mit `python3 docs/produkt/roter-faden/roter_faden.py`, prüfen. Dann wie jeder Block: Branch, PR, Merge.

Regeln: kürzen statt anhängen; nur Demo-Daten in Bildern; nichts erfinden (Fakten aus dem Code); Rechtliches nur als Prüffrage.
