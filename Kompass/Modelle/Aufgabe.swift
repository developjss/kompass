import Foundation

/// Eine einmalige Aufgabe auf „Mein Weg“ – optional mit Schritten, Fälligkeit und Ziel.
/// [ENTSCHEIDUNG – 28.11.2026, Gründer: „Bau“] Schritte optional, ganze Aufgabe über den Compass-Balken,
/// erledigte Aufgaben bleiben bis Mitternacht sichtbar (Ausblenden kommt mit den Funktionen).
struct Aufgabe: Identifiable, Hashable, Sendable {
    struct Schritt: Identifiable, Hashable, Sendable {
        let id: String
        var text: String
        var erledigt = false
    }

    let id: String
    var name: String
    var bild: String
    var schritte: [Schritt] = []
    /// Fällig an diesem Tag (nil = ohne Datum)
    var faellig: Date? = nil
    var zielID: String? = nil
    var erledigt = false

    var ziel: Ziel? { Ziel.demo.first { $0.id == zielID } }

    /// Demo-Aufgaben (bis Aufgaben gespeichert werden). Fälligkeit relativ zu `heute`.
    static func demo(heute: Date = .now) -> [Aufgabe] {
        let k = Calendar(identifier: .gregorian)
        let tag = { (n: Int) in k.date(byAdding: .day, value: n, to: k.startOfDay(for: heute)) }
        return [
            Aufgabe(id: "emails", name: "E-Mails", bild: "habit-4", faellig: tag(0)),
            Aufgabe(id: "einkaufen", name: "Einkaufen", bild: "habit-1", schritte: [
                Schritt(id: "e1", text: "Milch", erledigt: true), Schritt(id: "e2", text: "Brot"),
                Schritt(id: "e3", text: "Obst"), Schritt(id: "e4", text: "Kaffee"),
            ], faellig: tag(0)),
            Aufgabe(id: "anrufen", name: "Anrufen", bild: "habit-3", schritte: [
                Schritt(id: "a1", text: "Oma"), Schritt(id: "a2", text: "Werkstatt wegen Termin"),
            ]),
            Aufgabe(id: "lernplan", name: "Lernplan", bild: "habit-2", schritte: [
                Schritt(id: "l1", text: "Luftrecht Kapitel 1"), Schritt(id: "l2", text: "Meteorologie Kapitel 2"),
                Schritt(id: "l3", text: "Probeprüfung"),
            ], faellig: tag(1), zielID: "pilotenschein"),
            Aufgabe(id: "steuer", name: "Steuer", bild: "habit-5", faellig: tag(17)),
        ]
    }
}

/// Regeln für Aufgaben – fest gerechnet, mit Tests.
enum AufgabenRegel {
    /// Anteil für den Ring: erledigt = 1, sonst erledigte Schritte / alle Schritte (ohne Schritte 0).
    static func anteil(_ a: Aufgabe) -> Double {
        if a.erledigt { return 1 }
        guard !a.schritte.isEmpty else { return 0 }
        return Double(a.schritte.filter(\.erledigt).count) / Double(a.schritte.count)
    }

    /// Schritt umschalten. Sind danach alle Schritte erledigt, ist die Aufgabe erledigt;
    /// wird ein Schritt wieder geöffnet, ist die Aufgabe wieder offen.
    static func umschalten(_ schrittID: String, in a: inout Aufgabe) {
        guard let i = a.schritte.firstIndex(where: { $0.id == schrittID }) else { return }
        a.schritte[i].erledigt.toggle()
        a.erledigt = a.schritte.allSatisfy(\.erledigt)
    }

    /// Ganze Aufgabe erledigt (Compass-Balken ganz rechts): alle Schritte mit abhaken. Zurück: alles wieder offen.
    static func setzeErledigt(_ erledigt: Bool, in a: inout Aufgabe) {
        a.erledigt = erledigt
        for i in a.schritte.indices { a.schritte[i].erledigt = erledigt }
    }

    /// Reihenfolge auf „Mein Weg“: offene zuerst (in ihrer Reihenfolge), erledigte ans Ende.
    static func sortiert(_ liste: [Aufgabe]) -> [Aufgabe] {
        liste.filter { !$0.erledigt } + liste.filter(\.erledigt)
    }

    /// Fälligkeit als Text: „Heute fällig“, „Morgen fällig“, „Überfällig“, „Fällig am 15. Dez.“ (nil ohne Datum).
    static func faelligText(_ datum: Date?, heute: Date = .now) -> String? {
        guard let datum else { return nil }
        let k = Calendar(identifier: .gregorian)
        let tage = k.dateComponents([.day], from: k.startOfDay(for: heute), to: k.startOfDay(for: datum)).day ?? 0
        switch tage {
        case ..<0: return "Überfällig"
        case 0: return "Heute fällig"
        case 1: return "Morgen fällig"
        default:
            let f = DateFormatter()
            f.locale = Locale(identifier: "de_DE")
            f.dateFormat = "d. MMM"
            return "Fällig am \(f.string(from: datum))"
        }
    }

    /// Zeile über dem Namen: „Heute fällig · 1 von 4 Schritten“, „2 Schritte“, „Erledigt“, „Offen“.
    static func zeile(_ a: Aufgabe, heute: Date = .now) -> String {
        if a.erledigt { return "Erledigt" }
        var teile: [String] = []
        if let f = faelligText(a.faellig, heute: heute) { teile.append(f) }
        if !a.schritte.isEmpty {
            let n = a.schritte.filter(\.erledigt).count
            teile.append("\(n) von \(a.schritte.count) Schritten")
        }
        return teile.isEmpty ? "Offen" : teile.joined(separator: " · ")
    }
}
