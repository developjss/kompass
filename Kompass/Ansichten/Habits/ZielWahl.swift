import SwiftUI

// Einheit und Ziel eines Habits – Bausteine im Stil des Vorbilds (Maße aus den Vorlagen, @3x gemessen):
// Lineal 71 pt hoch mit Strichen alle 10,7 pt, Rad mit 45-pt-Zeilen und Mittel-Kapsel, Zwei-Spalten-Rad im Glas-Fenster,
// Füllbalken mit Lichtstaub wie der Schwierigkeits-Regler. Nur Aussehen und Auswahl – gespeichert wird noch nichts.

// MARK: - Blatt-Grund und Kopf

/// Gleicher Grund wie „Neuer Habit“: Glas + #2C2C2C.
struct HabitBlattGrund: ViewModifier {
    var hoehe: CGFloat?
    func body(content: Content) -> some View {
        content
            .foregroundStyle(DFarbe.text)
            .presentationDetents(hoehe.map { [.height($0)] } ?? [.large])
            .presentationBackground { ZStack { Rectangle().fill(.ultraThinMaterial); Color(0x2C2C2C).opacity(0.62) } }
            .presentationCornerRadius(Dunkel.blattRadius)
            .presentationDragIndicator(.visible)
            .preferredColorScheme(.dark)
    }
}

extension View {
    func habitBlatt(hoehe: CGFloat? = nil) -> some View { modifier(HabitBlattGrund(hoehe: hoehe)) }
}

/// Kopf wie Opals „Ausgewählt“-Blatt: Schließen links, Titel, runder Verlaufs-Haken rechts.
struct HakenKopf: View {
    var titel: String
    var fertigAn = true
    var schliessen: () -> Void
    var fertig: () -> Void
    var body: some View {
        ZStack {
            Text(titel).font(.system(size: 18, weight: .semibold)).accessibilityAddTraits(.isHeader)
            HStack {
                BlattKnopf(symbol: "xmark", beschriftung: "Schließen", aktion: schliessen)
                Spacer()
                Button(action: fertig) {
                    Image(systemName: "checkmark").font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(width: 44, height: 44)
                        .background(LinearGradient(colors: DFarbe.akzentFarben, startPoint: .topLeading, endPoint: .bottomTrailing), in: Circle())
                        .opacity(fertigAn ? 1 : 0.35)
                }
                .buttonStyle(.plain)
                .disabled(!fertigAn)
                .accessibilityLabel("Fertig")
            }
        }
    }
}

/// Etikett mit Akzent-Verlauf („SCHWIERIGKEIT“ im Vorbild).
struct VerlaufEtikett: View {
    var text: String
    var groesse: CGFloat = 13
    var body: some View {
        Text(text.uppercased()).font(.system(size: groesse, weight: .semibold)).tracking(groesse * 0.05)
            .foregroundStyle(DFarbe.akzent)
    }
}

// MARK: - Umschalter

/// Umschalter wie im Vorbild („Sperren | Nur erlauben“): dunkle Spur 31 pt, gewähltes Feld hellgrau.
struct GlasUmschalter<Wert: Hashable>: View {
    var optionen: [(Wert, String)]
    @Binding var wahl: Wert
    @Namespace private var ns
    var body: some View {
        HStack(spacing: 0) {
            ForEach(optionen, id: \.0) { o in
                Button { withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { wahl = o.0 } } label: {
                    Text(o.1).font(.system(size: 15, weight: .medium))
                        .frame(maxWidth: .infinity, minHeight: 27)
                        .background {
                            if wahl == o.0 { Capsule().fill(Color.white.opacity(0.3)).matchedGeometryEffect(id: "feld", in: ns) }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(wahl == o.0 ? .isSelected : [])
            }
        }
        .padding(2)
        .background(Color.white.opacity(0.07), in: Capsule())
        .overlay { Capsule().strokeBorder(Color.white.opacity(0.06), lineWidth: 0.5) }
        .sensoryFeedback(.selection, trigger: wahl)
    }
}

// MARK: - Blatt „Einheit“

struct EinheitBlatt: View {
    @Binding var einheit: Einheit
    @Environment(\.dismiss) private var dismiss
    @State private var wahl: Einheit
    @State private var art: EinheitArt
    @State private var eigene: Einheit?
    @State private var eigeneOffen = false

    init(einheit: Binding<Einheit>) {
        _einheit = einheit
        _wahl = State(initialValue: einheit.wrappedValue)
        _art = State(initialValue: einheit.wrappedValue.art)
        _eigene = State(initialValue: einheit.wrappedValue.istEigene ? einheit.wrappedValue : nil)
    }

    private var liste: [Einheit] {
        art == .zeit ? Einheit.zeiten : (eigene.map { [$0] } ?? []) + Einheit.mengen
    }

    var body: some View {
        VStack(spacing: 18) {
            HakenKopf(titel: "Einheit", schliessen: { dismiss() }, fertig: { einheit = wahl; dismiss() })
                .padding(.horizontal, 16).padding(.top, 18)

            GlasUmschalter(optionen: EinheitArt.allCases.map { ($0, $0.rawValue) }, wahl: $art)
                .padding(.horizontal, 16)

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    BlattGruppe {
                        ForEach(Array(liste.enumerated()), id: \.element.id) { i, e in
                            if i > 0 { BlattTrenner() }
                            Button { wahl = e } label: {
                                BlattZeile(titel: e.name) {
                                    if let z = e.zeichen { Text(z).font(.system(size: 17)).foregroundStyle(Color(0x9A9A9E)) }
                                    Image(systemName: "checkmark").font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(DFarbe.akzent)
                                        .opacity(wahl == e ? 1 : 0)
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(wahl == e ? .isSelected : [])
                        }
                    }
                    if art == .zeit {
                        Text("Mit einer Zeit-Einheit läuft später ein Timer mit.")
                            .font(.system(size: 13)).foregroundStyle(Color(0x8E8E93))
                            .padding(.horizontal, 18)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, art == .menge ? 96 : 24)
                .animation(.easeInOut(duration: 0.2), value: art)
            }
            .scrollIndicators(.hidden)
        }
        .overlay(alignment: .bottom) {
            if art == .menge {
                Button { eigeneOffen = true } label: {
                    Label("Eigene Einheit", systemImage: "plus")
                        .font(.system(size: 17, weight: .medium))
                        .padding(.horizontal, 26).frame(height: 50)
                        .background(Color.white, in: Capsule())
                        .foregroundStyle(.black)
                        .shadow(color: .black.opacity(0.35), radius: 14, y: 4)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 14)
                .transition(.opacity)
            }
        }
        .sheet(isPresented: $eigeneOffen) {
            EigeneEinheitBlatt { name in
                let e = Einheit.eigene(name)
                eigene = e; wahl = e
            }
        }
        .habitBlatt()
    }
}

/// Eigene Einheit benennen – Feld in grauer Kapsel wie der Habit-Name.
struct EigeneEinheitBlatt: View {
    var fertig: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @FocusState private var schreibt: Bool
    private var gueltig: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        VStack(spacing: 20) {
            HakenKopf(titel: "Eigene Einheit", fertigAn: gueltig, schliessen: { dismiss() }, fertig: { fertig(name); dismiss() })
            TextField("", text: $name, prompt: Text("Name").foregroundStyle(Color(0x8E8E93)))
                .font(.system(size: 17, weight: .semibold))
                .multilineTextAlignment(.center)
                .focused($schreibt)
                .submitLabel(.done)
                .onSubmit { if gueltig { fertig(name); dismiss() } }
                .padding(.horizontal, 16)
                .frame(width: 240, height: 44)
                .background(Color(0x3A3A3A).opacity(0.75), in: Capsule())
                .overlay { Capsule().strokeBorder(Color.white.opacity(schreibt ? 0.22 : 0.08), lineWidth: 0.5) }
                .tint(Color(Dunkel.akzentA))
                .accessibilityLabel("Name der Einheit")
            Text("Zum Beispiel Liegestütze, Kapitel oder Runden.")
                .font(.system(size: 13)).foregroundStyle(Color(0x8E8E93))
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16).padding(.top, 18)
        .onAppear { schreibt = true }
        .habitBlatt(hoehe: 250)
    }
}

// MARK: - Blatt „Ziel“

struct ZielBlatt: View {
    var einheit: Einheit
    @Binding var wert: Double
    @Environment(\.dismiss) private var dismiss
    @State private var entwurf: Double

    init(einheit: Einheit, wert: Binding<Double>) {
        self.einheit = einheit
        _wert = wert
        _entwurf = State(initialValue: einheit.eingerastet(wert.wrappedValue))
    }

    private var hoehe: CGFloat {
        switch einheit.auswahl {
        case .lineal: 300
        case .rad: 500
        case .zweiSpalten: 440
        case .fuellen: 360
        case .keine: 260
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HakenKopf(titel: "Tagesziel", schliessen: { dismiss() }, fertig: { wert = entwurf; dismiss() })
                .padding(.horizontal, 16).padding(.top, 18)
            VerlaufEtikett(text: "Täglich · \(einheit.name)").padding(.top, 18)

            switch einheit.auswahl {
            case .lineal:
                LinealWahl(einheit: einheit, wert: $entwurf).padding(.top, 26)
            case .rad:
                WertRad(eintraege: einheit.werte.map { einheit.text($0) }, index: index)
                    .padding(.horizontal, 28).padding(.top, 8)
            case .zweiSpalten:
                ZweiSpaltenWahl(einheit: einheit, wert: $entwurf).padding(.top, 22)
            case .fuellen:
                FuellWahl(einheit: einheit, wert: $entwurf).padding(.top, 10)
            case .keine:
                Text("Einmal am Tag").font(.system(size: 34, weight: .bold)).padding(.top, 30)
            }
            Spacer(minLength: 0)
        }
        .habitBlatt(hoehe: hoehe)
    }

    private var index: Binding<Int> {
        Binding(get: { einheit.index(von: entwurf) }, set: { entwurf = einheit.werte[$0] })
    }
}

// MARK: - Lineal (Vorbild: Timer „1h 25m“)

struct LinealWahl: View {
    var einheit: Einheit
    @Binding var wert: Double

    private var index: Binding<Int> {
        Binding(get: { einheit.index(von: wert) }, set: { wert = einheit.werte[$0] })
    }

    var body: some View {
        VStack(spacing: 14) {
            // Schnellwahl-Kapseln
            HStack(spacing: 9) {
                ForEach(einheit.schnellwahl, id: \.self) { w in
                    Button { withAnimation(.snappy) { wert = w } } label: {
                        Text(einheit.kapsel(w)).font(.system(size: 17, weight: .medium))
                            .padding(.horizontal, 18).frame(height: 39)
                            .background(Color.white.opacity(0.07), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            Lineal(werte: einheit.werte, markeAlle: einheit.markeAlle, index: index,
                   marke: { einheit.marke($0) }, wertText: einheit.text(wert),
                   wertZahl: einheit.art == .zeit ? einheit.text(wert) : Einheit.zahl(wert),
                   wertWort: einheit.art == .zeit ? nil : einheit.wort(wert))
                .padding(.horizontal, 24)
        }
    }
}

/// Waagrechtes Lineal in Glas-Kapsel: Striche alle 10,7 pt, lange Striche mit Beschriftung, Wert groß in der Mitte.
struct Lineal: View {
    var werte: [Double]
    var markeAlle: Int
    @Binding var index: Int
    var marke: (Double) -> String
    var wertText: String
    var wertZahl: String
    var wertWort: String?

    @State private var pos: Int?
    @State private var wertBreite: CGFloat = 90
    private let abstand: CGFloat = 10.7
    private let hoehe: CGFloat = 71

    var body: some View {
        GeometryReader { g in
            let breite = g.size.width
            ZStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 0) {
                        ForEach(werte.indices, id: \.self) { i in
                            strich(i, mitte: abstand / 2)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollPosition(id: $pos, anchor: .center)
                .scrollTargetBehavior(.viewAligned)
                .safeAreaPadding(.horizontal, (breite - abstand) / 2)
                .mask(LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.12),
                                             .init(color: .black, location: 0.88), .init(color: .clear, location: 1)],
                                     startPoint: .leading, endPoint: .trailing))

                // Mittel-Marken oben und unten
                VStack {
                    Capsule().fill(.white).frame(width: 2.5, height: 6)
                    Spacer()
                    Capsule().fill(.white).frame(width: 2.5, height: 6)
                }
                .padding(.vertical, 5)
                .allowsHitTesting(false)

                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text(wertZahl).font(.system(size: 34, weight: .bold)).monospacedDigit()
                        .contentTransition(.numericText())
                    if let wertWort { Text(wertWort).font(.system(size: 17, weight: .semibold)).foregroundStyle(Color.white.opacity(0.6)) }
                }
                .animation(.snappy(duration: 0.2), value: wertText)
                .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { wertBreite = $0 }
                .allowsHitTesting(false)
            }
            .frame(width: breite, height: hoehe)
            .background(Color.white.opacity(0.07), in: Capsule())
            .overlay { Capsule().strokeBorder(LinearGradient(colors: [.white.opacity(0.16), .white.opacity(0.05)], startPoint: .top, endPoint: .bottom), lineWidth: 0.75) }
            .clipShape(Capsule())
        }
        .frame(height: hoehe)
        .onAppear { pos = index }
        .onChange(of: pos) { _, neu in if let neu, neu != index { index = neu } }
        .onChange(of: index) { _, neu in if pos != neu { withAnimation(.snappy) { pos = neu } } }
        .sensoryFeedback(.selection, trigger: index)
        .accessibilityElement()
        .accessibilityLabel("Ziel")
        .accessibilityValue(wertText)
        .accessibilityAdjustableAction { r in
            switch r {
            case .increment: index = min(index + 1, werte.count - 1)
            case .decrement: index = max(index - 1, 0)
            @unknown default: break
            }
        }
    }

    private func strich(_ i: Int, mitte: CGFloat) -> some View {
        let raster = (werte.count > 1 ? werte[1] - werte[0] : 1) * Double(markeAlle)
        let q = werte[i] / raster
        let lang = abs(q - q.rounded()) < 0.001
        let frei = wertBreite / 2 + 22
        return ZStack {
            VStack {
                Rectangle().fill(Color.white.opacity(lang ? 0.42 : 0.2)).frame(width: 1, height: lang ? 11 : 4.5)
                Spacer()
                Rectangle().fill(Color.white.opacity(lang ? 0.42 : 0.2)).frame(width: 1, height: lang ? 11 : 4.5)
            }
            .padding(.vertical, 5)
            if lang {
                Text(marke(werte[i])).font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.24))
                    .fixedSize()
                    // Beschriftung verschwindet unter dem großen Wert in der Mitte
                    .visualEffect { inhalt, p in
                        let x = p.frame(in: .scrollView(axis: .horizontal)).midX
                        // ausblenden, wo der große Wert liegt (Beschriftung ≈ 36 pt breit)
                        let d = abs(x - mitte) - frei
                        return inhalt.opacity(Double(min(max(d / 14, 0), 1)))
                    }
            }
        }
        .frame(width: abstand, height: hoehe)
    }
}

// MARK: - Rad (Vorbild: „Für …  5 Minuten“)

/// Senkrechtes Rad: Zeilen 45 pt, helle Kapsel in der Mitte, Nachbarn blassen nach außen aus.
struct WertRad: View {
    var eintraege: [String]
    @Binding var index: Int
    var zeile: CGFloat = 45
    var sichtbar = 7
    var schrift: Font = .system(size: 18, weight: .medium)
    var kapsel = true

    @State private var pos: Int?

    var body: some View {
        let hoehe = zeile * CGFloat(sichtbar)
        ZStack {
            if kapsel {
                Capsule().fill(Color.white.opacity(0.07)).frame(height: zeile - 1)
            }
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(eintraege.indices, id: \.self) { i in
                        Text(eintraege[i]).font(schrift).monospacedDigit()
                            .frame(maxWidth: .infinity).frame(height: zeile)
                            .visualEffect { inhalt, p in
                                let y = p.frame(in: .scrollView(axis: .vertical)).midY
                                let d = abs(y - zeile / 2) / zeile
                                let o = d < 1 ? 1 - 0.58 * d : max(0.08, 0.52 - 0.11 * d)
                                return inhalt.opacity(o)
                            }
                    }
                }
                .scrollTargetLayout()
            }
            .scrollPosition(id: $pos, anchor: .center)
            .scrollTargetBehavior(.viewAligned)
            .safeAreaPadding(.vertical, (hoehe - zeile) / 2)
        }
        .frame(height: hoehe)
        .onAppear { pos = index }
        .onChange(of: pos) { _, neu in if let neu, neu != index { index = neu } }
        .onChange(of: index) { _, neu in if pos != neu { withAnimation(.snappy) { pos = neu } } }
        .sensoryFeedback(.selection, trigger: index)
        .accessibilityElement()
        .accessibilityValue(eintraege.indices.contains(index) ? eintraege[index] : "")
        .accessibilityAdjustableAction { r in
            switch r {
            case .increment: index = min(index + 1, eintraege.count - 1)
            case .decrement: index = max(index - 1, 0)
            @unknown default: break
            }
        }
    }
}

// MARK: - Zwei-Spalten-Rad (Vorbild: Uhrzeit-Fenster „09 00“)

struct ZweiSpaltenWahl: View {
    var einheit: Einheit
    @Binding var wert: Double

    private var zehntel: Int { Int((wert * 10).rounded()) }
    private var ganz: Binding<Int> {
        Binding(get: { zehntel / 10 }, set: { setze($0 * 10 + zehntel % 10) })
    }
    private var komma: Binding<Int> {
        Binding(get: { zehntel % 10 }, set: { setze((zehntel / 10) * 10 + $0) })
    }
    private func setze(_ z: Int) { wert = einheit.eingerastet(Double(z) / 10) }

    var body: some View {
        VStack(spacing: 18) {
            Text(einheit.text(wert)).font(.system(size: 34, weight: .bold)).monospacedDigit()
                .contentTransition(.numericText()).animation(.snappy(duration: 0.2), value: wert)
            ZStack {
                Capsule().fill(Color.white.opacity(0.1)).frame(height: 36).padding(.horizontal, 12)
                HStack(spacing: 0) {
                    WertRad(eintraege: (0...Int(einheit.bis)).map { String($0) }, index: ganz,
                            zeile: 36, sichtbar: 6, schrift: .system(size: 22), kapsel: false)
                        .frame(width: 70)
                    Text(",").font(.system(size: 22)).padding(.horizontal, 2)
                    WertRad(eintraege: (0...9).map { String($0) }, index: komma,
                            zeile: 36, sichtbar: 6, schrift: .system(size: 22), kapsel: false)
                        .frame(width: 50)
                    Text(einheit.zeichen ?? einheit.name).font(.system(size: 22)).frame(width: 46, alignment: .leading)
                }
            }
            .frame(width: 236, height: 216)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 38, style: .continuous).fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 38, style: .continuous).fill(Color(0x4A4A4C).opacity(0.55))
                    // leichter Farbschimmer im Glas wie im Vorbild
                    Circle().fill(Color(0xC88AA0).opacity(0.16)).frame(width: 90).blur(radius: 30).offset(x: -30, y: -40)
                    Circle().fill(Color(0x7F9CFF).opacity(0.16)).frame(width: 90).blur(radius: 30).offset(x: 20, y: -30)
                }
                .clipShape(RoundedRectangle(cornerRadius: 38, style: .continuous))
            }
            .overlay { RoundedRectangle(cornerRadius: 38, style: .continuous).strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5) }
            .shadow(color: .black.opacity(0.35), radius: 24, y: 10)
        }
    }
}

// MARK: - Füllbalken (Vorbild: Schwierigkeits-Regler mit Lichtstaub)

struct FuellWahl: View {
    var einheit: Einheit
    @Binding var wert: Double

    var body: some View {
        VStack(spacing: 6) {
            Text(einheit.text(wert)).font(.system(size: 34, weight: .bold)).monospacedDigit()
                .contentTransition(.numericText()).animation(.snappy(duration: 0.2), value: wert)
            Text(Einheit.glaeserText(ml: wert)).font(.system(size: 17)).foregroundStyle(Color(0x9A9A9E))
            FuellBalken(stufen: einheit.werte.count, index: Binding(get: { einheit.index(von: wert) }, set: { wert = einheit.werte[$0] }),
                        wertText: einheit.text(wert))
                .padding(.horizontal, 34).padding(.top, 34)
        }
    }
}

/// Balken 35 pt hoch; links gefülltes Glas mit Lichtstaub und hellem Oberrand, Griff 38 × 53 weiß.
struct FuellBalken: View {
    var stufen: Int
    @Binding var index: Int
    var wertText: String
    private let griffB: CGFloat = 38
    private let griffH: CGFloat = 53
    private let spur: CGFloat = 35

    var body: some View {
        GeometryReader { g in
            let w = g.size.width
            let x = (w - griffB) * CGFloat(index) / CGFloat(max(stufen - 1, 1))
            ZStack(alignment: .leading) {
                // leere Spur
                Capsule().fill(Color.white.opacity(0.07)).frame(height: spur)
                HStack {
                    Circle().fill(Color.white.opacity(0.6)).frame(width: 4.5, height: 4.5)
                    Spacer()
                    Circle().fill(Color.white.opacity(0.6)).frame(width: 4.5, height: 4.5)
                }
                .padding(.horizontal, 16)
                // gefüllter Teil
                ZStack {
                    Capsule().fill(LinearGradient(colors: [Color(0x434C49), Color(0x587069)], startPoint: .leading, endPoint: .trailing))
                    Lichtstaub().clipShape(Capsule())
                    // helle Oberkante wie im Vorbild: oben, zum Griff hin heller, mit weichem Schein
                    ZStack {
                        Capsule().strokeBorder(Color.white.opacity(0.9), lineWidth: 1.2).blur(radius: 2.5)
                        Capsule().strokeBorder(Color.white.opacity(0.95), lineWidth: 0.8)
                    }
                    .mask(LinearGradient(stops: [.init(color: .white, location: 0), .init(color: .white.opacity(0.25), location: 0.35),
                                                 .init(color: .clear, location: 0.6)], startPoint: .top, endPoint: .bottom))
                    .mask(LinearGradient(colors: [.white.opacity(0.35), .white], startPoint: .leading, endPoint: .trailing))
                }
                .frame(width: x + griffB / 2 + 8, height: spur)
                .shadow(color: Color(Dunkel.akzentB).opacity(0.18), radius: 10, y: -2)
                .overlay(alignment: .leading) {
                    Circle().fill(Color.white.opacity(0.6)).frame(width: 4.5, height: 4.5).padding(.leading, 16)
                }
                // Griff
                RoundedRectangle(cornerRadius: 19, style: .continuous).fill(.white)
                    .frame(width: griffB, height: griffH)
                    .overlay { Image(systemName: "drop.fill").font(.system(size: 15, weight: .semibold)).foregroundStyle(.black) }
                    .shadow(color: .black.opacity(0.25), radius: 6, y: 2)
                    .offset(x: x)
            }
            .frame(height: griffH)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { z in
                let anteil = (z.location.x - griffB / 2) / max(w - griffB, 1)
                let neu = min(max(Int((anteil * CGFloat(stufen - 1)).rounded()), 0), stufen - 1)
                if neu != index { withAnimation(.snappy(duration: 0.18)) { index = neu } }
            })
        }
        .frame(height: griffH)
        .sensoryFeedback(.selection, trigger: index)
        .accessibilityElement()
        .accessibilityLabel("Ziel")
        .accessibilityValue(wertText)
        .accessibilityAdjustableAction { r in
            switch r {
            case .increment: index = min(index + 1, stufen - 1)
            case .decrement: index = max(index - 1, 0)
            @unknown default: break
            }
        }
    }
}

/// Feine helle Punkte im gefüllten Balken, leicht funkelnd (ruht bei „Bewegung reduzieren“).
private struct Lichtstaub: View {
    @Environment(\.accessibilityReduceMotion) private var ruhig
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 15, paused: ruhig)) { k in
            let t = ruhig ? 0 : k.date.timeIntervalSinceReferenceDate
            Canvas { ctx, g in
                var s: UInt64 = 0x57A0_B11E
                func zufall() -> Double {
                    s &+= 0x9E37_79B9_7F4A_7C15
                    var z = s
                    z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
                    z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
                    return Double(z ^ (z >> 31)) / Double(UInt64.max)
                }
                let n = Int(g.width / 2.6)
                for _ in 0..<n {
                    let x = zufall() * g.width, y = zufall() * g.height
                    let r = 0.3 + zufall() * 0.55
                    let p = zufall() * 6.28
                    let a = 0.35 + 0.45 * (0.5 + 0.5 * sin(t * 1.6 + p))
                    ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r * 2, height: r * 2)), with: .color(.white.opacity(a)))
                }
            }
        }
        .allowsHitTesting(false)
    }
}
