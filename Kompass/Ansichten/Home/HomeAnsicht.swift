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
                // Platz für die Bühne: sie steht fest dahinter (wie im Vorbild-Video), die Werte liegen auf dem Fels
                Color.clear.frame(height: 384)
                werte
                VStack(spacing: 17) {
                    ImmerErlaubtKarte().erscheint(da, 0)
                    BildschirmzeitKarte().erscheint(da, 1)
                    SerieKarte().erscheint(da, 2)
                    ErkenntnisKarte().erscheint(da, 3)
                }
                .padding(.horizontal, 17)
                .padding(.top, 27)
                .padding(.bottom, 170)
            }
        }
        .ignoresSafeArea(edges: .top)
        .scrollIndicators(.hidden)
        .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y + $0.contentInsets.top } action: { _, neu in scroll = neu }
        .background(alignment: .top) {
            ZStack(alignment: .top) {
                DFarbe.grund
                HomeBuehne(scroll: scroll)
            }
            .ignoresSafeArea()
        }
        .foregroundStyle(DFarbe.text)
        .overlay(alignment: .top) {
            ZStack(alignment: .top) {
                // Inhalt, der unter den Kopf läuft, wird unscharf und dunkel (wie im Vorbild-Video)
                ZStack {
                    Rectangle().fill(.ultraThinMaterial)
                    Rectangle().fill(Color.black.opacity(0.6))
                }
                .mask(LinearGradient(stops: [.init(color: .black, location: 0), .init(color: .black, location: 0.62), .init(color: .clear, location: 1)], startPoint: .top, endPoint: .bottom))
                .frame(height: 132)
                .opacity(min(1, max(0, (scroll - 20) / 90)))
                .ignoresSafeArea()
                .allowsHitTesting(false)
                kopf.padding(.top, 4)
            }
        }
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
        // Wie im Vorbild: drei mittige Spalten ohne Trennlinien, Symbole der Ablenker überlappen leicht
        HStack(alignment: .top, spacing: 0) {
            VStack(spacing: 5) {
                etikett("Wert", 0xB6F5E6, 0xC6F8E2)
                HStack(spacing: 6) {
                    ZaehlZahl(ziel: da ? 79 : 0).font(.system(size: 27, weight: .regular))
                        .foregroundStyle(LinearGradient(colors: [Color(0xBCFFF5), Color(0xCFFFF6)], startPoint: .leading, endPoint: .trailing))
                    Image(systemName: "arrowtriangle.up.fill").font(.system(size: 11)).foregroundStyle(Color(0xC1FFF1))
                }
            }
            .frame(width: 96)
            Spacer(minLength: 0)
            VStack(spacing: 5) {
                etikett("Bildschirmzeit", 0xCFF9E0, 0xE5FCE6)
                Text("2h 4m").font(.system(size: 27, weight: .regular)).lineLimit(1)
                    .foregroundStyle(LinearGradient(colors: [Color(0xD7FFEF), Color(0xE3FFF1)], startPoint: .leading, endPoint: .trailing))
            }
            .frame(width: 130)
            Spacer(minLength: 0)
            VStack(spacing: 8) {
                etikett("Ablenker", 0xEBFFDB, 0xE9FFCD)
                HStack(spacing: -4) {
                    AppKachel(symbol: "camera.fill", farben: [Color(0xF9CE34), Color(0xEE2A7B), Color(0x6228D7)], groesse: 22)
                    AppKachel(symbol: "asterisk", farben: [Color(0x1B1D1C), Color(0x0C0D0C)], groesse: 22).zIndex(1)
                    AppKachel(symbol: "message.fill", farben: [Color(0x5BF675), Color(0x25D366)], groesse: 22).zIndex(2)
                }
            }
            .frame(width: 96)
        }
        .padding(.horizontal, 22)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Wert 79, Bildschirmzeit 2 Stunden 4 Minuten, drei Ablenker")
    }

    /// Etikett in Großbuchstaben; die Farbe läuft über die ganze Zeile von Aqua (links) nach Limette (rechts) – aus dem Vorbild gemessen.
    private func etikett(_ t: String, _ von: UInt32, _ bis: UInt32) -> some View {
        Text(t.uppercased()).font(.system(size: 12, weight: .medium)).tracking(0.4)
            .foregroundStyle(LinearGradient(colors: [Color(von), Color(bis)], startPoint: .leading, endPoint: .trailing))
            .lineLimit(1).minimumScaleFactor(0.8)
    }

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
                    .offset(y: -34)
                // Schein am Kompass (liegt bei 51 % der Breite, 55 % der Höhe)
                GeometryReader { g in
                    Circle()
                        .fill(RadialGradient(colors: [Color(0x66FFE6).opacity(0.33 + 0.12 * sin(t * 1.1)), .clear], center: .center, startRadius: 4, endRadius: 96))
                        .frame(width: 200, height: 200)
                        .position(x: g.size.width * 0.5, y: g.size.height * 0.55 - 34)
                        .blendMode(.screen)
                }
            }
        }
        .frame(height: 500)
        .frame(maxWidth: .infinity)
        .clipped()
        // Der Fels läuft unter den Werten weiter und erst darunter ins Schwarz
        .mask(LinearGradient(stops: [.init(color: .black, location: 0), .init(color: .black, location: 0.74), .init(color: .clear, location: 0.97)], startPoint: .top, endPoint: .bottom))
        // Hochscrollen (Video 0,6–1,4 s): Bühne bleibt stehen, wird kleiner, unscharf und dunkel, während der Inhalt darüberläuft.
        // Herunterziehen (Video 15,2–15,5 s): Bühne wächst von oben.
        .scaleEffect(scroll < 0 ? 1 + min(0.35, -scroll / 380) : 1 - min(0.08, scroll / 1600), anchor: .top)
        .blur(radius: ruhig ? 0 : min(9, max(0, scroll) / 16))
        .opacity(1 - min(1, max(0, scroll) / 165))
        .offset(y: scroll > 0 ? -min(30, scroll * 0.12) : 0)
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
    private struct Zeile: Identifiable { var id: String { name }; var name: String; var symbol: String; var farben: [Color]; var minuten: Int; var rund = false }
    private let zeilen = [
        Zeile(name: "Fotos teilen", symbol: "camera.fill", farben: [Color(0xF9CE34), Color(0xEE2A7B), Color(0x6228D7)], minuten: 17),
        Zeile(name: "Fußball-Manager", symbol: "asterisk", farben: [Color(0x1B1D1C), Color(0x0C0D0C)], minuten: 13),
        Zeile(name: "Nachrichten", symbol: "message.fill", farben: [Color(0x5BF675), Color(0x25D366)], minuten: 10),
        Zeile(name: "Kalender", symbol: "calendar", farben: [Color(0xF4F4F4), Color(0xD9D9D9)], minuten: 8),
        Zeile(name: "Store", symbol: "bag.fill", farben: [Color(0x2D9BF7), Color(0x1668E3)], minuten: 6),
    ]
    @State private var da = false

    var body: some View {
        HomeGlas(schimmer: Color(0x15302A)) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    Text("Bildschirmzeit").font(.system(size: 16)).foregroundStyle(Color(0xA3A8A5))
                    Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundStyle(Color(0xA3A8A5))
                }
                Text("2h 4m").font(.system(size: 26, weight: .semibold)).padding(.top, 10)
                Text("Heute").font(.system(size: 14)).foregroundStyle(Color(0x7D8380)).padding(.top, 5)
                VStack(alignment: .leading, spacing: 22) {
                    ForEach(Array(zeilen.enumerated()), id: \.element.id) { i, z in
                        HStack(alignment: .center, spacing: 18) {
                            AppKachel(symbol: z.symbol, farben: z.farben, groesse: 30, symbolFarbe: z.name == "Kalender" ? Color(0xE5484D) : .white)
                            VStack(alignment: .leading, spacing: 9) {
                                Text(z.name).font(.system(size: 15))
                                HStack(spacing: 6) {
                                    Capsule()
                                        .fill(i == 0 ? AnyShapeStyle(LinearGradient(colors: [Color(0xE9667A), Color(0xF08A8F)], startPoint: .leading, endPoint: .trailing))
                                                     : AnyShapeStyle(LinearGradient(colors: [Color(0xE9FBF3), Color(0x8FE9CC)], startPoint: .leading, endPoint: .trailing)))
                                        .frame(width: da ? CGFloat(z.minuten) / 17 * 218 : 0, height: 3)
                                    Text("\(z.minuten)m").font(.system(size: 13)).monospacedDigit()
                                        .foregroundStyle(i == 0 ? Color(0xF08A8F) : Color(0x9EF0CF))
                                        .opacity(da ? 1 : 0)
                                }
                            }
                        }
                    }
                }
                .padding(.top, 38)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 23).padding(.top, 22).padding(.bottom, 26)
        }
        .onAppear { withAnimation(.spring(response: 0.9, dampingFraction: 0.85).delay(0.45)) { da = true } }
        .accessibilityElement(children: .combine)
    }
}

/// Erkenntnisse am ersten Tag: verschwommener Platzhalter-Inhalt, davor der Satz.
private struct ErkenntnisKarte: View {
    var body: some View {
        HomeGlas(schimmer: Color(0x15302A)) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Erkenntnisse").font(.system(size: 16)).foregroundStyle(Color(0xA3A8A5))
                ZStack {
                    VStack(spacing: 14) {
                        RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.22)).frame(width: 60, height: 22)
                        RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.16)).frame(width: 250, height: 54)
                    }
                    .blur(radius: 14)
                    .offset(y: -40)
                    Text("Deine ersten Erkenntnisse brauchen einen vollen Tag.")
                        .font(.system(size: 16)).foregroundStyle(Color(0xC9CDCB)).multilineTextAlignment(.center)
                        .frame(maxWidth: 250).offset(y: 46)
                }
                .frame(maxWidth: .infinity).frame(height: 290)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 23).padding(.top, 22).padding(.bottom, 20)
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
                    Flamme(groesse: 58)
                    Text("1").font(.system(size: 34, weight: .heavy)).foregroundStyle(LinearGradient(colors: [Color(0xFFF3C4), Color(0xF5C24C)], startPoint: .top, endPoint: .bottom))
                        .shadow(color: Color(0x8A4B06), radius: 0, y: 1.5).shadow(color: Color(0xFFB347).opacity(0.8), radius: 6)
                        .offset(y: 14)
                }
                .frame(width: 72).padding(.bottom, 10)
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
    var symbolFarbe: Color = .white
    var body: some View {
        Image(systemName: symbol).font(.system(size: groesse * 0.5, weight: .bold)).foregroundStyle(symbolFarbe)
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
    var body: some View { Color.clear.frame(width: 33, height: 32).modifier(ZaehlText(wert: ziel)) }
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
