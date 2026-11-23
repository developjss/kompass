import Foundation

// rechenregeln.md §4 (Auf Kurs), §5 (Prognose) und die Frist-Texte („noch 3 Monate“).

enum Kurs {

    enum Lage: String, Sendable {
        case voraus, imPlan, hinterher, ueberfaellig, erreicht

        var text: String {
            switch self {
            case .voraus: "voraus"
            case .imPlan: "im Plan"
            case .hinterher: "hinterher"
            case .ueberfaellig: "überfällig"
            case .erreicht: "erreicht"
            }
        }
    }

    struct Ergebnis: Equatable, Sendable {
        var lage: Lage
        var fortschritt: Double
        /// erwarteter Anteil 0…1
        var erwartet: Double
        var verstrichen: Int
        var gesamt: Int
    }

    /// erwartet = verstrichene Tage ÷ Tage von Anlage bis Fälligkeit; ≥ +5 Punkte voraus, ≤ −10 Punkte hinterher.
    static func aufKurs(fortschritt p: Double, angelegt: Tag, faellig: Tag, erreicht: Bool, heute: Tag) -> Ergebnis {
        if erreicht { return Ergebnis(lage: .erreicht, fortschritt: p, erwartet: 1, verstrichen: 0, gesamt: 0) }
        let gesamt = angelegt.tage(bis: faellig)
        let verstrichen = min(max(angelegt.tage(bis: heute), 0), max(gesamt, 0))
        if heute > faellig && p < 1 {
            return Ergebnis(lage: .ueberfaellig, fortschritt: p, erwartet: 1, verstrichen: verstrichen, gesamt: gesamt)
        }
        if gesamt <= 0 { return Ergebnis(lage: .imPlan, fortschritt: p, erwartet: p, verstrichen: verstrichen, gesamt: gesamt) }
        let erwartet = Double(verstrichen) / Double(gesamt)
        let d = p - erwartet
        let lage: Lage = d >= 0.05 ? .voraus : d <= -0.10 ? .hinterher : .imPlan
        return Ergebnis(lage: lage, fortschritt: p, erwartet: erwartet, verstrichen: verstrichen, gesamt: gesamt)
    }

    static func aufKurs(_ g: Ziel, in z: Zustand, heute: Tag) -> Ergebnis {
        aufKurs(fortschritt: Fortschritt.ziel(g, in: z, heute: heute), angelegt: g.angelegt, faellig: g.faellig,
                erreicht: g.status == .erreicht, heute: heute)
    }

    // MARK: Prognose (§5)

    enum Prognose: Equatable, Sendable {
        /// Weniger als 7 Tage Verlauf oder schon erreicht
        case keine
        case keinFortschritt(tage: Int)
        case datum(Tag, restTage: Int, tempoProTag: Double)
    }

    /// Tempo = (heute − Stand vor ~28 Tagen) ÷ Tage; Rest-Tage = (1 − Fortschritt) ÷ Tempo.
    static func prognose(verlauf: [VerlaufPunkt], fortschritt p: Double, heute: Tag) -> Prognose {
        let l = verlauf.sorted { $0.tag < $1.tag }
        guard p < 1, l.count >= 2 else { return .keine }
        let ziel = heute.plus(tage: -28)
        var ref = l.last { $0.tag <= ziel }
        if ref == nil {
            ref = l.first
            if let r = ref, r.tag.tage(bis: heute) < 7 { return .keine }
        }
        guard let r = ref else { return .keine }
        let tage = r.tag.tage(bis: heute)
        guard tage > 0 else { return .keine }
        let v = (p - r.wert) / Double(tage)
        guard v > 0.00005 else { return .keinFortschritt(tage: tage) }
        let rest = Int(((1 - p) / v).rounded(.up))
        return .datum(heute.plus(tage: rest), restTage: rest, tempoProTag: v)
    }

    /// Verlauf fortschreiben: ein Wert pro Tag, gleicher Wert wie zuletzt wird nicht doppelt gespeichert.
    static func verlaufFortschreiben(_ l: [VerlaufPunkt], wert: Double, heute: Tag, hoechstens: Int = 800) -> [VerlaufPunkt] {
        var l = l
        let w = (wert * 10_000).rounded() / 10_000
        if let letzter = l.last, letzter.tag == heute {
            l[l.count - 1].wert = w
        } else if l.last?.wert != w {
            l.append(VerlaufPunkt(tag: heute, wert: w))
        }
        if l.count > hoechstens { l.removeFirst(l.count - hoechstens) }
        return l
    }

    // MARK: Frist-Text

    /// „heute fällig“, „noch 30 Tage“, „noch 1 Monat“, „noch 2 Jahre 3 Mon.“, „seit 4 Tagen überfällig“
    static func bisText(_ faellig: Tag, heute: Tag) -> String {
        let dd = heute.tage(bis: faellig)
        if dd < 0 { return dd == -1 ? "seit gestern überfällig" : "seit \(-dd) Tagen überfällig" }
        if dd == 0 { return "heute fällig" }
        if dd == 1 { return "morgen fällig" }
        var m = (faellig.jahr - heute.jahr) * 12 + faellig.monat - heute.monat
        if faellig.tag < heute.tag { m -= 1 }
        if m < 1 { return "noch \(dd) Tage" }
        if m < 24 { return "noch \(m) \(m == 1 ? "Monat" : "Monate")" }
        let j = m / 12, r = m % 12
        return "noch \(j) Jahre" + (r > 0 ? " \(r) Mon." : "")
    }
}
