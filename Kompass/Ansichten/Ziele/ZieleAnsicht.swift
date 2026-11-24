import SwiftUI

/// Ziele (Inhalt im Tab Fortschritt): Aussage-Karte, Filter als Verlaufskacheln (Alle · Auf Kurs · Hinterher · Erreicht),
/// Sortieren nach Frist, Jahr, Fortschritt, Hinterher zuerst, Bereich oder Name, dann die Zielkarten.
struct ZieleAnsicht: View {
    @Environment(Speicher.self) private var speicher
    @Environment(\.accessibilityReduceMotion) private var ruhig
    @AppStorage("ziele.filter") private var filterRoh = ZielOrdnung.Filter.alle.rawValue
    @AppStorage("ziele.sortierung") private var sortierungRoh = ZielOrdnung.Sortierung.frist.rawValue

    private var filter: ZielOrdnung.Filter { .init(rawValue: filterRoh) ?? .alle }
    private var sortierung: ZielOrdnung.Sortierung { .init(rawValue: sortierungRoh) ?? .frist }

    var body: some View {
        let z = speicher.zustand
        let T = speicher.heute
        let gruppen = ZielOrdnung.gruppen(z, filter: filter, sortierung: sortierung, heute: T)

        VStack(alignment: .leading, spacing: 0) {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(ZielOrdnung.Filter.allCases, id: \.self) { f in
                    FilterKachel(filter: f, anzahl: ZielOrdnung.anzahl(f, in: z, heute: T), an: f == filter) {
                        withAnimation(ruhig ? nil : .snappy) { filterRoh = f.rawValue }
                    }
                }
            }

            HStack(alignment: .firstTextBaseline) {
                Text(filter == .alle ? "Deine Ziele" : filter.titel).font(.abschnitt).foregroundStyle(Farbe.text).accessibilityAddTraits(.isHeader)
                Spacer()
                Menu {
                    Picker("Sortieren", selection: $sortierungRoh) {
                        ForEach(ZielOrdnung.Sortierung.allCases, id: \.self) { Label($0.titel, systemImage: $0.symbol).tag($0.rawValue) }
                    }
                } label: {
                    Label(sortierung.titel, systemImage: "arrow.up.arrow.down")
                        .font(.kompass(.subheadline, .bold)).foregroundStyle(Farbe.akzent)
                        .padding(.horizontal, 12).frame(minHeight: 36)
                        .background(Farbe.akzentWeich, in: Capsule())
                }
                .accessibilityLabel("Sortieren: \(sortierung.titel)")
            }
            .padding(.top, Mass.abschnitt).padding(.bottom, Mass.ueberschrift)

            if gruppen.isEmpty {
                GruppierteListe { LeerZeile(text: leerText) }
            }
            ForEach(Array(gruppen.enumerated()), id: \.offset) { i, gr in
                if let t = gr.titel {
                    HStack {
                        Text(t).font(.kompass(.headline, .heavy)).foregroundStyle(Farbe.text)
                        Spacer()
                        Text("\(gr.ziele.count) Ziel\(gr.ziele.count == 1 ? "" : "e")").font(.unterzeile).foregroundStyle(Farbe.zweitrangig)
                    }
                    .padding(.top, i == 0 ? 0 : 20).padding(.bottom, 8)
                    .accessibilityAddTraits(.isHeader)
                }
                VStack(spacing: 12) { ForEach(gr.ziele) { ZielKarte(ziel: $0) } }
            }
        }
    }

    private var leerText: String {
        switch filter {
        case .alle: "Noch keine Ziele. Oben auf „+ Neu“."
        case .aufKurs: "Gerade ist kein Ziel auf Kurs."
        case .hinterher: "Kein Ziel hinkt hinterher – stark."
        case .erreicht: "Noch kein Ziel erreicht."
        }
    }
}

/// Filter-Kachel mit Farbverlauf (wie „Coming up“ in Gapless): Glas-Kreis mit Symbol, Titel, Anzahl; gewählt = weißer Rand + Haken.
private struct FilterKachel: View {
    var filter: ZielOrdnung.Filter
    var anzahl: Int
    var an: Bool
    var aktion: () -> Void

    var body: some View {
        let c = farbe
        Button(action: aktion) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top) {
                    Image(systemName: symbol).font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
                        .frame(width: 38, height: 38).background(c.gradient, in: Circle())
                        .shadow(color: c.opacity(0.35), radius: 6, y: 3)
                    Spacer()
                    if an {
                        Image(systemName: "checkmark.circle.fill").font(.title3).symbolRenderingMode(.palette).foregroundStyle(.white, c)
                    }
                }
                Spacer(minLength: 10)
                Text(filter.titel).font(.kompass(.headline, .heavy)).foregroundStyle(Farbe.text).lineLimit(1).minimumScaleFactor(0.8)
                Text("\(anzahl) Ziel\(anzahl == 1 ? "" : "e")").font(.klein).foregroundStyle(Farbe.text.opacity(0.7))
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
            .background {
                // Weiß oben links → kräftige Farbe unten rechts
                LinearGradient(stops: [.init(color: Farbe.karte, location: 0), .init(color: c.opacity(0.28), location: 0.45), .init(color: c.opacity(0.75), location: 1)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(an ? c : c.opacity(0.2), lineWidth: an ? 2.5 : 1))
            .shadow(color: c.opacity(an ? 0.3 : 0.12), radius: an ? 10 : 6, y: 4)
        }
        .buttonStyle(DruckStil())
        .accessibilityLabel("\(filter.titel), \(anzahl) Ziele")
        .accessibilityAddTraits(an ? [.isButton, .isSelected] : .isButton)
    }

    private var symbol: String {
        switch filter {
        case .alle: "square.grid.2x2.fill"
        case .aufKurs: "arrow.up.right"
        case .hinterher: "tortoise.fill"
        case .erreicht: "flag.checkered"
        }
    }

    private var farbe: Color {
        switch filter {
        case .alle: Color(hex: "#5B5BE6")
        case .aufKurs: Color(hex: "#1FA67A")
        case .hinterher: Color(hex: "#F08A3C")
        case .erreicht: Color(hex: "#B05CD6")
        }
    }
}

struct ZielKarte: View {
    var ziel: Ziel
    @Environment(Speicher.self) private var speicher

    var body: some View {
        let z = speicher.zustand
        let T = speicher.heute
        let kurs = Kurs.aufKurs(ziel, in: z, heute: T)
        let c = Color(hex: ziel.farbe)
        let form = RoundedRectangle(cornerRadius: Mass.karte, style: .continuous)
        NavigationLink(value: ZielAuswahl(id: ziel.id)) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().stroke(c.opacity(0.15), lineWidth: 6)
                    Circle().trim(from: 0, to: max(0.001, kurs.fortschritt)).stroke(c, style: StrokeStyle(lineWidth: 6, lineCap: .round)).rotationEffect(.degrees(-90))
                    Text(Zahl.prozent(kurs.fortschritt)).font(.kompass(.caption, .heavy)).foregroundStyle(Farbe.text).monospacedDigit()
                        .minimumScaleFactor(0.7).lineLimit(1).padding(6)
                }
                .frame(width: 54, height: 54)
                VStack(alignment: .leading, spacing: 6) {
                    Text(ziel.titel).font(.kompass(.headline, .bold)).foregroundStyle(Farbe.text).lineLimit(1)
                    Text(kurs.lage.text).font(.klein).padding(.horizontal, 8).frame(minHeight: 22)
                        .background(lageFarbe(kurs.lage).opacity(0.14), in: Capsule()).foregroundStyle(lageFarbe(kurs.lage))
                }
                Spacer(minLength: 4)
                Image(systemName: "arrow.right").font(.footnote.weight(.heavy)).foregroundStyle(.white)
                    .frame(width: 30, height: 30).background(c.gradient, in: Circle())
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Farbe.karte, in: form)
            .overlay { Lichtrand(farbe: c, ecken: Mass.karte) }
            .shadow(color: c.opacity(0.10), radius: 10, y: 4)
        }
        .buttonStyle(DruckStil())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(ziel.titel), \(Zahl.prozent(kurs.fortschritt)), \(kurs.lage.text), \(Kurs.bisText(ziel.faellig, heute: T))")
        .accessibilityAddTraits(.isButton)
    }

    private func lageFarbe(_ l: Kurs.Lage) -> Color {
        switch l {
        case .voraus, .erreicht: Farbe.freude
        case .imPlan: Farbe.akzent
        case .hinterher, .ueberfaellig: Farbe.warnung
        }
    }
}

/// Beim Drücken leicht kleiner – fühlt sich antippbar an.
struct DruckStil: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Umlaufender Lichtrand: eine fertige Verlaufs-Ebene dreht sich gleichmäßig (Zeitleiste statt Neu-Berechnung je Bild)
/// und wird auf den Rand der Karte zugeschnitten – dadurch flackert nichts. Bei „Bewegung reduzieren“ steht er still.
struct Lichtrand: View {
    var farbe: Color
    var ecken: CGFloat
    var dauer: Double = 7
    @Environment(\.accessibilityReduceMotion) private var ruhig

    var body: some View {
        let form = RoundedRectangle(cornerRadius: ecken, style: .continuous)
        GeometryReader { geo in
            let seite = max(geo.size.width, geo.size.height) * 1.5
            TimelineView(.animation(minimumInterval: 1.0 / 30, paused: ruhig)) { zeit in
                let winkel = ruhig ? 45 : (zeit.date.timeIntervalSinceReferenceDate / dauer).truncatingRemainder(dividingBy: 1) * 360
                AngularGradient(colors: [farbe.opacity(0), farbe.opacity(0.1), farbe.opacity(0.9), farbe.opacity(0.1), farbe.opacity(0)], center: .center)
                    .frame(width: seite, height: seite)
                    .rotationEffect(.degrees(winkel))
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
        }
        .mask(form.strokeBorder(lineWidth: 2.5))
        .overlay(form.strokeBorder(farbe.opacity(0.14), lineWidth: 1))
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
