import SwiftUI

/// Die Compass-Figur: eine leuchtende Kugel aus bewegtem Farbnetz – eigene Zeichnung statt des Vorbild-Steins. Kein Bild, keine Lizenz.
struct Figur: View {
    enum Zustand: Sendable, Equatable {
        /// Matt grau – wie der Stein vor dem Aufbrechen (Intro, Meilenstein nicht erreicht)
        case stein
        /// Ruhig leuchtend (Standard)
        case ruhig
        /// Pulsiert schneller (Assistent schreibt, wertet aus)
        case denkt
        /// Grün hell (Erfolg)
        case erfolg
        /// Lila (Pro, Belohnung)
        case belohnung
    }

    var zustand: Zustand = .ruhig
    var groesse: CGFloat = 90
    @Environment(\.accessibilityReduceMotion) private var ruhig

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: ruhig)) { kontext in
            let t = ruhig ? 0 : kontext.date.timeIntervalSinceReferenceDate * tempo
            ZStack {
                // Schein um die Kugel
                Circle()
                    .fill(RadialGradient(colors: [schein.opacity(zustand == .stein ? 0.15 : 0.55), .clear],
                                         center: .center, startRadius: groesse * 0.2, endRadius: groesse * 1.1))
                    .frame(width: groesse * 2.2, height: groesse * 2.2)
                    .scaleEffect(1 + 0.04 * sin(t * 0.9))
                MeshGradient(width: 3, height: 3, points: punkte(t), colors: farben(t))
                    .frame(width: groesse * 1.12, height: groesse * 1.2)
                    .frame(width: groesse, height: groesse * 1.08)
                    .clipShape(Form(t: t))
                    .overlay {
                        // Tiefe: Rand dunkler, Mitte hell
                        Form(t: t).fill(RadialGradient(colors: [.clear, .clear, .black.opacity(zustand == .stein ? 0.35 : 0.22)],
                                                       center: UnitPoint(x: 0.42, y: 0.4), startRadius: 0, endRadius: groesse * 0.62))
                    }
                    .overlay {
                        // Glanz oben links
                        Form(t: t).fill(RadialGradient(colors: [.white.opacity(zustand == .stein ? 0.12 : 0.55), .clear],
                                                       center: UnitPoint(x: 0.32, y: 0.24), startRadius: 0, endRadius: groesse * 0.45))
                    }
                    .overlay { Form(t: t).stroke(.white.opacity(0.25), lineWidth: 1) }
                    .rotationEffect(.degrees(sin(t * 0.3) * 6))
                    .shadow(color: schein.opacity(zustand == .stein ? 0 : 0.6), radius: groesse * 0.25)
            }
        }
        .frame(width: groesse * 2.2, height: groesse * 2.2)
        .animation(.easeInOut(duration: 0.8), value: zustand)
        .accessibilityHidden(true)
    }

    private var tempo: Double { zustand == .denkt ? 1.6 : 0.6 }

    private var schein: Color {
        switch zustand {
        case .stein: .gray
        case .ruhig, .denkt: Color(Dunkel.akzentB)
        case .erfolg: Color(Dunkel.akzentA)
        case .belohnung: Color(Dunkel.pro)
        }
    }

    private func punkte(_ t: Double) -> [SIMD2<Float>] {
        let w = { (p: Double) in Float(0.5 + 0.18 * sin(t + p)) }
        return [[0, 0], [w(0), 0], [1, 0],
                [0, w(1.3)], [w(2.1), Float(0.5 + 0.16 * cos(t * 0.8))], [1, w(3.4)],
                [0, 1], [w(4.2), 1], [1, 1]]
    }

    private func farben(_ t: Double) -> [Color] {
        let satz: [Color]
        switch zustand {
        case .stein: satz = [0x6E6E70, 0x8A8A8C, 0x505052, 0x9A9A9C, 0x7A7A7C].map { Color($0) }
        case .belohnung: satz = [0x6F63B0, 0xB8A8FF, 0x3E7BFA, 0xFF7AD9, 0x2FD3C6].map { Color($0) }
        default: satz = [0xA9FBEF, 0xD3FFA0, 0x7FB8FF, 0xFFD6F0, 0x9AF0C4].map { Color($0) }
        }
        // Farben wandern langsam durch das Netz
        let k = Int((t / 3).rounded(.down))
        return (0..<9).map { satz[($0 + k) % satz.count] }
    }
}

/// Weiche, leicht unregelmäßige Kugel-Form, die sich langsam verformt.
private struct Form: Shape {
    var t: Double
    func path(in r: CGRect) -> Path {
        var p = Path()
        let n = 64
        for i in 0...n {
            let a = Double(i) / Double(n) * 2 * .pi
            let wackel = 1 + 0.035 * sin(3 * a + t) + 0.025 * cos(2 * a - t * 0.7)
            let x = r.midX + cos(a) * r.width / 2 * wackel
            let y = r.midY + sin(a) * r.height / 2 * wackel
            if i == 0 { p.move(to: CGPoint(x: x, y: y)) } else { p.addLine(to: CGPoint(x: x, y: y)) }
        }
        p.closeSubpath()
        return p
    }
}

/// Benannter Bildplatz in Originalgröße des Vorbilds: zeigt das Bild aus `Assets.xcassets`, wenn es dort liegt,
/// sonst `ersatz` (eigener Inhalt). So lassen sich lizenzierte Original-Dateien ohne Codeänderung einsetzen.
struct BildPlatz<Ersatz: View>: View {
    var name: String
    @ViewBuilder var ersatz: Ersatz
    var body: some View {
        if UIImage(named: name) != nil {
            Image(name).resizable().scaledToFill().accessibilityHidden(true)
        } else {
            ersatz
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack { Figur(zustand: .stein, groesse: 60); Figur(zustand: .ruhig, groesse: 60) }
        HStack { Figur(zustand: .erfolg, groesse: 60); Figur(zustand: .belohnung, groesse: 60) }
    }
    .dunkelGrund()
}
