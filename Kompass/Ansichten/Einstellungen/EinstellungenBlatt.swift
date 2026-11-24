import SwiftUI

/// Daten & Kalender: Beispielkalender ein/aus, Speicherort, Demo zurücksetzen.
struct EinstellungenBlatt: View {
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav
    @State private var zuruecksetzenFragen = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Apple-Kalender lesen", isOn: Binding(get: { speicher.zustand.einstellungen.appleKalender }, set: { neu in
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
                    }
                    Toggle("Farben nach Kategorie", isOn: schalter(\.farbenNachKategorie))
                } header: {
                    Text("Kalender")
                } footer: {
                    Text("Termine bleiben auf deinem Gerät. Google-Kalender, die im Apple-Kalender eingebunden sind, erscheinen mit. Ohne Schalter färbt Kompass nach Ziel.")
                }
                Section {
                    Toggle("Beispiel: Google", isOn: schalter(\.googleBeispiel))
                    Toggle("Beispiel: Apple", isOn: schalter(\.appleBeispiel))
                } header: {
                    Text("Beispieltermine")
                } footer: {
                    Text("Zum Ausprobieren ohne echten Kalender.")
                }
                Section {
                    LabeledContent("Antwortet mit", value: Sprachmodelle.aktiv == nil ? "Regeln auf dem Gerät" : "Claude (offline: Regeln)")
                    if !speicher.zustand.lernen.lotse.erinnerungen.isEmpty {
                        DisclosureGroup("Das merkt sich der Assistent (\(speicher.zustand.lernen.lotse.erinnerungen.count))") {
                            ForEach(speicher.zustand.lernen.lotse.erinnerungen, id: \.self) { e in
                                Text(e).font(.footnote)
                                    .swipeActions { Button("Löschen", role: .destructive) { speicher.aendern { $0.lernen.lotse.erinnerungen.removeAll { $0 == e } } } }
                            }
                        }
                    }
                    if let k = LotseStand.geteilt.kontingent {
                        LabeledContent("Heute frei", value: k.pro ? "unbegrenzt (Pro)" : "\(k.frei) von \(k.limit)")
                    }
                    Button("Kompass Pro") { nav.blatt = .pro }
                    if Kanal.aktuell != .store {
                        TextField("Server-URL (Debug/Beta)", text: Binding(
                            get: { LotseKonfiguration.ueberschriebeneURL ?? "" },
                            set: { LotseKonfiguration.ueberschriebeneURL = $0; Sprachmodelle.einrichten(pro: speicher.zustand.einstellungen.pro) }))
                            .textInputAutocapitalization(.never).keyboardType(.URL).font(.footnote)
                        Toggle("Pro zum Testen", isOn: schalter(\.pro))
                    }
                } header: {
                    Text("Assistent")
                } footer: {
                    Text("Klare Fragen beantwortet der Assistent auf dem Gerät – kostenlos. Freie Formulierungen gehen an den Kompass-Server (Claude). Fragen werden dort nicht gespeichert.")
                }
                Section {
                    LabeledContent("Speicherort", value: "Nur auf diesem Gerät")
                    LabeledContent("Status", value: speicher.speicherText)
                } header: {
                    Text("Daten")
                } footer: {
                    Text("Funktioniert vollständig offline.")
                }
                Section {
                    Button("Demo-Daten neu laden", role: .destructive) { zuruecksetzenFragen = true }
                }
                Section {
                    LabeledContent("Version", value: version)
                }
            }
            .navigationTitle("Daten & Kalender")
            .navigationBarTitleDisplayMode(.inline)
            .schliessenKnopf()
            .confirmationDialog("Alle Einträge durch Demo-Daten ersetzen?", isPresented: $zuruecksetzenFragen, titleVisibility: .visible) {
                Button("Ersetzen", role: .destructive) { speicher.demoZuruecksetzen() }
            }
        }
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
        Binding(get: { speicher.zustand.einstellungen[keyPath: pfad] },
                set: { neu in speicher.aendern { $0.einstellungen[keyPath: pfad] = neu } })
    }
}
