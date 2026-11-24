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
            ZieleKopf(ziele: z.ziele.filter { $0.status == .aktiv })

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(ZielOrdnung.Filter.allCases, id: \.self) { f in
                    FilterKachel(filter: f, anzahl: ZielOrdnung.anzahl(f, in: z, heute: T), an: f == filter) {
                        withAnimation(ruhig ? nil : .snappy) { filterRoh = f.rawValue }
                    }
                }
            }
            .padding(.top, 16)

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
            .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
            .background(LinearGradient(colors: farben, startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(.white, lineWidth: an ? 3 : 0))
            .shadow(color: farben[0].opacity(an ? 0.35 : 0.15), radius: an ? 10 : 6, y: 4)
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

    private var farben: [Color] {
        switch filter {
        case .alle: [Color(hex: "#2A36A0"), Color(hex: "#6A5BE0")]
        case .aufKurs: [Color(hex: "#0F6E5C"), Color(hex: "#2FB36C")]
        case .hinterher: [Color(hex: "#B4400A"), Color(hex: "#F0A030")]
        case .erreicht: [Color(hex: "#5A33B0"), Color(hex: "#C060C8")]
        }
    }
}

/// Eine Aussage über alle aktiven Ziele: „2 von 3 auf Kurs“, dazu, wo es hakt.
private struct ZieleKopf: View {
    var ziele: [Ziel]
    @Environment(Speicher.self) private var speicher

    var body: some View {
        let z = speicher.zustand
        let T = speicher.heute
        let lagen = ziele.map { ($0, Kurs.aufKurs($0, in: z, heute: T)) }
        let gut = lagen.filter { $0.1.lage == .imPlan || $0.1.lage == .voraus }.count
        let hinten = lagen.filter { $0.1.lage == .hinterher || $0.1.lage == .ueberfaellig }.map(\.0)
        let mittel = lagen.isEmpty ? 0 : lagen.reduce(0) { $0 + $1.1.fortschritt } / Double(lagen.count)
        Verlaufskarte(farben: Farbe.indigo) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    KartenLabel(text: "Ziele")
                    Text(ziele.isEmpty ? "Noch kein Ziel" : "\(gut) von \(ziele.count) auf Kurs").font(.kompass(.title, .heavy)).contentTransition(.numericText())
                    Text(unterzeile(hinten: hinten, T: T)).font(.unterzeile).opacity(0.9).lineLimit(2).fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 12)
                if !ziele.isEmpty {
                    VStack(spacing: 2) {
                        Text(Zahl.prozent(mittel)).font(.kompass(.title2, .heavy)).monospacedDigit()
                        Text("im Schnitt").font(.klein).opacity(0.85)
                    }
                }
            }
            if !ziele.isEmpty {
                // Geteilter Balken: auf Kurs (grün) · hinterher (orange) – je Ziel ein Stück
                GeometryReader { geo in
                    HStack(spacing: 3) {
                        if gut > 0 { Capsule().fill(Color(hex: "#5EE0B5")).frame(width: max(8, (geo.size.width - 3) * CGFloat(gut) / CGFloat(ziele.count))) }
                        if !hinten.isEmpty { Capsule().fill(Color(hex: "#FFC266")) }
                    }
                }
                .frame(height: 8).padding(.top, 10)
                .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func unterzeile(hinten: [Ziel], T: Tag) -> String {
        if ziele.isEmpty { return "Oben auf „+ Neu“ – zum Beispiel „Führerschein Klasse B“." }
        if hinten.isEmpty {
            if let n = ziele.min(by: { $0.faellig < $1.faellig }) { return "Nächste Frist: \(n.titel.prefix(24))\(n.titel.count > 24 ? "…" : "") · \(Kurs.bisText(n.faellig, heute: T))" }
            return "Alles im Plan."
        }
        let namen = hinten.prefix(2).map { $0.titel.count > 22 ? String($0.titel.prefix(21)) + "…" : $0.titel }
        return "Hinterher: " + namen.joined(separator: ", ") + (hinten.count > 2 ? " +\(hinten.count - 2)" : "")
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
        NavigationLink(value: ZielAuswahl(id: ziel.id)) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().stroke(c.opacity(0.15), lineWidth: 6)
                    Circle().trim(from: 0, to: max(0.001, kurs.fortschritt)).stroke(c, style: StrokeStyle(lineWidth: 6, lineCap: .round)).rotationEffect(.degrees(-90))
                    Text(Zahl.prozent(kurs.fortschritt)).font(.kompass(.caption, .heavy)).foregroundStyle(Farbe.text).monospacedDigit()
                        .minimumScaleFactor(0.7).lineLimit(1).padding(6)
                }
                .frame(width: 58, height: 58)
                VStack(alignment: .leading, spacing: 4) {
                    Text(ziel.titel).font(.kompass(.headline, .bold)).foregroundStyle(Farbe.text).lineLimit(2)
                    HStack(spacing: 6) {
                        Text(kurs.lage.text).font(.klein).padding(.horizontal, 8).frame(minHeight: 22)
                            .background(lageFarbe(kurs.lage).opacity(0.14), in: Capsule()).foregroundStyle(lageFarbe(kurs.lage))
                        Text(Kurs.bisText(ziel.faellig, heute: T)).font(.unterzeile).foregroundStyle(Farbe.zweitrangig).lineLimit(1)
                    }
                    if let n = Fortschritt.naechsterSchritt(ziel, in: z, heute: T) {
                        Text("Als Nächstes: \(n.aufgabe?.titel ?? n.schritt.titel)").font(.unterzeile).foregroundStyle(Farbe.zweitrangig).lineLimit(1)
                    }
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.right").font(.footnote.weight(.bold)).foregroundStyle(Farbe.pfeil)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Farbe.karte, in: RoundedRectangle(cornerRadius: Mass.karte, style: .continuous))
        }
        .buttonStyle(.plain)
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
