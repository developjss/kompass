import SwiftUI

/// Compass – Neustart am 27.11.2026. Aufbau und Abläufe nach dem Vorbild (siehe `docs/plan.md`), nur dunkel.
@main
struct CompassApp: App {
    var body: some Scene {
        WindowGroup {
            Group {
                if ProcessInfo.processInfo.arguments.contains("-designVorschau") { DesignVorschau() } else { Hauptansicht() }
            }
            .preferredColorScheme(.dark)
        }
    }
}

/// Die drei Bereiche des Vorbilds.
enum Bereich: String, CaseIterable, Hashable {
    case home, apps, habits

    var titel: String {
        switch self {
        case .home: "Home"
        case .apps: "Meine Apps"
        case .habits: "Mein Weg"   // später englisch „Path“
        }
    }

    var symbol: String {
        switch self {
        case .home: "pentagon"
        case .apps: "square.grid.2x2.fill"
        case .habits: "play.fill"
        }
    }
}

/// Gerüst: Seite, darüber schwebend die laufende Sitzung und die Tab-Kapsel der Vorlage (294 × 60 pt).
struct Hauptansicht: View {
    @State private var bereich: Bereich = .home

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch bereich {
                case .home: HomeAnsicht()
                case .habits: HabitsAnsicht()
                case .apps: LeereSeite(bereich: bereich)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // Unterkante: Inhalt läuft weich ins Schwarz
            LinearGradient(colors: [.clear, .black.opacity(0.85), .black], startPoint: .top, endPoint: .bottom)
                .frame(height: 190).allowsHitTesting(false).ignoresSafeArea()
            VStack(spacing: 16) {
                if bereich == .home { SitzungsLeiste() }
                TabKapsel(bereich: $bereich)
            }
            .padding(.bottom, 52)
        }
        .ignoresSafeArea(edges: .bottom)
        .background(DFarbe.grund.ignoresSafeArea())
    }
}

/// Tab-Kapsel: dunkles Glas, aktiver Tab hell mit eigener dunkler Fläche und Schimmer.
struct TabKapsel: View {
    @Binding var bereich: Bereich
    @Namespace private var raum

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Bereich.allCases, id: \.self) { b in
                let an = b == bereich
                Button { withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) { bereich = b } } label: {
                    VStack(spacing: 5) {
                        Group {
                            if b == .habits { WegSymbol().frame(width: 28, height: 28) }
                            else { Image(systemName: b.symbol).font(.system(size: 21, weight: .semibold)) }
                        }
                        .frame(height: 24)
                        Text(b.titel).font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(an ? Color.white : Color(0x8B908D))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background {
                        if an {
                            Capsule().fill(LinearGradient(colors: [Color(0x0A0B0A), Color(0x13201B)], startPoint: .top, endPoint: .bottom))
                                .overlay(alignment: .bottom) { Capsule().fill(Color(0x5FE3C0).opacity(0.28)).frame(width: 46, height: 8).blur(radius: 7) }
                                .padding(4)
                                .matchedGeometryEffect(id: "aktiv", in: raum)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("tab.\(b.rawValue)")
                .accessibilityAddTraits(an ? .isSelected : [])
            }
        }
        .frame(width: 294, height: 60)
        .background {
            ZStack {
                Capsule().fill(.ultraThinMaterial)
                Capsule().fill(Color(0x121413).opacity(0.86))
            }
        }
        .overlay { Capsule().strokeBorder(LinearGradient(colors: [.white.opacity(0.2), .white.opacity(0.04)], startPoint: .top, endPoint: .bottom), lineWidth: 1) }
        .shadow(color: .black.opacity(0.6), radius: 16, y: 8)
    }
}

/// Laufende Sitzung über der Tab-Kapsel: Glas-Kapsel 355 × 49 pt, Restzeit läuft, Lichtkante unten wandert.
struct SitzungsLeiste: View {
    @Environment(\.accessibilityReduceMotion) private var ruhig
    private let start = Date()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: ruhig)) { k in
            let t = k.date.timeIntervalSince(start)
            let rest = max(0, 4 * 3600 + 18 * 60 + 20 - Int(t))
            HStack(spacing: 12) {
                ZStack(alignment: .bottomTrailing) {
                    AppKachel(symbol: "camera.fill", farben: [Color(0xF9CE34), Color(0xEE2A7B), Color(0x6228D7)], groesse: 26).offset(x: -8, y: -4)
                    AppKachel(symbol: "graduationcap.fill", farben: [Color(0x3B6FE0), Color(0x23408F)], groesse: 22).offset(x: 6, y: -6)
                    Text("+2").font(.system(size: 10, weight: .bold)).padding(.horizontal, 4).frame(height: 15)
                        .background(Color(0x3A3F3C), in: RoundedRectangle(cornerRadius: 5, style: .continuous)).offset(x: 6, y: 5)
                }
                .frame(width: 44)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Lernzeit").font(.system(size: 15, weight: .semibold))
                    Text(String(format: "%d:%02d:%02d", rest / 3600, rest / 60 % 60, rest % 60)).font(.system(size: 14)).foregroundStyle(Color(0xA3A8A5)).monospacedDigit()
                }
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "lock.open.fill").font(.system(size: 12, weight: .bold))
                    Text("Entsperren").font(.system(size: 15, weight: .semibold))
                }
            }
            .padding(.leading, 16).padding(.trailing, 18)
            .frame(width: 355, height: 49)
            .background {
                ZStack {
                    Capsule().fill(.ultraThinMaterial)
                    Capsule().fill(LinearGradient(colors: [Color(0x16211D).opacity(0.9), Color(0x10302A).opacity(0.92)], startPoint: .top, endPoint: .bottom))
                    // wandernde Lichtkante
                    Capsule().fill(LinearGradient(colors: [.clear, Color(0x5FE3C0), Color(0xB9FFE9), Color(0x5FE3C0), .clear], startPoint: .leading, endPoint: .trailing))
                        .frame(width: 210, height: 3).blur(radius: 2.5)
                        .offset(x: ruhig ? 0 : CGFloat(sin(t * 0.9)) * 60, y: 23)
                }
                .clipShape(Capsule())
            }
            .overlay { Capsule().strokeBorder(LinearGradient(colors: [.white.opacity(0.22), Color(0x5FE3C0).opacity(0.25)], startPoint: .top, endPoint: .bottom), lineWidth: 1) }
            .shadow(color: .black.opacity(0.55), radius: 14, y: 6)
        }
        .foregroundStyle(DFarbe.text)
        .accessibilityElement(children: .combine)
    }
}

/// Platzhalter je Bereich, bis der Block dazu gebaut ist.
struct LeereSeite: View {
    var bereich: Bereich
    var body: some View {
        VStack(spacing: 12) {
            Figur(zustand: .ruhig, groesse: 90)
            Text(bereich.titel).font(DSchrift.grosserTitel)
            Text("Wird neu gebaut.").font(DSchrift.zeile).foregroundStyle(DFarbe.zweitrangig)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .strahlenGrund()
        .accessibilityIdentifier("seite.\(bereich.rawValue)")
    }
}

/// Zeichen für „Mein Weg“ (Vorlage des Gründers): zwei Punkte, eine geschwungene Linie, in der Mitte ein Pfeil –
/// einfarbig in der Farbe des Tabs (der Pfeil bleibt grau bzw. weiß wie der Rest, nicht blau).
struct WegSymbol: View {
    var body: some View {
        Canvas { ctx, g in
            let s = min(g.width, g.height) / 24
            func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * s, y: y * s) }
            let farbe = GraphicsContext.Shading.foreground
            let strich = StrokeStyle(lineWidth: 1.9 * s, lineCap: .round, lineJoin: .round)
            // Punkte (Ringe)
            for m in [p(20.4, 4.4), p(3.6, 19.6)] {
                ctx.stroke(Path(ellipseIn: CGRect(x: m.x - 2.4 * s, y: m.y - 2.4 * s, width: 4.8 * s, height: 4.8 * s)), with: farbe, style: strich)
            }
            // Linie oben und unten
            var oben = Path(); oben.move(to: p(18.0, 4.6)); oben.addCurve(to: p(13.6, 6.9), control1: p(15.9, 4.6), control2: p(14.4, 5.4))
            var unten = Path(); unten.move(to: p(6.0, 19.6)); unten.addCurve(to: p(10.6, 17.6), control1: p(8.2, 19.6), control2: p(9.7, 19.0))
            ctx.stroke(oben, with: farbe, style: strich); ctx.stroke(unten, with: farbe, style: strich)
            // Pfeil in der Mitte
            var pfeil = Path()
            pfeil.move(to: p(15.9, 8.6)); pfeil.addLine(to: p(8.3, 12.6)); pfeil.addLine(to: p(11.5, 13.1)); pfeil.addLine(to: p(12.8, 16.0)); pfeil.closeSubpath()
            ctx.fill(pfeil, with: farbe)
            ctx.stroke(pfeil, with: farbe, style: StrokeStyle(lineWidth: 0.7 * s, lineJoin: .round))
        }
        .accessibilityHidden(true)
    }
}
