# Personen-Test über zwei Jahre – 23.11.2026

**Was:** vier erfundene Personen, je zwei Jahre (1.12.2026–30.11.2028), Tag für Tag im Klick-Dummy durchgespielt. Jede angezeigte Zahl gegen eine unabhängig geschriebene zweite Rechnung (`prototyp/tests/sim.js`). Enthält KW 53, 29. Februar und Zeitumstellungen.

| Person | Vermögen/Ziele | Tagesablauf |
|---|---|---|
| Lena | Studentin, 12.000 € Schulden, Bachelor | unregelmäßig, vergisst den Timer |
| Markus | Angestellter, ETF-Depot, Halbmarathon | 9–17 Uhr, liest 730 Tage am Stück |
| Aylin | Selbstständig, Krypto + Firma (schwankt stark), App-Launch | arbeitet nachts über Mitternacht |
| Jonas | Schichtarbeit, Eigenkapital in Sprüngen, LAPL, Führerschein | wechselnde Lerntage, erreicht Ziele, legt neue an |

Dazu je Person 81 zufällige Eingriffe in Schritte (anlegen, löschen, Art/Gewicht ändern auch auf ungültige Werte, abhaken, Aufgaben löschen/umhängen, Zielwert 0/negativ, Vorschläge übernehmen, Zahl ↔ Schritte).

## Gefunden und behoben (13)
1. Habit-Serie endete bei 400 Tagen · 2. Beste Serie nur 120 Tage zurück · 3. Quote zählte den laufenden Tag als verpasst · 4. Wochen-Quote zählte Tage vor der Anlage · 5. Vergessener Timer zählte unbegrenzt (jetzt max. 4 h) · 6. Fokus über Mitternacht am falschen Tag · 7. Fälligkeitstag als „überfällig“ · 8. „in -1 Jahren“ und Ziel außerhalb der Zeitachse · 9. Offene Aufgaben von gestern verschwanden (jetzt „Liegen geblieben“) · 10. „Wiederholen“ tat nichts · 11. Termin-Zuordnung nur für einen Termin (jetzt Serie) · 12. Start = Ziel ergab 0 % · 13. Einzelnen Termin einer Serie löschen beendete die Serie.
Außerdem: monatlich ab 31. rutschte ab; Speichern gebündelt.

## Ergebnis
Alle Prüfungen grün: ~46.000 Schritt-Vergleiche, 324 Eingriffe, 18 Randfälle (`prototyp/tests/unit.py`). Darstellung je Ansicht < 60 ms nach zwei Jahren Daten.

## Offen
- [RISIKO] Geänderte Habit-Tage rechnen die Historie mit dem neuen Plan.
- Swift-App: denselben Test als Unit-Test nachbauen (Phase 2).
