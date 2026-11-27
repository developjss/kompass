import Foundation

// Umbau Block C: Daten für Onboarding, Journal, Bildschirmzeit, Serie, Meilensteine und Pro
// (`docs/produkt/konzepte/umbau-nach-vorbild.md` §9, Rechenregeln §15–§20).

/// „Was willst du verbessern?“ (Onboarding, mehrere möglich)
enum Verbessern: String, Codable, Sendable, CaseIterable, Hashable {
    case ziele, gewohnheiten, wenigerHandy, schlafen, ruhe, anderes
}

/// Lebenslage (Onboarding)
enum Lebenslage: String, Codable, Sendable, CaseIterable, Hashable {
    case schule, ausbildung, studium, job, selbststaendig, eltern, anderes
}

/// Geschätzte Bildschirmzeit je Tag (Onboarding, §16)
enum BildschirmSpanne: String, Codable, Sendable, CaseIterable, Hashable {
    case unter1, eins3, drei4, vier5, fuenf7, ueber7, weissNicht
}

/// Wie man sich angemeldet hat. Telefon und E-Mail brauchen den Server (Phase 4).
enum Anmeldung: String, Codable, Sendable, Hashable {
    case keine, apple, telefon, email
}

struct Profil: Codable, Sendable, Hashable {
    var name = ""
    var alter: Int?
    var lebenslage: Lebenslage?
    var verbessern: [Verbessern] = []
    var spanne: BildschirmSpanne?
    var anmeldung: Anmeldung = .keine
    /// Kennung von „Mit Apple anmelden“ (nur auf dem Gerät)
    var appleKennung: String?
    var onboardingFertig = false
    /// Eigener Einladungs-Code (5 Zeichen), wird beim ersten Teilen erzeugt
    var einladungsCode: String?

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
        alter = try c.decodeIfPresent(Int.self, forKey: .alter)
        lebenslage = try c.decodeIfPresent(Lebenslage.self, forKey: .lebenslage)
        verbessern = try c.decodeIfPresent([Verbessern].self, forKey: .verbessern) ?? []
        spanne = try c.decodeIfPresent(BildschirmSpanne.self, forKey: .spanne)
        anmeldung = try c.decodeIfPresent(Anmeldung.self, forKey: .anmeldung) ?? .keine
        appleKennung = try c.decodeIfPresent(String.self, forKey: .appleKennung)
        onboardingFertig = try c.decodeIfPresent(Bool.self, forKey: .onboardingFertig) ?? false
        einladungsCode = try c.decodeIfPresent(String.self, forKey: .einladungsCode)
    }
}

/// Ein Journal-Tag: Stimmung 1–5 und ein Satz (§15).
struct JournalEintrag: Codable, Sendable, Hashable {
    var stimmung: Int?
    var satz = ""
    var zeit: Date?
}

/// Häufigkeit der Hinweise bei Ablenkung (§17)
enum HinweisHaeufigkeit: String, Codable, Sendable, CaseIterable, Hashable {
    case aus, niedrig, mittel, hoch
}

/// Schwierigkeit beim vorzeitigen Beenden eines Fokus mit Sperre (§17)
enum Schwierigkeit: String, Codable, Sendable, CaseIterable, Hashable {
    case leicht, steigend, durchziehen
}

/// Bildschirmzeit: Auswahl, Ziel, gemeldete Ablenkung je Tag (§17). Rohdaten bleiben auf dem Gerät.
struct Bildschirmzeit: Codable, Sendable, Hashable {
    /// Erlaubnis von Apple erteilt
    var erlaubt = false
    /// Apples Auswahl der Ablenker (FamilyActivitySelection, codiert) – undurchsichtig für Kompass
    var ablenker: Data?
    /// Apples Auswahl „Immer erlaubt“
    var immerErlaubt: Data?
    /// Ziel Ablenkung je Tag in Minuten; nil = aus §16 abgeleitet
    var zielMinuten: Int?
    var hinweise: HinweisHaeufigkeit = .mittel
    /// Höchste erreichte Schwelle je Tag („JJJJ-MM-TT“ → Minuten)
    var ablenkung: [String: Int] = [:]
    /// Tage, an denen die Überwachung lief (ohne Eintrag: „keine Daten“)
    var ueberwacht: Set<String> = []
    var schwierigkeit: Schwierigkeit = .leicht
    /// Abbrüche je Tag (für „steigend“)
    var abbrueche: [String: Int] = [:]
    /// Letzte Nutzung des Notfall-Passes
    var notfallPass: Date?

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        erlaubt = try c.decodeIfPresent(Bool.self, forKey: .erlaubt) ?? false
        ablenker = try c.decodeIfPresent(Data.self, forKey: .ablenker)
        immerErlaubt = try c.decodeIfPresent(Data.self, forKey: .immerErlaubt)
        zielMinuten = try c.decodeIfPresent(Int.self, forKey: .zielMinuten)
        hinweise = try c.decodeIfPresent(HinweisHaeufigkeit.self, forKey: .hinweise) ?? .mittel
        ablenkung = try c.decodeIfPresent([String: Int].self, forKey: .ablenkung) ?? [:]
        ueberwacht = try c.decodeIfPresent(Set<String>.self, forKey: .ueberwacht) ?? []
        schwierigkeit = try c.decodeIfPresent(Schwierigkeit.self, forKey: .schwierigkeit) ?? .leicht
        abbrueche = try c.decodeIfPresent([String: Int].self, forKey: .abbrueche) ?? [:]
        notfallPass = try c.decodeIfPresent(Date.self, forKey: .notfallPass)
    }
}

/// Zeitraum im Urlaubsmodus (§18), Tage als „JJJJ-MM-TT“, beide eingeschlossen.
struct Urlaub: Codable, Sendable, Hashable {
    var von: String
    var bis: String
}

/// Pro-Abo (StoreKit). Echte Produkte in App Store Connect folgen in Phase 3.
struct ProAbo: Codable, Sendable, Hashable {
    var produkt: String?
    var seit: Date?
    var verlaengertAm: Date?
}
