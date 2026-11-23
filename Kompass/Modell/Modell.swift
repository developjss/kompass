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

/// Einheit einer Habit-Menge. `kurz` für Zeilen („12 von 20 min“), `name` für Auswahl.
enum Einheit: String, Codable, Sendable, CaseIterable {
    case minuten, stunden, sekunden, gramm, kilogramm, milliliter, liter, seiten, mal, kilometer, schritte

    var kurz: String {
        switch self {
        case .minuten: "min"
        case .stunden: "h"
        case .sekunden: "s"
        case .gramm: "g"
        case .kilogramm: "kg"
        case .milliliter: "ml"
        case .liter: "l"
        case .seiten: "Seiten"
        case .mal: "×"
        case .kilometer: "km"
        case .schritte: "Schritte"
        }
    }

    var name: String {
        switch self {
        case .minuten: "Minuten"
        case .stunden: "Stunden"
        case .sekunden: "Sekunden"
        case .gramm: "Gramm"
        case .kilogramm: "Kilogramm"
        case .milliliter: "Milliliter"
        case .liter: "Liter"
        case .seiten: "Seiten"
        case .mal: "Mal"
        case .kilometer: "Kilometer"
        case .schritte: "Schritte"
        }
    }
}

/// Wann ein Habit geplant ist.
enum Rhythmus: Codable, Sendable, Hashable {
    case taeglich
    /// 1 = Montag … 7 = Sonntag
    case wochentage(Set<Int>)
    /// n-mal pro Woche, egal an welchen Tagen
    case proWoche(Int)

    private enum K: String, CodingKey { case art, tage, n }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: K.self)
        switch try c.decode(String.self, forKey: .art) {
        case "wochentage": self = .wochentage(Set(try c.decodeIfPresent([Int].self, forKey: .tage) ?? []))
        case "proWoche": self = .proWoche(max(1, try c.decodeIfPresent(Int.self, forKey: .n) ?? 3))
        default: self = .taeglich
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: K.self)
        switch self {
        case .taeglich: try c.encode("taeglich", forKey: .art)
        case .wochentage(let t): try c.encode("wochentage", forKey: .art); try c.encode(t.sorted(), forKey: .tage)
        case .proWoche(let n): try c.encode("proWoche", forKey: .art); try c.encode(n, forKey: .n)
        }
    }

    /// Aus Wochentagen: alle sieben = täglich.
    static func aus(tagen t: Set<Int>) -> Rhythmus { t.count >= 7 ? .taeglich : .wochentage(t) }
}

struct Habit: Identifiable, Codable, Sendable, Hashable {
    var id = UUID()
    var titel: String
    var farbe: String
    var symbol: String
    var rhythmus: Rhythmus = .taeglich
    /// Soll je Tag (z. B. 20); nil = einfach abhaken
    var menge: Double?
    var einheit: Einheit?
    /// Erinnerung als Minuten seit Mitternacht; nil = keine
    var erinnerung: Int?
    /// Feste Uhrzeit im Kalender (Minuten seit Mitternacht); nil = irgendwann am Tag
    var uhrzeit: Int?
    /// Dauer im Kalender in Minuten; nil = aus der Menge (Minuten/Stunden) oder 30
    var dauer: Int?
    /// Uhrzeit nur für einen Tag (in den Kalender gezogen); geht `uhrzeit` vor
    var planZeiten: [Tag: Int] = [:]
    var notiz = ""
    var zielID: UUID?
    /// Eingetragene Menge je Tag. Ohne Soll: 1 = abgehakt.
    var eintraege: [Tag: Double] = [:]
    var angelegt: Tag

    init(id: UUID = UUID(), titel: String, farbe: String, symbol: String, rhythmus: Rhythmus = .taeglich, menge: Double? = nil,
         einheit: Einheit? = nil, erinnerung: Int? = nil, notiz: String = "", zielID: UUID? = nil, eintraege: [Tag: Double] = [:], angelegt: Tag) {
        self.id = id; self.titel = titel; self.farbe = farbe; self.symbol = symbol; self.rhythmus = rhythmus; self.menge = menge
        self.einheit = einheit; self.erinnerung = erinnerung; self.notiz = notiz; self.zielID = zielID; self.eintraege = eintraege; self.angelegt = angelegt
    }

    /// Alte Schreibweise (Wochentage) – bleibt für Aufrufer und Tests.
    init(titel: String, farbe: String, symbol: String, wochentage: Set<Int>, zielID: UUID? = nil, angelegt: Tag) {
        self.init(titel: titel, farbe: farbe, symbol: symbol, rhythmus: .aus(tagen: wochentage), zielID: zielID, angelegt: angelegt)
    }

    /// Geplante Wochentage (bei „n-mal pro Woche“ alle sieben).
    var wochentage: Set<Int> {
        switch rhythmus {
        case .taeglich, .proWoche: [1, 2, 3, 4, 5, 6, 7]
        case .wochentage(let t): t
        }
    }

    /// Anteil eines Tages 0…1: Menge ÷ Soll (ohne Soll: 0 oder 1).
    func anteil(am tag: Tag) -> Double {
        guard let e = eintraege[tag], e > 0 else { return 0 }
        guard let soll = menge, soll > 0 else { return 1 }
        return min(1, e / soll)
    }

    func voll(am tag: Tag) -> Bool { anteil(am: tag) >= 1 }

    /// Uhrzeit an einem Tag: in den Tag gezogen, sonst die feste Uhrzeit.
    func zeit(am tag: Tag) -> Int? { planZeiten[tag] ?? uhrzeit }

    /// Wie lange der Habit im Kalender dauert.
    var dauerMinuten: Int {
        if let d = dauer, d > 0 { return d }
        if let m = menge, m > 0, let e = einheit {
            if e == .minuten { return max(5, Int(m.rounded())) }
            if e == .stunden { return max(5, Int((m * 60).rounded())) }
        }
        return 30
    }

    /// Tage, die voll geschafft sind (für ältere Rechenwege).
    var erledigt: Set<Tag> { Set(eintraege.filter { anteil(am: $0.key) >= 1 }.map(\.key)) }

    /// Ganze Menge eintragen (Abhaken); bei vollem Tag wieder leeren.
    mutating func umschalten(am tag: Tag) {
        if voll(am: tag) { eintraege[tag] = nil } else { eintraege[tag] = menge ?? 1 }
    }

    mutating func eintragen(_ wert: Double, am tag: Tag) {
        eintraege[tag] = wert > 0 ? wert : nil
    }

    /// Codable: Einträge als Text-Schlüssel; alte Felder `wochentage` und `erledigt` werden gelesen.
    private enum K: String, CodingKey { case id, titel, farbe, symbol, rhythmus, menge, einheit, erinnerung, uhrzeit, dauer, planZeiten, notiz, zielID, eintraege, angelegt, wochentage, erledigt }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: K.self)
        id = try c.decode(UUID.self, forKey: .id)
        titel = try c.decode(String.self, forKey: .titel)
        farbe = try c.decode(String.self, forKey: .farbe)
        symbol = try c.decode(String.self, forKey: .symbol)
        if let r = try c.decodeIfPresent(Rhythmus.self, forKey: .rhythmus) { rhythmus = r }
        else { rhythmus = .aus(tagen: Set(try c.decodeIfPresent([Int].self, forKey: .wochentage) ?? [1, 2, 3, 4, 5, 6, 7])) }
        menge = try c.decodeIfPresent(Double.self, forKey: .menge)
        einheit = try c.decodeIfPresent(Einheit.self, forKey: .einheit)
        erinnerung = try c.decodeIfPresent(Int.self, forKey: .erinnerung)
        uhrzeit = try c.decodeIfPresent(Int.self, forKey: .uhrzeit)
        dauer = try c.decodeIfPresent(Int.self, forKey: .dauer)
        var p: [Tag: Int] = [:]
        for (k, v) in try c.decodeIfPresent([String: Int].self, forKey: .planZeiten) ?? [:] { if let t = Tag(text: k) { p[t] = v } }
        planZeiten = p
        notiz = try c.decodeIfPresent(String.self, forKey: .notiz) ?? ""
        zielID = try c.decodeIfPresent(UUID.self, forKey: .zielID)
        angelegt = try c.decode(Tag.self, forKey: .angelegt)
        var e: [Tag: Double] = [:]
        for (k, v) in try c.decodeIfPresent([String: Double].self, forKey: .eintraege) ?? [:] { if let t = Tag(text: k) { e[t] = v } }
        for t in try c.decodeIfPresent([Tag].self, forKey: .erledigt) ?? [] where e[t] == nil { e[t] = menge ?? 1 }
        eintraege = e
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: K.self)
        try c.encode(id, forKey: .id); try c.encode(titel, forKey: .titel); try c.encode(farbe, forKey: .farbe); try c.encode(symbol, forKey: .symbol)
        try c.encode(rhythmus, forKey: .rhythmus)
        try c.encodeIfPresent(menge, forKey: .menge); try c.encodeIfPresent(einheit, forKey: .einheit); try c.encodeIfPresent(erinnerung, forKey: .erinnerung)
        try c.encodeIfPresent(uhrzeit, forKey: .uhrzeit); try c.encodeIfPresent(dauer, forKey: .dauer)
        if !planZeiten.isEmpty { try c.encode(Dictionary(uniqueKeysWithValues: planZeiten.map { ($0.key.text, $0.value) }), forKey: .planZeiten) }
        try c.encode(notiz, forKey: .notiz); try c.encodeIfPresent(zielID, forKey: .zielID); try c.encode(angelegt, forKey: .angelegt)
        try c.encode(Dictionary(uniqueKeysWithValues: eintraege.map { ($0.key.text, $0.value) }), forKey: .eintraege)
    }
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
    /// Farbe im Kalender, wenn kein Ziel dran hängt
    var kategorie: Kategorie?

    var einmalig: Bool { wiederholung == .nie }
}

/// Kategorie für Farben im Kalender (Struktur v3 §1).
enum Kategorie: String, Codable, Sendable, CaseIterable, Hashable {
    case arbeit, schule, studium, freizeit, gesundheit, familie

    var name: String {
        switch self {
        case .arbeit: "Arbeit"
        case .schule: "Schule"
        case .studium: "Studium"
        case .freizeit: "Freizeit"
        case .gesundheit: "Gesundheit"
        case .familie: "Familie"
        }
    }

    var farbe: String {
        switch self {
        case .arbeit: "#3B4CCA"
        case .schule: "#1F7AC2"
        case .studium: "#7A4FD6"
        case .freizeit: "#C2410C"
        case .gesundheit: "#15803D"
        case .familie: "#B8456E"
        }
    }

    var symbol: String {
        switch self {
        case .arbeit: "briefcase.fill"
        case .schule: "backpack.fill"
        case .studium: "graduationcap.fill"
        case .freizeit: "sun.max.fill"
        case .gesundheit: "heart.fill"
        case .familie: "house.fill"
        }
    }
}

/// Termin, den man in Kompass anlegt (Apple/Google bleiben dort). Kann für ein Ziel zählen oder einen Habit erfüllen.
struct EigenerTermin: Identifiable, Codable, Sendable, Hashable {
    var id = UUID()
    var titel: String
    var tag: Tag
    /// Minuten seit Mitternacht
    var start: Int
    var ende: Int
    var kategorie: Kategorie?
    var zielID: UUID?
    var schrittID: UUID?
    /// Erfüllt diesen Habit, sobald der Termin vorbei ist
    var habitID: UUID?
    /// nie, täglich, werktags, wöchentlich (monatlich = gleicher Tag im Monat)
    var wiederholung: Wiederholung = .nie
    var notiz: String?
    /// Bis zu diesem Tag sind Habit-Einträge übernommen
    var habitBis: Tag?

    /// Findet der Termin an diesem Tag statt?
    func findetStatt(am d: Tag) -> Bool {
        guard d >= tag else { return false }
        switch wiederholung {
        case .nie: return d == tag
        case .taeglich: return true
        case .werktags: return d.wochentag <= 5
        case .woechentlich: return d.wochentag == tag.wochentag
        case .monatlich: return d.tag == tag.tag
        }
    }
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
        case habit(UUID)
        case bereich(String)
        /// Kompass Pro vorstellen (Kontingent aufgebraucht)
        case pro
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
    /// Kompass Pro (unbegrenzter Lotse). [RISIKO] Bis zur StoreKit-Prüfung nur ein Schalter (Test).
    var pro = false
    /// Farben im Kalender nach Ziel (Standard) oder Kategorie
    var farbenNachKategorie = false
    /// Apple-Kalender (EventKit) lesen – nur nach Zustimmung
    var appleKalender = false

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        nurEineAufgabe = try c.decodeIfPresent(Bool.self, forKey: .nurEineAufgabe) ?? false
        weitereAusblenden = try c.decodeIfPresent(Bool.self, forKey: .weitereAusblenden) ?? false
        googleBeispiel = try c.decodeIfPresent(Bool.self, forKey: .googleBeispiel) ?? false
        appleBeispiel = try c.decodeIfPresent(Bool.self, forKey: .appleBeispiel) ?? false
        pro = try c.decodeIfPresent(Bool.self, forKey: .pro) ?? false
        farbenNachKategorie = try c.decodeIfPresent(Bool.self, forKey: .farbenNachKategorie) ?? false
        appleKalender = try c.decodeIfPresent(Bool.self, forKey: .appleKalender) ?? false
    }
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
    /// Termine, die in Kompass angelegt wurden
    var eigeneTermine: [EigenerTermin] = []
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
        eigeneTermine = try c.decodeIfPresent([EigenerTermin].self, forKey: .eigeneTermine) ?? []
    }

    func ziel(_ id: UUID?) -> Ziel? { id.flatMap { i in ziele.first { $0.id == i } } }
    func habit(_ id: UUID?) -> Habit? { id.flatMap { i in habits.first { $0.id == i } } }
    func aufgabe(_ id: UUID?) -> Aufgabe? { id.flatMap { i in aufgaben.first { $0.id == i } } }
    func eigenerTermin(_ id: UUID?) -> EigenerTermin? { id.flatMap { i in eigeneTermine.first { $0.id == i } } }
    func schritt(_ id: UUID?, in zielID: UUID?) -> Schritt? { id.flatMap { i in ziel(zielID)?.schritte.first { $0.id == i } } }
}
