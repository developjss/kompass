import SwiftUI

/// Vorschau aller Bausteine des Designsystems „Dunkel“ – zum Vergleich mit den Vorbild-Bildern.
/// Start mit dem Argument `-designVorschau` (Simulator), sonst nicht erreichbar.
struct DesignVorschau: View {
    @State private var name = ""
    @State private var tage: Set<Int> = [1, 2, 3, 4, 5]
    @State private var stufe = 0
    @State private var wahl = 1
    @State private var blatt = false
    @State private var gehalten = 0
    @State private var seite = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text("Designsystem").font(DSchrift.grosserTitel)

                gruppe("Gespräch") {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Ich helfe dir, dranzubleiben.").gespraechSchrift().foregroundStyle(DFarbe.zweitrangig).blur(radius: 1.5)
                        Text("Wie heißt du?").gespraechSchrift()
                        Text("Hallo, Lena.").gespraechSchrift().foregroundStyle(DFarbe.antwort)
                    }
                    EingabeKapsel(platzhalter: "Lena", text: $name)
                    Button("Weiter") {}.buttonStyle(.kapsel).disabled(name.isEmpty)
                }

                gruppe("Auswahl") {
                    VStack(spacing: 14) {
                        AuswahlKapsel(symbol: "target", titel: "Ziele erreichen", gewaehlt: wahl == 0) { wahl = 0 }
                        AuswahlKapsel(symbol: "repeat", titel: "Gewohnheiten aufbauen", gewaehlt: wahl == 1) { wahl = 1 }
                        AuswahlKapsel(symbol: "iphone.slash", titel: "Weniger am Handy", gewaehlt: wahl == 2) { wahl = 2 }
                        AuswahlKapsel(symbol: "moon.fill", titel: "Besser schlafen", gewaehlt: wahl == 3) { wahl = 3 }
                    }
                }

                gruppe("Knöpfe") {
                    Button("Weiter") {}.buttonStyle(.kapsel)
                    Button("Mit Apple fortfahren", systemImage: "apple.logo") {}.buttonStyle(.kapsel(.hell))
                    Button("Kostenlos testen") {}.buttonStyle(.kapsel(.kauf))
                    HaltenKnopf(titel: gehalten == 0 ? "Gedrückt halten zum Festlegen" : "Festgelegt ✓") { gehalten += 1 }
                    HaltenKnopf(titel: "Halten zum Einlösen", art: .rot) {}
                    HStack(spacing: 12) {
                        RundKnopf(symbol: "xmark", beschriftung: "Schließen") {}
                        RundKnopf(symbol: "chevron.left", beschriftung: "Zurück") {}
                        RundKnopf(symbol: "pencil", beschriftung: "Bearbeiten") {}
                        Spacer()
                        Plakette(text: "PRO")
                        Plakette(text: "Serie 7", farbe: Color(Dunkel.akzentA), symbol: "flame.fill")
                    }
                }

                gruppe("Zahlen") {
                    VStack(spacing: 4) {
                        Text("13 Jahre").font(.system(size: 40, weight: .heavy)).foregroundStyle(DFarbe.akzent).opacity(0.35).blur(radius: 2)
                        AkzentZahl(text: "14 Jahre")
                        Text("15 Jahre").font(.system(size: 40, weight: .heavy)).foregroundStyle(DFarbe.akzent).opacity(0.35).blur(radius: 2)
                    }.frame(maxWidth: .infinity)
                    Aufforderung(text: "Tippen zum Weiter").frame(maxWidth: .infinity)
                    DSeitenPunkte(anzahl: 5, aktiv: seite).frame(maxWidth: .infinity)
                }

                gruppe("Zeilen") {
                    GlasGruppe {
                        GlasZeile(symbol: "bell.fill", titel: "Mitteilungen", wert: "An")
                        GlasZeile(symbol: "hourglass", titel: "Warteraum", unter: "Was du siehst, bevor du abbrichst")
                        GlasZeile(titel: "Dauer", wert: "45 Min", pfeil: false)
                    }
                    GlasGruppe {
                        VonBis(von: "20:00", bis: "22:00")
                    }
                    GlasGruppe {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack { Text("An diesen Tagen").font(DSchrift.zeile); Spacer(); Text("Werktags").foregroundStyle(DFarbe.zweitrangig) }
                            TageWahl(tage: $tage)
                        }
                        .padding(18)
                    }
                    VStack(spacing: 6) {
                        Text("SCHWIERIGKEIT").font(DSchrift.etikett).foregroundStyle(DFarbe.akzent)
                        Text(["Leicht", "Steigend", "Durchziehen"][stufe]).font(DSchrift.ueberschrift)
                        StufenRegler(stufe: $stufe, stufen: ["Leicht", "Steigend", "Durchziehen"]).padding(.top, 8)
                    }
                    Button("Glas-Blatt öffnen") { blatt = true }.buttonStyle(.kapsel)
                }
            }
            .padding(.horizontal, Dunkel.rand_)
            .padding(.vertical, 24)
        }
        .dunkelGrund()
        .sheet(isPresented: $blatt) {
            VStack(spacing: 16) {
                BlattKopf(titel: "Abendruhe", zurueck: true, schliessen: { blatt = false }, rechts: ("pencil", "Bearbeiten", {}))
                GlasGruppe { GlasZeile(titel: "Gesperrte Apps", wert: "Auswählen") }
                GlasGruppe { VonBis(von: "20:00", bis: "22:00") }
                Spacer()
                HaltenKnopf(titel: "Gedrückt halten zum Festlegen") { blatt = false }
            }
            .padding(.horizontal, 16).padding(.bottom, 16)
            .presentationDetents([.medium, .large])
            .glasBlatt()
        }
    }

    private func gruppe<I: View>(_ titel: String, @ViewBuilder _ inhalt: () -> I) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(titel.uppercased()).font(DSchrift.etikett).foregroundStyle(DFarbe.zweitrangig)
            inhalt()
        }
    }
}

#Preview { DesignVorschau() }
