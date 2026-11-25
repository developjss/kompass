import SwiftUI

/// Ziele (Tab Fortschritt, Blattwerk): Bühne mit dem Wort „x von y auf Kurs“ und dem Kompass, Karte vorn mit
/// Filter (Alle · Hinterher · Erreicht) und dem Ziel mit dem größten Hebel, darunter alle Ziele mit Ring und Lage.
/// Hick: drei Filter, Sortieren (drei) unter „Mehr“.
struct ZieleAnsicht: View {
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav
    @Environment(\.accessibilityReduceMotion) private var ruhig
    @AppStorage("ziele.filter") private var filterRoh = ZielOrdnung.Filter.alle.rawValue
    @AppStorage("ziele.sortierung") private var sortierungRoh = ZielOrdnung.Sortierung.frist.rawValue
    @State private var mehr = false

    /// Hick: drei Filter (Auf Kurs steckt in „Alle“ und im Wort auf der Bühne)
    private let filterWahl: [ZielOrdnung.Filter] = [.alle, .hinterher, .erreicht]
    /// Hick: drei Sortierungen statt sechs
    private let sortierWahl: [ZielOrdnung.Sortierung] = [.frist, .fortschritt, .hinterherZuerst]

    private var filter: ZielOrdnung.Filter { .init(rawValue: filterRoh) ?? .alle }
    private var sortierung: ZielOrdnung.Sortierung { .init(rawValue: sortierungRoh) ?? .frist }

    var body: some View {
        let z = speicher.zustand
        let T = speicher.heute
        let gruppen = ZielOrdnung.gruppen(z, filter: filter, sortierung: sortierung, heute: T)
        let alle = gruppen.flatMap(\.ziele)
        let aktiv = z.ziele.filter { $0.status == .aktiv }
        let aufKurs = aktiv.filter { !Kurs.aufKurs($0, in: z, heute: T).lage.hinten }
        let hebel = Self.hebel(z, heute: T)

        BuehnenSeite(wort: Self.wort(aufKurs: aufKurs.count, gesamt: aktiv.count), marke: {
            FortschrittWahl()
            Spacer(minLength: 8)
            RahmenKnopf(symbol: "info", beschriftung: "Erklärung") { nav.blatt = .info(.ziele) }
        }) {
            VornKarte(abstand: 12) {
                ChipReihe(titel: "", auswahl: filterWahl.map { ($0.titel, $0 == filter) }) { i in
                    withAnimation(ruhig ? nil : .snappy) { filterRoh = filterWahl[i].rawValue }
                }
                if let g = hebel {
                    let kurs = Kurs.aufKurs(g, in: z, heute: T)
                    let naechster = Fortschritt.naechsterSchritt(g, in: z, heute: T)
                    Rectangle().fill(Farbe.linie).frame(height: 1)
                    NavigationLink(value: ZielAuswahl(id: g.id)) {
                        HStack(spacing: 12) {
                            FortschrittRing(anteil: kurs.fortschritt)
                            VStack(alignment: .leading, spacing: 3) {
                                Etikett(text: kurs.lage.hinten ? "Größter Hebel" : "Dein nächster Schritt")
                                Text(g.titel).font(.kompass(.body, .heavy)).foregroundStyle(Farbe.text).lineLimit(2).multilineTextAlignment(.leading)
                                Text(naechster.map { $0.aufgabe?.titel ?? $0.schritt.titel } ?? "Meilenstein wählen")
                                    .font(.unterzeile).foregroundStyle(Farbe.zweitrangig).lineLimit(1)
                            }
                            Spacer(minLength: 4)
                            LagePille(kurs.lage)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Text(filter == .alle ? "Alle Ziele" : filter.titel).font(.abschnitt).foregroundStyle(Farbe.text).accessibilityAddTraits(.isHeader)
                    Spacer()
                    Button(mehr ? "weniger" : "Mehr") { withAnimation(ruhig ? nil : .snappy) { mehr.toggle() } }
                        .font(.kompass(.subheadline, .bold)).foregroundStyle(Farbe.akzent)
                }
                .padding(.top, 8)
                if mehr {
                    ChipReihe(titel: "Sortieren", auswahl: sortierWahl.map { ($0.titel, $0 == sortierung) }) { i in
                        withAnimation(ruhig ? nil : .snappy) { sortierungRoh = sortierWahl[i].rawValue }
                    }
                HinzufuegenKarte(titel: "Ziel hinzufügen", unter: "mit Frist und Meilensteinen") { nav.blatt = .neu(.ziel) }
                }
                GruppierteListe {
                    if alle.isEmpty { LeerZeile(text: leerText) }
                    ForEach(alle) { ZielListenZeile(ziel: $0) }
                }
            }
            .padding(.horizontal, Mass.rand).padding(.top, 12)
        }
    }

    /// Das Wort: die Aussage über alle aktiven Ziele (§4 Auf Kurs).
    nonisolated static func wort(aufKurs: Int, gesamt: Int) -> Wort {
        if gesamt == 0 { return Wort(zeilen: ["Noch kein"], akzent: "Ziel.", groesse: Wort.mittel) }
        if aufKurs == gesamt { return Wort(zeilen: ["Alle \(gesamt)"], akzent: "auf Kurs.", groesse: Wort.mittel) }
        return Wort(zeilen: ["\(aufKurs) von \(gesamt)"], akzent: "auf Kurs.", groesse: Wort.mittel)
    }

    /// Größter Hebel: das Ziel, das am weitesten hinter dem Plan liegt; sonst das mit der nächsten Frist.
    static func hebel(_ z: Zustand, heute T: Tag) -> Ziel? {
        let aktiv = z.ziele.filter { $0.status == .aktiv }
        let mitKurs = aktiv.map { ($0, Kurs.aufKurs($0, in: z, heute: T)) }
        if let hinten = mitKurs.filter({ $0.1.lage.hinten }).min(by: { $0.1.fortschritt - $0.1.erwartet < $1.1.fortschritt - $1.1.erwartet }) {
            return hinten.0
        }
        return aktiv.min { $0.faellig < $1.faellig }
    }

    private var leerText: String {
        switch filter {
        case .alle: "Noch keine Ziele."
        case .aufKurs: "Gerade ist kein Ziel auf Kurs."
        case .hinterher: "Kein Ziel hinkt hinterher – stark."
        case .erreicht: "Noch kein Ziel erreicht."
        }
    }
}

extension Kurs.Lage {
    /// „hinterher“ oder „überfällig“
    var hinten: Bool { self == .hinterher || self == .ueberfaellig }
}

/// Eine Ziel-Zeile: Ring, Titel, Frist, Lage.
struct ZielListenZeile: View {
    var ziel: Ziel
    @Environment(Speicher.self) private var speicher

    var body: some View {
        let z = speicher.zustand
        let T = speicher.heute
        let kurs = Kurs.aufKurs(ziel, in: z, heute: T)
        NavigationLink(value: ZielAuswahl(id: ziel.id)) {
            HStack(spacing: 12) {
                FortschrittRing(anteil: kurs.fortschritt).padding(.leading, 8)
                VStack(alignment: .leading, spacing: 2) {
                    Text(ziel.titel).font(.zeile).foregroundStyle(Farbe.text).lineLimit(2).multilineTextAlignment(.leading)
                    Text("bis \(ziel.faellig.datum().formatted(.dateTime.day().month(.abbreviated).year().locale(Locale(identifier: "de_DE"))))")
                        .font(.unterzeile).foregroundStyle(Farbe.zweitrangig)
                }
                Spacer(minLength: 4)
                LagePille(kurs.lage).padding(.trailing, 12)
            }
            .frame(minHeight: 72)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(ziel.titel), \(Zahl.prozent(kurs.fortschritt)), \(kurs.lage.text), \(Kurs.bisText(ziel.faellig, heute: T))")
        .accessibilityAddTraits(.isButton)
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
