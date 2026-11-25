import SwiftUI
import UIKit

// Farben, Maße und Schrift nach docs/produkt/design.md (Vorbild Gapless „Harbor 2“, kein geteilter Code).
// Nachtblau (Entscheidung 25.11.2026): Nachtblau trägt, Creme spricht, Schwarz ist die Handlung – hell und dunkel.
// Messing ist die eine warme Marke („jetzt“) und sonst nirgends. Löst Blattwerk (Rosé/Weinrot/Grün) ab.

extension Color {
    /// Farbe aus Hex – bunte Farben (Ziele, Habits, Kalender) werden auf die Nachtblau-Palette gelegt
    /// (Blau-, Dunst- und Schiefertöne; je hell/dunkel). Dunkle, helle und graue Farben bleiben, wie sie sind.
    init(hex: String) {
        if let t = Farbe.tonArt(hex) { self = t.farbe } else { self.init(roh: hex) }
    }

    /// Farbe genau aus Hex, ohne Palette
    init(roh hex: String) {
        let s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let v = UInt64(s, radix: 16) ?? 0x33475F
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

/// Die Nachtblau-Palette als Zahlen – damit Tests Kontraste rechnen können (WCAG).
enum Nachtblau {
    // Hell
    static let creme: UInt32 = 0xF3F1E6
    static let cremeKarte: UInt32 = 0xFDFCF6
    static let papier: UInt32 = 0xFBF9F1
    static let blau: UInt32 = 0x33475F
    static let blauOben: UInt32 = 0x26364B
    static let blauUnten: UInt32 = 0x415671
    static let schwarz: UInt32 = 0x141B24
    static let akzentHell: UInt32 = 0x3F5571
    static let zweitrangigHell: UInt32 = 0x5E6B7C
    static let linieHell: UInt32 = 0xD6D5CD
    static let weichHell: UInt32 = 0xDCDDD6
    // Dunkel
    static let nacht: UInt32 = 0x0F141B
    static let nachtKarte: UInt32 = 0x182029
    static let nachtPapier: UInt32 = 0x1F2935
    static let blauDunkel: UInt32 = 0x141C27
    static let blauDunkelOben: UInt32 = 0x0B1017
    static let blauDunkelUnten: UInt32 = 0x1E2A39
    static let zweitrangigDunkel: UInt32 = 0x9AA8B9
    static let linieDunkel: UInt32 = 0x2F3337
    static let weichDunkel: UInt32 = 0x262A2F
    // Beide
    static let dunst: UInt32 = 0x9FBAD6
    static let messing: UInt32 = 0xC9A227

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
    static let grund = Color(hell: Nachtblau.creme, dunkel: Nachtblau.nacht)
    /// Bühne (Ebene 1) als Fläche; der Verlauf dazu in `buehneVerlauf`
    static let buehne = Color(hell: Nachtblau.blau, dunkel: Nachtblau.blauDunkel)
    static let buehneVerlauf = [Color(hell: Nachtblau.blauOben, dunkel: Nachtblau.blauDunkelOben),
                                Color(hell: Nachtblau.blau, dunkel: Nachtblau.blauDunkel),
                                Color(hell: Nachtblau.blauUnten, dunkel: Nachtblau.blauDunkelUnten)]
    static let grundOben = buehne
    /// Lichtkegel hinter dem Wort (Ebene 1a) – mit Deckkraft verwenden
    static let schein = Color(hell: 0x9EBCDC, dunkel: 0x6084B0)
    static let karte = Color(hell: Nachtblau.cremeKarte, dunkel: Nachtblau.nachtKarte)
    /// Die Bordkarte (Statistik): einen Hauch wärmer als die Karte
    static let papier = Color(hell: Nachtblau.papier, dunkel: Nachtblau.nachtPapier)
    static let text = Color(hell: Nachtblau.schwarz, dunkel: Nachtblau.creme)
    /// Das große Wort auf der Bühne, die Marke, die Statusleiste: immer Creme
    static let wort = Color(roh: "#F3F1E6")
    /// Das letzte Wort auf der Bühne: Dunst
    static let wortAkzent = Color(roh: "#9FBAD6")
    static let zweitrangig = Color(hell: Nachtblau.zweitrangigHell, dunkel: Nachtblau.zweitrangigDunkel)
    static let pfeil = Color(hell: 0x8C98A8, dunkel: 0x6F7C8C)
    /// Handlung als Text und Zeichen (lesbar auf dem Grund): hell Nachtblau, dunkel Dunst
    static let akzent = Color(hell: Nachtblau.akzentHell, dunkel: Nachtblau.dunst)
    /// Handlung als Fläche (Hauptknopf, Ring, Haken, gewählter Tag): hell Schwarz, dunkel Creme – Schrift darauf `aufFarbe`
    static let handlung = Color(hell: Nachtblau.schwarz, dunkel: Nachtblau.creme)
    /// Die eine warme Marke: Punkt am heutigen Tag, Zeitlinie, Strecke im Fokus – sonst nirgends
    static let jetzt = Color(roh: "#C9A227")
    /// Pille, Vorschläge, „dein Normal“, Tab-Pille
    static let akzentWeich = Color(hell: Nachtblau.weichHell, dunkel: Nachtblau.weichDunkel)
    /// Schrift und Zeichen auf der Handlungsfläche
    static let aufFarbe = Color(hell: Nachtblau.creme, dunkel: Nachtblau.nacht)
    /// Schrift und Zeichen auf Zielfarben-Flächen (`tonArt`): hell sind die Töne dunkel → Creme; dunkel sind sie hell → Nacht
    static let aufTon = Color(hell: Nachtblau.creme, dunkel: Nachtblau.nacht)
    /// Schatten unter Karte vorn (mit Deckkraft verwenden)
    static let schatten = Color(hell: Nachtblau.schwarz, dunkel: 0x000000)
    static let freude = akzent
    /// „hinterher“: Nachtblau auf Dunst hell (dunkel umgekehrt)
    static let warnung = Color(hell: Nachtblau.blau, dunkel: Nachtblau.dunst)
    static let warnungGrund = Color(hell: 0xDCE4EE, dunkel: 0x22303F)
    /// „überfällig“: Creme auf Nachtblau, dunkel Nacht auf Creme – kein neuer Farbton
    static let kritisch = Color(hell: Nachtblau.creme, dunkel: Nachtblau.nacht)
    static let kritischGrund = Color(hell: Nachtblau.blau, dunkel: Nachtblau.creme)
    static let linie = Color(hell: Nachtblau.linieHell, dunkel: Nachtblau.linieDunkel)

    /// Ziel- und Habit-Farben zur Auswahl – je eine Familie der Palette (gespeichert als Hex, angezeigt über `tonArt`)
    static let ziele = ["#1F7AC2", "#15803D", "#9A6700", "#3B4CCA", "#7A4FD6", "#B8456E"]

    /// Töne der Palette für bunte Farben (Ziele, Habits, Kalender): Blau-, Dunst- und Schiefertöne
    enum TonArt: CaseIterable, Sendable {
        case weinrot, beere, rosa, wein, gruen, gruenTief
        var farbe: Color {
            switch self {
            case .weinrot: Color(hell: 0x33475F, dunkel: 0x9FBAD6)   // Nachtblau · Dunst
            case .beere: Color(hell: 0x2A3F58, dunkel: 0xB7CBE2)     // tief · hell
            case .rosa: Color(hell: 0x5E6B7C, dunkel: 0xC5CED9)      // Schiefer
            case .wein: Color(hell: 0x4B6480, dunkel: 0x8FA9C8)      // Stahl
            case .gruen: Color(hell: 0x3F5571, dunkel: 0xA6BED8)     // Nachtblau hell
            case .gruenTief: Color(hell: 0x6E7B4F, dunkel: 0xC9A227) // Oliv · Messing (Gold, Gelb)
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
    /// Nachtblau: Bühne, Karte vorn, Knopf
    static let buehne: CGFloat = 360
    static let buehneKurz: CGFloat = 250
    static let buehneLang: CGFloat = 430
    static let karteVorn: CGFloat = 28
    static let karteVornVersatz: CGFloat = -44
    static let knopf: CGFloat = 50
    static let knopfKlein: CGFloat = 40
    /// Saum: die untersten Punkte der Bühne laufen in den Grund aus (kurz 112, lang 190)
    static func saum(fuer hoehe: CGFloat) -> CGFloat { hoehe <= buehneKurz ? 112 : hoehe >= buehneLang ? 190 : 160 }
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
    /// Das Wort auf der Bühne (New York, Großbuchstaben), feste Größe mit Mindestskalierung
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
