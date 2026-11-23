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

/// Ziel im Detail: Kopf, Prognose, Schritte mit Stand, „So wird gerechnet“.
struct ZielDetail: View {
    var id: UUID
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let z = speicher.zustand
        let T = speicher.heute
        if let g = z.ziel(id) {
            let kurs = Kurs.aufKurs(g, in: z, heute: T)
            let prognose = Kurs.prognose(verlauf: z.verlauf[g.id] ?? [], fortschritt: kurs.fortschritt, heute: T)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Verlaufskarte(farben: Farbe.verlauf(g.farbe)) {
                        KartenLabel(text: g.bereich)
                        Text(Zahl.prozent(kurs.fortschritt)).font(.grosseZahl)
                        Text("\(kurs.lage.text) · \(Kurs.bisText(g.faellig, heute: T))").font(.unterzeile).opacity(0.9)
                        Balken(anteil: kurs.fortschritt).padding(.top, 8)
                        Text(prognoseText(prognose)).font(.klein).opacity(0.9).padding(.top, 4)
                    }
                    if !g.warum.isEmpty {
                        Text("Warum: \(g.warum)").font(.unterzeile).foregroundStyle(Farbe.zweitrangig).padding(.top, 12)
                    }

                    if let m = g.zahl {
                        AbschnittKopf(titel: "Stand")
                        GruppierteListe {
                            HStack {
                                Text("\(Zahl.text(m.aktuell)) \(m.einheit)").font(.zeile)
                                Spacer()
                                Text("Ziel \(Zahl.text(m.ziel)) \(m.einheit)").font(.unterzeile).foregroundStyle(Farbe.zweitrangig)
                            }
                            .padding(.horizontal, 16).frame(minHeight: Mass.zeileKompakt)
                            if m.verlauf.count > 1 {
                                Kurve(werte: m.verlauf.map(\.wert), farbe: Color(hex: g.farbe)).frame(height: 70).padding(12)
                            }
                        }
                    }

                    AbschnittKopf(titel: g.zahl == nil ? "Schritte" : "Schritte (Planung)") {
                        Button("So wird gerechnet") { nav.blatt = .rechnung(g.id) }
                    }
                    GruppierteListe {
                        if g.schritte.isEmpty { LeerZeile(text: "Wie misst du das? Lege Schritte an.") }
                        ForEach(g.schritte) { s in SchrittZeile(ziel: g, schritt: s) }
                    }

                    let wochen = Fortschritt.zeit(ziel: g.id, in: z, von: T.montag, bis: T)
                    AbschnittKopf(titel: "Diese Woche") { Text(Zahl.dauer(wochen)).foregroundStyle(Farbe.zweitrangig) }
                    GruppierteListe {
                        let offen = z.aufgaben.filter { $0.zielID == g.id && !$0.erledigt }.sorted { ($0.datum ?? T.plus(tage: 9999)) < ($1.datum ?? T.plus(tage: 9999)) }
                        if offen.isEmpty { LeerZeile(text: "Keine offenen Aufgaben.") }
                        ForEach(offen.prefix(5)) { AufgabeZeile(aufgabe: $0, datumZeigen: true) }
                    }

                    Button(g.status == .erreicht ? "Wieder aktiv setzen" : "Als erreicht markieren") {
                        speicher.aendern { s in
                            if let i = s.ziele.firstIndex(where: { $0.id == id }) { s.ziele[i].status = g.status == .erreicht ? .aktiv : .erreicht }
                        }
                    }
                    .font(.zeile).frame(maxWidth: .infinity, minHeight: 50)
                    .background(Farbe.karte, in: RoundedRectangle(cornerRadius: Mass.karte, style: .continuous))
                    .padding(.top, Mass.abschnitt)
                }
                .padding(Mass.rand)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .background(Farbe.grund.ignoresSafeArea())
            .navigationTitle(g.titel)
            .navigationBarTitleDisplayMode(.inline)
        } else {
            ContentUnavailableView("Ziel nicht gefunden", systemImage: "target", description: Text("Es wurde vielleicht gelöscht."))
        }
    }

    private func prognoseText(_ p: Kurs.Prognose) -> String {
        switch p {
        case .keine: "Prognose ab 7 Tagen Verlauf"
        case .keinFortschritt: "Kein messbarer Fortschritt in den letzten Wochen"
        case .datum(let d, _, _): "Voraussichtlich erreicht: \(d.datum().formatted(.dateTime.month(.wide).year().locale(Locale(identifier: "de_DE"))))"
        }
    }
}

private struct SchrittZeile: View {
    var ziel: Ziel
    var schritt: Schritt
    @Environment(Speicher.self) private var speicher

    var body: some View {
        let st = Fortschritt.stand(schritt, in: speicher.zustand, heute: speicher.heute)
        HStack(spacing: 10) {
            Haken(an: schritt.geschafft, farbe: Color(hex: ziel.farbe), beschriftung: schritt.titel) {
                speicher.aendern { $0.schrittUmschalten(ziel: ziel.id, schritt: schritt.id) }
            }
            .padding(.leading, 4)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(schritt.titel).font(.zeile).foregroundStyle(Farbe.text)
                    Spacer()
                    Text(Zahl.prozent(st.anteil)).font(.kompass(.subheadline, .bold)).foregroundStyle(Farbe.zweitrangig).monospacedDigit()
                }
                Text(st.hinweis ?? "\(st.text) · \(["", "klein", "mittel", "groß"][st.gewicht])")
                    .font(.unterzeile).foregroundStyle(st.hinweis == nil ? Farbe.zweitrangig : Farbe.warnung)
                Balken(anteil: st.anteil, farbe: Color(hex: ziel.farbe), spur: Farbe.linie, hoehe: 4)
            }
            .padding(.trailing, 16)
        }
        .padding(.vertical, 10)
    }
}

/// „So wird gerechnet“: die Formel mit den echten Zahlen dieses Ziels.
struct RechnungBlatt: View {
    var zielID: UUID
    @Environment(Speicher.self) private var speicher

    var body: some View {
        NavigationStack {
            let z = speicher.zustand
            let T = speicher.heute
            List {
                if let g = z.ziel(zielID) {
                    let p = Fortschritt.ziel(g, in: z, heute: T)
                    let kurs = Kurs.aufKurs(g, in: z, heute: T)
                    if let m = g.zahl {
                        Section("Ziel als Zahl") {
                            Text("(aktuell − Start) ÷ (Ziel − Start)")
                            Text("(\(Zahl.text(m.aktuell)) − \(Zahl.text(m.start))) ÷ (\(Zahl.text(m.ziel)) − \(Zahl.text(m.start))) = \(Zahl.prozent(p))").bold()
                        }
                    } else {
                        Section("Ziel mit Schritten") {
                            Text("Σ(Gewicht × Stand) ÷ Σ Gewicht")
                            ForEach(g.schritte) { s in
                                let st = Fortschritt.stand(s, in: z, heute: T)
                                LabeledContent(s.titel, value: "\(st.gewicht) × \(Zahl.prozent(st.anteil))")
                            }
                            Text("= \(Zahl.prozent(p))").bold()
                        }
                    }
                    Section("Auf Kurs") {
                        LabeledContent("Erwartet", value: "\(kurs.verstrichen) von \(kurs.gesamt) Tagen = \(Zahl.prozent(kurs.erwartet))")
                        LabeledContent("Ergebnis", value: kurs.lage.text)
                        Text("Ab 5 Punkten über dem Erwarteten „voraus“, ab 10 Punkten darunter „hinterher“.").font(.footnote).foregroundStyle(.secondary)
                    }
                    Section {
                        Text("Aufgaben zählen bis 90 % eines Schritts, die letzten 10 % durch Abhaken.").font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("So wird gerechnet")
            .navigationBarTitleDisplayMode(.inline)
            .schliessenKnopf()
        }
    }
}
