import SwiftUI

/// Journal (Tab statt Kalender, 27.11.2026): Figur oben, Gespräch „Wie war dein Tag?“, Stimmung 1–5, ein Satz.
/// Darunter die letzten sieben Tage und die Wochenreflexion. Gerechnet wird nichts hier – Muster folgen (§15).
struct JournalAnsicht: View {
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav
    @State private var stimmung: Int?
    @State private var satz = ""
    @State private var gespeichert = false
    @FocusState private var schreibt: Bool

    private let woerter = ["schwer", "mäßig", "okay", "gut", "sehr gut"]

    var body: some View {
        let T = speicher.heute
        let eintrag = speicher.zustand.journal[T.text]
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Figur(zustand: gespeichert ? .erfolg : .ruhig, groesse: 80)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)

                VStack(alignment: .leading, spacing: 16) {
                    if eintrag != nil && !gespeichert {
                        Text("Heute schon eingetragen.").gespraechSchrift().foregroundStyle(DFarbe.zweitrangig).blur(radius: 0.6)
                    }
                    Text(speicher.zustand.profil.name.isEmpty ? "Wie war dein Tag?" : "Wie war dein Tag, \(speicher.zustand.profil.name)?")
                        .gespraechSchrift()
                    if let s = stimmung {
                        Text(woerter[s - 1].prefix(1).uppercased() + woerter[s - 1].dropFirst() + ".").gespraechSchrift().foregroundStyle(DFarbe.antwort)
                    }
                }

                HStack(spacing: 10) {
                    ForEach(1...5, id: \.self) { s in
                        Button { withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { stimmung = s } } label: {
                            Text("\(s)").font(.system(.title3, weight: .semibold))
                                .frame(maxWidth: .infinity, minHeight: 54)
                                .foregroundStyle(stimmung == s ? Color.black : DFarbe.text)
                                .background(stimmung == s ? AnyShapeStyle(DFarbe.akzent) : AnyShapeStyle(DFarbe.kapsel), in: Capsule())
                                .overlay { Capsule().strokeBorder(Color.white.opacity(0.12), lineWidth: 1) }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Stimmung \(s), \(woerter[s - 1])")
                        .accessibilityAddTraits(stimmung == s ? .isSelected : [])
                    }
                }

                EingabeKapsel(platzhalter: "Ein Satz reicht …", text: $satz)
                    .focused($schreibt)
                    .submitLabel(.done)

                Button(gespeichert ? "Gespeichert ✓" : "Speichern") { speichern(T) }
                    .buttonStyle(.kapsel)
                    .disabled(stimmung == nil && satz.trimmingCharacters(in: .whitespaces).isEmpty)

                woche(T)

                Button { nav.blatt = .reflexion(woche: true) } label: {
                    GlasGruppe {
                        GlasZeile(symbol: "moon.stars", titel: "Wochenreflexion",
                                  unter: speicher.zustand.reflexionen["woche:\(T.montag.text)"] == nil ? "Drei Fragen, zwei Minuten" : "Diese Woche erledigt ✓")
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Dunkel.rand_)
            .padding(.bottom, 40)
        }
        .scrollDismissesKeyboard(.interactively)
        .dunkelGrund()
        .navigationTitle("Journal")
        .toolbarTitleDisplayMode(.inlineLarge)
        .onAppear {
            stimmung = eintrag?.stimmung
            satz = eintrag?.satz ?? ""
        }
        .sensoryFeedback(.success, trigger: gespeichert)
    }

    private func speichern(_ T: Tag) {
        schreibt = false
        let jetzt = speicher.jetzt()
        speicher.aendern { $0.journal[T.text] = JournalEintrag(stimmung: stimmung, satz: satz.trimmingCharacters(in: .whitespacesAndNewlines), zeit: jetzt) }
        withAnimation { gespeichert = true }
    }

    /// Die letzten sieben Tage: Stimmung als Säule, Satz darunter (nur Anzeige).
    @ViewBuilder private func woche(_ T: Tag) -> some View {
        let tage = (0..<7).map { T.plus(tage: -6 + $0) }
        let werte = tage.compactMap { speicher.zustand.journal[$0.text]?.stimmung }
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Diese Woche").font(DSchrift.zeileFett)
                Spacer()
                if !werte.isEmpty {
                    Text("Ø " + Muster.zahl(Double(werte.reduce(0, +)) / Double(werte.count))).font(DSchrift.zeileFett).foregroundStyle(DFarbe.akzent)
                }
            }
            HStack(alignment: .bottom, spacing: 0) {
                ForEach(tage, id: \.self) { t in
                    let s = speicher.zustand.journal[t.text]?.stimmung
                    VStack(spacing: 6) {
                        Capsule()
                            .fill(s == nil ? AnyShapeStyle(Color.white.opacity(0.1)) : AnyShapeStyle(LinearGradient(colors: DFarbe.akzentFarben, startPoint: .bottom, endPoint: .top)))
                            .frame(width: 26, height: s.map { CGFloat($0) * 14 } ?? 8)
                        Text(t.kurzerWochentag).font(.system(.caption, weight: .semibold)).foregroundStyle(DFarbe.zweitrangig)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 100, alignment: .bottom)
            .accessibilityElement()
            .accessibilityLabel(werte.isEmpty ? "Diese Woche noch keine Einträge" : "Stimmung diese Woche: " + tage.map { t in "\(t.kurzerWochentag) \(speicher.zustand.journal[t.text]?.stimmung.map(String.init) ?? "–")" }.joined(separator: ", "))
            if werte.isEmpty {
                Text("Dein erster Eintrag dauert 30 Sekunden.").font(DSchrift.unterzeile).foregroundStyle(DFarbe.zweitrangig)
            }
        }
        .padding(18)
        .background(DFarbe.glas, in: RoundedRectangle(cornerRadius: Dunkel.gruppenRadius, style: .continuous))
    }
}

private extension Tag {
    var kurzerWochentag: String { ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"][wochentag - 1] }
}
