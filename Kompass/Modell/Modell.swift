import Foundation

// Datenmodell wie im Klick-Dummy (docs/technik/plattformen-und-speicherung.md). Reine Werte, keine Logik.
// Felder sind bewusst offen gehalten (Optionals mit Standardwerten), damit spätere Änderungen alte Daten lesen können.

enum SchrittArt: String, Codable, Sendable, CaseIterable {
    case aufgaben, zeit, habit, zahl

    var name: String {
        switch self {
        case .aufgaben: "Aufgaben / abhaken"
        case .zeit: "Zeit sammeln"
        case .habit: "Habit wiederholen"
        case .zahl: "Zahl erreichen"
        }
    }
}

struct Schritt: Identifiable, Codable, Sendable, Hashable {
    var id = UUID()
    var titel: String
    var art: SchrittArt = .aufgaben
    /// 1 klein, 2 mittel, 3 groß – alles andere zählt als 1 (rechenregeln.md §2).
    var gewicht: Int = 1
    var geschafft = false
    /// Ab wann ein Habit-Schritt zählt.
    var seit: Tag?
    /// Soll: Stunden (Zeit), Anzahl (Habit) oder Zielwert (Zahl).
    var soll: Double?
    var start: Double?
    var aktuell: Double?
    var einheit: String?
    var habitID: UUID?
}

enum ZielStatus: String, Codable, Sendable { case aktiv, erreicht }

struct ZahlMessung: Codable, Sendable, Hashable {
    var start: Double
    var aktuell: Double
    var ziel: Double
    var einheit: String
    var verlauf: [VerlaufPunkt] = []
}

struct VerlaufPunkt: Codable, Sendable, Hashable {
    var tag: Tag
    var wert: Double
}

struct Ziel: Identifiable, Codable, Sendable, Hashable {
    var id = UUID()
    var titel: String
    var farbe: String
    var symbol: String
    var bereich: String
    var faellig: Tag
    var warum: String = ""
    var status: ZielStatus = .aktiv
    var angelegt: Tag
    /// Gesetzt = Ziel als Zahl; sonst zählen die Schritte.
    var zahl: ZahlMessung?
    var schritte: [Schritt] = []
}

struct Habit: Identifiable, Codable, Sendable, Hashable {
    var id = UUID()
    var titel: String
    var farbe: String
    var symbol: String
    /// 1 = Montag … 7 = Sonntag
    var wochentage: Set<Int>
    var zielID: UUID?
    var erledigt: Set<Tag> = []
    var angelegt: Tag
}

enum Prioritaet: String, Codable, Sendable { case hoch, normal }

enum Wiederholung: String, Codable, Sendable, CaseIterable {
    case nie, taeglich, werktags, woechentlich, monatlich

    var name: String {
        switch self {
        case .nie: "Nie"
        case .taeglich: "Täglich"
        case .werktags: "Werktags"
        case .woechentlich: "Wöchentlich"
        case .monatlich: "Monatlich"
        }
    }
}

struct Aufgabe: Identifiable, Codable, Sendable, Hashable {
    var id = UUID()
    var titel: String
    /// Leer = Eingang
    var datum: Tag?
    /// Minuten seit Mitternacht
    var uhrzeit: Int?
    var dauer: Int = 60
    var prio: Prioritaet = .normal
    var reihenfolge: Double = 0
    var zielID: UUID?
    var schrittID: UUID?
    var erledigt = false
    var erledigtAm: Date?
    var fokusSekunden: TimeInterval = 0
    var notizen = ""
    var wiederholung: Wiederholung = .nie
    var serie: UUID?
    var ankerTag: Int?

    var einmalig: Bool { wiederholung == .nie }
}

struct FokusSitzung: Identifiable, Codable, Sendable, Hashable {
    var id = UUID()
    var aufgabeID: UUID?
    var zielID: UUID?
    var schrittID: UUID?
    var tag: Tag
    var sekunden: TimeInterval
}

/// Laufender Fokus-Timer: abgeschlossene Abschnitte plus ggf. der laufende.
struct LaufenderTimer: Codable, Sendable, Hashable {
    var aufgabeID: UUID
    var abschnitte: [Abschnitt] = []
    var laeuftSeit: Date?

    struct Abschnitt: Codable, Sendable, Hashable {
        var start: Date
        var ende: Date
    }
}

struct Lernen: Codable, Sendable, Hashable {
    /// tatsächlich ÷ geplant je abgeschlossenem Zeit-Schritt (die letzten 30)
    var zeitVerhaeltnisse: [Double] = []
    /// je Vorschlag (normalisierter Titel): gezeigt / übernommen
    var vorschlaege: [String: VorschlagZaehler] = [:]

    struct VorschlagZaehler: Codable, Sendable, Hashable {
        var gezeigt = 0
        var uebernommen = 0
    }
}

struct Einstellungen: Codable, Sendable, Hashable {
    var nurEineAufgabe = false
    var weitereAusblenden = false
    var googleBeispiel = false
    var appleBeispiel = false
}

struct Reflexion: Codable, Sendable, Hashable {
    var antworten: [String: String] = [:]
}

/// Der ganze gespeicherte Zustand. Version hochzählen, wenn sich das Format ändert.
struct Zustand: Codable, Sendable, Hashable {
    var version = 1
    var ziele: [Ziel] = []
    var habits: [Habit] = []
    var aufgaben: [Aufgabe] = []
    var sitzungen: [FokusSitzung] = []
    /// Fortschritt je Ziel und Tag (ein Wert pro Tag, für die Prognose)
    var verlauf: [UUID: [VerlaufPunkt]] = [:]
    var lernen = Lernen()
    var einstellungen = Einstellungen()
    var reflexionen: [String: Reflexion] = [:]
    var timer: LaufenderTimer?

    func ziel(_ id: UUID?) -> Ziel? { id.flatMap { i in ziele.first { $0.id == i } } }
    func habit(_ id: UUID?) -> Habit? { id.flatMap { i in habits.first { $0.id == i } } }
    func aufgabe(_ id: UUID?) -> Aufgabe? { id.flatMap { i in aufgaben.first { $0.id == i } } }
}
