import SwiftUI
import UIKit

// Farben, Maße und Schrift nach docs/produkt/design.md (Vorbild Gapless „Harbor 2“, kein geteilter Code).

extension Color {
    init(hex: String) {
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

enum Farbe {
    static let grund = Color(hell: 0xF2F2F7, dunkel: 0x000000)
    static let grundOben = Color(hell: 0xD9DFFA, dunkel: 0x171D4D)
    static let karte = Color(hell: 0xFFFFFF, dunkel: 0x1C1C1E)
    static let text = Color(hell: 0x18233F, dunkel: 0xF2F2F7)
    static let zweitrangig = Color(hell: 0x4D5262, dunkel: 0xA1A1A6)
    static let pfeil = Color(hell: 0x7E8391, dunkel: 0x8E8E93)
    static let akzent = Color(hell: 0x3B4CCA, dunkel: 0x9AA6FF)
    static let akzentWeich = Color(hell: 0xE6E9FC, dunkel: 0x262D63)
    static let freude = Color(hell: 0x1F9D55, dunkel: 0x5EE0B5)
    static let warnung = Color(hell: 0x8A5300, dunkel: 0xFFC266)
    static let warnungGrund = Color(hell: 0xFFF3DC, dunkel: 0x2E2614)
    static let kritisch = Color(hell: 0xBA3228, dunkel: 0xFF7A6E)
    static let linie = Color(hell: 0xE3E5EC, dunkel: 0x2C2C2E)

    /// Ziel-Farben (Reihe wie Gapless `chartSeries`)
    static let ziele = ["#3B4CCA", "#7A4FD6", "#1F7AC2", "#0E8580", "#B8456E", "#9A6700", "#C2410C", "#15803D", "#A21CAF", "#6B7285"]

    /// Verläufe der Kopfkarten (tief → hell)
    static let indigo = [Color(hex: "#2A36A0"), Color(hex: "#5B6BE0")]
    static let violett = [Color(hex: "#5A33B0"), Color(hex: "#9670E8")]
    static let gruen = [Color(hex: "#0F6E3C"), Color(hex: "#2FB36C")]

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
    static let seitenTitel = Font.kompass(.largeTitle, .heavy)
    static let abschnitt = Font.kompass(.title2, .bold)
    static let zeile = Font.kompass(.body, .semibold)
    static let unterzeile = Font.kompass(.subheadline, .medium)
    static let klein = Font.kompass(.footnote, .semibold)
    static let grosseZahl = Font.kompass(.largeTitle, .heavy)
}
