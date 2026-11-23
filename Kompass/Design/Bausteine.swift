import SwiftUI

// Bausteine aus design.md §5: Seitenkopf, Abschnitt, gruppierte Liste, Verlaufskarte, Balken, Haken, Seitenfuß.

/// Seite mit Verlauf oben (läuft bei ~64 % in den Grund), Seitenkopf und Fuß.
struct Seite<Inhalt: View>: View {
    var titel: String
    var info: InfoThema?
    var neu: NeuArt? = nil
    /// z. B. der Umschalter Ziele · Habits, direkt unter dem Kopf
    var oben: AnyView? = nil
    @ViewBuilder var inhalt: Inhalt
    @Environment(Navigation.self) private var nav

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                SeitenKopf(titel: titel, info: info, neu: neu)
                    .padding(.top, 14)
                    .padding(.bottom, oben == nil ? 20 : 12)
                if let oben { oben.padding(.bottom, 16) }
                inhalt
                SeitenFuss()
                    .padding(.top, Mass.abschnitt)
            }
            .padding(.horizontal, Mass.rand)
            .padding(.bottom, 32)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .background(alignment: .top) {
            LinearGradient(stops: [.init(color: Farbe.grundOben, location: 0), .init(color: Farbe.grund, location: 0.64)],
                           startPoint: .top, endPoint: .bottom)
                .frame(height: 520)
                .ignoresSafeArea()
        }
        .background(Farbe.grund.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }
}

struct SeitenKopf: View {
    var titel: String
    var info: InfoThema?
    var neu: NeuArt?
    /// false = kein „+ Neu“ (z. B. Lotse)
    var neuZeigen = true
    @Environment(Navigation.self) private var nav

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Text(titel)
                .font(.seitenTitel)
                .foregroundStyle(Farbe.text)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 8)
            if neuZeigen {
                Button { nav.blatt = .neu(neu) } label: {
                    Text("+ Neu").font(.kompass(.subheadline, .bold))
                        .padding(.horizontal, 14).frame(minHeight: 44)
                        .background(Farbe.akzentWeich, in: Capsule())
                        .foregroundStyle(Farbe.akzent)
                }
            }
            if let info {
                RunderKnopf(symbol: "info", beschriftung: "Erklärung") { nav.blatt = .info(info) }
            }
            RunderKnopf(symbol: "gearshape", beschriftung: "Einstellungen") { nav.blatt = .einstellungen }
        }
    }
}

struct RunderKnopf: View {
    var symbol: String
    var beschriftung: String
    var aktion: () -> Void
    var body: some View {
        Button(action: aktion) {
            Image(systemName: symbol).font(.system(size: 16, weight: .semibold))
                .frame(width: 44, height: 44)
                .background(Farbe.karte, in: Circle())
                .foregroundStyle(Farbe.text)
        }
        .accessibilityLabel(beschriftung)
    }
}

struct AbschnittKopf<Rechts: View>: View {
    var titel: String
    @ViewBuilder var rechts: Rechts
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(titel).font(.abschnitt).foregroundStyle(Farbe.text).accessibilityAddTraits(.isHeader)
            Spacer()
            rechts.font(.kompass(.subheadline, .semibold)).foregroundStyle(Farbe.akzent)
        }
        .padding(.top, Mass.abschnitt)
        .padding(.bottom, Mass.ueberschrift)
    }
}

extension AbschnittKopf where Rechts == EmptyView {
    init(titel: String) { self.init(titel: titel) { EmptyView() } }
}

/// Zeilen in einer weißen Karte, Trennlinie ab 66 pt.
struct GruppierteListe<Inhalt: View>: View {
    @ViewBuilder var inhalt: Inhalt
    var body: some View {
        VStack(spacing: 0) {
            Group(subviews: inhalt) { zeilen in
                ForEach(Array(zeilen.enumerated()), id: \.element.id) { i, zeile in
                    if i > 0 { Rectangle().fill(Farbe.linie).frame(height: 0.5).padding(.leading, 66) }
                    zeile
                }
            }
        }
        .background(Farbe.karte, in: RoundedRectangle(cornerRadius: Mass.karte, style: .continuous))
    }
}

/// Leerzustand innerhalb einer Liste
struct LeerZeile: View {
    var text: String
    var body: some View {
        Text(text).font(.unterzeile).foregroundStyle(Farbe.zweitrangig)
            .frame(maxWidth: .infinity, minHeight: Mass.zeileKompakt, alignment: .leading)
            .padding(.horizontal, 16)
    }
}

/// Verlaufskarte wie „Insights“: tief → hell, Lichtschein oben links, farbiger Schatten.
struct Verlaufskarte<Inhalt: View>: View {
    var farben: [Color]
    @ViewBuilder var inhalt: Inhalt
    var body: some View {
        VStack(alignment: .leading, spacing: 6) { inhalt }
            .foregroundStyle(.white)
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: Mass.verlaufskarte, style: .continuous)
                    .fill(LinearGradient(colors: farben, startPoint: .bottomTrailing, endPoint: .topLeading))
                    .overlay(alignment: .topLeading) {
                        Circle().fill(.white.opacity(0.18)).frame(width: 180).blur(radius: 50).offset(x: -40, y: -60)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: Mass.verlaufskarte, style: .continuous))
                    .shadow(color: (farben.first ?? .black).opacity(0.35), radius: 16, y: 8)
            }
    }
}

struct KartenLabel: View {
    var text: String
    var body: some View { Text(text).font(.klein).opacity(0.85) }
}

struct Balken: View {
    var anteil: Double
    var farbe: Color = .white
    var spur: Color = .white.opacity(0.25)
    var hoehe: CGFloat = 6
    @State private var sichtbar = false
    @Environment(\.accessibilityReduceMotion) private var ruhig

    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(spur)
                Capsule().fill(farbe).frame(width: g.size.width * (sichtbar || ruhig ? max(0, min(1, anteil)) : 0))
            }
        }
        .frame(height: hoehe)
        .onAppear { withAnimation(ruhig ? nil : .spring(duration: 0.9)) { sichtbar = true } }
        .accessibilityHidden(true)
    }
}

/// Runder Haken; ploppt mit Feder und kurzer Vibration.
struct Haken: View {
    var an: Bool
    var farbe: Color = Farbe.freude
    var groesse: CGFloat = 26
    var beschriftung: String
    var aktion: () -> Void
    @Environment(\.accessibilityReduceMotion) private var ruhig

    var body: some View {
        Button(action: aktion) {
            ZStack {
                Circle().strokeBorder(an ? farbe : Farbe.pfeil.opacity(0.6), lineWidth: 2)
                    .background(Circle().fill(an ? farbe : .clear))
                if an {
                    Image(systemName: "checkmark").font(.system(size: groesse * 0.45, weight: .heavy)).foregroundStyle(.white)
                        .transition(ruhig ? .opacity : .scale.combined(with: .opacity))
                }
            }
            .frame(width: groesse, height: groesse)
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.success, trigger: an) { _, neu in neu }
        .animation(ruhig ? nil : .spring(response: 0.3, dampingFraction: 0.55), value: an)
        .accessibilityLabel(beschriftung)
        .accessibilityValue(an ? "erledigt" : "offen")
    }
}

/// Weiche Kachel in Zielfarbe mit Symbol (40 pt).
struct SymbolKachel: View {
    var symbol: String
    var farbe: Color
    var body: some View {
        Image(systemName: symbol).font(.system(size: 17, weight: .semibold))
            .foregroundStyle(farbe)
            .frame(width: 40, height: 40)
            .background(farbe.opacity(0.14), in: Circle())
            .accessibilityHidden(true)
    }
}

/// Kleine Säulen (weiß auf Verlaufskarte); `hervor` hebt eine Säule hervor.
struct MiniSaeulen: View {
    var werte: [Double]
    var hoehe: CGFloat = 48
    var farbe: Color = .white
    var hervor: Int? = nil
    var body: some View {
        let mx = max(werte.max() ?? 0, 0.0001)
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(Array(werte.enumerated()), id: \.offset) { i, v in
                Capsule().fill(farbe.opacity(hervor == nil || hervor == i ? 1 : 0.55))
                    .frame(width: 7, height: max(4, hoehe * v / mx))
            }
        }
        .frame(height: hoehe, alignment: .bottom)
        .accessibilityHidden(true)
    }
}

/// Kurve, die sich in 1,25 s von links nach rechts zeichnet (Reduce Motion: sofort).
struct Kurve: View {
    var werte: [Double]
    var farbe: Color = .white
    @State private var fortschritt: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var ruhig

    var body: some View {
        GeometryReader { g in
            let pfad = Kurve.pfad(werte, in: g.size)
            ZStack {
                pfad.trim(from: 0, to: ruhig ? 1 : fortschritt)
                    .stroke(farbe, style: StrokeStyle(lineWidth: 2.6, lineCap: .round))
            }
        }
        .onAppear { withAnimation(ruhig ? nil : .easeOut(duration: 1.25)) { fortschritt = 1 } }
        .accessibilityHidden(true)
    }

    static func pfad(_ w: [Double], in s: CGSize) -> Path {
        var w = w
        if w.count < 2 { w = [w.first ?? 0, w.first ?? 0] }
        let mn = w.min() ?? 0, mx = w.max() ?? 1, r = (mx - mn) == 0 ? 1 : mx - mn
        let pad: CGFloat = 6
        let pts = w.enumerated().map { i, v in
            CGPoint(x: pad + CGFloat(i) * (s.width - 2 * pad) / CGFloat(w.count - 1), y: s.height - pad - CGFloat((v - mn) / r) * (s.height - 2 * pad))
        }
        var p = Path()
        p.move(to: pts[0])
        for i in 1..<pts.count {
            let a = pts[i - 1], b = pts[i], cx = (a.x + b.x) / 2
            p.addCurve(to: b, control1: CGPoint(x: cx, y: a.y), control2: CGPoint(x: cx, y: b.y))
        }
        return p
    }
}

/// Speicherstatus + „Daten & Kalender“ unten auf jeder Seite.
struct SeitenFuss: View {
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(speicher.speicherFehler ? Farbe.kritisch : Farbe.freude).frame(width: 7, height: 7)
            Text(speicher.speicherFehler ? speicher.speicherText : "\(speicher.speicherText) · offline verfügbar")
            Spacer()
            Button("Daten & Kalender") { nav.blatt = .einstellungen }.foregroundStyle(Farbe.akzent)
        }
        .font(.klein)
        .foregroundStyle(Farbe.zweitrangig)
    }
}

/// Tippbare Zeile mit Symbol, Text und Pfeil (z. B. „Tagesabschluss · 2 Min.“)
struct PfeilZeile: View {
    var symbol: String
    var text: String
    var aktion: () -> Void
    var body: some View {
        Button(action: aktion) {
            HStack(spacing: 12) {
                Image(systemName: symbol).foregroundStyle(Farbe.akzent).frame(width: 28)
                Text(text).font(.zeile).foregroundStyle(Farbe.text)
                Spacer()
                Image(systemName: "chevron.right").font(.footnote.weight(.bold)).foregroundStyle(Farbe.pfeil)
            }
            .padding(.horizontal, 16).frame(minHeight: Mass.zeileKompakt)
            .background(Farbe.karte, in: RoundedRectangle(cornerRadius: Mass.karte, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

/// Fakt als Zeile: Bezeichnung links, Wert rechts, Pfeil – antippen öffnet den Editor (wie eine Gapless-Transaktion).
struct FaktZeile<Wert: View>: View {
    var titel: String
    @ViewBuilder var wert: Wert
    var aktion: () -> Void

    var body: some View {
        Button(action: aktion) {
            HStack(spacing: 12) {
                Text(titel).font(.zeile).foregroundStyle(Farbe.text)
                Spacer(minLength: 12)
                wert.font(.unterzeile).foregroundStyle(Farbe.zweitrangig).multilineTextAlignment(.trailing)
                Image(systemName: "chevron.right").font(.footnote.weight(.bold)).foregroundStyle(Farbe.pfeil)
            }
            .padding(.horizontal, 16)
            .frame(minHeight: Mass.zeileKompakt)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Bearbeiten")
    }
}

extension FaktZeile where Wert == Text {
    init(_ titel: String, wert: String, aktion: @escaping () -> Void) {
        self.init(titel: titel, wert: { Text(wert) }, aktion: aktion)
    }
}

/// Ein Wert mit Bezeichnung als kleine Karte – drei nebeneinander (Serie · Beste · Quote).
struct WertKachel: View {
    var titel: String
    var wert: String
    var einheit: String? = nil
    var body: some View {
        VStack(spacing: 3) {
            Text(wert).font(.kompass(.title2, .heavy)).foregroundStyle(Farbe.text).monospacedDigit().lineLimit(1).minimumScaleFactor(0.7)
            Text(einheit.map { "\(titel) · \($0)" } ?? titel).font(.klein).foregroundStyle(Farbe.zweitrangig).lineLimit(1).minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, minHeight: 68)
        .padding(.horizontal, 8)
        .background(Farbe.karte, in: RoundedRectangle(cornerRadius: Mass.karte, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
