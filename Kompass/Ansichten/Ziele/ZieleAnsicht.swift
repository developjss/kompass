import SwiftUI

/// Ziele (Inhalt im Tab Fortschritt): Aussage-Karte, dann Verlaufskarte je Ziel mit Prozent, Auf Kurs, Frist, Wochenzeit und Balken.
struct ZieleAnsicht: View {
    @Environment(Speicher.self) private var speicher
    @State private var erreichteZeigen = false

    var body: some View {
        let z = speicher.zustand
        let liste = z.ziele.filter { $0.status == (erreichteZeigen ? .erreicht : .aktiv) }.sorted { $0.faellig < $1.faellig }
        let erreicht = z.ziele.filter { $0.status == .erreicht }.count

        VStack(alignment: .leading, spacing: 0) {
            if !erreichteZeigen { ZieleKopf(ziele: liste) }
            if liste.isEmpty {
                GruppierteListe {
                    LeerZeile(text: erreichteZeigen ? "Noch kein Ziel erreicht." : "Noch keine Ziele. Oben auf „+ Neu“.")
                }
            }
            if !liste.isEmpty {
                AbschnittKopf(titel: erreichteZeigen ? "Erreicht" : "Deine Ziele") { Text("nach Frist").foregroundStyle(Farbe.zweitrangig) }
                VStack(spacing: 12) { ForEach(liste) { ZielKarte(ziel: $0) } }
            }
            if erreicht > 0 || erreichteZeigen {
                PfeilZeile(symbol: "checkmark", text: erreichteZeigen ? "Zurück zu aktiven Zielen" : "Erreicht · \(erreicht)") { erreichteZeigen.toggle() }
                    .padding(.top, Mass.abschnitt)
            }
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
