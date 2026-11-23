import SwiftUI

/// Ziel im Detail: Kopf mit Prozent, dann Meilensteine (zählen), Aufgaben, Habits, Termine (fließen ein) und Einsatz.
/// Alles lässt sich hier hinzufügen, abhaken und wieder lösen.
struct ZielDetail: View {
    var id: UUID
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav

    var body: some View {
        let z = speicher.zustand
        let T = speicher.heute
        if let g = z.ziel(id) {
            let kurs = Kurs.aufKurs(g, in: z, heute: T)
            let prognose = Kurs.prognose(verlauf: z.verlauf[g.id] ?? [], fortschritt: kurs.fortschritt, heute: T)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Button { nav.blatt = .rechnung(g.id) } label: {
                        Verlaufskarte(farben: Farbe.verlauf(g.farbe)) {
                            HStack {
                                KartenLabel(text: g.bereich)
                                Spacer()
                                Image(systemName: "info.circle").opacity(0.85)
                            }
                            Text(Zahl.prozent(kurs.fortschritt)).font(.grosseZahl).contentTransition(.numericText())
                            Text("\(kurs.lage.text) · \(Kurs.bisText(g.faellig, heute: T))").font(.unterzeile).opacity(0.9)
                            Balken(anteil: kurs.fortschritt).padding(.top, 8)
                            Text(prognoseText(prognose)).font(.klein).opacity(0.9).padding(.top, 4)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Zeigt, wie gerechnet wird")

                    if !g.warum.isEmpty {
                        Text(g.warum).font(.unterzeile).foregroundStyle(Farbe.zweitrangig).padding(.top, 12)
                    }

                    MeilensteinListe(ziel: g)
                    ZielAufgaben(ziel: g)
                    ZielHabits(ziel: g)
                    ZielTermine(ziel: g)
                    ZielEinsatz(ziel: g)

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
                .padding(.bottom, 24)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .background(Farbe.grund.ignoresSafeArea())
            .navigationTitle(g.titel)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Bearbeiten") { nav.blatt = .zielBearbeiten(g.id) }
                }
            }
        } else {
            ContentUnavailableView("Ziel nicht gefunden", systemImage: "target", description: Text("Es wurde vielleicht gelöscht."))
        }
    }

    private func prognoseText(_ p: Kurs.Prognose) -> String {
        switch p {
        case .keine: "Prognose ab 7 Tagen Verlauf"
        case .keinFortschritt: "Kein messbarer Fortschritt in den letzten Wochen"
        case .datum(let d, _, _): "Im jetzigen Tempo erreicht: \(d.datum().formatted(.dateTime.month(.wide).year().locale(Locale(identifier: "de_DE"))))"
        }
    }
}

/// Zeile „+ …“ am Ende einer Liste
struct PlusZeile: View {
    var text: String
    var aktion: () -> Void
    var body: some View {
        Button(action: aktion) {
            HStack(spacing: 10) {
                Image(systemName: "plus").font(.body.weight(.semibold)).frame(width: 44)
                Text(text).font(.zeile)
                Spacer()
            }
            .foregroundStyle(Farbe.akzent)
            .frame(minHeight: Mass.zeileKompakt)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: Meilensteine

private struct MeilensteinListe: View {
    var ziel: Ziel
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav

    var body: some View {
        AbschnittKopf(titel: "Meilensteine") {
            Button { nav.blatt = .rechnung(ziel.id) } label: { Image(systemName: "info.circle") }
                .accessibilityLabel("So wird gerechnet")
        }
        GruppierteListe {
            if ziel.schritte.isEmpty { LeerZeile(text: "Wie misst du das Ziel? Lege Meilensteine an.") }
            ForEach(ziel.schritte) { s in MeilensteinZeile(ziel: ziel, schritt: s) }
            PlusZeile(text: "Meilenstein") { nav.blatt = .meilenstein(ziel: ziel.id, schritt: nil) }
        }
    }
}

private struct MeilensteinZeile: View {
    var ziel: Ziel
    var schritt: Schritt
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav

    var body: some View {
        let z = speicher.zustand
        let T = speicher.heute
        let st = Fortschritt.stand(schritt, in: z, heute: T)
        let c = Color(hex: ziel.farbe)
        HStack(spacing: 10) {
            Haken(an: schritt.geschafft, farbe: c, beschriftung: schritt.titel) {
                speicher.aendern { $0.schrittUmschalten(ziel: ziel.id, schritt: schritt.id, heute: T) }
            }
            .padding(.leading, 4)
            Button { nav.blatt = .meilenstein(ziel: ziel.id, schritt: schritt.id) } label: {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(schritt.titel).font(.zeile).foregroundStyle(Farbe.text)
                        if st.gewicht > 1 {
                            Text("×\(st.gewicht)").font(.klein).foregroundStyle(Farbe.zweitrangig)
                                .accessibilityLabel(st.gewicht == 3 ? "zählt dreifach" : "zählt doppelt")
                        }
                        Spacer()
                        Text(Zahl.prozent(st.anteil)).font(.kompass(.subheadline, .bold)).foregroundStyle(Farbe.zweitrangig).monospacedDigit()
                    }
                    Text(unterzeile(st)).font(.unterzeile).foregroundStyle(st.hinweis == nil ? Farbe.zweitrangig : Farbe.warnung)
                    Balken(anteil: st.anteil, farbe: c, spur: Farbe.linie, hoehe: 4)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.trailing, 16)
        }
        .padding(.vertical, 10)
        .contextMenu {
            Button("Bearbeiten", systemImage: "pencil") { nav.blatt = .meilenstein(ziel: ziel.id, schritt: schritt.id) }
            Button(schritt.geschafft ? "Wieder öffnen" : "Abhaken", systemImage: "checkmark") {
                speicher.aendern { $0.schrittUmschalten(ziel: ziel.id, schritt: schritt.id, heute: T) }
            }
            Button("Löschen", systemImage: "trash", role: .destructive) {
                speicher.aendern { $0.schrittLoeschen(ziel: ziel.id, schritt: schritt.id) }
            }
        }
    }

    private func unterzeile(_ st: Fortschritt.SchrittStand) -> String {
        if let h = st.hinweis { return h }
        let erreicht = Fortschritt.erreichteSchwellen(schritt, in: speicher.zustand, heute: speicher.heute).count
        if let n = schritt.schwellen?.count, n > 0 { return "\(st.text) · \(erreicht) von \(n) Zwischenständen" }
        return st.text
    }
}

// MARK: Aufgaben, Habits, Termine, Einsatz

private struct ZielAufgaben: View {
    var ziel: Ziel
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav
    @State private var alle = false

    var body: some View {
        let z = speicher.zustand
        let T = speicher.heute
        let offen = z.aufgaben.filter { $0.zielID == ziel.id && !$0.erledigt }
            .sorted { ($0.datum ?? T.plus(tage: 99_999)) < ($1.datum ?? T.plus(tage: 99_999)) }
        let erledigt = z.aufgaben.filter { $0.zielID == ziel.id && $0.erledigt }.count
        AbschnittKopf(titel: "Aufgaben") { Text("\(erledigt) erledigt").foregroundStyle(Farbe.zweitrangig) }
        GruppierteListe {
            ForEach(alle ? offen : Array(offen.prefix(5))) { a in
                AufgabeZeile(aufgabe: a, datumZeigen: true)
                    .contextMenu {
                        Button("Vom Ziel lösen", systemImage: "link.badge.minus") {
                            speicher.aendern { $0.aufgabeZuordnen(a.id, ziel: nil, heute: T) }
                        }
                    }
            }
            if offen.count > 5 {
                Button(alle ? "Weniger" : "\(offen.count - 5) weitere") { alle.toggle() }.font(.unterzeile).frame(maxWidth: .infinity, minHeight: 44)
            }
            AufgabeHinzufuegen(platzhalter: "Neue Aufgabe", datum: nil, prio: .hoch, zielID: ziel.id)
            PlusZeile(text: "Bestehende Aufgabe") { nav.blatt = .aufgabeZuZiel(ziel.id) }
        }
    }
}

private struct ZielHabits: View {
    var ziel: Ziel
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav

    var body: some View {
        let z = speicher.zustand
        let T = speicher.heute
        let habits = z.habits.filter { h in h.zielID == ziel.id || ziel.schritte.contains { $0.habitID == h.id } }
        AbschnittKopf(titel: "Habits")
        GruppierteListe {
            ForEach(habits) { h in
                let zaehlt = ziel.schritte.contains { $0.art == .habit && $0.habitID == h.id }
                HStack(spacing: 10) {
                    Haken(an: h.erledigt.contains(T), farbe: Color(hex: h.farbe), beschriftung: h.titel) {
                        speicher.aendern { $0.habitUmschalten(h.id, am: T) }
                    }
                    .padding(.leading, 4)
                    .disabled(!HabitRechnung.geplant(h, am: T))
                    .opacity(HabitRechnung.geplant(h, am: T) ? 1 : 0.4)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(h.titel).font(.zeile).foregroundStyle(Farbe.text)
                        Text("Serie \(HabitRechnung.serie(h, heute: T)) · \(Zahl.prozent(HabitRechnung.quote(h, heute: T))) · \(zaehlt ? "zählt" : "nur Einsatz")")
                            .font(.unterzeile).foregroundStyle(Farbe.zweitrangig)
                    }
                    Spacer()
                }
                .frame(minHeight: Mass.zeile)
                .contentShape(Rectangle())
                .onTapGesture { nav.blatt = .habit(h.id) }
                .contextMenu {
                    Button("Vom Ziel lösen", systemImage: "link.badge.minus") { speicher.aendern { $0.habitLoesen(h.id, ziel: ziel.id) } }
                }
            }
            PlusZeile(text: "Habit") { nav.blatt = .habitZuZiel(ziel.id) }
        }
    }
}

private struct ZielTermine: View {
    var ziel: Ziel
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav

    var body: some View {
        let z = speicher.zustand
        let T = speicher.heute
        let links = z.termine.filter { $0.zielID == ziel.id }
        AbschnittKopf(titel: "Termine")
        GruppierteListe {
            ForEach(links) { l in
                let n = l.vorkommen.filter { $0.tag >= l.seit && $0.tag <= T }.count
                let wohin = z.schritt(l.schrittID, in: ziel.id).map { "zählt in „\($0.titel)“" } ?? "nur Einsatz"
                HStack(spacing: 12) {
                    Image(systemName: "calendar").foregroundStyle(Color(hex: ziel.farbe)).frame(width: 44)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(l.titel).font(.zeile).foregroundStyle(Farbe.text)
                        Text("\(n) stattgefunden · \(wohin)").font(.unterzeile).foregroundStyle(Farbe.zweitrangig)
                    }
                    Spacer()
                }
                .frame(minHeight: Mass.zeile)
                .contextMenu {
                    Button("Vom Ziel lösen", systemImage: "link.badge.minus") { speicher.aendern { $0.terminLoesen(l.id) } }
                }
            }
            PlusZeile(text: "Termin-Serie") { nav.blatt = .terminZuZiel(ziel.id) }
        }
    }
}

private struct ZielEinsatz: View {
    var ziel: Ziel
    @Environment(Speicher.self) private var speicher

    var body: some View {
        let z = speicher.zustand
        let T = speicher.heute
        let woche = Fortschritt.zeit(ziel: ziel.id, in: z, von: T.montag, bis: T)
        let gesamt = Fortschritt.zeit(ziel: ziel.id, in: z)
        AbschnittKopf(titel: "Einsatz")
        GruppierteListe {
            HStack {
                Text("Diese Woche").font(.zeile)
                Spacer()
                Text(Zahl.dauer(woche)).font(.zeile).foregroundStyle(Farbe.zweitrangig)
            }
            .padding(.horizontal, 16).frame(minHeight: Mass.zeileKompakt)
            HStack {
                Text("Seit Beginn").font(.zeile)
                Spacer()
                Text(Zahl.dauer(gesamt)).font(.zeile).foregroundStyle(Farbe.zweitrangig)
            }
            .padding(.horizontal, 16).frame(minHeight: Mass.zeileKompakt)
        }
    }
}
