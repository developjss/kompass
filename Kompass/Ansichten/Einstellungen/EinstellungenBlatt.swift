import SwiftUI

/// Daten & Kalender: Beispielkalender ein/aus, Speicherort, Demo zurücksetzen.
struct EinstellungenBlatt: View {
    @Environment(Speicher.self) private var speicher
    @State private var zuruecksetzenFragen = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Google Kalender", isOn: schalter(\.googleBeispiel))
                    Toggle("Apple Kalender (iCloud)", isOn: schalter(\.appleBeispiel))
                } header: {
                    Text("Kalender")
                } footer: {
                    Text("Noch Beispieltermine – keine echte Verbindung.")
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
