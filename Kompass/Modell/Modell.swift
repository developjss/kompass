import Foundation

// Datenmodell wie im Klick-Dummy (docs/technik/plattformen-und-speicherung.md). Reine Werte, keine Logik.
// Felder sind bewusst offen gehalten (Optionals mit Standardwerten), damit spätere Änderungen alte Daten lesen können.

/// Wie ein Meilenstein gemessen wird (rechenregeln.md §2). Rohwerte bleiben für gespeicherte Daten gleich.
enum SchrittArt: String, Codable, Sendable, CaseIterable {
    case aufgaben, zahl, zeit, habit

    var name: String {
        switch self {
        case .aufgaben: "Abhaken"
        case .zahl: "Zahl"
        case .zeit: "Zeit"
        case .habit: "Habit"
        }
    }

    /// Ein Satz, wie gezählt wird – für die Auswahl beim Anlegen.
    var erklaerung: String {
        switch self {
        case .aufgaben: "Fertig, wenn abgehakt. Aufgaben füllen bis 90 %."
        case .zahl: "Von Start bis Ziel, z. B. kg, €, Fahrstunden. Termine zählen je 1."
        case .zeit: "Stunden aus Fokus-Timer und Terminen."
        case .habit: "Wie oft oder wie viele Wochen du einen Habit durchhältst."
        }
    }

    var symbol: String {
        switch self {
        case .aufgaben: "checkmark.circle"
        case .zahl: "number"
        case .zeit: "clock"
        case .habit: "flame"
        }
    }
}

/// Habit-Meilenstein: Anzahl erledigter Male oder durchgehaltene Wochen.
enum HabitModus: String, Codable, Sendable, CaseIterable {
    case anzahl, wochen
    var name: String { self == .anzahl ? "Anzahl" : "Wochen durchhalten" }
}

struct Schritt: Identifiable, Codable, Sendable, Hashable {
    var id = UUID()
    var titel: String
    var art: SchrittArt = .aufgaben
    /// 1 klein, 2 mittel, 3 groß – alles andere zählt als 1 (rechenregeln.md §2).
    var gewicht: Int = 1
    var geschafft = false
    /// Ab wann ein Habit-Meilenstein zählt.
    var seit: Tag?
    /// Soll: Stunden (Zeit), Anzahl bzw. Wochen (Habit) oder Zielwert (Zahl).
    var soll: Double?
    var start: Double?
    /// Zahl: zuletzt eingetragener Stand (ohne Termine)
    var aktuell: Double?
    var einheit: String?
    var habitID: UUID?
    var habitModus: HabitModus?
    /// Zahl: Zwischenstände (z. B. 100.000 €) – werden automatisch erreicht, zählen nicht extra.
    var schwellen: [Double]?
    /// Zahl: eingetragene Stände
    var verlauf: [VerlaufPunkt]?

    var modus: HabitModus { habitModus ?? .anzahl }
}

enum ZielStatus: String, Codable, Sendable { case aktiv, erreicht }

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
    /// Meilensteine – einzige Quelle des Fortschritts (rechenregeln.md §1)
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

/// Termin-Serie aus dem Kalender, einem Ziel (Einsatz) und optional einem Meilenstein (Fortschritt) zugeordnet.
/// Gespeichert werden nur Tag und Dauer stattgefundener Termine ab `seit` – kein Titel, kein Ort.
struct TerminVerknuepfung: Identifiable, Codable, Sendable, Hashable {
    var id = UUID()
    /// „quelle:schlüssel“, z. B. „google:fahr“
    var serie: String
    var titel: String
    var zielID: UUID
    var schrittID: UUID?
    var seit: Tag
    var vorkommen: [TerminVorkommen] = []
    /// Bis zu diesem Tag ist abgeglichen (danach nur neue Tage prüfen)
    var abgeglichenBis: Tag?
}

struct TerminVorkommen: Codable, Sendable, Hashable {
    var tag: Tag
    var minuten: Int
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
    /// Was der Lotse aus Rückmeldungen lernt
    var lotse = LotseLernen()

    struct VorschlagZaehler: Codable, Sendable, Hashable {
        var gezeigt = 0
        var uebernommen = 0
    }

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        zeitVerhaeltnisse = try c.decodeIfPresent([Double].self, forKey: .zeitVerhaeltnisse) ?? []
        vorschlaege = try c.decodeIfPresent([String: VorschlagZaehler].self, forKey: .vorschlaege) ?? [:]
        lotse = try c.decodeIfPresent(LotseLernen.self, forKey: .lotse) ?? LotseLernen()
    }
}

/// Lernen des Lotsen: nur Zähler und Fragen, nie Antworten verändern. Später anonym über alle Nutzer zusammengeführt.
struct LotseLernen: Codable, Sendable, Hashable {
    /// Fragen, die kein Werkzeug getroffen haben (die letzten 50) – daraus entstehen neue Werkzeuge
    var unbeantwortet: [String] = []
    /// Fragen mit „Daumen runter“ (die letzten 50)
    var schlecht: [String] = []
    var gut = 0
    /// je Werkzeug: wie oft genutzt
    var genutzt: [String: Int] = [:]
}

/// Eine Nachricht im Lotsen-Chat.
struct ChatNachricht: Identifiable, Codable, Sendable, Hashable {
    enum Rolle: String, Codable, Sendable { case nutzer, lotse }
    enum Aktion: Codable, Sendable, Hashable {
        case ziel(UUID)
        case aufgabe(UUID)
        case bereich(String)
    }

    var id = UUID()
    var rolle: Rolle
    var text: String
    var zeit: Date
    /// Welches Werkzeug geantwortet hat (für Lernen und Anzeige)
    var werkzeug: String?
    var aktion: Aktion?
    /// Rückmeldung des Nutzers: true gut, false schlecht
    var rueckmeldung: Bool?
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
    static let aktuelleVersion = 2
    var version = Zustand.aktuelleVersion
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
    var termine: [TerminVerknuepfung] = []
    /// Chat mit dem Lotsen (die letzten 200 Nachrichten)
    var chat: [ChatNachricht] = []

    init(ziele: [Ziel] = [], habits: [Habit] = [], aufgaben: [Aufgabe] = [], sitzungen: [FokusSitzung] = []) {
        self.ziele = ziele
        self.habits = habits
        self.aufgaben = aufgaben
        self.sitzungen = sitzungen
    }

    /// Fehlende Felder (ältere Versionen) bekommen Standardwerte statt eines Lesefehlers.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        version = try c.decodeIfPresent(Int.self, forKey: .version) ?? 1
        ziele = try c.decodeIfPresent([Ziel].self, forKey: .ziele) ?? []
        habits = try c.decodeIfPresent([Habit].self, forKey: .habits) ?? []
        aufgaben = try c.decodeIfPresent([Aufgabe].self, forKey: .aufgaben) ?? []
        sitzungen = try c.decodeIfPresent([FokusSitzung].self, forKey: .sitzungen) ?? []
        verlauf = try c.decodeIfPresent([UUID: [VerlaufPunkt]].self, forKey: .verlauf) ?? [:]
        lernen = try c.decodeIfPresent(Lernen.self, forKey: .lernen) ?? Lernen()
        einstellungen = try c.decodeIfPresent(Einstellungen.self, forKey: .einstellungen) ?? Einstellungen()
        reflexionen = try c.decodeIfPresent([String: Reflexion].self, forKey: .reflexionen) ?? [:]
        timer = try c.decodeIfPresent(LaufenderTimer.self, forKey: .timer)
        termine = try c.decodeIfPresent([TerminVerknuepfung].self, forKey: .termine) ?? []
        chat = try c.decodeIfPresent([ChatNachricht].self, forKey: .chat) ?? []
    }

    func ziel(_ id: UUID?) -> Ziel? { id.flatMap { i in ziele.first { $0.id == i } } }
    func habit(_ id: UUID?) -> Habit? { id.flatMap { i in habits.first { $0.id == i } } }
    func aufgabe(_ id: UUID?) -> Aufgabe? { id.flatMap { i in aufgaben.first { $0.id == i } } }
    func schritt(_ id: UUID?, in zielID: UUID?) -> Schritt? { id.flatMap { i in ziel(zielID)?.schritte.first { $0.id == i } } }
}
