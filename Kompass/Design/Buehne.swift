import SwiftUI

// Nachtblau: jede Hauptseite in drei Ebenen – Bühne (Verlauf, Lichtkegel, Marke, Wort, Saum), eine meist leere
// zweite Ebene und die Karte vorn. Kompass ist eine Kalender-App; die Fliegerei steckt in drei Momenten (Überflug auf
// Home, 747 im Fokus, Bordkarte als Statistik), nicht in Bildern auf den Seiten (docs/produkt/design.md §2a).

/// Die echten Fotos (Assets „nachtblau-…“, freigestellt; Heck der 747 auf Nachtblau getönt).
enum Objekt: String, CaseIterable, Sendable {
    case b747 = "nachtblau-b747"
    case b747Abflug = "nachtblau-b747-abflug"
    case landebahn = "nachtblau-landebahn"
    case landebahnNacht = "nachtblau-landebahn-nacht"
    var bild: Image { Image(rawValue) }
}

/// Wo ein Objekt liegt: Abstand vom rechten Rand (negativ = ragt hinaus), von oben, Breite, Drehung in Grad.
/// Nur noch der Fokus hat ein Objekt; `ueberflug` ist die Startlage des 747 auf Home (Easter Egg, `Ueberflug`).
struct Platz: Sendable, Equatable {
    var rechts: CGFloat = 0
    var oben: CGFloat
    var breite: CGFloat
    var drehung: Double = 0
    var links: CGFloat? = nil

    /// Fokus: Flugzeug links unten, fliegt nach rechts oben (Bewegung über `FokusBlatt`)
    static let fokus = Platz(oben: 0, breite: 190, drehung: -8, links: 0)
    /// Home: der 747 startet links außerhalb und zieht einmal über die Bühne
    static let ueberflug = Platz(oben: 150, breite: 240, drehung: -6, links: -260)
}

/// Das Wort auf der Bühne: Zeilen in Großbuchstaben, die letzte in Dunst; optional eine kleine Zeile darunter.
/// Das Wort ist die Aussage der Seite („3 von 4 auf Kurs“) – nie ein Etikett.
struct Wort: Sendable, Equatable {
    var zeilen: [String]
    var akzent: String
    var klein: String? = nil
    var groesse: CGFloat = Wort.gross

    static let kleinGroesse: CGFloat = 56
    static let mittel: CGFloat = 64
    static let gross: CGFloat = 72
    static let riesig: CGFloat = 98
}

/// Ebene 1: Nachtblau-Verlauf (168°) mit Lichtkegel oben rechts, Marke (Titel, Hinweis, Knöpfe), dem Wort und dem
/// Saum, mit dem die Bühne unten in den Grund ausläuft. Ragt oben unter die Statusleiste.
struct Buehne<Marke: View, Extra: View>: View {
    var hoehe: CGFloat = Mass.buehne
    var wort: Wort
    /// Höhe der Statusleiste, die die Bühne überdeckt (0 in Blättern ohne Statusleiste)
    var sicherOben: CGFloat = 54
    @ViewBuilder var marke: Marke
    @ViewBuilder var extra: Extra

    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: Farbe.buehneVerlauf, startPoint: .top, endPoint: UnitPoint(x: 0.2, y: 1))
            Schein()
            Saum(hoehe: Mass.saum(fuer: hoehe))
            WortText(wort: wort)
                .padding(.leading, 20)
                .padding(.top, sicherOben + (hoehe <= Mass.buehneKurz ? 48 : 60))
            extra
            HStack(spacing: 10) { marke }
                .padding(.horizontal, 20)
                .padding(.top, sicherOben + 8)
                .foregroundStyle(Farbe.wort)
        }
        .frame(height: hoehe)
        .frame(maxWidth: .infinity)
        .clipped()
    }
}

extension Buehne where Extra == EmptyView {
    init(hoehe: CGFloat = Mass.buehne, wort: Wort, sicherOben: CGFloat = 54, @ViewBuilder marke: () -> Marke) {
        self.init(hoehe: hoehe, wort: wort, sicherOben: sicherOben, marke: marke, extra: { EmptyView() })
    }
}

/// Ebene 1a: Lichtkegel – ein weicher Kreis (380 pt) oben rechts, wie das Licht hinter einem Produktfoto.
struct Schein: View {
    var body: some View {
        GeometryReader { g in
            RadialGradient(colors: [Farbe.schein.opacity(0.30), .clear], center: .center, startRadius: 0, endRadius: 190 * 0.68)
                .frame(width: 380, height: 380)
                .position(x: g.size.width + 90 - 190, y: -70 + 190)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Ebene 1b: Saum – die untersten Punkte der Bühne laufen weich in den Grund aus (40 % = 4 %, 68 % = 22 %, 88 % = 70 %); das Wort steht darüber.
struct Saum: View {
    var hoehe: CGFloat
    var body: some View {
        VStack { Spacer(minLength: 0)
            LinearGradient(stops: [.init(color: Farbe.grund.opacity(0), location: 0), .init(color: Farbe.grund.opacity(0.04), location: 0.40),
                                   .init(color: Farbe.grund.opacity(0.22), location: 0.68), .init(color: Farbe.grund.opacity(0.70), location: 0.88), .init(color: Farbe.grund, location: 1)],
                           startPoint: .top, endPoint: .bottom)
                .frame(height: hoehe)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Das Wort: Serif, Großbuchstaben, Zeilenabstand 0,86, letztes Wort in Dunst.
struct WortText: View {
    var wort: Wort
    var body: some View {
        VStack(alignment: .leading, spacing: -wort.groesse * 0.34) {
            ForEach(Array(wort.zeilen.enumerated()), id: \.offset) { _, z in
                Text(z.uppercased()).font(.wort(wort.groesse)).foregroundStyle(Farbe.wort)
            }
            Text(wort.akzent.uppercased()).font(.wort(wort.groesse)).foregroundStyle(Farbe.wortAkzent)
            if let k = wort.klein {
                Text(k.uppercased()).font(.etikett).tracking(1).foregroundStyle(Farbe.wort.opacity(0.85))
                    .padding(.top, 12 + wort.groesse * 0.34).frame(maxWidth: 250, alignment: .leading).lineLimit(2)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .frame(maxWidth: 300, alignment: .leading)
        .accessibilityElement(children: .combine)
        .allowsHitTesting(false)
    }
}

/// Ebene 2: Foto, freigestellt, mit zweistufigem Schatten, nie antippbar (Fokus, Überflug).
struct ObjektBild: View {
    var objekt: Objekt
    var platz: Platz
    var body: some View {
        GeometryReader { g in
            let bild = objekt.bild.resizable().scaledToFit().frame(width: platz.breite)
                .rotationEffect(.degrees(platz.drehung))
                .shadow(color: Farbe.schatten.opacity(0.22), radius: 4, y: 6)
                .shadow(color: Farbe.schatten.opacity(0.28), radius: 17, y: 26)
            if let l = platz.links {
                bild.offset(x: l, y: platz.oben)
            } else {
                bild.frame(width: g.size.width, alignment: .trailing).offset(x: -platz.rechts, y: platz.oben)
            }
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

/// Ebene 3: Creme-Karte, schiebt sich 44 pt über die Bühne – genau eine Hauptaktion darin.
/// Oben eine Innenlinie 1 pt in Creme, Doppelschatten (eng und weit).
struct VornKarte<Inhalt: View>: View {
    var abstand: CGFloat = 8
    @ViewBuilder var inhalt: Inhalt
    var body: some View {
        VStack(alignment: .leading, spacing: abstand) { inhalt }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Farbe.karte, in: RoundedRectangle(cornerRadius: Mass.karteVorn, style: .continuous))
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: Mass.karteVorn, style: .continuous)
                    .strokeBorder(LinearGradient(colors: [Farbe.wort.opacity(0.55), .clear], startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.15)), lineWidth: 1)
            }
            .shadow(color: Farbe.schatten.opacity(0.10), radius: 5, y: 4)
            .shadow(color: Farbe.schatten.opacity(0.28), radius: 24, y: 24)
            .padding(.horizontal, Mass.rand)
            .padding(.top, Mass.karteVornVersatz)
    }
}

/// Seite mit Bühne oben (ragt unter die Statusleiste), Inhalt darunter, Fuß. Ersetzt `Seite` auf den Hauptseiten.
/// Der Inhalt bringt seinen Seitenrand selbst mit (`VornKarte` hat ihn; Listen `.padding(.horizontal, Mass.rand)`).
struct BuehnenSeite<Marke: View, Extra: View, Inhalt: View>: View {
    var hoehe: CGFloat = Mass.buehne
    var wort: Wort
    /// true = mit Seitenfuß; Standard ohne – der Speicherort steht in den Einstellungen
    var fuss = false
    @ViewBuilder var marke: Marke
    @ViewBuilder var extra: Extra
    @ViewBuilder var inhalt: Inhalt

    var body: some View {
        GeometryReader { g in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Buehne(hoehe: hoehe, wort: wort, sicherOben: g.safeAreaInsets.top, marke: { marke }, extra: { extra })
                    VStack(alignment: .leading, spacing: 0) { inhalt }
                        .frame(maxWidth: 720)
                        .frame(maxWidth: .infinity)
                    if fuss {
                        SeitenFuss()
                            .padding(.horizontal, Mass.rand)
                            .padding(.top, Mass.abschnitt)
                            .frame(maxWidth: 720)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.bottom, 32)
            }
            .ignoresSafeArea(edges: .top)
        }
        .background(Farbe.grund.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }
}

extension BuehnenSeite where Extra == EmptyView {
    init(hoehe: CGFloat = Mass.buehne, wort: Wort, fuss: Bool = false, @ViewBuilder marke: () -> Marke, @ViewBuilder inhalt: () -> Inhalt) {
        self.init(hoehe: hoehe, wort: wort, fuss: fuss, marke: marke, extra: { EmptyView() }, inhalt: inhalt)
    }
}

/// Easter Egg 1: ist der Tag geschafft, zieht der echte 747 einmal still über die Bühne – 7 s, dann ist er weg.
/// Einmal je Tag (`gesehen` = Tag-Text). Bei „Bewegung reduzieren“ gar nicht.
struct Ueberflug: View {
    var heute: String
    @AppStorage("ueberflug.gesehen") private var gesehen = ""
    @Environment(\.accessibilityReduceMotion) private var ruhig
    @State private var fliegt = false

    var body: some View {
        if !ruhig && Self.faellig(gesehen: gesehen, heute: heute) {
            GeometryReader { g in
                Objekt.b747.bild.resizable().scaledToFit().frame(width: Platz.ueberflug.breite)
                    .rotationEffect(.degrees(Platz.ueberflug.drehung))
                    .scaleEffect(fliegt ? 1.05 : 0.85)
                    .opacity(fliegt ? 0 : 0.92)
                    .shadow(color: .black.opacity(0.35), radius: 12, y: 18)
                    .offset(x: fliegt ? g.size.width + 120 : Platz.ueberflug.links ?? -260, y: Platz.ueberflug.oben + (fliegt ? -70 : 60))
                    .onAppear {
                        withAnimation(.timingCurve(0.3, 0.05, 0.2, 1, duration: 7).delay(0.6)) { fliegt = true }
                        gesehen = heute
                    }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    /// Fällig, wenn heute noch kein Überflug war.
    nonisolated static func faellig(gesehen: String, heute: String) -> Bool { gesehen != heute }
}

/// Kleines Etikett in Versalien über dem Karten-Titel („Dein nächster Schritt“)
struct Etikett: View {
    var text: String
    var body: some View {
        Text(text.uppercased()).font(.etikett).tracking(1.2).foregroundStyle(Farbe.zweitrangig)
    }
}

/// Marke oben auf der Bühne: Name der Seite in Versalien mit Laufweite
struct MarkenTitel: View {
    var text: String
    var body: some View {
        Text(text.uppercased()).font(.marke).tracking(2.4).lineLimit(1).minimumScaleFactor(0.7).accessibilityAddTraits(.isHeader)
    }
}

/// Hinweis rechts in der Marke (Datum, Zeitraum), Versalien 12 bold, 75 %
struct MarkenHinweis: View {
    var text: String
    var body: some View {
        Text(text.uppercased()).font(.etikett).tracking(1).opacity(0.75).lineLimit(1)
    }
}

/// Zurück in der Marke – jede Bühnen-Seite, die im Stapel liegt, braucht ihn (die Navigationsleiste ist versteckt).
struct ZurueckKnopf: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View { RahmenKnopf(symbol: "chevron.left", beschriftung: "Zurück") { dismiss() } }
}

/// Runder Knopf mit Rahmen (36 pt) für die Marke: +, i, ‹, ›, ×
struct RahmenKnopf: View {
    var symbol: String
    var beschriftung: String
    var voll = false
    var aktion: () -> Void
    var body: some View {
        Button(action: aktion) {
            Image(systemName: symbol).font(.system(size: 14, weight: .heavy))
                .frame(width: 36, height: 36)
                .background(voll ? Farbe.handlung : .clear, in: Circle())
                .overlay(Circle().strokeBorder(voll ? .clear : Color.primary.opacity(0.9), lineWidth: 1.5))
                .foregroundStyle(voll ? Farbe.aufFarbe : Color.primary)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(beschriftung)
    }
}

/// Knöpfe: haupt (Schwarz, dunkel Creme; füllt die Breite), leise (Rahmen), rot (Löschen, in Palette). 50 pt, klein 40 pt.
enum KnopfArt: Sendable { case haupt, leise, rot }

struct KnopfStil: ButtonStyle {
    var art: KnopfArt
    var klein = false
    var breit = false
    @Environment(\.isEnabled) private var aktiv
    func makeBody(configuration c: Configuration) -> some View {
        c.label
            .font(.kompass(klein ? .subheadline : .body, .heavy))
            .lineLimit(1)
            .padding(.horizontal, klein ? 16 : 20)
            .frame(minHeight: klein ? Mass.knopfKlein : Mass.knopf)
            .frame(maxWidth: art == .haupt || breit ? .infinity : nil)
            .background(hintergrund, in: Capsule())
            .overlay(Capsule().strokeBorder(Farbe.linie, lineWidth: art == .leise ? 1.5 : 0))
            .foregroundStyle(vordergrund)
            .opacity(!aktiv ? 0.4 : c.isPressed ? 0.8 : 1)
            .scaleEffect(c.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: c.isPressed)
    }
    private var hintergrund: Color {
        switch art { case .haupt: Farbe.handlung; case .leise: .clear; case .rot: Farbe.warnungGrund }
    }
    private var vordergrund: Color {
        switch art { case .haupt: Farbe.aufFarbe; case .leise: Farbe.text; case .rot: Farbe.warnung }
    }
}

extension ButtonStyle where Self == KnopfStil {
    static var haupt: KnopfStil { KnopfStil(art: .haupt) }
    static var leise: KnopfStil { KnopfStil(art: .leise) }
    static var rot: KnopfStil { KnopfStil(art: .rot) }
    static var hauptKlein: KnopfStil { KnopfStil(art: .haupt, klein: true) }
    static var leiseKlein: KnopfStil { KnopfStil(art: .leise, klein: true) }
    static var leiseBreit: KnopfStil { KnopfStil(art: .leise, breit: true) }
    static var rotBreit: KnopfStil { KnopfStil(art: .rot, breit: true) }
}

/// Auswahl-Kachel (Was anlegen, Einstellungen): Zeichen im Kreis, Titel, Unterzeile; gewählt = schwarzer Rand.
struct AuswahlKachel: View {
    var symbol: String
    var titel: String
    var unter: String? = nil
    var an = false
    var aktion: () -> Void
    var body: some View {
        Button(action: aktion) { AuswahlKachelInhalt(symbol: symbol, titel: titel, unter: unter, an: an) }
            .buttonStyle(.plain)
            .accessibilityLabel(unter.map { "\(titel): \($0)" } ?? titel)
            .accessibilityAddTraits(an ? .isSelected : [])
    }
}

/// Dieselbe Kachel ohne Knopf – für `NavigationLink` und `Menu`.
struct AuswahlKachelInhalt: View {
    var symbol: String
    var titel: String
    var unter: String? = nil
    var an = false
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZeichenKreis(symbol: symbol)
            Spacer(minLength: 2)
            Text(titel).font(.kompass(.body, .heavy)).foregroundStyle(Farbe.text).lineLimit(2).multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true)
            if let unter {
                Text(unter).font(.kompass(.footnote, .semibold)).foregroundStyle(Farbe.zweitrangig).lineLimit(2).multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
        .background(Farbe.karte, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(an ? Farbe.handlung : Farbe.linie, lineWidth: an ? 2.5 : 1.5))
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

/// Fortschritts-Ring: Bahn in `linie`, Weg in `handlung`, Zahl in der Mitte. 56 pt, groß 96 pt.
struct FortschrittRing: View {
    var anteil: Double
    var gross = false
    /// nil = Prozent aus `anteil`; sonst eigener Text (z. B. „3/5“)
    var text: String? = nil
    var symbol: String? = nil

    var body: some View {
        let s: CGFloat = gross ? 96 : 56
        let strich: CGFloat = gross ? 8 : 5
        ZStack {
            Circle().stroke(Farbe.linie, lineWidth: strich)
            Circle().trim(from: 0, to: max(0.001, min(1, anteil)))
                .stroke(Farbe.handlung, style: StrokeStyle(lineWidth: strich, lineCap: .round))
                .rotationEffect(.degrees(-90))
            if let symbol {
                Image(systemName: symbol).font(.system(size: gross ? 30 : 18, weight: .bold)).foregroundStyle(Farbe.text)
            } else {
                Text(text ?? Zahl.prozent(anteil))
                    .font(gross ? .zahl : .kompass(.caption, .heavy))
                    .foregroundStyle(Farbe.text).monospacedDigit().lineLimit(1).minimumScaleFactor(0.6).padding(gross ? 14 : 7)
            }
        }
        .frame(width: s, height: s)
        .accessibilityHidden(true)
    }
}

/// Lage eines Ziels als Pille, direkt aus der Rechnung (§4).
extension LagePille {
    init(_ lage: Kurs.Lage) {
        self.init(text: lage.text, art: lage == .hinterher ? .hinten : lage == .ueberfaellig ? .kritisch : .gut)
    }
}

/// Die Frage eines Schritts: Serif 40, das Fragezeichen in Akzent („Wann?“)
struct FrageWort: View {
    var text: String
    var body: some View {
        let frage = text.hasSuffix("?")
        (Text(frage ? String(text.dropLast()) : text) + Text(frage ? "?" : "").foregroundStyle(Farbe.akzent))
            .font(.system(size: 40, weight: .regular, design: .serif))
            .foregroundStyle(Farbe.text)
            .lineLimit(2)
            .minimumScaleFactor(0.7)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }
}

/// Schritt-Punkte statt Fortschrittsbalken (Hick: der Weg ist sichtbar, lenkt aber nicht ab)
struct SchrittPunkte: View {
    var anzahl: Int
    var aktiv: Int
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<max(1, anzahl), id: \.self) { i in
                Circle().fill(i <= aktiv ? Farbe.handlung : Farbe.linie).frame(width: 8, height: 8)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Schritt \(aktiv + 1) von \(anzahl)")
    }
}

/// „Mehr“-Taste (Stufen statt Listen): zugeklappt sagt sie, was dahinter liegt.
struct MehrKnopf: View {
    @Binding var offen: Bool
    var zu: String
    var auf = "Weniger"
    var body: some View {
        Button { withAnimation(.snappy(duration: 0.25)) { offen.toggle() } } label: {
            Label(offen ? auf : zu, systemImage: offen ? "chevron.up" : "chevron.down")
        }
        .buttonStyle(.leiseBreit)
        .accessibilityHint(offen ? "Klappt ein" : "Klappt aus")
    }
}

/// Lage als Pille: im Plan / voraus (weich), hinterher (Dunst mit Nachtblau), überfällig (Nachtblau mit Creme)
struct LagePille: View {
    var text: String
    var art: Art = .gut
    enum Art: Sendable { case gut, hinten, kritisch }
    var body: some View {
        Text(text).font(.kompass(.caption, .heavy)).padding(.horizontal, 10).padding(.vertical, 4)
            .background(grund, in: Capsule()).foregroundStyle(vorn).lineLimit(1)
    }
    private var grund: Color { switch art { case .gut: Farbe.akzentWeich; case .hinten: Farbe.warnungGrund; case .kritisch: Farbe.kritischGrund } }
    private var vorn: Color { switch art { case .gut: Farbe.text; case .hinten: Farbe.warnung; case .kritisch: Farbe.kritisch } }
}

#Preview("Bühne") {
    ScrollView {
        VStack(spacing: 0) {
            Buehne(wort: Wort(zeilen: ["Jetzt"], akzent: "dran.")) {
                MarkenTitel(text: "Kompass"); Spacer(); MarkenHinweis(text: "Di · 24. Nov")
                RahmenKnopf(symbol: "plus", beschriftung: "Neu") {}
            }
            VornKarte {
                Etikett(text: "Führerschein Klasse B · 40 min")
                Text("Theorie-Fragebogen Kapitel 4").font(.karteTitel).foregroundStyle(Farbe.text)
                HStack(spacing: 8) {
                    Button { } label: { Label("Fokus starten", systemImage: "play.fill") }.buttonStyle(.haupt)
                    Button("Erledigt") { }.buttonStyle(.leise)
                }
            }
            HStack { LagePille(text: "im Plan"); LagePille(text: "hinterher", art: .hinten); LagePille(text: "überfällig", art: .kritisch) }.padding()
        }
    }
    .background(Farbe.grund)
    .ignoresSafeArea(edges: .top)
}

/// Einstell-Kachel (Blattwerk): Zeichen im Kreis, Titel, Wert, Unterzeile. Die Farb-Parameter bleiben für
/// die Aufrufer erhalten, wirken aber nicht mehr – Blattwerk nutzt nur Palette-Farben.
struct EinstellKachelInhalt: View {
    var symbol: String
    var titel: String
    var wert: String
    var unter: String? = nil
    var farbe: Color = Farbe.handlung
    var hinweis = false
    var hervor = false
    var verlauf = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                ZeichenKreis(symbol: symbol)
                Spacer()
                if hinweis {
                    Image(systemName: "exclamationmark").font(.caption.weight(.heavy)).foregroundStyle(Farbe.warnungGrund)
                        .frame(width: 22, height: 22).background(Farbe.warnung, in: Circle())
                }
            }
            Spacer(minLength: 6)
            Text(titel).font(.kompass(.subheadline, .heavy)).foregroundStyle(Farbe.text)
            Text(wert).font(.unterzeile).foregroundStyle(Farbe.text).lineLimit(1)
            if let unter { Text(unter).font(.klein).foregroundStyle(Farbe.zweitrangig).lineLimit(1) }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
        .background(Farbe.karte, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(hervor ? Farbe.handlung : Farbe.linie, lineWidth: hervor ? 2.5 : 1.5))
        .accessibilityElement(children: .combine)
    }
}
