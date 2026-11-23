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

        Seite(titel: erreichteZeigen ? "Erreicht" : "Ziele", info: .ziele, neu: .ziel) {
            if liste.isEmpty {
                GruppierteListe {
                    LeerZeile(text: erreichteZeigen ? "Noch kein Ziel erreicht." : "Noch keine Ziele. Oben auf „+ Neu“.")
                }
            }
            ForEach(jahre, id: \.key) { jahr, ziele in
                AbschnittKopf(titel: String(jahr)) { Text("\(ziele.count)").foregroundStyle(Farbe.zweitrangig) }
                VStack(spacing: 12) {
                    ForEach(ziele) { ZielKarte(ziel: $0) }
                }
            }
            if erreicht > 0 || erreichteZeigen {
                PfeilZeile(symbol: "checkmark", text: erreichteZeigen ? "Zurück zu aktiven Zielen" : "Erreicht · \(erreicht)") { erreichteZeigen.toggle() }
                    .padding(.top, Mass.abschnitt)
            }
        }
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
