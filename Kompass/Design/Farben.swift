import SwiftUI
import UIKit

// Farben, Maße und Schrift nach docs/produkt/design.md (Vorbild Gapless „Harbor 2“, kein geteilter Code).

extension Color {
    /// Farbe aus Hex – bunte Farben (Ziele, Habits, Kalender) werden auf die Nachtflug-Palette gelegt
    /// (Indigo, Seladon, Gold; je hell/dunkel). Dunkle, helle und graue Farben bleiben, wie sie sind.
    init(hex: String) {
        if let t = Farbe.tonArt(hex) { self = t.farbe } else { self.init(roh: hex) }
    }

    /// Farbe genau aus Hex, ohne Palette
    init(roh hex: String) {
        let s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let v = UInt64(s, radix: 16) ?? 0x3B4CCA
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

/// Nachtflug (Entscheidung 24.11.2026): Indigo trägt, Seladon ist die Handlung, Gold zeigt, was zählt. Hell und dunkel.
enum Farbe {
    static let grund = Color(hell: 0xF3F6F4, dunkel: 0x0B1325)
    static let grundOben = Color(hell: 0xE1ECE7, dunkel: 0x1A2950)
    static let karte = Color(hell: 0xFFFFFF, dunkel: 0x121D38)
    static let text = Color(hell: 0x0B1325, dunkel: 0xEAF1EE)
    static let zweitrangig = Color(hell: 0x56657A, dunkel: 0x93A3B8)
    static let pfeil = Color(hell: 0x7E8A9A, dunkel: 0x6F7E96)
    /// Handlung: Seladon (hell tief, dunkel hell)
    static let akzent = Color(hell: 0x3A7262, dunkel: 0xA9CDBE)
    static let akzentWeich = Color(hell: 0xDCEBE4, dunkel: 0x22364A)
    /// Schrift und Zeichen auf Akzent- und Palette-Flächen
    static let aufFarbe = Color(hell: 0xFFFFFF, dunkel: 0x0B1325)
    /// Gold: Ziele, Fortschritt, Erfolg (Fläche/Ring) und als Text (hell tief genug für Kontrast)
    static let gold = Color(roh: "#F2B53A")
    static let goldText = Color(hell: 0x855B00, dunkel: 0xF2B53A)
    static let seladon = Color(roh: "#A9CDBE")
    static let nacht = Color(roh: "#0B1325")
    static let freude = Color(hell: 0x2F6E58, dunkel: 0x8CCBA8)
    static let warnung = Color(hell: 0x855B00, dunkel: 0xF2B53A)
    static let warnungGrund = Color(hell: 0xFBF1DA, dunkel: 0x2A2516)
    static let kritisch = Color(hell: 0xBA3228, dunkel: 0xFF7A6E)
    static let linie = Color(hell: 0xE2E8E5, dunkel: 0x1F2C4A)

    /// Ziel- und Habit-Farben zur Auswahl – je eine Familie der Palette (gespeichert als Hex, angezeigt über `tonArt`)
    static let ziele = ["#1F7AC2", "#15803D", "#9A6700", "#3B4CCA", "#7A4FD6", "#B8456E"]

    /// Verläufe der Kopf- und Reel-Karten: Nacht in drei Tönungen (bleiben dunkel, Schrift weiß)
    static let indigo = [Color(roh: "#0F1A35"), Color(roh: "#24396E")]
    static let violett = [Color(roh: "#14182F"), Color(roh: "#3B3A6A")]
    static let gruen = [Color(roh: "#0E1F2A"), Color(roh: "#24504A")]

    /// Töne der Palette für bunte Farben (Ziele, Habits, Kalender)
    enum TonArt: CaseIterable, Sendable {
        case seladon, seladonTief, indigoHell, goldHell, gold, goldTief
        var farbe: Color {
            switch self {
            case .seladon: Color(hell: 0x3A7262, dunkel: 0xA9CDBE)
            case .seladonTief: Color(hell: 0x2F5E50, dunkel: 0x6FA592)
            case .indigoHell: Color(hell: 0x2B3A66, dunkel: 0x8E9CC9)
            case .goldHell: Color(hell: 0x855B00, dunkel: 0xF7D58A)
            case .gold: Color(hell: 0x9A6A00, dunkel: 0xF2B53A)
            case .goldTief: Color(hell: 0x8A4B12, dunkel: 0xE0A04A)
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
        case 35..<75: return .gold
        case 75..<165: return .seladonTief
        case 165..<228: return .seladon
        case 228..<255: return .indigoHell
        case 255..<320: return .goldHell
        default: return .goldTief
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
}

extension Font {
    /// SF Pro Rounded mit Dynamic Type
    static func kompass(_ stil: Font.TextStyle, _ gewicht: Font.Weight = .regular) -> Font {
        .system(stil, design: .rounded, weight: gewicht)
    }
    /// Nachtflug: Seitentitel und große Zahlen in Serif (New York), Bedienung bleibt SF Pro Rounded
    static let seitenTitel = Font.system(.largeTitle, design: .serif, weight: .medium)
    static let abschnitt = Font.kompass(.title2, .bold)
    static let zeile = Font.kompass(.body, .semibold)
    static let unterzeile = Font.kompass(.subheadline, .medium)
    static let klein = Font.kompass(.footnote, .semibold)
    static let grosseZahl = Font.system(.largeTitle, design: .serif, weight: .semibold)
}
