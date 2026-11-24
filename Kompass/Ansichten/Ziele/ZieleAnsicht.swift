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
        Button(action: aktion) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top) {
                    Image(systemName: symbol).font(.system(size: 16, weight: .bold))
                        .frame(width: 38, height: 38).background(.white.opacity(0.22), in: Circle())
                    Spacer()
                    if an {
                        Image(systemName: "checkmark.circle.fill").font(.title3).symbolRenderingMode(.palette).foregroundStyle(farben[0], .white)
                    }
                }
                Spacer(minLength: 10)
                Text(filter.titel).font(.kompass(.headline, .heavy)).lineLimit(1).minimumScaleFactor(0.8)
                Text("\(anzahl) Ziel\(anzahl == 1 ? "" : "e")").font(.klein).opacity(0.9)
            }
            .foregroundStyle(.white)
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
            .background {
                ZStack {
                    LinearGradient(colors: farben, startPoint: .topLeading, endPoint: .bottomTrailing)
                    // weicher Lichtschein oben links für mehr Tiefe
                    RadialGradient(colors: [.white.opacity(0.18), .clear], center: .topLeading, startRadius: 0, endRadius: 160)
                }
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(.white, lineWidth: an ? 3 : 0))
            .shadow(color: farben[1].opacity(an ? 0.3 : 0.12), radius: an ? 10 : 6, y: 4)
            .scaleEffect(an ? 1 : 0.98)
        }
        .buttonStyle(.plain)
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

    /// Ruhige Verläufe mit drei Stufen und leichtem Farbwechsel (wie „Coming up“ in Gapless)
    private var farben: [Color] {
        switch filter {
        case .alle: [Color(hex: "#3A3F9E"), Color(hex: "#5753C2"), Color(hex: "#7D6CCF")]
        case .aufKurs: [Color(hex: "#2C6E6A"), Color(hex: "#3D8F86"), Color(hex: "#5C93B8")]
        case .hinterher: [Color(hex: "#A65A3A"), Color(hex: "#C47A55"), Color(hex: "#C76A78")]
        case .erreicht: [Color(hex: "#5A479E"), Color(hex: "#7E5AAF"), Color(hex: "#A76AA8")]
        }
    }
}

/// Zielkarte: Ring mit Prozent, Titel, ein Lage-Chip – mehr nicht. Ein leuchtender Rand in der Zielfarbe läuft langsam
/// um die Karte und lädt zum Antippen ein (bei „Bewegung reduzieren“ steht er still).
struct ZielKarte: View {
    var ziel: Ziel
    @Environment(Speicher.self) private var speicher
    @Environment(\.accessibilityReduceMotion) private var ruhig
    @State private var dreh = 0.0

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
            .overlay {
                // umlaufender Lichtrand: ein heller Bogen in der Zielfarbe wandert um die Karte
                form.strokeBorder(AngularGradient(colors: [c.opacity(0.0), c.opacity(0.12), c.opacity(0.85), c.opacity(0.12), c.opacity(0.0)],
                                                  center: .center, angle: .degrees(dreh)), lineWidth: 2)
            }
            .background {
                form.stroke(AngularGradient(colors: [.clear, c.opacity(0.4), .clear], center: .center, angle: .degrees(dreh)), lineWidth: 6)
                    .blur(radius: 8)
            }
        }
        .buttonStyle(ZielKartenDruck())
        .onAppear {
            guard !ruhig else { dreh = 45; return }
            withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) { dreh = 360 }
        }
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
private struct ZielKartenDruck: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
