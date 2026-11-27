import SwiftUI

/// Home – Aussehen nach der Vorlage des Gründers (27.11.2026), noch ohne Funktionen: feste Beispielwerte.
/// Maße in pt aus der Vorlage (393 × 854): Kopf y 72 · Bühne bis 383 · Werte 392–435 · Karte 1 464–590 · Karte 2 ab 607.
struct HomeAnsicht: View {
    @State private var da = false
    @State private var scroll: CGFloat = 0
    @State private var serieOffen = false
    @Environment(\.accessibilityReduceMotion) private var ruhig

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ZStack(alignment: .top) {
                    HomeBuehne(scroll: scroll)
                    kopf.padding(.top, 58)
                }
                werte.padding(.top, 9)
                VStack(spacing: 17) {
                    ImmerErlaubtKarte().erscheint(da, 0)
                    BildschirmzeitKarte().erscheint(da, 1)
                    SerieKarte().erscheint(da, 2)
                }
                .padding(.horizontal, 17)
                .padding(.top, 29)
                .padding(.bottom, 170)
            }
        }
        .ignoresSafeArea(edges: .top)
        .scrollIndicators(.hidden)
        .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y + $0.contentInsets.top } action: { _, neu in scroll = neu }
        .background(DFarbe.grund.ignoresSafeArea())
        .foregroundStyle(DFarbe.text)
        .onAppear { withAnimation(ruhig ? nil : .easeOut(duration: 1.1)) { da = true } }
        .sheet(isPresented: $serieOffen) { SerieBlatt(serie: 1) }
    }

    // MARK: Kopf – Schriftzug, Flamme, Pro, Profil

    private var kopf: some View {
        HStack(spacing: 0) {
            Text("Compass").font(.system(size: 28, weight: .semibold)).tracking(-0.4)
                .shadow(color: .black.opacity(0.5), radius: 6)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 8)
            Button { serieOffen = true } label: {
                HStack(spacing: 7) {
                    Flamme(groesse: 17)
                    Text("1").font(.system(size: 17, weight: .semibold)).foregroundStyle(Color(0xF2C879))
                }
                .frame(minWidth: 44, minHeight: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Serie: 1 Tag")
            Text("PRO").font(.system(size: 11, weight: .bold)).tracking(0.4)
                .foregroundStyle(Color(0xC9BEFF))
                .padding(.horizontal, 8).frame(height: 19)
                .background(Color(0x1D1A33).opacity(0.85), in: Capsule())
                .overlay { Capsule().strokeBorder(Color(0x8F82E8), lineWidth: 1) }
                .padding(.leading, 14)
                .accessibilityLabel("Pro")
            Image(systemName: "person.fill").font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(0x9FF3D2))
                .frame(width: 34, height: 36)
                .background { SchildForm().fill(Color(0x10231C).opacity(0.9)) }
                .overlay { SchildForm().stroke(Color(0x7FE9C0), lineWidth: 1.2) }
                .padding(.leading, 6)
                .accessibilityLabel("Profil")
        }
        .padding(.leading, 24).padding(.trailing, 20)
    }

    // MARK: Werte – drei Spalten mit Trennlinien

    private var werte: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 5) {
                etikett("Wert")
                HStack(spacing: 8) {
                    ZaehlZahl(ziel: da ? 79 : 0).font(.system(size: 26, weight: .semibold))
                    Image(systemName: "triangle.fill").font(.system(size: 10)).foregroundStyle(Color(0x5FE3C0))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 22)
            trenner
            VStack(alignment: .leading, spacing: 5) {
                etikett("Bildschirmzeit")
                Text("2h 4m").font(.system(size: 26, weight: .semibold)).minimumScaleFactor(0.7).lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 30).frame(width: 142, alignment: .leading)
            trenner
            VStack(alignment: .leading, spacing: 7) {
                etikett("Ablenker")
                HStack(spacing: 5) {
                    AppKachel(symbol: "camera.fill", farben: [Color(0xF9CE34), Color(0xEE2A7B), Color(0x6228D7)], groesse: 19)
                    AppKachel(symbol: "music.note", farben: [Color(0x1ED760), Color(0x17A84A)], groesse: 19, rund: true)
                    AppKachel(symbol: "message.fill", farben: [Color(0x5BF675), Color(0x25D366)], groesse: 19)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 24)
        }
        .padding(.horizontal, 17)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Wert 79, Bildschirmzeit 2 Stunden 4 Minuten, drei Ablenker")
    }

    private func etikett(_ t: String) -> some View {
        Text(t.uppercased()).font(.system(size: 12, weight: .medium)).tracking(0.3).foregroundStyle(Color(0x9EF0CF)).lineLimit(1).minimumScaleFactor(0.8)
    }

    private var trenner: some View { Rectangle().fill(Color.white.opacity(0.14)).frame(width: 1, height: 43) }
}

// MARK: - Bühne

/// Bühnenbild (Kompass im Glas auf dem Fels, Flugzeug auf dem Vorfeld) – eigenes Bild des Gründers.
/// Bewegung: langsames Atmen des Bildes, pulsierender Schein am Kompass, beim Scrollen Parallaxe und Ausblenden.
private struct HomeBuehne: View {
    var scroll: CGFloat
    @Environment(\.accessibilityReduceMotion) private var ruhig

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: ruhig)) { k in
            let t = ruhig ? 0 : k.date.timeIntervalSinceReferenceDate
            ZStack {
                Image("home-buehne").resizable().scaledToFill()
                    .scaleEffect(1.03 + 0.012 * sin(t * 0.35))
                // Schein am Kompass (liegt bei 51 % der Breite, 55 % der Höhe)
                GeometryReader { g in
                    Circle()
                        .fill(RadialGradient(colors: [Color(0x66FFE6).opacity(0.33 + 0.12 * sin(t * 1.1)), .clear], center: .center, startRadius: 4, endRadius: 96))
                        .frame(width: 200, height: 200)
                        .position(x: g.size.width * 0.5, y: g.size.height * 0.55)
                        .blendMode(.screen)
                }
            }
        }
        .frame(height: 400)
        .frame(maxWidth: .infinity)
        .clipped()
        .mask(LinearGradient(stops: [.init(color: .black, location: 0), .init(color: .black, location: 0.8), .init(color: .clear, location: 1)], startPoint: .top, endPoint: .bottom))
        .offset(y: ruhig ? 0 : max(0, scroll) * 0.35)
        .opacity(1 - min(0.75, max(0, scroll) / 320))
        .scaleEffect(scroll < 0 ? 1 + (-scroll / 400) : 1, anchor: .top)
        .accessibilityHidden(true)
    }
}

// MARK: - Karten

/// Glaskarte der Vorlage: Radius 28, dunkles Glas mit grünem Schimmer, feiner Rand, der oben heller ist.
struct HomeGlas<Inhalt: View>: View {
    var schimmer: Color = Color(0x1B3A30)
    @ViewBuilder var inhalt: Inhalt
    var body: some View {
        inhalt
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous).fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(LinearGradient(colors: [Color(0x0E1512).opacity(0.92), Color(0x0A0D0C).opacity(0.96)], startPoint: .top, endPoint: .bottom))
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(RadialGradient(colors: [schimmer.opacity(0.75), .clear], center: UnitPoint(x: 0.75, y: 1.15), startRadius: 0, endRadius: 230))
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(LinearGradient(colors: [.white.opacity(0.2), .white.opacity(0.05), Color(0x5FE3C0).opacity(0.14)], startPoint: .top, endPoint: .bottom), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: .black.opacity(0.5), radius: 14, y: 8)
    }
}

private struct ImmerErlaubtKarte: View {
    var body: some View {
        HomeGlas {
            HStack(alignment: .center, spacing: 0) {
                ZStack {
                    AppKachel(symbol: "map.fill", farben: [Color(0x7BE63B), Color(0x4CC417)], groesse: 33).offset(x: -11, y: -9)
                    AppKachel(symbol: "leaf.fill", farben: [Color(0x2B2F2D), Color(0x161817)], groesse: 20, rund: true).offset(x: 4, y: 8)
                    AppKachel(symbol: "sparkle", farben: [Color(0xF27A3B), Color(0xD9541A)], groesse: 21).offset(x: 16, y: 16)
                }
                .frame(width: 70)
                .padding(.leading, 13)
                VStack(alignment: .leading, spacing: 5) {
                    Text("Immer erlaubt?").font(.system(size: 17, weight: .semibold))
                    Text("Sorge dafür, dass Apps wie Karten, Bahn oder Gesundheit nie gesperrt werden.")
                        .font(.system(size: 15)).foregroundStyle(Color(0xA3A8A5)).lineSpacing(1.5)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.leading, 13)
                Spacer(minLength: 8)
                Text("Einrichten").font(.system(size: 13, weight: .semibold))
                    .padding(.horizontal, 13).frame(height: 32)
                    .background(LinearGradient(colors: [Color(0x3F6A5A), Color(0x274438)], startPoint: .top, endPoint: .bottom), in: Capsule())
                    .overlay { Capsule().strokeBorder(Color.white.opacity(0.16), lineWidth: 1) }
                    .padding(.trailing, 17)
            }
            .padding(.vertical, 21)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct BildschirmzeitKarte: View {
    private let apps: [(String, String, [Color], Double)] = [
        ("Fotos teilen", "58 min", [Color(0xF9CE34), Color(0xEE2A7B), Color(0x6228D7)], 0.82),
        ("Musik", "41 min", [Color(0x1ED760), Color(0x17A84A)], 0.58),
        ("Nachrichten", "25 min", [Color(0x5BF675), Color(0x25D366)], 0.36),
    ]
    private let symbole = ["camera.fill", "music.note", "message.fill"]
    var body: some View {
        HomeGlas(schimmer: Color(0x15302A)) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    Text("Bildschirmzeit").font(.system(size: 16)).foregroundStyle(Color(0xA3A8A5))
                    Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundStyle(Color(0xA3A8A5))
                }
                Text("2h 4m").font(.system(size: 26, weight: .semibold)).padding(.top, 10)
                VStack(spacing: 16) {
                    ForEach(Array(apps.enumerated()), id: \.offset) { i, a in
                        HStack(spacing: 12) {
                            AppKachel(symbol: symbole[i], farben: a.2, groesse: 30)
                            VStack(alignment: .leading, spacing: 6) {
                                HStack { Text(a.0).font(.system(size: 15, weight: .medium)); Spacer(); Text(a.1).font(.system(size: 15)).foregroundStyle(Color(0xA3A8A5)).monospacedDigit() }
                                GeometryReader { g in
                                    ZStack(alignment: .leading) {
                                        Capsule().fill(Color.white.opacity(0.08))
                                        Capsule().fill(LinearGradient(colors: DFarbe.akzentFarben, startPoint: .leading, endPoint: .trailing)).frame(width: g.size.width * a.3)
                                    }
                                }
                                .frame(height: 5)
                            }
                        }
                    }
                }
                .padding(.top, 62)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 23).padding(.top, 22).padding(.bottom, 24)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct SerieKarte: View {
    var body: some View {
        HomeGlas(schimmer: Color(0x4A3410)) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Erster Schritt geschafft").font(.system(size: 17, weight: .semibold))
                    Text("Du hast angefangen. Das ist der schwerste Teil – dein späteres Ich dankt dir.")
                        .font(.system(size: 15)).foregroundStyle(Color(0xA3A8A5)).fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                ZStack(alignment: .bottom) {
                    Flamme(groesse: 46)
                    Text("1").font(.system(size: 26, weight: .heavy)).foregroundStyle(Color(0xFFE9A8)).shadow(color: Color(0xC77A12), radius: 2).offset(y: 4)
                }
                .frame(width: 66)
            }
            .padding(.horizontal, 21).padding(.vertical, 20)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Bausteine der Seite

/// Neutrale App-Kachel (statt fremder App-Logos): Verlauf mit Symbol.
struct AppKachel: View {
    var symbol: String
    var farben: [Color]
    var groesse: CGFloat
    var rund = false
    var body: some View {
        Image(systemName: symbol).font(.system(size: groesse * 0.5, weight: .bold)).foregroundStyle(.white)
            .frame(width: groesse, height: groesse)
            .background(LinearGradient(colors: farben, startPoint: .bottomLeading, endPoint: .topTrailing),
                        in: RoundedRectangle(cornerRadius: rund ? groesse / 2 : groesse * 0.26, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: rund ? groesse / 2 : groesse * 0.26, style: .continuous).strokeBorder(.white.opacity(0.18), lineWidth: 0.5) }
            .accessibilityHidden(true)
    }
}

/// Flamme in Gold, flackert leicht.
struct Flamme: View {
    var groesse: CGFloat
    @Environment(\.accessibilityReduceMotion) private var ruhig
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20, paused: ruhig)) { k in
            let t = ruhig ? 0 : k.date.timeIntervalSinceReferenceDate
            Image(systemName: "flame.fill").font(.system(size: groesse))
                .foregroundStyle(LinearGradient(colors: [Color(0xFFE7A0), Color(0xFFB347), Color(0xF07A1A)], startPoint: .top, endPoint: .bottom))
                .shadow(color: Color(0xFFA63D).opacity(0.55 + 0.2 * sin(t * 3.1)), radius: groesse * 0.35)
                .scaleEffect(x: 1 + 0.025 * sin(t * 4.3), y: 1 + 0.04 * sin(t * 3.7), anchor: .bottom)
        }
        .accessibilityHidden(true)
    }
}

/// Schild-Form des Profil-Knopfs: sechs Ecken, weich gerundet.
struct SchildForm: Shape {
    func path(in r: CGRect) -> Path {
        let ecken: [(CGFloat, CGFloat)] = [(0.5, 0), (1, 0.22), (0.94, 0.74), (0.5, 1), (0.06, 0.74), (0, 0.22)]
        var p: [CGPoint] = []
        for e in ecken { p.append(CGPoint(x: r.minX + e.0 * r.width, y: r.minY + e.1 * r.height)) }
        var path = Path()
        let radius: CGFloat = 5
        for i in p.indices {
            let vor = p[(i + p.count - 1) % p.count], nach = p[(i + 1) % p.count]
            if i == 0 { path.move(to: CGPoint(x: (vor.x + p[0].x) / 2, y: (vor.y + p[0].y) / 2)) }
            path.addArc(tangent1End: p[i], tangent2End: CGPoint(x: (p[i].x + nach.x) / 2, y: (p[i].y + nach.y) / 2), radius: radius)
        }
        path.closeSubpath()
        return path
    }
}

/// Zahl, die beim Erscheinen hochzählt.
struct ZaehlZahl: View {
    var ziel: Double
    var body: some View { Color.clear.frame(width: 34, height: 31).modifier(ZaehlText(wert: ziel)) }
}

private struct ZaehlText: AnimatableModifier {
    var wert: Double
    nonisolated var animatableData: Double { get { wert } set { wert = newValue } }
    func body(content: Content) -> some View {
        content.overlay(alignment: .leading) { Text("\(Int(wert.rounded()))").monospacedDigit().fixedSize() }
    }
}

private struct Erscheint: ViewModifier {
    var da: Bool
    var stufe: Int
    @Environment(\.accessibilityReduceMotion) private var ruhig
    func body(content: Content) -> some View {
        content
            .opacity(da ? 1 : 0)
            .offset(y: da || ruhig ? 0 : 26)
            .blur(radius: da || ruhig ? 0 : 6)
            .animation(ruhig ? nil : .spring(response: 0.75, dampingFraction: 0.82).delay(0.12 + Double(stufe) * 0.09), value: da)
    }
}

private extension View {
    func erscheint(_ da: Bool, _ stufe: Int) -> some View { modifier(Erscheint(da: da, stufe: stufe)) }
}

/// Serie groß in Gold – Glas-Blatt.
private struct SerieBlatt: View {
    var serie: Int
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(spacing: 6) {
            HStack { RundKnopf(symbol: "xmark", beschriftung: "Schließen") { dismiss() }; Spacer() }
            Flamme(groesse: 78).padding(.top, 4)
            Text("\(serie)").font(.system(size: 52, weight: .heavy)).foregroundStyle(Color(0xFFD98A))
            Text(serie == 1 ? "TAG IN FOLGE" : "TAGE IN FOLGE").font(.system(size: 20, weight: .bold)).foregroundStyle(Color(0xF2C879))
            Text("Tage in Folge, an denen du mit Compass fokussiert hast").font(.system(size: 15)).foregroundStyle(Color(0xF2C879).opacity(0.85)).multilineTextAlignment(.center).padding(.top, 4)
            Spacer()
        }
        .padding(16)
        .background(RadialGradient(colors: [Color(0x6B4A12).opacity(0.7), .clear], center: .center, startRadius: 0, endRadius: 260))
        .presentationDetents([.height(370)])
        .glasBlatt()
    }
}
