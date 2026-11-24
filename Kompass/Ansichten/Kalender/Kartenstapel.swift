import SwiftUI

// Kartenstapel (Kalender v5): weiße Karte mit Aussage oben, darunter gestapelte Karten – die hinteren deutlich versetzt, damit man sie lesen kann.
// Ein Knopf fächert den Stapel zur Liste auf. Genutzt für „Als Nächstes“ und „Empfehlung“.

/// Stapel oder Liste derselben Karten; beim Wechsel gleiten die Karten an ihren neuen Platz.
struct KartenStapel<E: Identifiable, Karte: View>: View where E.ID: Hashable {
    var elemente: [E]
    var offen: Bool
    /// wie viele Karten hinter der vorderen zu sehen sind
    var hinten = 2
    /// so viel schaut jede hintere Karte oben heraus (Titel lesbar)
    var versatz: CGFloat = 52
    @ViewBuilder var karte: (E, _ vorne: Bool) -> Karte
    @Namespace private var raum

    var body: some View {
        if offen {
            VStack(spacing: 10) {
                ForEach(elemente) { e in
                    karte(e, true).matchedGeometryEffect(id: e.id, in: raum)
                }
            }
        } else {
            let sicht = Array(elemente.prefix(hinten + 1))
            let m = sicht.count
            ZStack(alignment: .top) {
                ForEach(Array(sicht.enumerated()), id: \.element.id) { tiefe, e in
                    karte(e, tiefe == 0)
                        .matchedGeometryEffect(id: e.id, in: raum)
                        .scaleEffect(1 - CGFloat(tiefe) * 0.05, anchor: .top)
                        .padding(.top, CGFloat(m - 1 - tiefe) * versatz)
                        .zIndex(Double(m - tiefe))
                        .accessibilityHidden(tiefe > 0)
                }
            }
        }
    }
}

/// Der weiße Rahmen um einen Stapel: kleines Label, Aussage, Stapel, Knopf „Alle n ansehen“.
struct StapelRahmen<Inhalt: View>: View {
    var label: String
    var symbol: String
    var aussage: String
    var anzahl: Int
    @Binding var offen: Bool
    @ViewBuilder var inhalt: Inhalt
    @Environment(\.accessibilityReduceMotion) private var ruhig

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 6) {
                Label(label, systemImage: symbol).font(.klein).foregroundStyle(Farbe.akzent)
                Text(aussage).font(.kompass(.title3, .heavy)).foregroundStyle(Farbe.text)
                    .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
            }
            .frame(maxWidth: .infinity)
            inhalt
            if anzahl > 1 {
                Button {
                    withAnimation(ruhig ? nil : .spring(response: 0.45, dampingFraction: 0.82)) { offen.toggle() }
                } label: {
                    Text(offen ? "Weniger zeigen" : "Alle \(anzahl) ansehen")
                        .font(.kompass(.headline, .bold)).foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Farbe.akzent, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .background(Farbe.karte, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 12, y: 4)
    }
}

/// Eine Karte im Stapel: farbiger Kreis mit Symbol, Titel, Unterzeile, rechts eine kurze Angabe.
struct StapelKarte<Unten: View>: View {
    var titel: String
    var unter: String
    var farbe: String
    var symbol: String
    var rechts: String?
    var rechtsUnter: String?
    var hervor = false
    @ViewBuilder var unten: Unten

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(LinearGradient(colors: Farbe.verlauf(farbe), startPoint: .bottomTrailing, endPoint: .topLeading))
                    Image(systemName: symbol).font(.system(size: 17, weight: .bold)).foregroundStyle(.white)
                }
                .frame(width: 42, height: 42)
                .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(titel).font(.zeile).foregroundStyle(Farbe.text).lineLimit(1)
                    Text(unter).font(.unterzeile).foregroundStyle(Farbe.zweitrangig).lineLimit(1)
                }
                Spacer(minLength: 6)
                if let rechts {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(rechts).font(.kompass(.headline, .heavy)).foregroundStyle(Farbe.text).monospacedDigit().lineLimit(1)
                        if let rechtsUnter { Text(rechtsUnter).font(.klein).foregroundStyle(Farbe.zweitrangig).lineLimit(1) }
                    }
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            unten
        }
        .frame(maxWidth: .infinity)
        .background(Farbe.karte, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(hervor ? Farbe.akzent : Farbe.linie, lineWidth: hervor ? 2 : 1))
        .shadow(color: .black.opacity(hervor ? 0.12 : 0.06), radius: hervor ? 12 : 6, y: hervor ? 6 : 2)
        .scaleEffect(hervor ? 1.02 : 1)
    }
}

// MARK: Als Nächstes

/// Kalender oben: die nächsten Einträge mit Uhrzeit als Stapel.
struct NaechsteStapel: View {
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav
    @Environment(\.dynamicTypeSize) private var schrift
    @State private var offen = false

    var body: some View {
        let T = speicher.heute
        let jetzt = speicher.jetztMinuten
        let n = Tagesplan.naechste(zustand: speicher.zustand, heute: T, jetzt: jetzt, termine: speicher.termine(am:), anzahl: 5)
        let aussage = n.first.map { Self.aussage($0, heute: T, jetzt: jetzt) } ?? "Nichts mit Uhrzeit"
        StapelRahmen(label: "Als Nächstes", symbol: "clock", aussage: aussage, anzahl: n.count, offen: $offen) {
            if n.isEmpty {
                Text("In den nächsten 7 Tagen ist nichts eingeplant. Zieh eine Empfehlung in den Kalender.")
                    .font(.unterzeile).foregroundStyle(Farbe.zweitrangig).multilineTextAlignment(.center)
            } else {
                KartenStapel(elemente: n, offen: offen || schrift.isAccessibilitySize) { b, _ in
                    let wann = Self.unter(b, heute: T, zustand: speicher.zustand)
                    Button { KalenderAktion.oeffnen(b, nav: nav) } label: {
                        StapelKarte(titel: b.titel, unter: wann, farbe: b.farbe, symbol: symbol(b), rechts: Tagesplan.uhr(b.start), rechtsUnter: "bis \(Tagesplan.uhr(b.ende))") { EmptyView() }
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(b.titel), \(wann), bis \(Tagesplan.uhr(b.ende))")
                    .accessibilityAddTraits(.isButton)
                }
            }
        }
    }

    /// Kopf: wie lange bis zum Nächsten („Nächstes in 57 Min“) – die Uhrzeit steht schon auf der Karte.
    nonisolated static func aussage(_ b: Tagesplan.Block, heute T: Tag, jetzt: Int) -> String {
        if b.tag == T {
            let m = b.start - jetzt
            if m <= 0 { return "Läuft gerade" }
            if m < 60 { return "Nächstes in \(m) Min" }
            let h = m / 60, r = m % 60
            return r == 0 ? "Nächstes in \(h) h" : "Nächstes in \(h) h \(r) Min"
        }
        if b.tag == T.plus(tage: 1) { return "Nächstes morgen" }
        return "Nächstes " + b.tag.datum().formatted(.dateTime.weekday(.wide).locale(Locale(identifier: "de_DE")))
    }

    /// Unterzeile einer Karte: Tag und – falls vorhanden – das Ziel, für das es zählt (Uhrzeit steht rechts).
    static func unter(_ b: Tagesplan.Block, heute T: Tag, zustand z: Zustand) -> String {
        let tag = b.tag == T ? "heute" : b.tag == T.plus(tage: 1) ? "morgen"
            : b.tag.datum().formatted(.dateTime.weekday(.wide).locale(Locale(identifier: "de_DE")))
        if let g = z.ziel(b.zielID) { return "\(tag) · \(g.titel)" }
        return b.art == .habit ? "\(tag) · Habit" : tag
    }

    private func symbol(_ b: Tagesplan.Block) -> String {
        switch b.art {
        case .termin: "calendar"
        case .aufgabe: "checkmark"
        case .habit: "repeat"
        }
    }
}

// MARK: Empfehlung

/// Unter dem Kalender: was man jetzt in den Kalender ziehen sollte – passend zur Ansicht Tag, Woche oder Monat.
struct EmpfehlungStapel: View {
    var bereich: Empfehlung.Bereich
    var tag: Tag
    @Environment(Speicher.self) private var speicher
    @Environment(\.dynamicTypeSize) private var schrift
    @Environment(\.accessibilityReduceMotion) private var ruhig
    @State private var offen = false
    @State private var hinweis: String?
    @State private var eingeplant = 0

    var body: some View {
        let T = speicher.heute
        let v = Empfehlung.fuer(bereich, tag: tag, zustand: speicher.zustand, heute: T, jetzt: speicher.jetztMinuten, termine: speicher.termine(am:))
        StapelRahmen(label: "Empfehlung", symbol: "sparkles", aussage: aussage(v.count, T), anzahl: v.count, offen: $offen) {
            if v.isEmpty {
                Text("Alles eingeplant. Neue Aufgabe? Oben auf „+ Neu“.")
                    .font(.unterzeile).foregroundStyle(Farbe.zweitrangig).multilineTextAlignment(.center)
            } else {
                if hinweis == nil {
                    Label("Halten und in den Kalender ziehen", systemImage: "hand.draw")
                        .font(.klein).foregroundStyle(Farbe.zweitrangig).multilineTextAlignment(.center)
                }
                KartenStapel(elemente: v, offen: offen || schrift.isAccessibilitySize) { e, vorne in
                    karte(e, vorne: vorne, T: T)
                }
            }
            if offen {
                AufgabeHinzufuegen(platzhalter: bereich == .tag ? "Aufgabe für diesen Tag" : "Idee für später", datum: bereich == .tag ? tag : nil, prio: .normal)
                    .background(Farbe.grund.opacity(0.6), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .ablagezone(ecken: 28) { items, _ in
            // Zurück aus dem Kalender: Tag → an diesem Tag ohne Uhrzeit; Woche/Monat → in den Eingang (ohne Tag)
            KalenderAktion.ablegen(items, tag: bereich == .tag ? tag : nil, uhrzeit: nil, speicher: speicher)
        }
        .sensoryFeedback(.success, trigger: eingeplant)
        .onChange(of: bereich) { offen = false; hinweis = nil }
    }

    @ViewBuilder
    private func karte(_ e: Empfehlung.Vorschlag, vorne: Bool, T: Tag) -> some View {
        let platz = Empfehlung.platzText(e, bereich: bereich, heute: T)
        let an = hinweis == e.id
        StapelKarte(titel: e.titel, unter: e.grund, farbe: e.farbe, symbol: e.symbol, rechts: platz,
                    rechtsUnter: platz == nil ? nil : (e.verschoben ? "mehr Platz" : bereich == .tag ? "frei" : "am freiesten"), hervor: an) {
            if an {
                VStack(alignment: .leading, spacing: 10) {
                    Rectangle().fill(Farbe.linie).frame(height: 0.5)
                    HStack(spacing: 10) {
                        Image(systemName: "hand.draw.fill").font(.title3).foregroundStyle(Farbe.akzent)
                            .symbolEffect(.bounce, options: .repeat(2), value: an)
                        Text(ziehText).font(.klein).foregroundStyle(Farbe.text).fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 4)
                    }
                    if platz != nil { Button { einplanen(e) } label: {
                        Label(knopf(e, platz: platz), systemImage: "calendar.badge.plus")
                            .font(.kompass(.subheadline, .bold)).foregroundStyle(Farbe.akzent)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(Farbe.akzentWeich, in: Capsule())
                    }
                    .buttonStyle(.plain) }
                }
                .padding(.horizontal, 14).padding(.bottom, 14)
                .transition(.opacity)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .onTapGesture {
            // hintere Karte im Stapel: erst auffächern; sonst zeigen, wie man zieht
            withAnimation(ruhig ? nil : .spring(response: 0.35, dampingFraction: 0.8)) {
                if vorne { hinweis = an ? nil : e.id } else { offen = true }
            }
        }
        .draggable(e.nutzlast) {
            Label(e.titel, systemImage: e.symbol).font(.kompass(.subheadline, .bold)).padding(.horizontal, 12).padding(.vertical, 8)
                .background(Farbe.karte, in: Capsule()).overlay(Capsule().strokeBorder(Color(hex: e.farbe), lineWidth: 2))
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(e.titel), \(e.grund)\(platz.map { bereich == .tag ? ", frei um \($0)" : ", am freiesten \($0)" } ?? "")")
        .accessibilityHint("Halten und in den Kalender ziehen")
        .accessibilityAction(named: platz == nil ? "Halten und ziehen" : knopf(e, platz: platz)) { if platz != nil { einplanen(e) } }
    }

    private var ziehText: String {
        switch bereich {
        case .tag: "Halten und auf eine Uhrzeit im Kalender ziehen."
        case .woche: "Halten und auf einen Tag der Woche ziehen."
        case .monat: "Halten und auf einen Tag im Monat ziehen."
        }
    }

    private func knopf(_ e: Empfehlung.Vorschlag, platz: String?) -> String {
        guard let platz else { return "Auf diesen Tag legen" }
        return bereich == .tag && !e.verschoben ? "Um \(platz) einplanen" : "Auf \(platz) legen"
    }

    private func einplanen(_ e: Empfehlung.Vorschlag) {
        let u = bereich == .tag ? e.uhrzeit : nil
        if KalenderAktion.ablegen([e.nutzlast], tag: e.tag, uhrzeit: u, speicher: speicher) { eingeplant += 1 }
        withAnimation(ruhig ? nil : .snappy) { hinweis = nil }
    }

    private func aussage(_ n: Int, _ T: Tag) -> String {
        let wofuer: String
        switch bereich {
        case .tag:
            wofuer = tag == T ? "für heute" : tag == T.plus(tage: 1) ? "für morgen"
                : "für " + tag.datum().formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "de_DE")))
        case .woche: wofuer = tag.montag == T.montag ? "für diese Woche" : "für KW \(tag.kalenderwoche)"
        case .monat: wofuer = "für " + tag.datum().formatted(.dateTime.month(.wide).locale(Locale(identifier: "de_DE")))
        }
        if n == 0 { return "Nichts offen \(wofuer)" }
        return n == 1 ? "1 Vorschlag \(wofuer)" : "\(n) Vorschläge \(wofuer)"
    }
}

// MARK: Empfehlung kompakt (Tagesansicht)

/// Tagesansicht: Vorschläge als Leiste direkt über der Zeitleiste – kurzer Weg zum Ziehen.
/// Antippen zeigt „Um 11:15 einplanen“; zurück auf die Leiste ziehen = an diesem Tag ohne Uhrzeit.
struct EmpfehlungLeiste: View {
    var tag: Tag
    @Environment(Speicher.self) private var speicher
    @Environment(\.accessibilityReduceMotion) private var ruhig
    @State private var gewaehlt: String?
    @State private var eingeplant = 0

    var body: some View {
        let v = Empfehlung.fuer(.tag, tag: tag, zustand: speicher.zustand, heute: speicher.heute, jetzt: speicher.jetztMinuten, termine: speicher.termine(am:))
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles").foregroundStyle(Farbe.akzent)
                Text(v.isEmpty ? "Alles eingeplant" : v.count == 1 ? "1 Vorschlag" : "\(v.count) Vorschläge")
                    .font(.kompass(.subheadline, .bold)).foregroundStyle(Farbe.text)
                if !v.isEmpty { Text("· ziehen oder antippen").font(.klein).foregroundStyle(Farbe.zweitrangig) }
                Spacer()
            }
            if !v.isEmpty {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(v) { e in chip(e) }
                    }
                    .padding(.vertical, 2)
                }
                .scrollIndicators(.hidden)
                if let id = gewaehlt, let e = v.first(where: { $0.id == id }) {
                    Button { einplanen(e) } label: {
                        Label(e.uhrzeit.map { e.verschoben ? "Auf \(Empfehlung.platzText(e, bereich: .tag, heute: speicher.heute) ?? "") legen" : "„\(e.titel)“ um \(Tagesplan.uhr($0)) einplanen" } ?? "Auf diesen Tag legen",
                              systemImage: "calendar.badge.plus")
                            .font(.kompass(.subheadline, .bold)).foregroundStyle(Farbe.akzent).lineLimit(1)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(Farbe.akzentWeich, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity)
                    .accessibilityIdentifier("empfehlung.einplanen")
                }
            }
        }
        .padding(12)
        .background(Farbe.karte, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .ablagezone(ecken: 20) { items, _ in
            KalenderAktion.ablegen(items, tag: tag, uhrzeit: nil, speicher: speicher)
        }
        .sensoryFeedback(.success, trigger: eingeplant)
        .onChange(of: tag) { gewaehlt = nil }
    }

    private func chip(_ e: Empfehlung.Vorschlag) -> some View {
        let an = gewaehlt == e.id
        return HStack(spacing: 8) {
            Image(systemName: e.symbol).font(.system(size: 11, weight: .bold)).foregroundStyle(.white)
                .frame(width: 26, height: 26).background(Color(hex: e.farbe).gradient, in: Circle())
            VStack(alignment: .leading, spacing: 0) {
                Text(e.titel).font(.kompass(.caption, .bold)).foregroundStyle(Farbe.text).lineLimit(1)
                Text(e.uhrzeit.map { e.verschoben ? "morgen" : "frei \(Tagesplan.uhr($0))" } ?? e.grund).font(.caption2).foregroundStyle(Farbe.zweitrangig).lineLimit(1)
            }
            .frame(maxWidth: 140, alignment: .leading)
        }
        .padding(.leading, 6).padding(.trailing, 12).frame(minHeight: 44)
        .background(Farbe.grund, in: Capsule())
        .overlay(Capsule().strokeBorder(an ? Farbe.akzent : Farbe.linie, lineWidth: an ? 2 : 1))
        .contentShape(Capsule())
        .onTapGesture { withAnimation(ruhig ? nil : .snappy) { gewaehlt = an ? nil : e.id } }
        .draggable(e.nutzlast) {
            Label(e.titel, systemImage: e.symbol).font(.kompass(.subheadline, .bold)).padding(.horizontal, 12).padding(.vertical, 8)
                .background(Farbe.karte, in: Capsule()).overlay(Capsule().strokeBorder(Color(hex: e.farbe), lineWidth: 2))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(e.titel), \(e.grund)\(e.uhrzeit.map { ", frei um \(Tagesplan.uhr($0))" } ?? "")")
        .accessibilityHint("Halten und in den Kalender ziehen")
        .accessibilityAction(named: "Einplanen") { einplanen(e) }
    }

    private func einplanen(_ e: Empfehlung.Vorschlag) {
        if KalenderAktion.ablegen([e.nutzlast], tag: e.tag, uhrzeit: e.uhrzeit, speicher: speicher) { eingeplant += 1 }
        withAnimation(ruhig ? nil : .snappy) { gewaehlt = nil }
    }
}
