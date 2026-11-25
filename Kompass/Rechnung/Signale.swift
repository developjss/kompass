import Foundation

// rechenregeln.md §12 – Signale: was auf Home als wichtig gilt. Nur Rechnung, keine KI.
// Jedes Signal hat eine feste Bedingung, einen Rang und genau eine Handlung. Je Art höchstens eines.

enum Signale {

    /// Die Arten in der Reihenfolge ihres Gewichts.
    enum Art: String, CaseIterable, Sendable, Hashable {
        case serieGefahr, liegengeblieben, ueberschneidung, engpass, keinPlatz, zielKippt, fristNah, luft, serieGeschafft

        /// Gewicht der Art (§12, Tabelle). Rang = Gewicht ÷ (1 + Tage bis zum Ereignis).
        var gewicht: Int {
            switch self {
            case .serieGefahr: 100
            case .liegengeblieben: 90
            case .ueberschneidung: 85
            case .engpass: 80
            case .keinPlatz: 75
            case .zielKippt: 70
            case .fristNah: 60
            case .luft: 40
            case .serieGeschafft: 30
            }
        }

        var symbol: String {
            switch self {
            case .serieGefahr: "flame"
            case .liegengeblieben: "tray.full"
            case .ueberschneidung: "rectangle.on.rectangle"
            case .engpass: "gauge.with.dots.needle.67percent"
            case .keinPlatz: "hourglass"
            case .zielKippt: "arrow.down.right"
            case .fristNah: "flag"
            case .luft: "wind"
            case .serieGeschafft: "rosette"
            }
        }

        /// Name für „Passt nicht“ und den Assistenten
        var name: String {
            switch self {
            case .serieGefahr: "Serie in Gefahr"
            case .liegengeblieben: "Liegengeblieben"
            case .ueberschneidung: "Überschneidung"
            case .engpass: "Voller Tag"
            case .keinPlatz: "Zu wenig Zeit"
            case .zielKippt: "Ziel hinter Plan"
            case .fristNah: "Frist nah"
            case .luft: "Freier Tag"
            case .serieGeschafft: "Serie geschafft"
            }
        }
    }

    /// Wohin das Signal führt – genau eine Handlung.
    enum Handlung: Hashable, Sendable {
        case kalender(Tag)
        case ziel(UUID)
        case habit(UUID)
        case habitAnalyse(UUID)
        /// Liegengebliebene Aufgaben auf heute legen
        case aufHeute
    }

    struct Signal: Identifiable, Hashable, Sendable {
        var art: Art
        /// Tage bis zum Ereignis (0 = heute)
        var tage: Int
        var titel: String
        var text: String
        var handlung: Handlung
        var id: String { art.rawValue }
        var rang: Double { Double(art.gewicht) / Double(1 + max(0, tage)) }
    }

    // Schwellen (§12)
    static let vollAb = 0.75
    static let luftBis = 0.25
    static let fristTage = 14
    static let serieAb = 7
    static let abendAb = 18 * 60
    static let serienMarken: Set<Int> = [7, 30, 100]
    /// „Passt nicht“ stellt eine Art so viele Tage stumm
    static let stummTage = 56
    static let aufHome = 3

    /// Alle Signale, je Art höchstens eines, nach Rang (höchster zuerst; bei Gleichstand das höhere Gewicht).
    static func alle(zustand z: Zustand, heute T: Tag, jetzt: Int, termine: (Tag) -> [Termin]) -> [Signal] {
        var out: [Signal] = []

        // Liegengeblieben
        let liegen = z.aufgaben.filter { a in !a.erledigt && a.datum.map { $0 < T } == true }.count
        if liegen > 0 {
            out.append(Signal(art: .liegengeblieben, tage: 0, titel: liegen == 1 ? "1 Aufgabe liegen geblieben" : "\(liegen) Aufgaben liegen geblieben",
                              text: "von gestern oder früher", handlung: .aufHeute))
        }

        // Überschneidung und zu wenig Zeit: der früheste Tag aus den Hinweisen (§9)
        let hinweise = Tagesplan.hinweise(zustand: z, heute: T, jetzt: jetzt, termine: termine)
        if let h = hinweise.first(where: { $0.art == .ueberschneidung }) {
            out.append(Signal(art: .ueberschneidung, tage: T.tage(bis: h.tag), titel: "\(tagWort(h.tag, heute: T)): Überschneidung", text: h.text, handlung: .kalender(h.tag)))
        }
        if let h = hinweise.first(where: { $0.art == .keinPlatz }) {
            out.append(Signal(art: .keinPlatz, tage: T.tage(bis: h.tag), titel: "\(tagWort(h.tag, heute: T)): zu wenig Zeit", text: h.text, handlung: .kalender(h.tag)))
        }

        // Voller Tag (heute bis in 7 Tagen) und freier Tag (morgen bis in 3 Tagen)
        let ohneDatum = z.aufgaben.filter { !$0.erledigt && $0.datum == nil }.count
        var voll: Signal?, luft: Signal?
        for i in 0...7 {
            let d = T.plus(tage: i)
            let b = Tagesplan.bloecke(am: d, zustand: z, termine: termine(d)).filter { !$0.erledigt && (i > 0 || $0.ende > jetzt) }
            let a = Tagesplan.auslastung(b, ab: i == 0 ? max(jetzt, Tagesplan.wachVon) : Tagesplan.wachVon)
            if voll == nil, a.anteil >= vollAb {
                voll = Signal(art: .engpass, tage: i, titel: "\(tagWort(d, heute: T)) ist voll", text: "\(Zahl.dauer(Double(a.verplant) * 60)) verplant", handlung: .kalender(d))
            }
            if luft == nil, (1...3).contains(i), a.anteil <= luftBis, ohneDatum > 0 {
                luft = Signal(art: .luft, tage: i, titel: "\(tagWort(d, heute: T)) ist Luft",
                              text: "\(Zahl.dauer(Double(a.frei) * 60)) frei · \(ohneDatum) \(ohneDatum == 1 ? "Aufgabe" : "Aufgaben") ohne Datum", handlung: .kalender(d))
            }
        }
        if let voll { out.append(voll) }
        if let luft { out.append(luft) }

        // Ziele: hinter Plan (größter Rückstand) und Frist nah (früheste Frist)
        let aktiv = z.ziele.filter { $0.status == .aktiv }
        let kurse = aktiv.map { ($0, Kurs.aufKurs($0, in: z, heute: T)) }
        let hinten = kurse.filter { g, k in
            if k.lage == .hinterher || k.lage == .ueberfaellig { return true }
            if case .datum(let d, _, _) = Kurs.prognose(verlauf: z.verlauf[g.id] ?? [], fortschritt: k.fortschritt, heute: T) { return d > g.faellig }
            return false
        }
        .sorted { a, b in
            let da = a.1.erwartet - a.1.fortschritt, db = b.1.erwartet - b.1.fortschritt
            return da != db ? da > db : (a.0.faellig, a.0.titel) < (b.0.faellig, b.0.titel)
        }
        if let (g, k) = hinten.first {
            let text = k.lage == .ueberfaellig ? "\(g.titel) · überfällig"
                : k.lage == .hinterher ? "\(g.titel) · \(Zahl.prozent(k.fortschritt)) statt \(Zahl.prozent(k.erwartet))"
                : "\(g.titel) · Prognose nach der Frist"
            out.append(Signal(art: .zielKippt, tage: 0, titel: "Ziel hinter Plan", text: text, handlung: .ziel(g.id)))
        }
        let fristen = kurse.filter { g, k in k.fortschritt < 1 && (0...fristTage).contains(T.tage(bis: g.faellig)) }
            .sorted { ($0.0.faellig, $0.0.titel) < ($1.0.faellig, $1.0.titel) }
        if let (g, k) = fristen.first {
            let n = T.tage(bis: g.faellig)
            out.append(Signal(art: .fristNah, tage: n, titel: n == 0 ? "Frist heute" : n == 1 ? "Frist morgen" : "Frist in \(n) Tagen",
                              text: "\(g.titel) · \(Zahl.prozent(k.fortschritt))", handlung: .ziel(g.id)))
        }

        // Habits: Serie in Gefahr (abends, längste Serie) und Serie geschafft (höchste Marke)
        let serien = z.habits.filter { T >= $0.angelegt }.map { ($0, HabitRechnung.serie($0, heute: T)) }
        if jetzt >= abendAb {
            let gefahr = serien.filter { h, s in
                if case .proWoche = h.rhythmus { return false }
                return s >= serieAb && HabitRechnung.geplant(h, am: T) && !h.voll(am: T)
            }
            .sorted { $0.1 != $1.1 ? $0.1 > $1.1 : $0.0.titel < $1.0.titel }
            if let (h, s) = gefahr.first {
                out.append(Signal(art: .serieGefahr, tage: 0, titel: "Serie in Gefahr", text: "\(h.titel) · \(s) Tage · heute offen", handlung: .habit(h.id)))
            }
        }
        let marken = serien.filter { h, s in serienMarken.contains(s) && h.voll(am: T) }
            .sorted { $0.1 != $1.1 ? $0.1 > $1.1 : $0.0.titel < $1.0.titel }
        if let (h, s) = marken.first {
            let einheit: String = { if case .proWoche = h.rhythmus { return "Wochen" }; return "Tage" }()
            out.append(Signal(art: .serieGeschafft, tage: 0, titel: "\(s) \(einheit) Serie", text: h.titel, handlung: .habitAnalyse(h.id)))
        }

        return out.sorted { $0.rang != $1.rang ? $0.rang > $1.rang : $0.art.gewicht > $1.art.gewicht }
    }

    /// Was Home zeigt: die höchsten Ränge ohne stummgestellte Arten – höchstens `anzahl`.
    static func oben(_ alle: [Signal], stumm: [String: Tag], heute: Tag, anzahl: Int = aufHome) -> [Signal] {
        Array(alle.filter { s in stumm[s.art.rawValue].map { $0 <= heute } ?? true }.prefix(anzahl))
    }

    /// „Passt nicht“: die Art bis zu diesem Tag nicht mehr zeigen.
    static func stummBis(heute: Tag) -> Tag { heute.plus(tage: stummTage) }

    /// „Heute“, „Morgen“, sonst der Wochentag
    static func tagWort(_ d: Tag, heute: Tag) -> String {
        if d == heute { return "Heute" }
        if d == heute.plus(tage: 1) { return "Morgen" }
        return d.datum().formatted(.dateTime.weekday(.wide).locale(Locale(identifier: "de_DE")))
    }
}
