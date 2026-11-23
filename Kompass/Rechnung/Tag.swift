import Foundation

/// Ein Kalendertag ohne Uhrzeit und Zeitzone (rechenregeln.md §4: „Tage in ganzen Kalendertagen, sommerzeitfest“).
/// Gerechnet wird mit der fortlaufenden Tagnummer (Tage seit 1970-01-01) – reine Ganzzahl-Arithmetik, keine Uhrzeit.
struct Tag: Hashable, Comparable, Sendable, Codable, CustomStringConvertible {
    let jahr: Int
    let monat: Int
    let tag: Int

    init(_ jahr: Int, _ monat: Int, _ tag: Int) {
        self.jahr = jahr
        self.monat = monat
        self.tag = tag
    }

    /// Der Kalendertag, in den ein Zeitpunkt in dieser Zeitzone fällt.
    init(_ datum: Date, kalender: Calendar = .kompass) {
        let k = kalender.dateComponents([.year, .month, .day], from: datum)
        self.init(k.year ?? 1970, k.month ?? 1, k.day ?? 1)
    }

    /// „JJJJ-MM-TT“ – gleiche Schreibweise wie im Klick-Dummy; Vergleich als Text = Vergleich als Datum.
    init?(text: String) {
        let teile = text.split(separator: "-").compactMap { Int($0) }
        guard teile.count == 3, (1...12).contains(teile[1]), (1...Tag.tageImMonat(teile[0], teile[1])).contains(teile[2]) else { return nil }
        self.init(teile[0], teile[1], teile[2])
    }

    var text: String { String(format: "%04d-%02d-%02d", jahr, monat, tag) }
    var description: String { text }

    // MARK: Tagnummer (Algorithmus „days from civil“, proleptischer gregorianischer Kalender)

    var nummer: Int {
        let y = monat <= 2 ? jahr - 1 : jahr
        let era = (y >= 0 ? y : y - 399) / 400
        let yoe = y - era * 400
        let mp = (monat + 9) % 12
        let doy = (153 * mp + 2) / 5 + tag - 1
        let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy
        return era * 146_097 + doe - 719_468
    }

    init(nummer: Int) {
        let z = nummer + 719_468
        let era = (z >= 0 ? z : z - 146_096) / 146_097
        let doe = z - era * 146_097
        let yoe = (doe - doe / 1460 + doe / 36524 - doe / 146_096) / 365
        let doy = doe - (365 * yoe + yoe / 4 - yoe / 100)
        let mp = (5 * doy + 2) / 153
        let d = doy - (153 * mp + 2) / 5 + 1
        let m = mp < 10 ? mp + 3 : mp - 9
        self.init(yoe + era * 400 + (m <= 2 ? 1 : 0), m, d)
    }

    static func < (a: Tag, b: Tag) -> Bool { a.nummer < b.nummer }

    func plus(tage n: Int) -> Tag { Tag(nummer: nummer + n) }

    /// Ganze Kalendertage von `self` bis `b` (negativ, wenn `b` davor liegt).
    func tage(bis b: Tag) -> Int { b.nummer - nummer }

    /// 1 = Montag … 7 = Sonntag (wie im Klick-Dummy `wdn`).
    var wochentag: Int {
        let w = (nummer + 3) % 7 // 1970-01-01 war ein Donnerstag
        return (w < 0 ? w + 7 : w) + 1
    }

    var montag: Tag { plus(tage: 1 - wochentag) }

    /// Kalenderwoche nach ISO 8601 (KW 53 möglich).
    var kalenderwoche: Int {
        let donnerstag = plus(tage: 4 - wochentag)
        let neujahr = Tag(donnerstag.jahr, 1, 1)
        return neujahr.tage(bis: donnerstag) / 7 + 1
    }

    static func tageImMonat(_ jahr: Int, _ monat: Int) -> Int {
        switch monat {
        case 2: return (jahr % 4 == 0 && jahr % 100 != 0) || jahr % 400 == 0 ? 29 : 28
        case 4, 6, 9, 11: return 30
        default: return 31
        }
    }

    /// Gleicher Tag `n` Monate später; gibt es den Tag nicht, der Monatsletzte (`ankerTag` verhindert Abrutschen).
    func plus(monate n: Int, ankerTag: Int? = nil) -> Tag {
        let gesamt = jahr * 12 + (monat - 1) + n
        let j = Int((Double(gesamt) / 12).rounded(.down))
        let m = gesamt - j * 12 + 1
        return Tag(j, m, min(ankerTag ?? tag, Tag.tageImMonat(j, m)))
    }

    /// Mittag dieses Tages als Zeitpunkt (nur für Anzeige/Formatierung, nie zum Rechnen).
    func datum(kalender: Calendar = .kompass) -> Date {
        kalender.date(from: DateComponents(year: jahr, month: monat, day: tag, hour: 12)) ?? Date(timeIntervalSince1970: 0)
    }

    // Codable als „JJJJ-MM-TT“
    init(from decoder: Decoder) throws {
        let s = try decoder.singleValueContainer().decode(String.self)
        guard let t = Tag(text: s) else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Kein Datum: \(s)"))
        }
        self = t
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(text)
    }
}

extension Calendar {
    /// Gregorianisch, Woche ab Montag, aktuelle Zeitzone des Geräts.
    static var kompass: Calendar {
        var k = Calendar(identifier: .gregorian)
        k.firstWeekday = 2
        k.minimumDaysInFirstWeek = 4
        k.locale = Locale(identifier: "de_DE")
        return k
    }
}
