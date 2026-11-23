# Konzept: Kalender-Anbindung

Stand: 23. November 2026 · noch nicht gebaut (Klick-Dummy zeigt Beispieltermine).

- **Grundsatz** [ENTSCHEIDUNG – 23.11.2026]: Kompass ergänzt Google- und Apple-Kalender, ersetzt sie nicht. Termine bleiben dort; Kompass liest und speichert nur die Zuordnung (Termin-Serie → Ziel oder Habit).
- **Apple:** iPhone/iPad/Mac über EventKit (Systemberechtigung). Windows/Android nur über iCloud-CalDAV mit app-spezifischem Passwort [RISIKO: umständlich].
- **Google:** Anmeldung mit Google (OAuth) + Google Calendar API, auf allen Plattformen gleich. [RISIKO] Kalender-Zugriff gilt als sensibel – Google prüft die App vor der Veröffentlichung.
- **Outlook:** später über Microsoft Graph.
- **Zuordnung:** gilt für die ganze Serie ab dem Tag der Zuordnung; nur stattgefundene Termine zählen. Habit-Zuordnung hakt den Habit an Termintagen ab.
- **Schreiben** in den fremden Kalender nur auf Wunsch (z. B. Fokusblock) [OFFEN].
- **Nächster Schritt** [OFFEN]: Termine direkt in Zeit-/Zahl-Schritte zählen (`docs/produkt/rechenregeln.md` §8).
