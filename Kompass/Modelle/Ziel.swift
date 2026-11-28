import Foundation

/// Ein langfristiges Ziel auf „Mein Weg“. Habits können einem Ziel zugeordnet werden (oder keinem).
struct Ziel: Identifiable, Hashable, Sendable {
    let id: String
    let titel: String
    let unter: String
    let dauer: String
    /// Bild aus `Assets.xcassets`
    let bild: String

    /// Demo-Ziele (bis Ziele angelegt und gespeichert werden können).
    static let demo: [Ziel] = [
        Ziel(id: "pilotenschein", titel: "Pilotenschein", unter: "Theorie und Praxis", dauer: "4 Monate", bild: "ziel-1"),
        Ziel(id: "alleinflug", titel: "Erster Alleinflug", unter: "Ohne Fluglehrer", dauer: "6 Wochen", bild: "ziel-2"),
    ]

    /// Text in der Zeile „Gehört zu“.
    static func zeilenText(_ ziel: Ziel?) -> String { ziel?.titel ?? "Kein Ziel" }
}
