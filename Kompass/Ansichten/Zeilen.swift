import SwiftUI

/// Aufgabe in einer Liste: Haken · Titel · eine Unterzeile (Ziel · Uhrzeit/Datum) · Fokus-Knopf.
struct AufgabeZeile: View {
    var aufgabe: Aufgabe
    var datumZeigen = false
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav

    var body: some View {
        let z = speicher.zustand
        let ziel = z.ziel(aufgabe.zielID)
        let laeuft = z.timer?.aufgabeID == aufgabe.id
        HStack(spacing: 10) {
            Haken(an: aufgabe.erledigt, farbe: ziel.map { Color(hex: $0.farbe) } ?? Farbe.freude, beschriftung: aufgabe.titel) {
                speicher.aendern { $0.umschalten(aufgabe.id, jetzt: speicher.jetzt()) }
            }
            .padding(.leading, 4)
            Button { nav.blatt = .aufgabe(aufgabe.id) } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(aufgabe.titel).font(.zeile).foregroundStyle(aufgabe.erledigt ? Farbe.zweitrangig : Farbe.text)
                        .strikethrough(aufgabe.erledigt)
                    let unter = unterzeile(ziel: ziel, laeuft: laeuft)
                    if !unter.isEmpty {
                        Text(unter).font(.unterzeile).foregroundStyle(laeuft ? Farbe.akzent : Farbe.zweitrangig).lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if !aufgabe.erledigt {
                Button { nav.blatt = .fokus(aufgabe.id) } label: {
                    Image(systemName: laeuft ? "pause.fill" : "play.fill").font(.footnote)
                        .frame(width: 34, height: 34).background(Farbe.akzentWeich, in: Circle()).foregroundStyle(Farbe.akzent)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(laeuft ? "Fokus öffnen" : "Fokus starten")
            }
        }
        .padding(.trailing, 8)
        .frame(minHeight: Mass.zeile)
    }

    private func unterzeile(ziel: Ziel?, laeuft: Bool) -> String {
        var teile: [String] = []
        if let ziel { teile.append(ziel.titel) }
        if laeuft { teile.append("Fokus läuft") }
        else if datumZeigen, let d = aufgabe.datum { teile.append(d.datum().formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).locale(Locale(identifier: "de_DE")))) }
        else if let u = aufgabe.uhrzeit { teile.append(Beispieltermine.uhrzeit(u)) }
        return teile.prefix(2).joined(separator: " · ")
    }
}

/// Letzte Zeile einer Liste: „+ Aufgabe“ zum direkten Eintippen.
struct AufgabeHinzufuegen: View {
    var platzhalter: String
    var datum: Tag?
    var prio: Prioritaet
    @Environment(Speicher.self) private var speicher
    @State private var text = ""
    @FocusState private var fokus: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "plus").font(.body.weight(.semibold)).foregroundStyle(Farbe.akzent).frame(width: 44)
            TextField(platzhalter, text: $text)
                .font(.zeile)
                .focused($fokus)
                .submitLabel(.done)
                .onSubmit(anlegen)
        }
        .padding(.trailing, 16)
        .frame(minHeight: Mass.zeileKompakt)
    }

    private func anlegen() {
        let t = text.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        speicher.aendern { $0.aufgabeAnlegen(t, datum: datum, prio: prio, heute: speicher.heute) }
        text = ""
        fokus = true
    }
}

/// Ziel als Zeile: Symbol · Titel · Prozent · Balken
struct ZielZeile: View {
    var ziel: Ziel
    @Environment(Speicher.self) private var speicher

    var body: some View {
        let p = Fortschritt.ziel(ziel, in: speicher.zustand, heute: speicher.heute)
        let c = Color(hex: ziel.farbe)
        NavigationLink(value: ZielAuswahl(id: ziel.id)) {
            HStack(spacing: 12) {
                SymbolKachel(symbol: ziel.symbol, farbe: c)
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(ziel.titel).font(.zeile).foregroundStyle(Farbe.text).lineLimit(1)
                        Spacer()
                        Text(Zahl.prozent(p)).font(.kompass(.subheadline, .bold)).foregroundStyle(Farbe.zweitrangig).monospacedDigit()
                    }
                    Balken(anteil: p, farbe: c, spur: Farbe.linie)
                }
            }
            .padding(.horizontal, 12)
            .frame(minHeight: Mass.zeile)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(ziel.titel), \(Zahl.prozent(p))")
        .accessibilityAddTraits(.isButton)
    }
}
