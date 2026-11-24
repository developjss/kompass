import SwiftUI
import UIKit

// Farben, Maße und Schrift nach docs/produkt/design.md (Vorbild Gapless „Harbor 2“, kein geteilter Code).
// Blattwerk (Entscheidung 24.11.2026): Rosé trägt, Weinrot spricht, Kellygrün ist die eine Handlung. Hell und dunkel.

extension Color {
    /// Farbe aus Hex – bunte Farben (Ziele, Habits, Kalender) werden auf die Blattwerk-Palette gelegt
    /// (Weinrot-, Rosé- und Grüntöne; je hell/dunkel). Dunkle, helle und graue Farben bleiben, wie sie sind.
    init(hex: String) {
        if let t = Farbe.tonArt(hex) { self = t.farbe } else { self.init(roh: hex) }
    }

    /// Farbe genau aus Hex, ohne Palette
    init(roh hex: String) {
        let s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let v = UInt64(s, radix: 16) ?? 0x4A0F24
        self.init(.sRGB, red: Double((v >> 16) & 0xFF) / 255, green: Double((v >> 8) & 0xFF) / 255, blue: Double(v & 0xFF) / 255)
    }

    /// Hell/Dunkel-Paar
    init(hell: UInt32, dunkel: UInt32) {
        self.init(uiColor: UIColor { t in
            let v = t.userInterfaceStyle == .dark ? dunkel : hell
            return UIColor(red: CGFloat((v >> 16) & 0xFF) / 255, green: CGFloat((v >> 8) & 0xFF) / 255, blue: CGFloat(v & 0xFF) / 255, alpha: 1)
        })
    }
}

/// Die Blattwerk-Palette als Zahlen – damit Tests Kontraste rechnen können (WCAG).
enum Blattwerk {
    static let rose: UInt32 = 0xF6CBD4
    static let roseHell: UInt32 = 0xFBEDF1
    static let weinrot: UInt32 = 0x4A0F24
    static let weinrotTief: UInt32 = 0x2E0816
    static let weinrotKarte: UInt32 = 0x5A1C33
    static let gruen: UInt32 = 0x2DC92A
    static let gruenTief: UInt32 = 0x1B7A1A
    static let zweitrangigHell: UInt32 = 0x85536A
    static let zweitrangigDunkel: UInt32 = 0xD4A3B4

    /// Kontrastverhältnis zweier Farben (1 … 21) nach WCAG 2.1
    nonisolated static func kontrast(_ a: UInt32, _ b: UInt32) -> Double {
        func leucht(_ v: UInt32) -> Double {
            func k(_ c: Double) -> Double { c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4) }
            let r = k(Double((v >> 16) & 0xFF) / 255), g = k(Double((v >> 8) & 0xFF) / 255), bl = k(Double(v & 0xFF) / 255)
            return 0.2126 * r + 0.7152 * g + 0.0722 * bl
        }
        let l1 = leucht(a), l2 = leucht(b)
        return (max(l1, l2) + 0.05) / (min(l1, l2) + 0.05)
    }
}

enum Farbe {
    static let grund = Color(hell: Blattwerk.roseHell, dunkel: Blattwerk.weinrotTief)
    /// Bühne (Ebene 1) – auch der Verlauf oben auf Seiten ohne Bühne
    static let buehne = Color(hell: Blattwerk.rose, dunkel: Blattwerk.weinrot)
    static let grundOben = buehne
    static let karte = Color(hell: 0xFFFFFF, dunkel: Blattwerk.weinrotKarte)
    static let text = Color(hell: Blattwerk.weinrot, dunkel: Blattwerk.rose)
    /// Das große Wort auf der Bühne, die Marke, die Statusleiste
    static let wort = text
    static let zweitrangig = Color(hell: Blattwerk.zweitrangigHell, dunkel: Blattwerk.zweitrangigDunkel)
    static let pfeil = Color(hell: 0xA77A8A, dunkel: 0xB98FA0)
    /// Handlung als Text und Zeichen (lesbar auf dem Grund): hell Grün tief, dunkel Kellygrün
    static let akzent = Color(hell: Blattwerk.gruenTief, dunkel: Blattwerk.gruen)
    /// Handlung als Fläche (Hauptknopf, Ring, Haken, heutiger Tag): Kellygrün – Schrift darauf `aufFarbe`
    static let handlung = Color(roh: "#2DC92A")
    /// Pille, Vorschläge, „dein Normal“, Tab-Pille
    static let akzentWeich = Color(hell: 0xDDF5DC, dunkel: 0x3B4D30)
    /// Schrift und Zeichen auf Grün
    static let aufFarbe = Color(roh: "#2E0816")
    /// Schrift und Zeichen auf Zielfarben-Flächen (`tonArt`): hell sind die Töne dunkel → Weiß; dunkel sind sie hell → Weinrot tief
    static let aufTon = Color(hell: 0xFFFFFF, dunkel: Blattwerk.weinrotTief)
    /// Schatten unter Karte vorn und Objekten (mit Deckkraft verwenden)
    static let schatten = Color(hell: Blattwerk.weinrot, dunkel: 0x000000)
    static let freude = akzent
    /// „hinterher“: Weinrot auf Rosé (dunkel umgekehrt)
    static let warnung = Color(hell: Blattwerk.weinrot, dunkel: Blattwerk.rose)
    static let warnungGrund = Color(hell: Blattwerk.rose, dunkel: Blattwerk.weinrot)
    /// „überfällig“: kräftiges Weinrot, dunkel helles Rosé – kein neuer Farbton
    static let kritisch = Color(hell: 0x8E1B3C, dunkel: 0xFF9FB8)
    static let linie = Color(hell: 0xE6D2D8, dunkel: 0x4E2734)

    // Alte Namen aus Nachtflug – zeigen auf die neuen Rollen, bis alle Seiten umgebaut sind
    static let gold = handlung
    static let goldText = akzent
    static let seladon = handlung
    static let nacht = Color(roh: "#2E0816")

    /// Ziel- und Habit-Farben zur Auswahl – je eine Familie der Palette (gespeichert als Hex, angezeigt über `tonArt`)
    static let ziele = ["#1F7AC2", "#15803D", "#9A6700", "#3B4CCA", "#7A4FD6", "#B8456E"]

    /// Verläufe der Kopf- und Reel-Karten: Weinrot in drei Tönungen (bleiben dunkel, Schrift Rosé/Weiß)
    static let indigo = [Color(roh: "#2E0816"), Color(roh: "#6B1F3F")]
    static let violett = [Color(roh: "#3A0E22"), Color(roh: "#7A2E4A")]
    static let gruen = [Color(roh: "#3A0E22"), Color(roh: "#8E1B3C")]

    /// Töne der Palette für bunte Farben (Ziele, Habits, Kalender): Weinrot- und Rosétöne, zwei Grüntöne
    enum TonArt: CaseIterable, Sendable {
        case weinrot, beere, rosa, wein, gruen, gruenTief
        var farbe: Color {
            switch self {
            case .weinrot: Color(hell: 0x4A0F24, dunkel: 0xF6CBD4)
            case .beere: Color(hell: 0x8E1B3C, dunkel: 0xF4A3B8)
            case .rosa: Color(hell: 0xB04A72, dunkel: 0xF2B5C8)
            case .wein: Color(hell: 0x7A2E4A, dunkel: 0xE8A9C0)
            case .gruen: Color(hell: 0x1B7A1A, dunkel: 0x2DC92A)
            case .gruenTief: Color(hell: 0x2F6B2E, dunkel: 0x8FDC8C)
            }
        }
    }

    /// Welcher Palette-Ton zu einer Hex-Farbe gehört (nach Farbton); nil = dunkel, hell oder grau → Farbe bleibt.
    nonisolated static func tonArt(_ hex: String) -> TonArt? {
        let t = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard t.count == 6, let v = UInt64(t, radix: 16) else { return nil }
        let r = Double((v >> 16) & 0xFF) / 255, g = Double((v >> 8) & 0xFF) / 255, b = Double(v & 0xFF) / 255
        let mx = max(r, g, b), mn = min(r, g, b), l = (mx + mn) / 2, d = mx - mn
        guard d > 0.0001 else { return nil }
        let s = l > 0.5 ? d / (2 - mx - mn) : d / (mx + mn)
        guard s >= 0.25, l >= 0.2, l <= 0.85 else { return nil }
        var h: Double
        if mx == r { h = (g - b) / d + (g < b ? 6 : 0) } else if mx == g { h = (b - r) / d + 2 } else { h = (r - g) / d + 4 }
        h *= 60
        switch h {
        case 35..<75: return .gruenTief      // Gelb, Gold
        case 75..<165: return .gruen         // Grün
        case 165..<228: return .beere        // Cyan, Blau
        case 228..<255: return .weinrot      // Indigo
        case 255..<300: return .rosa         // Violett
        default: return .wein                // Pink, Rot, Orange
        }
    }

    static func verlauf(_ hex: String) -> [Color] {
        let c = Color(hex: hex)
        return [c.mix(with: .black, by: 0.25), c.mix(with: .white, by: 0.18)]
    }
}

enum Mass {
    static let rand: CGFloat = 16
    static let karte: CGFloat = 22
    static let verlaufskarte: CGFloat = 24
    static let abschnitt: CGFloat = 32
    static let ueberschrift: CGFloat = 12
    static let zeile: CGFloat = 64
    static let zeileKompakt: CGFloat = 52
    /// Blattwerk: Bühne, Karte vorn, Knopf
    static let buehne: CGFloat = 360
    static let buehneKurz: CGFloat = 260
    static let buehneLang: CGFloat = 430
    static let karteVorn: CGFloat = 24
    static let karteVornVersatz: CGFloat = -38
    static let knopf: CGFloat = 50
    static let knopfKlein: CGFloat = 40
}

extension Font {
    /// SF Pro Rounded mit Dynamic Type
    static func kompass(_ stil: Font.TextStyle, _ gewicht: Font.Weight = .regular) -> Font {
        .system(stil, design: .rounded, weight: gewicht)
    }
    /// Seitentitel und große Zahlen in Serif (New York), Bedienung bleibt SF Pro Rounded
    static let seitenTitel = Font.system(.largeTitle, design: .serif, weight: .medium)
    static let abschnitt = Font.system(.title2, design: .serif, weight: .regular)
    static let zeile = Font.kompass(.body, .semibold)
    static let unterzeile = Font.kompass(.subheadline, .medium)
    static let klein = Font.kompass(.footnote, .semibold)
    static let grosseZahl = Font.system(.largeTitle, design: .serif, weight: .semibold)
    /// Blattwerk: das Wort auf der Bühne (New York, Großbuchstaben), feste Größe mit Mindestskalierung
    static func wort(_ groesse: CGFloat) -> Font { .system(size: groesse, weight: .regular, design: .serif) }
    /// Titel in der Karte vorn (die eine Sache)
    static let karteTitel = Font.system(size: 26, weight: .regular, design: .serif)
    /// Kennzahl (28) und Uhrzeit rechts in Zeilen (21)
    static let zahl = Font.system(size: 28, weight: .regular, design: .serif)
    static let zahlKlein = Font.system(size: 21, weight: .regular, design: .serif)
    /// Kleines Etikett in Versalien (12, heavy, Laufweite)
    static let etikett = Font.kompass(.caption, .heavy)
    /// Marke oben auf der Bühne (New York 17, Versalien, Laufweite)
    static let marke = Font.system(size: 17, weight: .regular, design: .serif)
}
