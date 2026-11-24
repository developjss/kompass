import Foundation

/// Alle Termine eines Tages aus allen Quellen: Beispieltermine (Demo), eigene Kompass-Termine, Apple-Kalender (von außen übergeben).
enum Kalenderquelle {
    static func termine(am d: Tag, zustand z: Zustand, heute: Tag, extern: [Termin] = []) -> [Termin] {
        let e = z.einstellungen
        var t = Beispieltermine.termine(am: d, google: e.googleBeispiel, apple: e.appleBeispiel, heute: heute)
        t += z.eigeneTermine.filter { $0.findetStatt(am: d) }.map { x in
            Termin(quelle: .kompass, schluessel: x.id.uuidString, titel: x.titel, tag: d, start: x.start, ende: x.ende,
                   eigenID: x.id, kategorie: x.kategorie, zielID: x.zielID, habitID: x.habitID, wiederkehrend: x.wiederholung != .nie)
        }
        t += extern.filter { $0.tag == d }
        // Termine aus Apple/Google, die für ein Ziel zählen, tragen das Ziel (nur Anzeige: Farbe, Ziel-Zeichen)
        for i in t.indices where t[i].zielID == nil && t[i].quelle != .kompass {
            t[i].zielID = verknuepfung(serie: serie(t[i]), in: z)?.zielID
        }
        return t.sorted { ($0.start ?? -1, $0.titel) < ($1.start ?? -1, $1.titel) }
    }

    /// Serien-Schlüssel wie in `TerminVerknuepfung.serie`: „quelle:schlüssel“.
    static func serie(_ t: Termin) -> String { "\(t.quelle.rawValue):\(t.schluessel)" }

    /// Verknüpfung einer Serie mit einem Ziel (Kompass-Termine tragen sie selbst).
    static func verknuepfung(serie: String, in z: Zustand) -> TerminVerknuepfung? {
        z.termine.first { $0.serie == serie }
    }
}

/// Tagesplan (rechenregeln.md §9, Struktur v3 §6): Blöcke mit Zeit, Als Nächstes, Auslastung, Hinweise. Rein und testbar.
enum Tagesplan {

    enum Art: String, Sendable, Hashable { case termin, aufgabe, habit }

    struct Block: Identifiable, Hashable, Sendable {
        var id: String
        var art: Art
        var titel: String
        var tag: Tag
        /// Minuten seit Mitternacht
        var start: Int
        var ende: Int
        /// Hex-Farbe (Ziel, Kategorie, Habit oder Quelle)
        var farbe: String
        var unter: String
        var zielID: UUID?
        var aufgabeID: UUID?
        var habitID: UUID?
        var eigenID: UUID?
        var erledigt = false
        /// Nur Termine: Serie „quelle:schlüssel“ (öffnet die Termin-Seite)
        var serie: String? = nil
        /// Termin gehört zu einer Wiederholung → beim Ändern fragen: nur dieser oder alle
        var wiederkehrend = false
        var dauer: Int { ende - start }
    }

    static let wachVon = 7 * 60
    static let wachBis = 22 * 60

    // MARK: Farbe

    /// Farbe nach Einstellung: Ziel zuerst (Standard) oder Kategorie zuerst; sonst Habit- bzw. Quellfarbe.
    static func farbe(ziel: UUID?, kategorie: Kategorie?, sonst: String, in z: Zustand) -> String {
        let zf = z.ziel(ziel)?.farbe
        let kf = kategorie?.farbe
        return (z.einstellungen.farbenNachKategorie ? (kf ?? zf) : (zf ?? kf)) ?? sonst
    }

    // MARK: Blöcke

    /// Alles mit Uhrzeit an einem Tag. Ganztägige Termine sind keine Blöcke.
    static func bloecke(am d: Tag, zustand z: Zustand, termine: [Termin]) -> [Block] {
        var out: [Block] = []
        for t in termine where t.tag == d {
            guard let s = t.start, let e = t.ende, e > s else { continue }
            out.append(Block(id: "t:\(t.id)", art: .termin, titel: t.titel, tag: d, start: s, ende: e,
                             farbe: farbe(ziel: t.zielID, kategorie: t.kategorie, sonst: t.kalenderFarbe ?? t.quelle.farbe, in: z),
                             unter: "\(uhr(s))–\(uhr(e))", zielID: t.zielID, habitID: t.habitID, eigenID: t.eigenID, serie: Kalenderquelle.serie(t), wiederkehrend: t.wiederkehrend))
        }
        for a in z.aufgaben where a.datum == d {
            guard let u = a.uhrzeit else { continue }
            let dauer = max(a.dauer, 5)
            out.append(Block(id: "a:\(a.id)", art: .aufgabe, titel: a.titel, tag: d, start: u, ende: u + dauer,
                             farbe: farbe(ziel: a.zielID, kategorie: a.kategorie, sonst: "#6B7285", in: z),
                             unter: "\(uhr(u)) · \(dauer) Min", zielID: a.zielID, aufgabeID: a.id, erledigt: a.erledigt))
        }
        for h in z.habits where d >= h.angelegt && HabitRechnung.geplant(h, am: d) {
            guard let u = h.zeit(am: d) else { continue }
            out.append(Block(id: "h:\(h.id):\(d.text)", art: .habit, titel: h.titel, tag: d, start: u, ende: u + h.dauerMinuten,
                             farbe: z.einstellungen.farbenNachKategorie ? h.farbe : (z.ziel(h.zielID)?.farbe ?? h.farbe),
                             unter: "\(uhr(u)) · \(h.dauerMinuten) Min · Habit", zielID: h.zielID, habitID: h.id, erledigt: h.voll(am: d)))
        }
        return out.sorted { ($0.start, $0.ende, $0.titel) < ($1.start, $1.ende, $1.titel) }
    }

    /// Aufgaben und Habits eines Tages ohne Uhrzeit (offen und erledigt).
    static func ohneZeit(am d: Tag, zustand z: Zustand) -> (aufgaben: [Aufgabe], habits: [Habit]) {
        let a = z.aufgaben.filter { $0.datum == d && $0.uhrzeit == nil }.sorted { ($0.erledigt ? 1 : 0, $0.reihenfolge) < ($1.erledigt ? 1 : 0, $1.reihenfolge) }
        let h = z.habits.filter { d >= $0.angelegt && HabitRechnung.geplant($0, am: d) && $0.zeit(am: d) == nil }
        return (a, h)
    }

    // MARK: Als Nächstes

    /// Laufende und kommende Blöcke ab jetzt (nicht erledigt), nach Start sortiert, bis `tage` voraus.
    static func naechste(zustand z: Zustand, heute: Tag, jetzt: Int, termine: (Tag) -> [Termin], anzahl: Int = 3, tage: Int = 7) -> [Block] {
        var out: [Block] = []
        for i in 0..<tage {
            let d = heute.plus(tage: i)
            for b in bloecke(am: d, zustand: z, termine: termine(d)) where !b.erledigt {
                if i == 0 && b.ende <= jetzt { continue }
                out.append(b)
            }
            if out.count >= anzahl { break }
        }
        return Array(out.prefix(anzahl))
    }

    /// Läuft gerade etwas?
    static func laeuft(_ b: Block, heute: Tag, jetzt: Int) -> Bool { b.tag == heute && b.start <= jetzt && jetzt < b.ende }

    // MARK: Auslastung

    struct Auslastung: Equatable, Sendable {
        var verplant: Int
        var frei: Int
        var laengsteLuecke: Int
        var eng: Bool
        var anteil: Double { Double(verplant) / Double(Tagesplan.wachBis - Tagesplan.wachVon) }
    }

    /// Verplant = Vereinigung der offenen Blöcke in der wachen Zeit; ab `ab` (heute: jetzt) für die Lücke.
    static func auslastung(_ bloecke: [Block], ab: Int = wachVon) -> Auslastung {
        let iv = vereinigt(bloecke.filter { !$0.erledigt }.map { (max($0.start, wachVon), min($0.ende, wachBis)) }.filter { $0.1 > $0.0 })
        let verplant = iv.reduce(0) { $0 + $1.1 - $1.0 }
        let frei = (wachBis - wachVon) - verplant
        var luecke = 0, cursor = max(ab, wachVon)
        for (a, e) in iv {
            if a > cursor { luecke = max(luecke, a - cursor) }
            cursor = max(cursor, e)
        }
        if wachBis > cursor { luecke = max(luecke, wachBis - cursor) }
        let eng = Double(verplant) >= 0.75 * Double(wachBis - wachVon) || frei < 90
        return Auslastung(verplant: verplant, frei: frei, laengsteLuecke: luecke, eng: eng)
    }

    static func vereinigt(_ iv: [(Int, Int)]) -> [(Int, Int)] {
        var out: [(Int, Int)] = []
        for (a, e) in iv.sorted(by: { $0.0 < $1.0 }) {
            if let l = out.last, a <= l.1 { out[out.count - 1].1 = max(l.1, e) } else { out.append((a, e)) }
        }
        return out
    }

    // MARK: Hinweise

    struct Hinweis: Identifiable, Hashable, Sendable {
        enum Art: String, Sendable, Hashable { case eng, ueberschneidung, keinPlatz }
        var art: Art
        var tag: Tag
        var text: String
        var id: String { "\(art.rawValue):\(tag.text):\(text)" }
    }

    /// Hinweise für heute und die nächsten Tage: enger Tag, Überschneidung (≥ 5 Min), kein Platz für Offenes ohne Uhrzeit.
    static func hinweise(zustand z: Zustand, heute: Tag, jetzt: Int, termine: (Tag) -> [Termin], tage: Int = 7) -> [Hinweis] {
        var out: [Hinweis] = []
        var gesehen = Set<String>()
        func neu(_ h: Hinweis) { if gesehen.insert(h.id).inserted { out.append(h) } } // gleiche Titel doppelt → ein Hinweis
        for i in 0..<tage {
            let d = heute.plus(tage: i)
            let b = bloecke(am: d, zustand: z, termine: termine(d)).filter { !$0.erledigt && (i > 0 || $0.ende > jetzt) }
            // Überschneidungen
            for x in 0..<b.count {
                for y in (x + 1)..<b.count where min(b[x].ende, b[y].ende) - max(b[x].start, b[y].start) >= 5 {
                    neu(Hinweis(art: .ueberschneidung, tag: d, text: "\(b[x].titel) und \(b[y].titel) gleichzeitig"))
                }
            }
            let ab = i == 0 ? max(jetzt, wachVon) : wachVon
            let a = auslastung(b, ab: ab)
            // Offenes ohne Uhrzeit, das Zeit braucht
            let offen = ohneZeit(am: d, zustand: z)
            let brauchtA = offen.aufgaben.filter { !$0.erledigt }.reduce(0) { $0 + max($1.dauer, 5) }
            let brauchtH = offen.habits.filter { !$0.voll(am: d) }.reduce(0) { $0 + $1.dauerMinuten }
            let braucht = brauchtA + brauchtH
            let frei = i == 0 ? freiAb(b, ab: ab) : a.frei
            if braucht > 0 && braucht > frei {
                neu(Hinweis(art: .keinPlatz, tag: d, text: "\(braucht) Min offen, frei sind noch \(max(0, frei)) Min"))
            } else if a.eng && i <= 2 {
                neu(Hinweis(art: .eng, tag: d, text: "Enger Tag: \(a.verplant / 60) h \(a.verplant % 60) Min verplant"))
            }
        }
        return out
    }

    /// Freie Minuten ab `ab` bis Ende der wachen Zeit (für heute).
    static func freiAb(_ b: [Block], ab: Int) -> Int {
        let start = max(ab, wachVon)
        guard start < wachBis else { return 0 }
        let iv = vereinigt(b.filter { !$0.erledigt }.map { (max($0.start, start), min($0.ende, wachBis)) }.filter { $0.1 > $0.0 })
        return (wachBis - start) - iv.reduce(0) { $0 + $1.1 - $1.0 }
    }

    static func uhr(_ m: Int) -> String { String(format: "%02d:%02d", (m / 60) % 24, m % 60) }

    /// „in 25 Min“, „läuft · noch 40 Min“, „morgen 09:00“, „Do 14:00“
    static func wannText(_ b: Block, heute: Tag, jetzt: Int) -> String {
        if laeuft(b, heute: heute, jetzt: jetzt) { return "läuft · noch \(b.ende - jetzt) Min" }
        if b.tag == heute {
            let d = b.start - jetzt
            return d < 60 ? "in \(d) Min" : "heute \(uhr(b.start))"
        }
        if b.tag == heute.plus(tage: 1) { return "morgen \(uhr(b.start))" }
        let namen = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]
        return "\(namen[b.tag.wochentag - 1]) \(uhr(b.start))"
    }
}

// MARK: Woche im Rückblick (Struktur v3 §5)

extension Tagesplan {
    struct Wochenbilanz: Equatable, Sendable {
        var aufgabenGeplant: Int
        var aufgabenErledigt: Int
        var habitsGeplant: Int
        var habitsErledigt: Double
        var termine: Int
        /// je Tag (Mo…So): verplante Minuten (7–22 Uhr), geplant/erledigt (Aufgaben + Habit-Anteile)
        var verplant: [Int]
        var geplantJeTag: [Double]
        var erledigtJeTag: [Double]

        /// Anteil der Pläne, die geschafft sind (Aufgaben + Habits); Termine zählen nicht (finden ohnehin statt).
        var quote: Double {
            let g = Double(aufgabenGeplant + habitsGeplant)
            return g > 0 ? (Double(aufgabenErledigt) + habitsErledigt) / g : 0
        }
    }

    /// Bilanz einer Woche ab `montag`; Tage nach heute zählen nicht.
    static func woche(zustand z: Zustand, montag: Tag, heute: Tag, termine: (Tag) -> [Termin]) -> Wochenbilanz {
        var aG = 0, aE = 0, hG = 0, hE = 0.0, t = 0
        var verplant: [Int] = [], gJ: [Double] = [], eJ: [Double] = []
        for i in 0..<7 {
            let d = montag.plus(tage: i)
            let te = termine(d)
            let b = bloecke(am: d, zustand: z, termine: te)
            verplant.append(vereinigt(b.map { (max($0.start, wachVon), min($0.ende, wachBis)) }.filter { $0.1 > $0.0 }).reduce(0) { $0 + $1.1 - $1.0 })
            guard d <= heute else { gJ.append(0); eJ.append(0); continue }
            let au = z.aufgaben.filter { $0.datum == d }
            let erledigt = au.filter(\.erledigt).count
            let hq = HabitRechnung.quote(alle: z.habits, von: d, bis: d, heute: heute)
            aG += au.count; aE += erledigt; hG += hq.geplant; hE += hq.erledigt
            t += te.filter { $0.start != nil }.count
            gJ.append(Double(au.count + hq.geplant)); eJ.append(Double(erledigt) + hq.erledigt)
        }
        return Wochenbilanz(aufgabenGeplant: aG, aufgabenErledigt: aE, habitsGeplant: hG, habitsErledigt: hE, termine: t,
                            verplant: verplant, geplantJeTag: gJ, erledigtJeTag: eJ)
    }
}
