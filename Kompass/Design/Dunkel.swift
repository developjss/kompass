import SwiftUI

/// Designsystem „Dunkel“ (`docs/plan.md`). Compass ist nur dunkel [ENTSCHEIDUNG – 27.11.2026]. Werte aus den Vorbild-Bildern gemessen (393 × 852 pt).
enum Dunkel {
    // MARK: Farben (Hex)
    static let grund: UInt32 = 0x000000
    /// Glas-Blätter und gruppierte Zeilen
    static let blatt: UInt32 = 0x2B2B2B
    /// Auswahl-Kapseln
    static let kapsel: UInt32 = 0x202020
    /// Eingabefelder
    static let eingabe: UInt32 = 0x1C1C1E
    static let rand: UInt32 = 0x3A3A3C
    /// Fläche des Hauptknopfs
    static let knopf: UInt32 = 0x313532
    static let text: UInt32 = 0xFFFFFF
    static let zweitrangig: UInt32 = 0x96969B   // Vorbild ≈ #8E8E93, aufgehellt für AA auf Blättern
    /// Antwort im Gespräch
    static let antwort: UInt32 = 0x8AB994
    /// Licht oben – Standard, Pro/Belohnung, Intro
    /// Compass-Türkis (Farbton des Kompass-Scheins auf Home), in Helligkeit und Sättigung wie das Salbeigrün des Vorbilds (#779373)
    static let lichtGruen: UInt32 = 0x6E9A94
    static let lichtLila: UInt32 = 0x6F63B0
    static let lichtBlau: UInt32 = 0x5B6878
    /// Akzent-Verlauf Limette → Aqua
    static let akzentA: UInt32 = 0xD3FFA0
    static let akzentB: UInt32 = 0xA9FBEF
    /// Lila für Pro
    static let pro: UInt32 = 0xB8A8FF
    /// Rot für Notfall und Löschen
    static let rot: UInt32 = 0xFF5A5F

    // MARK: Maße (pt)
    static let rand_: CGFloat = 20
    static let knopfHoehe: CGFloat = 54
    static let auswahlHoehe: CGFloat = 58
    static let zeilenHoehe: CGFloat = 52
    static let gruppenRadius: CGFloat = 22
    static let blattRadius: CGFloat = 40
    static let kartenRadius: CGFloat = 32
    static let rundKnopf: CGFloat = 44
    /// Tiefe des Lichtkegels: nach 200 pt fast schwarz
    static let lichtTiefe: CGFloat = 200
}

extension Color {
    init(_ hex: UInt32, deckkraft: Double = 1) {
        self.init(.sRGB, red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255, opacity: deckkraft)
    }
}

/// Farben als `Color` – nur dunkel.
enum DFarbe {
    static let grund = Color(Dunkel.grund)
    static let blatt = Color(Dunkel.blatt)
    static let kapsel = Color(Dunkel.kapsel)
    static let eingabe = Color(Dunkel.eingabe)
    static let rand = Color(Dunkel.rand)
    static let knopf = Color(Dunkel.knopf)
    static let text = Color(Dunkel.text)
    static let zweitrangig = Color(Dunkel.zweitrangig)
    static let antwort = Color(Dunkel.antwort)
    static let pro = Color(Dunkel.pro)
    static let rot = Color(Dunkel.rot)
    static let akzent = LinearGradient(colors: [Color(Dunkel.akzentA), Color(Dunkel.akzentB)], startPoint: .leading, endPoint: .trailing)
    static let akzentFarben = [Color(Dunkel.akzentA), Color(Dunkel.akzentB)]
    /// Glas-Fläche über unscharfem Grund
    static let glas = Color.white.opacity(0.08)
    static let glasRand = Color.white.opacity(0.14)
}

/// Schrift-Stufen (SF Pro, Dynamic Type). Größen aus dem Vorbild, jeweils an eine Textstufe gebunden.
enum DSchrift {
    static let grosserTitel = Font.system(.largeTitle, weight: .bold)            // 34
    static let gespraech = Font.system(size: 20, weight: .regular, design: .default)
    static let ueberschrift = Font.system(.title2, weight: .semibold)            // 22
    static let zeile = Font.system(.body)                                       // 17
    static let zeileFett = Font.system(.body, weight: .semibold)
    static let knopf = Font.system(.body, weight: .medium)
    static let unterzeile = Font.system(.subheadline)                           // 15
    static let etikett = Font.system(.footnote, weight: .semibold)              // 13
    static let tab = Font.system(size: 10, weight: .medium)
    static let walze = Font.system(size: 56, weight: .heavy)
    static let grosseZahl = Font.system(size: 40, weight: .bold)
    static let aufforderung = Font.system(.subheadline, weight: .semibold)
}

/// Gespräch skaliert mit Dynamic Type wie `.title3`.
struct GespraechSchrift: ViewModifier {
    @ScaledMetric(relativeTo: .title3) private var groesse: CGFloat = 20
    func body(content: Content) -> some View { content.font(.system(size: groesse)) }
}

extension View {
    func gespraechSchrift() -> some View { modifier(GespraechSchrift()) }
}

// MARK: - Grund und Licht

enum LichtArt: Sendable { case gruen, lila, blau, aus
    var farbe: Color {
        switch self {
        case .gruen: Color(Dunkel.lichtGruen)
        case .lila: Color(Dunkel.lichtLila)
        case .blau: Color(Dunkel.lichtBlau)
        case .aus: .clear
        }
    }
}

/// Weicher Lichtkegel von oben über schwarzem Grund. Verlauf gemessen im Vorbild (Mitte oben → 200 pt fast schwarz,
/// Ränder oben ≈ ein Drittel der Mitte): elliptisch, Breite 1,6 × Bildschirm, Tiefe 200 pt.
struct LichtOben: View {
    var art: LichtArt = .gruen
    var body: some View {
        GeometryReader { g in
            Rectangle()
                .fill(EllipticalGradient(stops: [
                    .init(color: art.farbe, location: 0),
                    .init(color: art.farbe.opacity(0.78), location: 0.2),
                    .init(color: art.farbe.opacity(0.52), location: 0.4),
                    .init(color: art.farbe.opacity(0.17), location: 0.75),
                    .init(color: .clear, location: 1)
                ], center: .top, startRadiusFraction: 0, endRadiusFraction: 0.5))
                .frame(width: g.size.width * 1.6, height: Dunkel.lichtTiefe * 2)
                .position(x: g.size.width / 2, y: Dunkel.lichtTiefe)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Schwarzer Grund mit Licht oben – für jede Seite.
struct DunkelGrund: ViewModifier {
    var licht: LichtArt = .gruen
    func body(content: Content) -> some View {
        content
            .background { ZStack { DFarbe.grund; LichtOben(art: licht) }.ignoresSafeArea() }
            .foregroundStyle(DFarbe.text)
            .preferredColorScheme(.dark)
    }
}

extension View {
    func dunkelGrund(_ licht: LichtArt = .gruen) -> some View { modifier(DunkelGrund(licht: licht)) }
}

// MARK: - Knöpfe

enum KapselArt: Sendable { case haupt, hell, kauf, rot, leise }

/// Hauptknopf: Kapsel 54 pt, dunkles Glas, unten Glühen Limette → Aqua.
struct KapselStil: ButtonStyle {
    var art: KapselArt = .haupt
    @Environment(\.isEnabled) private var an

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(art == .kauf ? .system(.title3, weight: .medium) : DSchrift.knopf)
            .foregroundStyle(vorder)
            .frame(maxWidth: .infinity, minHeight: Dunkel.knopfHoehe)
            .padding(.horizontal, 20)
            .background { flaeche }
            .clipShape(Capsule())
            .overlay { Capsule().strokeBorder(LinearGradient(colors: [.white.opacity(an ? 0.22 : 0.08), .clear], startPoint: .top, endPoint: .center), lineWidth: 1) }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
            .contentShape(Capsule())
    }

    private var vorder: Color {
        guard an else { return DFarbe.zweitrangig.opacity(0.7) }
        switch art {
        case .hell: return .black
        case .leise: return DFarbe.text
        default: return DFarbe.text
        }
    }

    @ViewBuilder private var flaeche: some View {
        switch art {
        case .haupt:
            ZStack(alignment: .bottom) {
                DFarbe.knopf
                if an {
                    Ellipse().fill(LinearGradient(colors: DFarbe.akzentFarben, startPoint: .leading, endPoint: .trailing))
                        .frame(height: 30).offset(y: 22).blur(radius: 14).opacity(0.75)
                }
            }
            .opacity(an ? 1 : 0.55)
        case .hell:
            LinearGradient(colors: [.white, Color(0xEAF8F2)], startPoint: .top, endPoint: .bottom)
        case .kauf:
            LinearGradient(colors: [Color(0xB6E6C2), Color(0x5C8A68)], startPoint: .top, endPoint: .bottom)
        case .rot:
            ZStack(alignment: .bottom) {
                DFarbe.knopf
                Ellipse().fill(DFarbe.rot).frame(height: 30).offset(y: 22).blur(radius: 14).opacity(0.8)
            }
        case .leise:
            Color.clear
        }
    }
}

extension ButtonStyle where Self == KapselStil {
    static var kapsel: KapselStil { KapselStil() }
    static func kapsel(_ art: KapselArt) -> KapselStil { KapselStil(art: art) }
}

/// „Gedrückt halten zum Festlegen“: füllt sich in `dauer` Sekunden mit Licht, dann `aktion`.
struct HaltenKnopf: View {
    var titel: String
    var dauer: Double = 1.2
    var art: KapselArt = .haupt
    var aktion: () -> Void

    @State private var fuellung: CGFloat = 0
    @State private var fertig = false
    @Environment(\.accessibilityReduceMotion) private var ruhig

    var body: some View {
        Text(titel)
            .font(DSchrift.knopf)
            .frame(maxWidth: .infinity, minHeight: Dunkel.knopfHoehe)
            .background {
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        DFarbe.knopf
                        LinearGradient(colors: art == .rot ? [DFarbe.rot.opacity(0.6), DFarbe.rot] : DFarbe.akzentFarben.map { $0.opacity(0.85) },
                                       startPoint: .leading, endPoint: .trailing)
                            .frame(width: g.size.width * fuellung)
                        Ellipse().fill(LinearGradient(colors: art == .rot ? [DFarbe.rot, DFarbe.rot] : DFarbe.akzentFarben, startPoint: .leading, endPoint: .trailing))
                            .frame(height: 30).offset(y: 22).blur(radius: 14).opacity(0.7)
                            .frame(maxHeight: .infinity, alignment: .bottom)
                    }
                }
            }
            .foregroundStyle(fuellung > 0.5 ? Color.black : DFarbe.text)
            .clipShape(Capsule())
            .overlay { Capsule().strokeBorder(LinearGradient(colors: [.white.opacity(0.22), .clear], startPoint: .top, endPoint: .center), lineWidth: 1) }
            .contentShape(Capsule())
            .onLongPressGesture(minimumDuration: dauer, maximumDistance: 40) {
                fertig.toggle()
                aktion()
                withAnimation(.easeOut(duration: 0.3)) { fuellung = 0 }
            } onPressingChanged: { drueckt in
                withAnimation(drueckt ? .linear(duration: dauer) : .easeOut(duration: 0.25)) { fuellung = drueckt ? 1 : 0 }
            }
            .sensoryFeedback(.success, trigger: fertig)
            .accessibilityElement()
            .accessibilityLabel(titel)
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { aktion() }
    }
}

/// Runder Glas-Knopf (Schließen, Zurück, Bearbeiten), Ø 44.
struct RundKnopf: View {
    var symbol: String
    var beschriftung: String
    var aktion: () -> Void
    var body: some View {
        Button(action: aktion) {
            Image(systemName: symbol).font(.system(size: 17, weight: .semibold))
                .frame(width: Dunkel.rundKnopf, height: Dunkel.rundKnopf)
                .background(Color.white.opacity(0.12), in: Circle())
                .foregroundStyle(DFarbe.text)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(beschriftung)
    }
}

// MARK: - Auswahl und Eingabe

/// Auswahl-Zeile als Kapsel: Symbol grün links, Text.
struct AuswahlKapsel: View {
    var symbol: String?
    var titel: String
    var gewaehlt = false
    var aktion: () -> Void
    var body: some View {
        Button(action: aktion) {
            HStack(spacing: 14) {
                if let symbol {
                    Image(systemName: symbol).font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(DFarbe.akzent).frame(width: 22)
                }
                Text(titel).font(DSchrift.zeile).foregroundStyle(DFarbe.text)
                Spacer(minLength: 0)
                if gewaehlt { Image(systemName: "checkmark.circle.fill").foregroundStyle(DFarbe.akzent) }
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: Dunkel.auswahlHoehe)
            .background(gewaehlt ? Color(0x2C3A30) : DFarbe.kapsel, in: Capsule())
            .overlay { Capsule().strokeBorder(LinearGradient(colors: [.white.opacity(0.16), .white.opacity(0.03)], startPoint: .top, endPoint: .bottom), lineWidth: 1) }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(gewaehlt ? .isSelected : [])
    }
}

/// Eingabefeld als Kapsel.
struct EingabeKapsel: View {
    var platzhalter: String
    @Binding var text: String
    var body: some View {
        TextField("", text: $text, prompt: Text(platzhalter).foregroundStyle(DFarbe.zweitrangig))
            .font(DSchrift.zeile)
            .padding(.horizontal, 20)
            .frame(minHeight: Dunkel.knopfHoehe)
            .background(DFarbe.eingabe, in: Capsule())
            .overlay { Capsule().strokeBorder(DFarbe.rand, lineWidth: 1) }
            .tint(Color(Dunkel.akzentA))
    }
}

// MARK: - Gruppen und Zeilen

/// Gruppe aus Zeilen auf Glas, Radius 22, Trennlinien zwischen den Zeilen.
struct GlasGruppe<Inhalt: View>: View {
    @ViewBuilder var inhalt: Inhalt
    var body: some View {
        VStack(spacing: 0) {
            Group(subviews: inhalt) { teile in
                ForEach(Array(teile.enumerated()), id: \.offset) { i, teil in
                    if i > 0 { Rectangle().fill(Color.white.opacity(0.08)).frame(height: 0.5).padding(.leading, 18) }
                    teil
                }
            }
        }
        .background(DFarbe.glas, in: RoundedRectangle(cornerRadius: Dunkel.gruppenRadius, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: Dunkel.gruppenRadius, style: .continuous).strokeBorder(DFarbe.glasRand.opacity(0.6), lineWidth: 0.5) }
    }
}

/// Zeile: Symbol, Titel, Unterzeile, Wert rechts, Pfeil.
struct GlasZeile: View {
    var symbol: String?
    var titel: String
    var unter: String?
    var wert: String?
    var pfeil = true
    var body: some View {
        HStack(spacing: 14) {
            if let symbol { Image(systemName: symbol).font(.system(size: 16)).foregroundStyle(DFarbe.zweitrangig).frame(width: 22) }
            VStack(alignment: .leading, spacing: 2) {
                Text(titel).font(DSchrift.zeile)
                if let unter { Text(unter).font(DSchrift.unterzeile).foregroundStyle(DFarbe.zweitrangig) }
            }
            Spacer(minLength: 8)
            if let wert { Text(wert).font(DSchrift.zeile).foregroundStyle(DFarbe.zweitrangig) }
            if pfeil { Image(systemName: "chevron.right").font(.system(size: 14, weight: .semibold)).foregroundStyle(DFarbe.zweitrangig) }
        }
        .padding(.horizontal, 18)
        .frame(minHeight: Dunkel.zeilenHoehe)
        .padding(.vertical, unter == nil ? 0 : 8)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// Abschnitts-Kopf über einer Gruppe.
struct DAbschnitt: View {
    var titel: String
    var body: some View {
        Text(titel).font(DSchrift.zeileFett).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 4).padding(.top, 8)
            .accessibilityAddTraits(.isHeader)
    }
}

/// Wochentage als Kreise (Mo–So), an = weiß.
struct TageWahl: View {
    @Binding var tage: Set<Int>
    private let namen = ["M", "D", "M", "D", "F", "S", "S"]
    private let lang = ["Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag", "Sonntag"]
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { i in
                let an = tage.contains(i + 1)
                Button { if an { tage.remove(i + 1) } else { tage.insert(i + 1) } } label: {
                    Text(namen[i]).font(.system(.subheadline, weight: .semibold))
                        .frame(width: 36, height: 36)
                        .foregroundStyle(an ? Color.black : DFarbe.text)
                        .background(an ? Color.white : Color.white.opacity(0.12), in: Circle())
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, minHeight: 44)
                .accessibilityLabel(lang[i])
                .accessibilityAddTraits(an ? .isSelected : [])
            }
        }
    }
}

/// Von/Bis mit Punkt, gestrichelter Linie und Kreis.
struct VonBis: View {
    var von: String
    var bis: String
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(spacing: 2) {
                Circle().fill(DFarbe.zweitrangig).frame(width: 6, height: 6)
                Line(senkrecht: true).stroke(DFarbe.zweitrangig, style: StrokeStyle(lineWidth: 1, dash: [2, 3])).frame(width: 1, height: 34)
                Circle().strokeBorder(DFarbe.zweitrangig, lineWidth: 1).frame(width: 7, height: 7)
            }
            VStack(spacing: 0) {
                zeile("Von", von)
                Rectangle().fill(Color.white.opacity(0.08)).frame(height: 0.5)
                zeile("Bis", bis)
            }
        }
        .padding(.leading, 18)
    }
    private func zeile(_ t: String, _ w: String) -> some View {
        HStack { Text(t).font(DSchrift.zeile); Spacer(); Text(w).font(DSchrift.zeile).foregroundStyle(DFarbe.zweitrangig)
            Image(systemName: "chevron.up.chevron.down").font(.system(size: 12, weight: .semibold)).foregroundStyle(DFarbe.zweitrangig) }
            .padding(.trailing, 18).frame(minHeight: Dunkel.zeilenHoehe)
    }
}

/// Regler mit drei Stufen (Schwierigkeit): Leicht · Steigend · Durchziehen.
struct StufenRegler: View {
    @Binding var stufe: Int
    var stufen: [String]
    var body: some View {
        GeometryReader { g in
            let breite = g.size.width - 44
            let x = breite * CGFloat(stufe) / CGFloat(max(stufen.count - 1, 1))
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.08))
                Capsule().fill(LinearGradient(colors: DFarbe.akzentFarben.map { $0.opacity(0.35) }, startPoint: .leading, endPoint: .trailing))
                    .frame(width: x + 44)
                HStack { ForEach(stufen.indices, id: \.self) { i in
                    Circle().fill(Color.white.opacity(0.5)).frame(width: 5, height: 5)
                    if i < stufen.count - 1 { Spacer() } } }
                    .padding(.horizontal, 20)
                Capsule().fill(.white).frame(width: 40, height: 40)
                    .overlay { Image(systemName: "chart.bar.fill").font(.system(size: 13, weight: .bold)).foregroundStyle(.black) }
                    .offset(x: x + 2)
                    .gesture(DragGesture(minimumDistance: 0).onChanged { w in
                        let n = Int(((w.location.x / max(breite, 1)) * CGFloat(stufen.count - 1)).rounded())
                        let neu = min(max(n, 0), stufen.count - 1)
                        if neu != stufe { stufe = neu }
                    })
            }
        }
        .frame(height: 44)
        .sensoryFeedback(.selection, trigger: stufe)
        .accessibilityElement()
        .accessibilityLabel("Schwierigkeit")
        .accessibilityValue(stufen[stufe])
        .accessibilityAdjustableAction { r in
            switch r { case .increment: stufe = min(stufe + 1, stufen.count - 1)
            case .decrement: stufe = max(stufe - 1, 0)
            @unknown default: break }
        }
    }
}

/// Plakette: Kapsel mit Rand („Pro“, „Besitzt …“).
struct Plakette: View {
    var text: String
    var farbe: Color = DFarbe.pro
    var symbol: String?
    var body: some View {
        HStack(spacing: 4) {
            if let symbol { Image(systemName: symbol).font(.system(size: 11, weight: .bold)) }
            Text(text).font(.system(.caption, weight: .semibold))
        }
        .foregroundStyle(farbe)
        .padding(.horizontal, 8).frame(minHeight: 22)
        .overlay { Capsule().strokeBorder(farbe.opacity(0.8), lineWidth: 1) }
    }
}

/// Seitenpunkte (Karussell), aktiv weiß.
struct DSeitenPunkte: View {
    var anzahl: Int
    var aktiv: Int
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<anzahl, id: \.self) { i in
                Circle().fill(i == aktiv ? Color.white : Color.white.opacity(0.3)).frame(width: 6, height: 6)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Seite \(aktiv + 1) von \(anzahl)")
    }
}

/// Kopf eines Glas-Blatts: links Schließen/Zurück, Mitte Titel, rechts optional Bearbeiten.
struct BlattKopf: View {
    var titel: String
    var zurueck = false
    var schliessen: () -> Void
    var rechts: (symbol: String, beschriftung: String, aktion: () -> Void)?
    var body: some View {
        ZStack {
            Text(titel).font(.system(.title3, weight: .semibold)).accessibilityAddTraits(.isHeader)
            HStack {
                RundKnopf(symbol: zurueck ? "chevron.left" : "xmark", beschriftung: zurueck ? "Zurück" : "Schließen", aktion: schliessen)
                Spacer()
                if let rechts { RundKnopf(symbol: rechts.symbol, beschriftung: rechts.beschriftung, aktion: rechts.aktion) }
            }
        }
        .padding(.horizontal, 16).padding(.top, 16)
    }
}

/// Glas-Blatt: Hintergrund für `.sheet` (dunkles Glas, Radius 40).
extension View {
    func glasBlatt() -> some View {
        self
            .presentationBackground { ZStack { Color(Dunkel.blatt).opacity(0.82); Rectangle().fill(.ultraThinMaterial) } }
            .presentationCornerRadius(Dunkel.blattRadius)
            .presentationDragIndicator(.visible)
            .preferredColorScheme(.dark)
    }
}

/// Aufforderung „Tippen zum Weiter“: Großbuchstaben mit Akzent-Verlauf.
struct Aufforderung: View {
    var text: String
    var body: some View {
        Text(text.uppercased()).font(DSchrift.aufforderung).tracking(0.6).foregroundStyle(DFarbe.akzent)
    }
}

/// Große Zahl mit Akzent-Verlauf (Walze, Werte).
struct AkzentZahl: View {
    var text: String
    var font: Font = DSchrift.walze
    var body: some View { Text(text).font(font).foregroundStyle(DFarbe.akzent).monospacedDigit() }
}

/// Gerade Linie (waagerecht oder senkrecht), z. B. für gestrichelte Verbinder.
struct Line: Shape {
    var senkrecht = false
    func path(in r: CGRect) -> Path {
        Path { p in
            if senkrecht { p.move(to: CGPoint(x: r.midX, y: r.minY)); p.addLine(to: CGPoint(x: r.midX, y: r.maxY)) }
            else { p.move(to: CGPoint(x: r.minX, y: r.midY)); p.addLine(to: CGPoint(x: r.maxX, y: r.midY)) }
        }
    }
}

extension Dunkel {
    /// Kontrast zweier Farben nach WCAG (1…21) – für Tests.
    nonisolated static func kontrast(_ a: UInt32, _ b: UInt32) -> Double {
        func leucht(_ v: UInt32) -> Double {
            func k(_ c: Double) -> Double { c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4) }
            return 0.2126 * k(Double((v >> 16) & 0xFF) / 255) + 0.7152 * k(Double((v >> 8) & 0xFF) / 255) + 0.0722 * k(Double(v & 0xFF) / 255)
        }
        let x = max(leucht(a), leucht(b)), y = min(leucht(a), leucht(b))
        return (x + 0.05) / (y + 0.05)
    }
}

/// Sternenstaub wie im Vorbild: feine weiße Punkte in drei Größen, fest verteilt (gleicher Himmel bei jedem Start),
/// einzelne funkeln langsam. Bei „Bewegung reduzieren“ stehen sie still.
struct Sterne: View {
    var anzahl = 190
    @Environment(\.accessibilityReduceMotion) private var ruhig

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 12, paused: ruhig)) { kontext in
            let t = ruhig ? 0 : kontext.date.timeIntervalSinceReferenceDate
            Canvas { ctx, g in
                var s: UInt64 = 0x5EED_C0DE
                func zufall() -> Double {   // SplitMix64, fester Startwert
                    s &+= 0x9E37_79B9_7F4A_7C15
                    var z = s
                    z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
                    z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
                    return Double((z ^ (z >> 31)) >> 11) / Double(1 << 53)
                }
                for i in 0..<anzahl {
                    let x = zufall() * g.width, y = zufall() * g.height
                    let art = zufall()
                    let r = art > 0.93 ? 1.6 : art > 0.6 ? 1.0 : 0.6
                    var hell = 0.4 + zufall() * 0.6
                    if i % 7 == 0 { hell *= 0.55 + 0.45 * sin(t * 0.9 + Double(i)) }
                    ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)), with: .color(.white.opacity(max(0.08, hell))))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Lichtstrahlen von oben wie im Vorbild (Seite „Apps“): kein Kreis, sondern ein Fächer aus weichen Strahlen,
/// der von einem Punkt über dem oberen Rand (leicht rechts der Mitte) nach unten aufgeht und langsam schimmert.
struct LichtStrahlen: View {
    var art: LichtArt = .gruen
    @Environment(\.accessibilityReduceMotion) private var ruhig

    /// Strahlen: Winkel (Grad, 0 = senkrecht nach unten), halbe Breite (Grad), Stärke, Länge (Anteil), Phase
    private let strahlen: [(Double, Double, Double, Double, Double)] = [
        (-38, 5, 0.10, 0.80, 0.0), (-25, 7, 0.16, 0.95, 1.3), (-13, 4, 0.11, 0.85, 2.1), (-4, 8, 0.22, 1.0, 0.6),
        (7, 5, 0.14, 0.9, 3.0), (17, 8, 0.19, 0.95, 1.9), (29, 5, 0.11, 0.85, 4.2), (41, 6, 0.08, 0.75, 2.6),
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20, paused: ruhig)) { k in
            let t = ruhig ? 0 : k.date.timeIntervalSinceReferenceDate
            Canvas { ctx, g in
                // Grundschein: breit und flach, damit auch die Ränder oben nicht schwarz sind (Vorbild: Rand ≈ ein Viertel der Lichtfarbe)
                ctx.fill(Path(CGRect(x: 0, y: 0, width: g.width, height: 300)), with: .radialGradient(Gradient(stops: [
                    .init(color: art.farbe.opacity(0.34), location: 0), .init(color: art.farbe.opacity(0.2), location: 0.5), .init(color: .clear, location: 1),
                ]), center: CGPoint(x: g.width * 0.56, y: -40), startRadius: 0, endRadius: 400))
                let quelle = CGPoint(x: g.width * 0.56, y: -70)
                let laenge = 520.0
                for s in strahlen {
                    let wink = (s.0 + (ruhig ? 0 : 1.2 * sin(t * 0.12 + s.4))) * .pi / 180
                    let halb = s.1 * .pi / 180
                    let l = laenge * s.3
                    func punkt(_ w: Double) -> CGPoint { CGPoint(x: quelle.x + sin(w) * l, y: quelle.y + cos(w) * l) }
                    var p = Path()
                    p.move(to: quelle); p.addLine(to: punkt(wink - halb)); p.addLine(to: punkt(wink + halb)); p.closeSubpath()
                    let staerke = s.2 * 2.1 * (ruhig ? 1 : 0.8 + 0.2 * sin(t * 0.35 + s.4))
                    ctx.fill(p, with: .linearGradient(Gradient(stops: [
                        .init(color: art.farbe.opacity(staerke * 2.6), location: 0),
                        .init(color: art.farbe.opacity(staerke * 1.5), location: 0.16),
                        .init(color: art.farbe.opacity(staerke * 0.5), location: 0.42),
                        .init(color: .clear, location: 1),
                    ]), startPoint: quelle, endPoint: punkt(wink)))
                }
            }
            .blur(radius: 16)
        }
        .frame(height: 470)
        .frame(maxHeight: .infinity, alignment: .top)
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Lichterstaub im Lichtkegel: wenige weiche, unscharfe Punkte, die langsam treiben (keine scharfen Sterne).
struct Lichterstaub: View {
    var anzahl = 34
    @Environment(\.accessibilityReduceMotion) private var ruhig

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20, paused: ruhig)) { k in
            let t = ruhig ? 0 : k.date.timeIntervalSinceReferenceDate
            Canvas { ctx, g in
                var s: UInt64 = 0xA11C_E5ED
                func zufall() -> Double {
                    s &+= 0x9E37_79B9_7F4A_7C15
                    var z = s
                    z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
                    z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
                    return Double((z ^ (z >> 31)) >> 11) / Double(1 << 53)
                }
                for i in 0..<anzahl {
                    let x0 = zufall(), y0 = zufall(), r = 0.9 + zufall() * 1.6, hell = 0.14 + zufall() * 0.34, tempo = 0.4 + zufall()
                    let x = (x0 + 0.012 * sin(t * 0.21 * tempo + Double(i))) * g.width
                    let y = (y0 * 0.92 + 0.02 * cos(t * 0.17 * tempo + Double(i) * 1.7)) * g.height
                    // nach unten ausblenden
                    let d = hell * (1 - y / g.height) * (ruhig ? 1 : 0.75 + 0.25 * sin(t * 0.5 + Double(i)))
                    ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)), with: .color(.white.opacity(max(0, d))))
                }
            }
            .blur(radius: 0.9)
        }
        .frame(height: 400)
        .frame(maxHeight: .infinity, alignment: .top)
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Grund der Übersichtsseiten: Schwarz, Lichtstrahlen von oben, Lichterstaub.
struct StrahlenGrund: ViewModifier {
    var licht: LichtArt = .gruen
    func body(content: Content) -> some View {
        content
            .background {
                ZStack(alignment: .top) {
                    DFarbe.grund
                    LichtStrahlen(art: licht)
                    Lichterstaub()
                }
                .ignoresSafeArea()
            }
            .foregroundStyle(DFarbe.text)
            .preferredColorScheme(.dark)
    }
}

extension View {
    func strahlenGrund(_ licht: LichtArt = .gruen) -> some View { modifier(StrahlenGrund(licht: licht)) }
}
