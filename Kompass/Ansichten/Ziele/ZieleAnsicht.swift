import SwiftUI

/// Ziele nach Jahr: Verlaufskarte je Ziel mit Prozent, Auf Kurs, Frist, Wochenzeit und Balken.
struct ZieleAnsicht: View {
    @Environment(Speicher.self) private var speicher
    @State private var erreichteZeigen = false

    var body: some View {
        let z = speicher.zustand
        let liste = z.ziele.filter { $0.status == (erreichteZeigen ? .erreicht : .aktiv) }.sorted { $0.faellig < $1.faellig }
        let jahre = Dictionary(grouping: liste) { $0.faellig.jahr }.sorted { $0.key < $1.key }
        let erreicht = z.ziele.filter { $0.status == .erreicht }.count

        Seite(titel: erreichteZeigen ? "Erreicht" : "Fortschritt", info: .ziele, neu: .ziel, oben: AnyView(FortschrittWahl())) {
            if !erreichteZeigen { ZieleKopf(ziele: liste) }
            if liste.isEmpty {
                GruppierteListe {
                    LeerZeile(text: erreichteZeigen ? "Noch kein Ziel erreicht." : "Noch keine Ziele. Oben auf „+ Neu“.")
                }
            }
            if jahre.count > 1 {
                ForEach(jahre, id: \.key) { jahr, ziele in
                    AbschnittKopf(titel: String(jahr)) { Text("\(ziele.count)").foregroundStyle(Farbe.zweitrangig) }
                    VStack(spacing: 12) { ForEach(ziele) { ZielKarte(ziel: $0) } }
                }
            } else if let (jahr, ziele) = jahre.first {
                AbschnittKopf(titel: erreichteZeigen ? "Erreicht" : "Aktiv") { Text("bis \(String(jahr))").foregroundStyle(Farbe.zweitrangig) }
                VStack(spacing: 12) { ForEach(ziele) { ZielKarte(ziel: $0) } }
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
        let wochen = (0..<8).map { k -> Double in
            let s = T.montag.plus(tage: -7 * (7 - k))
            return Fortschritt.zeit(ziel: ziel.id, in: z, von: s, bis: s.plus(tage: 6)) / 3600
        }
        NavigationLink(value: ZielAuswahl(id: ziel.id)) {
            Verlaufskarte(farben: Farbe.verlauf(ziel.farbe)) {
                HStack {
                    Text(ziel.titel).font(.kompass(.headline, .bold)).lineLimit(2)
                    Spacer()
                    Image(systemName: "chevron.right").font(.footnote.weight(.bold)).opacity(0.8)
                }
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Zahl.prozent(kurs.fortschritt)).font(.grosseZahl).contentTransition(.numericText())
                        Text("\(kurs.lage.text) · \(Kurs.bisText(ziel.faellig, heute: T))").font(.unterzeile).opacity(0.9)
                    }
                    Spacer()
                    Kurve(werte: wochen).frame(width: 96, height: 34)
                }
                Balken(anteil: kurs.fortschritt).padding(.top, 6)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(ziel.titel), \(Zahl.prozent(kurs.fortschritt)), \(kurs.lage.text), \(Kurs.bisText(ziel.faellig, heute: T))")
        .accessibilityAddTraits(.isButton)
    }
}
