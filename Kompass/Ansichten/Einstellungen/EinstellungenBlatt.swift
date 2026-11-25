import SwiftUI

/// Daten & Kalender (Nachtblau, drei Ebenen): kurze Bühne mit dem Wort, Karte vorn mit den drei Schaltern,
/// darunter die Listen App und Daten. Beispielkalender ein/aus, Speicherort, Demo zurücksetzen.
struct EinstellungenBlatt: View {
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav
    @Environment(\.dismiss) private var dismiss
    @State private var zuruecksetzenFragen = false

    var body: some View {
        BuehnenSeite(hoehe: Mass.buehneKurz, wort: Wort(zeilen: ["Daten &"], akzent: "Kalender.", groesse: Wort.kleinGroesse), marke: {
            RahmenKnopf(symbol: "xmark", beschriftung: "Schließen") { dismiss() }
            MarkenTitel(text: "Einstellungen")
            Spacer(minLength: 8)
        }) {
            VornKarte(abstand: 0) {
                SchalterZeile(titel: "Apple-Kalender", unter: AppleKalender.aktiv.status == .abgelehnt ? "Zugriff in den iOS-Einstellungen erlauben" : "Termine lesen und schreiben",
                              an: Binding(get: { speicher.zustand.einstellungen.appleKalender }, set: { neu in
                    Task {
                        let ok = neu ? await AppleKalender.aktiv.erlauben() : true
                        speicher.aendern { $0.einstellungen.appleKalender = neu && ok }
                        speicher.appleKalenderLesen()
                    }
                }))
                if AppleKalender.aktiv.status == .abgelehnt {
                    Button("Zugriff in den iOS-Einstellungen erlauben") {
                        if let u = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(u) }
                    }
                    .font(.klein).foregroundStyle(Farbe.akzent).padding(.bottom, 8)
                }
                Trenner()
                SchalterZeile(titel: "Farben nach Kategorie", unter: "sonst färbt Kompass nach Ziel", an: schalter(\.farbenNachKategorie))
                Trenner()
                SchalterZeile(titel: "Beispielkalender", unter: "Demo-Termine zeigen (Google und Apple)", an: Binding(
                    get: { speicher.zustand.einstellungen.googleBeispiel || speicher.zustand.einstellungen.appleBeispiel },
                    set: { neu in speicher.aendern { $0.einstellungen.googleBeispiel = neu; $0.einstellungen.appleBeispiel = neu } }))
            }
            Text("Termine bleiben auf deinem Gerät. Google-Kalender, die im Apple-Kalender eingebunden sind, erscheinen mit.")
                .font(.klein).foregroundStyle(Farbe.zweitrangig).padding(.horizontal, Mass.rand + 4).padding(.top, 10)

            AbschnittKopf(titel: "App") { EmptyView() }.padding(.horizontal, Mass.rand).padding(.top, Mass.abschnitt)
            GruppierteListe {
                PfeilZeile(symbol: "sparkles", text: "Kompass Pro · " + proText) { nav.blatt = .pro }
                WertZeile(symbol: "bubble.left.and.bubble.right", titel: "Assistent", wert: Sprachmodelle.aktiv == nil ? "Regeln auf dem Gerät" : "Claude · offline Regeln")
                if !speicher.zustand.lernen.lotse.erinnerungen.isEmpty {
                    WertZeile(symbol: "brain", titel: "Das merkt sich der Assistent", wert: "\(speicher.zustand.lernen.lotse.erinnerungen.count) gemerkt")
                    ForEach(speicher.zustand.lernen.lotse.erinnerungen, id: \.self) { e in
                        HStack {
                            Text(e).font(.klein).foregroundStyle(Farbe.text).lineLimit(2)
                            Spacer()
                            Button("Löschen") { speicher.aendern { $0.lernen.lotse.erinnerungen.removeAll { $0 == e } } }
                                .font(.klein).foregroundStyle(Farbe.akzent)
                        }
                        .padding(.horizontal, 16).frame(minHeight: Mass.zeileKompakt)
                    }
                }
                if Kanal.aktuell != .store {
                    HStack(spacing: 12) {
                        ZeichenKreis(symbol: "server.rack")
                        TextField("Server-URL (Debug/Beta)", text: Binding(
                            get: { LotseKonfiguration.ueberschriebeneURL ?? "" },
                            set: { LotseKonfiguration.ueberschriebeneURL = $0; Sprachmodelle.einrichten(pro: speicher.zustand.einstellungen.pro) }))
                            .textInputAutocapitalization(.never).keyboardType(.URL).font(.klein)
                    }
                    .padding(.horizontal, 16).frame(minHeight: Mass.zeile)
                    SchalterZeile(titel: "Pro zum Testen", unter: "nur Debug und Beta", an: schalter(\.pro)).padding(.horizontal, 16)
                }
            }
            .padding(.horizontal, Mass.rand)
            Text("Klare Fragen beantwortet der Assistent auf dem Gerät – kostenlos. Freie Formulierungen gehen an den Kompass-Server (Claude). Fragen werden dort nicht gespeichert.")
                .font(.klein).foregroundStyle(Farbe.zweitrangig).padding(.horizontal, Mass.rand + 4).padding(.top, 10)

            AbschnittKopf(titel: "Daten") { EmptyView() }.padding(.horizontal, Mass.rand).padding(.top, Mass.abschnitt)
            GruppierteListe {
                WertZeile(symbol: "iphone", titel: "Speicherort", wert: "Nur auf diesem Gerät · " + speicher.speicherText)
                PfeilZeile(symbol: "arrow.counterclockwise", text: "Demo-Daten neu laden") { zuruecksetzenFragen = true }
                WertZeile(symbol: "info", titel: "Version", wert: version)
            }
            .padding(.horizontal, Mass.rand)
            Text("Funktioniert vollständig offline.").font(.klein).foregroundStyle(Farbe.zweitrangig).padding(.horizontal, Mass.rand + 4).padding(.top, 10)
        }
        .confirmationDialog("Alle Einträge durch Demo-Daten ersetzen?", isPresented: $zuruecksetzenFragen, titleVisibility: .visible) {
            Button("Ersetzen", role: .destructive) { speicher.demoZuruecksetzen() }
        }
    }

    private var proText: String {
        if speicher.zustand.einstellungen.pro || LotseStand.geteilt.kontingent?.pro == true { return "aktiv" }
        if let k = LotseStand.geteilt.kontingent { return "\(k.frei) von \(k.limit) heute frei" }
        return "Assistent ohne Limit"
    }

    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        #if BETA
        return v + " Beta"
        #elseif DEBUG
        return v + " Entwicklung"
        #else
        return v
        #endif
    }

    private func schalter(_ pfad: WritableKeyPath<Einstellungen, Bool>) -> Binding<Bool> {
        Binding(get: { speicher.zustand.einstellungen[keyPath: pfad] }, set: { neu in speicher.aendern { $0.einstellungen[keyPath: pfad] = neu } })
    }
}

/// Schalter-Zeile in der Karte vorn: Titel, Unterzeile, Schalter in `handlung`.
struct SchalterZeile: View {
    var titel: String
    var unter: String? = nil
    @Binding var an: Bool
    var body: some View {
        Toggle(isOn: $an) {
            VStack(alignment: .leading, spacing: 2) {
                Text(titel).font(.zeile).foregroundStyle(Farbe.text)
                if let unter { Text(unter).font(.klein).foregroundStyle(Farbe.zweitrangig).lineLimit(2) }
            }
        }
        .tint(Farbe.handlung)
        .frame(minHeight: Mass.zeileKompakt)
    }
}

/// Zeile mit Zeichen, Titel und Wert rechts (ohne Pfeil).
struct WertZeile: View {
    var symbol: String
    var titel: String
    var wert: String
    var body: some View {
        HStack(spacing: 12) {
            ZeichenKreis(symbol: symbol)
            Text(titel).font(.zeile).foregroundStyle(Farbe.text)
            Spacer(minLength: 8)
            Text(wert).font(.klein).foregroundStyle(Farbe.zweitrangig).multilineTextAlignment(.trailing).lineLimit(2)
        }
        .padding(.horizontal, 16).frame(minHeight: Mass.zeile)
        .accessibilityElement(children: .combine)
    }
}

/// Dünne Linie zwischen Zeilen in der Karte vorn.
struct Trenner: View {
    var body: some View { Rectangle().fill(Farbe.linie).frame(height: 0.5).padding(.vertical, 4).accessibilityHidden(true) }
}
