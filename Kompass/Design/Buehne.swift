import SwiftUI

// Blattwerk: jede Hauptseite in drei Ebenen – Bühne (Fläche, Marke, Wort), Objekt (echtes Foto) davor, Karte vorn.
// Maße wie im Prototyp (docs/produkt/design.md §2a): Bühne 360 (kurz 250, lang 430), Marke bei y 62, Wort bei y 118 / x 20.

/// Die echten Bilder (Assets „blattwerk-…“, einzeln skaliert, freigestellt).
enum Objekt: String, CaseIterable, Sendable {
    case a380 = "blattwerk-a380"
    case b747 = "blattwerk-b747"
    case b747Abflug = "blattwerk-b747-abflug"
    case tower = "blattwerk-tower"
    case tower2 = "blattwerk-tower-2"
    case kompassKugel = "blattwerk-kompass-kugel"
    case kompass = "blattwerk-kompass"
    case bordkarte = "blattwerk-bordkarte"
    case landebahn = "blattwerk-landebahn"
    case landebahnNacht = "blattwerk-landebahn-nacht"
    var bild: Image { Image(rawValue) }
}

/// Wo ein Objekt auf der Bühne liegt: Abstand vom rechten Rand (negativ = ragt hinaus), Abstand von oben, Breite, Drehung in Grad.
/// Werte aus dem Prototyp – je Seite genau eine Platzierung; `links` statt `rechts` für Objekte am linken Rand.
struct Platz: Sendable, Equatable {
    var rechts: CGFloat = 0
    var oben: CGFloat
    var breite: CGFloat
    var drehung: Double = 0
    var links: CGFloat? = nil

    static let home = Platz(rechts: -90, oben: 166, breite: 360, drehung: -8)
    static let kalender = Platz(rechts: -70, oben: 118, breite: 270, drehung: -14)
    static let neu = Platz(rechts: -70, oben: 62, breite: 230, drehung: 10)
    static let assistent = Platz(rechts: 6, oben: 34, breite: 150)
    static let fortschritt = Platz(rechts: -96, oben: 118, breite: 300, drehung: -12)
    static let ziel = Platz(rechts: -150, oben: 136, breite: 450, drehung: -6)
    static let habits = Platz(rechts: -130, oben: 44, breite: 300, drehung: -10)
    static let aufgabe = Platz(rechts: -130, oben: 30, breite: 380, drehung: -4)
    static let analyseZiel = Platz(rechts: -170, oben: 92, breite: 430, drehung: -6)
    static let analyseHabit = Platz(rechts: -80, oben: 70, breite: 220, drehung: 14)
    static let einstellungen = Platz(rechts: 10, oben: 40, breite: 130)
    static let rueckblick = Platz(rechts: -70, oben: 186, breite: 330, drehung: -16)
    /// Fokus: Flugzeug links unten, fliegt nach rechts oben (Bewegung über `FokusBlatt`)
    static let fokus = Platz(oben: 0, breite: 190, drehung: -8, links: 0)
}

/// Das Wort auf der Bühne: Zeilen in Großbuchstaben, die letzte in Grün; optional eine kleine Zeile darunter.
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

/// Ebene 1 + 2: Rosé-Fläche mit Marke (Titel, Hinweis, Knöpfe), dem Wort und dem Objekt. Ragt oben unter die Statusleiste.
struct Buehne<Marke: View, Extra: View>: View {
    var hoehe: CGFloat = Mass.buehne
    var wort: Wort
    var objekt: Objekt? = nil
    var platz: Platz = .home
    /// Höhe der Statusleiste, die die Bühne überdeckt (0 in Blättern ohne Statusleiste)
    var sicherOben: CGFloat = 54
    @ViewBuilder var marke: Marke
    @ViewBuilder var extra: Extra

    var body: some View {
        ZStack(alignment: .topLeading) {
            Farbe.buehne
            WortText(wort: wort)
                .padding(.leading, 20)
                .padding(.top, sicherOben + 64)
            if let objekt { ObjektBild(objekt: objekt, platz: platz) }
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
    init(hoehe: CGFloat = Mass.buehne, wort: Wort, objekt: Objekt? = nil, platz: Platz = .home, sicherOben: CGFloat = 54, @ViewBuilder marke: () -> Marke) {
        self.init(hoehe: hoehe, wort: wort, objekt: objekt, platz: platz, sicherOben: sicherOben, marke: marke, extra: { EmptyView() })
    }
}

/// Das Wort: Serif, Großbuchstaben, Zeilenabstand 0,86, letztes Wort in Grün.
struct WortText: View {
    var wort: Wort
    var body: some View {
        VStack(alignment: .leading, spacing: -wort.groesse * 0.12) {
            ForEach(Array(wort.zeilen.enumerated()), id: \.offset) { _, z in
                Text(z.uppercased()).font(.wort(wort.groesse)).foregroundStyle(Farbe.wort)
            }
            Text(wort.akzent.uppercased()).font(.wort(wort.groesse)).foregroundStyle(Farbe.handlung)
            if let k = wort.klein {
                Text(k.uppercased()).font(.etikett).tracking(1).foregroundStyle(Farbe.wort.opacity(0.85))
                    .padding(.top, 12 + wort.groesse * 0.12).frame(maxWidth: 250, alignment: .leading).lineLimit(2)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .frame(maxWidth: 330, alignment: .leading)
        .accessibilityElement(children: .combine)
        .allowsHitTesting(false)
    }
}

/// Ebene 2: Foto, freigestellt, mit weichem Schatten, nie antippbar.
struct ObjektBild: View {
    var objekt: Objekt
    var platz: Platz
    var body: some View {
        GeometryReader { g in
            let bild = objekt.bild.resizable().scaledToFit().frame(width: platz.breite)
                .rotationEffect(.degrees(platz.drehung))
                .shadow(color: Farbe.schatten.opacity(0.28), radius: 13, y: 24)
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

/// Ebene 3: weiße Karte, schiebt sich 38 pt über die Bühne – genau eine Hauptaktion darin.
struct VornKarte<Inhalt: View>: View {
    var abstand: CGFloat = 8
    @ViewBuilder var inhalt: Inhalt
    var body: some View {
        VStack(alignment: .leading, spacing: abstand) { inhalt }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Farbe.karte, in: RoundedRectangle(cornerRadius: Mass.karteVorn, style: .continuous))
            .shadow(color: Farbe.schatten.opacity(0.28), radius: 20, y: 18)
            .padding(.horizontal, Mass.rand)
            .padding(.top, Mass.karteVornVersatz)
    }
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
        Text(text.uppercased()).font(.marke).tracking(2.4).accessibilityAddTraits(.isHeader)
    }
}

/// Hinweis rechts in der Marke (Datum, Zeitraum), Versalien 12 bold, 75 %
struct MarkenHinweis: View {
    var text: String
    var body: some View {
        Text(text.uppercased()).font(.etikett).tracking(1).opacity(0.75).lineLimit(1)
    }
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

/// Knöpfe: haupt (Grün, füllt die Breite), leise (Rahmen), rot (Rosé/Weinrot, z. B. Löschen). 50 pt, klein 40 pt.
enum KnopfArt: Sendable { case haupt, leise, rot }

struct KnopfStil: ButtonStyle {
    var art: KnopfArt
    var klein = false
    func makeBody(configuration c: Configuration) -> some View {
        c.label
            .font(.kompass(klein ? .subheadline : .body, .heavy))
            .lineLimit(1)
            .padding(.horizontal, klein ? 16 : 20)
            .frame(minHeight: klein ? Mass.knopfKlein : Mass.knopf)
            .frame(maxWidth: art == .haupt ? .infinity : nil)
            .background(hintergrund, in: Capsule())
            .overlay(Capsule().strokeBorder(Farbe.linie, lineWidth: art == .leise ? 1.5 : 0))
            .foregroundStyle(vordergrund)
            .opacity(c.isPressed ? 0.8 : 1)
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
}

/// Lage als Pille: im Plan / voraus (grün weich), hinterher (Rosé mit Weinrot), überfällig (Weinrot mit Rosé)
struct LagePille: View {
    var text: String
    var art: Art = .gut
    enum Art: Sendable { case gut, hinten, kritisch }
    var body: some View {
        Text(text).font(.kompass(.caption, .heavy)).padding(.horizontal, 10).padding(.vertical, 4)
            .background(grund, in: Capsule()).foregroundStyle(vorn).lineLimit(1)
    }
    private var grund: Color { switch art { case .gut: Farbe.akzentWeich; case .hinten: Farbe.warnungGrund; case .kritisch: Farbe.warnung } }
    private var vorn: Color { switch art { case .gut: Farbe.text; case .hinten: Farbe.warnung; case .kritisch: Farbe.warnungGrund } }
}

#Preview("Bühne") {
    ScrollView {
        VStack(spacing: 0) {
            Buehne(wort: Wort(zeilen: ["Jetzt"], akzent: "dran."), objekt: .b747, platz: .home) {
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
