import Foundation

/// Empfehlungen im Kalender (rechenregeln.md §9.1): was man jetzt in den Kalender ziehen sollte – je nach Ansicht Tag, Woche oder Monat.
/// Deterministisch: Punkte nach Dringlichkeit, Platz nach freier Zeit. Die KI rechnet hier nichts.
enum Empfehlung {

    enum Bereich: String, Sendable { case tag, woche, monat }

    struct Vorschlag: Identifiable, Hashable, Sendable {
        enum Art: String, Sendable, Hashable { case aufgabe, habit }
        var art: Art
        var objektID: UUID
        var titel: String
        /// Ein Grund, warum es vorgeschlagen wird („Überfällig seit 2 Tagen“).
        var grund: String
        var farbe: String
        var symbol: String
        var dauer: Int
        var punkte: Int
        /// Wohin es passt: Tag und (nur in der Tagesansicht) Uhrzeit.
        var tag: Tag
        var uhrzeit: Int?
        /// Tagesansicht: an dem Tag kein Platz mehr, Vorschlag ist der nächste Tag.
        var verschoben = false
        /// Fälligkeit, wenn sie noch kommt – der vorgeschlagene Tag liegt nie danach.
        var frist: Tag?
        var id: String { nutzlast }
        var nutzlast: String { "\(art.rawValue):\(objektID.uuidString)" }
    }

    /// Die Vorschläge für die gewählte Ansicht, beste zuerst.
    /// - Tag: offene Habits und Aufgaben dieses Tags ohne Uhrzeit, Überfälliges, Eingang – mit der ersten freien Lücke, die lang genug ist.
    /// - Woche/Monat: Aufgaben ohne Uhrzeit, die fällig, überfällig oder ohne Tag sind – mit dem freiesten Tag im Zeitraum (ab heute).
    static func fuer(_ bereich: Bereich, tag gewaehlt: Tag, zustand z: Zustand, heute: Tag, jetzt: Int, termine: (Tag) -> [Termin]) -> [Vorschlag] {
        let (von, bis) = zeitraum(bereich, gewaehlt)
        // Aufgaben des nächsten Schritts je aktivem Ziel und Ziele, die hinterher sind
        var schrittAufgaben: [UUID: String] = [:]
        var hinten = Set<UUID>()
        for g in z.ziele where g.status == .aktiv {
            if let a = Fortschritt.naechsterSchritt(g, in: z, heute: heute)?.aufgabe { schrittAufgaben[a.id] = g.titel }
            let l = Kurs.aufKurs(g, in: z, heute: heute).lage
            if l == .hinterher || l == .ueberfaellig { hinten.insert(g.id) }
        }

        var out: [Vorschlag] = []
        for a in z.aufgaben where !a.erledigt {
            var p = 0
            var grund = ""
            if let d = a.datum {
                if d < heute {
                    p = 100 + min(heute.nummer - d.nummer, 30)
                    let n = heute.nummer - d.nummer
                    grund = n == 1 ? "Seit gestern überfällig" : "Überfällig seit \(n) Tagen"
                } else if d >= von && d <= bis && a.uhrzeit == nil {
                    p = 80 - min(d.nummer - max(heute, von).nummer, 30)
                    grund = d == heute ? "Heute fällig" : "Fällig \(kurz(d, heute: heute))"
                } else { continue }   // an einem anderen Tag geplant
            } else {
                if a.uhrzeit != nil { continue }
                p = 30
                grund = "Aus dem Eingang"
            }
            if let ziel = schrittAufgaben[a.id] { p += 40; grund = "Nächster Schritt für „\(ziel)“" + (a.datum.map { $0 < heute } == true ? " · überfällig" : "") }
            if let zid = a.zielID, hinten.contains(zid) { p += 20 }
            if a.prio == .hoch { p += 25; if a.datum == nil { grund = "Wichtig · noch ohne Tag" } }
            out.append(Vorschlag(art: .aufgabe, objektID: a.id, titel: a.titel, grund: grund,
                                 farbe: Tagesplan.farbe(ziel: a.zielID, kategorie: a.kategorie, sonst: "#6B7285", in: z),
                                 symbol: "checkmark.circle", dauer: max(5, a.dauer), punkte: p, tag: gewaehlt, uhrzeit: nil,
                                 frist: a.datum.flatMap { $0 >= heute ? $0 : nil }))
        }
        if bereich == .tag {
            for h in z.habits where gewaehlt >= h.angelegt && HabitRechnung.geplant(h, am: gewaehlt) && h.zeit(am: gewaehlt) == nil && !h.voll(am: gewaehlt) {
                let mitZiel = h.zielID != nil
                out.append(Vorschlag(art: .habit, objektID: h.id, titel: h.titel,
                                     grund: (gewaehlt == heute ? "Habit · heute noch offen" : "Habit · an diesem Tag geplant") + (mitZiel ? " · zählt fürs Ziel" : ""),
                                     farbe: h.farbe, symbol: h.symbol, dauer: h.dauerMinuten, punkte: 60 + (mitZiel ? 20 : 0), tag: gewaehlt, uhrzeit: nil))
            }
        }
        out.sort { ($0.punkte, $1.titel) > ($1.punkte, $0.titel) }
        return platzieren(out, bereich: bereich, von: von, bis: bis, gewaehlt: gewaehlt, zustand: z, heute: heute, jetzt: jetzt, termine: termine)
    }

    /// Zeitraum der Ansicht: Tag, Woche (Mo–So) oder Monat.
    static func zeitraum(_ b: Bereich, _ d: Tag) -> (Tag, Tag) {
        switch b {
        case .tag: return (d, d)
        case .woche: return (d.montag, d.montag.plus(tage: 6))
        case .monat:
            let erster = Tag(d.jahr, d.monat, 1)
            return (erster, Tag(d.jahr, d.monat, Tag.tageImMonat(d.jahr, d.monat)))
        }
    }

    /// Platz finden, der Reihe nach: jeder Vorschlag belegt seinen Platz, damit der nächste woanders landet.
    static func platzieren(_ liste: [Vorschlag], bereich: Bereich, von: Tag, bis: Tag, gewaehlt: Tag, zustand z: Zustand, heute: Tag, jetzt: Int, termine: (Tag) -> [Termin]) -> [Vorschlag] {
        var out = liste
        switch bereich {
        case .tag:
            guard gewaehlt >= heute else { return out }   // Vergangenes: kein Platzvorschlag
            var belegt = Tagesplan.bloecke(am: gewaehlt, zustand: z, termine: termine(gewaehlt)).filter { !$0.erledigt }.map { ($0.start, $0.ende) }
            let ab = gewaehlt == heute ? aufViertel(max(jetzt, frueheste)) : frueheste
            for i in out.indices {
                if let s = luecke(belegt, dauer: out[i].dauer, ab: ab) {
                    out[i].uhrzeit = s
                    belegt.append((s, s + out[i].dauer))
                } else if out[i].art == .aufgabe {
                    out[i].tag = gewaehlt.plus(tage: 1)   // kein Platz mehr an dem Tag → auf den nächsten Tag (ohne Uhrzeit)
                    out[i].verschoben = true
                }
            }
        case .woche, .monat:
            let start = max(von, heute)
            guard start <= bis else { return out }
            var frei: [(Tag, Int)] = []
            var d = start
            while d <= bis {
                let b = Tagesplan.bloecke(am: d, zustand: z, termine: termine(d))
                frei.append((d, Tagesplan.freiAb(b, ab: d == heute ? jetzt : Tagesplan.wachVon)))
                d = d.plus(tage: 1)
            }
            for i in out.indices {
                // freiester Tag bis zur Frist; bei Gleichstand der frühere
                let erlaubt = frei.indices.filter { out[i].frist == nil || frei[$0].0 <= out[i].frist! }
                guard let k = erlaubt.max(by: { frei[$0].1 < frei[$1].1 || (frei[$0].1 == frei[$1].1 && frei[$0].0 > frei[$1].0) }) else { continue }
                out[i].tag = frei[k].0
                frei[k].1 -= out[i].dauer
            }
        }
        return out
    }

    /// Vorschläge fangen frühestens um 8 Uhr an.
    static let frueheste = 8 * 60

    static func aufViertel(_ m: Int) -> Int { (m + 14) / 15 * 15 }

    /// Erste Lücke ≥ dauer ab `ab` (auf Viertelstunden) in der wachen Zeit; nil = passt nicht mehr.
    static func luecke(_ belegt: [(Int, Int)], dauer: Int, ab: Int) -> Int? {
        var cursor = max(ab, Tagesplan.wachVon)
        for (a, e) in Tagesplan.vereinigt(belegt.filter { $0.1 > $0.0 }) {
            if e <= cursor { continue }
            if a - cursor >= dauer { return cursor }
            cursor = aufViertel(max(cursor, e))
        }
        return Tagesplan.wachBis - cursor >= dauer ? cursor : nil
    }

    /// „Mi“, „morgen“, „12.3.“ – kurz für Gründe.
    static func kurz(_ d: Tag, heute: Tag) -> String {
        let n = heute.tage(bis: d)
        if n == 1 { return "morgen" }
        if n > 1 && n < 7 { return ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"][d.wochentag - 1] }
        return "\(d.tag).\(d.monat)."
    }

    /// Wohin es passt, als kurzer Text für die Karte: „14:00“ oder „Mi“ – nil, wenn kein Platz.
    static func platzText(_ v: Vorschlag, bereich: Bereich, heute: Tag) -> String? {
        switch bereich {
        case .tag:
            if let u = v.uhrzeit { return Tagesplan.uhr(u) }
            return v.verschoben ? kurz(v.tag, heute: heute) : nil
        case .woche, .monat: return v.tag == heute ? "heute" : kurz(v.tag, heute: heute)
        }
    }
}
