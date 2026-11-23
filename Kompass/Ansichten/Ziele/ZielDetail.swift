import SwiftUI

/// Ziel im Detail, geführt und schlank: Kopf (Prozent, Kurs, Frist), ein Satz wie gerechnet wird, **dein nächster Schritt**,
/// die Meilensteine. Alles Weitere (Aufgaben, Habits, Termine, Einsatz, Details) liegt unter „Verfeinern“ auf eigenen Seiten.
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
                                Label(g.bereich, systemImage: g.symbol).font(.klein).opacity(0.9)
                                Spacer()
                                Image(systemName: "info.circle").opacity(0.85)
                            }
                            Text(Zahl.prozent(kurs.fortschritt)).font(.grosseZahl).contentTransition(.numericText())
                            Text("\(kurs.lage.text.prefix(1).uppercased() + kurs.lage.text.dropFirst()) · \(Kurs.bisText(g.faellig, heute: T))").font(.unterzeile).opacity(0.9)
                            Balken(anteil: kurs.fortschritt).padding(.top, 8)
                            Text(prognoseText(prognose)).font(.klein).opacity(0.9).padding(.top, 4)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Zeigt, wie gerechnet wird")

                    if !g.warum.isEmpty {
                        Text("„\(g.warum)“").font(.unterzeile).italic().foregroundStyle(Farbe.zweitrangig).padding(.top, 12)
                    }

                    NaechsterSchrittKarte(ziel: g).padding(.top, 16)

                    MeilensteinListe(ziel: g)

                    Verfeinern(ziel: g)
                }
                .padding(Mass.rand)
                .padding(.bottom, 24)
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
        case .datum(let d, _, _): "Im jetzigen Tempo erreicht: \(d.datum().formatted(.dateTime.month(.wide).year().locale(Locale(identifier: "de_DE"))))"
        }
    }
}

// MARK: Dein nächster Schritt

/// Eine Karte, eine Handlung: der Meilenstein, der am meisten bringt – mit genau dem Knopf, der ihn voranbringt.
private struct NaechsterSchrittKarte: View {
    var ziel: Ziel
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav

    var body: some View {
        let z = speicher.zustand
        let T = speicher.heute
        let c = Color(hex: ziel.farbe)
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.forward.circle.fill").foregroundStyle(c)
                Text("Dein nächster Schritt").font(.klein).foregroundStyle(Farbe.zweitrangig)
            }
            if ziel.status == .erreicht {
                Text("Geschafft – dieses Ziel ist erreicht.").font(.kompass(.title3, .bold)).foregroundStyle(Farbe.text)
            } else if ziel.schritte.isEmpty {
                Text("Lege fest, woran du den Fortschritt misst.").font(.kompass(.title3, .bold)).foregroundStyle(Farbe.text)
                Text("Ein Meilenstein kann abgehakt, gezählt, in Stunden oder über einen Habit gemessen werden.").font(.unterzeile).foregroundStyle(Farbe.zweitrangig)
                knopf("Ersten Meilenstein anlegen", "plus") { nav.blatt = .meilenstein(ziel: ziel.id, schritt: nil) }
            } else if let n = Fortschritt.naechsterSchritt(ziel, in: z, heute: T) {
                let st = Fortschritt.stand(n.schritt, in: z, heute: T)
                Text(titel(n)).font(.kompass(.title3, .bold)).foregroundStyle(Farbe.text).fixedSize(horizontal: false, vertical: true)
                Text("„\(n.schritt.titel)“ · \(st.text) · bringt bis zu +\(Int((n.punkte * 100).rounded())) Prozentpunkte")
                    .font(.unterzeile).foregroundStyle(Farbe.zweitrangig).fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 8) { aktionen(n) }
            } else {
                Text("Alle Meilensteine sind geschafft.").font(.kompass(.title3, .bold)).foregroundStyle(Farbe.text)
                knopf("Als erreicht markieren", "checkmark") {
                    let zid = ziel.id
                    speicher.aendern { s in if let i = s.ziele.firstIndex(where: { $0.id == zid }) { s.ziele[i].status = .erreicht } }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Farbe.karte, in: RoundedRectangle(cornerRadius: Mass.karte, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Mass.karte, style: .continuous).strokeBorder(c.opacity(0.35), lineWidth: 1.5))
    }

    private func titel(_ n: Fortschritt.NaechsterSchritt) -> String {
        if let a = n.aufgabe { return a.titel }
        switch n.schritt.art {
        case .aufgaben: return "Abhaken, sobald es geschafft ist"
        case .zahl: return "Neuen Stand eintragen"
        case .zeit: return "Zeit sammeln – mit einer Aufgabe und Fokus"
        case .habit: return "Den Habit dranbleiben"
        }
    }

    @ViewBuilder private func aktionen(_ n: Fortschritt.NaechsterSchritt) -> some View {
        let T = speicher.heute
        if let a = n.aufgabe {
            knopf("Fokus starten", "play.fill") { nav.blatt = .fokus(a.id) }
            knopf("Erledigt", "checkmark", neben: true) { speicher.aendern { $0.erledigen(a.id, jetzt: speicher.jetzt()) } }
        } else {
            switch n.schritt.art {
            case .aufgaben:
                knopf("Abhaken", "checkmark") { let zid = ziel.id, sid = n.schritt.id; speicher.aendern { $0.schrittUmschalten(ziel: zid, schritt: sid, heute: T) } }
                knopf("Aufgabe dazu", "plus", neben: true) { nav.blatt = .aufgabeZuZiel(ziel.id) }
            case .zahl:
                knopf("Stand eintragen", "number") { nav.blatt = .meilenstein(ziel: ziel.id, schritt: n.schritt.id) }
            case .zeit:
                knopf("Aufgabe zuordnen", "plus") { nav.blatt = .aufgabeZuZiel(ziel.id) }
            case .habit:
                if let h = n.schritt.habitID { knopf("Habit öffnen", "repeat") { nav.oeffneHabit(h) } }
            }
        }
    }

    private func knopf(_ text: String, _ symbol: String, neben: Bool = false, _ aktion: @escaping () -> Void) -> some View {
        Button(action: aktion) {
            Label(text, systemImage: symbol).font(.kompass(.subheadline, .bold)).padding(.horizontal, 16).frame(minHeight: 44)
                .background(neben ? Farbe.akzentWeich : Farbe.akzent, in: Capsule())
                .foregroundStyle(neben ? Farbe.akzent : .white)
        }
        .buttonStyle(.plain)
    }
}

// MARK: Verfeinern – alles Weitere auf eigenen Seiten

/// Teile der Ziel-Seite, die nur bei Bedarf geöffnet werden.
enum ZielTeil: String, Hashable, CaseIterable {
    case aufgaben, habits, termine, einsatz, details

    var titel: String {
        switch self {
        case .aufgaben: "Aufgaben"
        case .habits: "Habits"
        case .termine: "Termine"
        case .einsatz: "Einsatz"
        case .details: "Details"
        }
    }
    var symbol: String {
        switch self {
        case .aufgaben: "checklist"
        case .habits: "repeat"
        case .termine: "calendar"
        case .einsatz: "clock"
        case .details: "slider.horizontal.3"
        }
    }
    /// Ein Satz: was hier passiert und warum
    var erklaerung: String {
        switch self {
        case .aufgaben: "Aufgaben mit diesem Ziel fallen in den nächsten offenen Meilenstein. Ohne passenden Meilenstein zählen sie als Einsatz."
        case .habits: "Ein Habit zählt in die Prozente, wenn ein Meilenstein ihn misst – sonst als Einsatz."
        case .termine: "Termin-Serien aus dem Kalender: jeder stattgefundene Termin zählt in einen Zahl- oder Zeit-Meilenstein oder als Einsatz."
        case .einsatz: "Fokuszeit und Termine für dieses Ziel. Einsatz zeigt, was du investierst – die Prozente ändert er nicht."
        case .details: "Titel, Frist, Bereich, Warum und Aussehen. Hier markierst du das Ziel auch als erreicht oder löschst es."
        }
    }
}

/// Für NavigationLink(value:) auf einen Teil eines Ziels
struct ZielTeilAuswahl: Hashable { var id: UUID; var teil: ZielTeil }

private struct Verfeinern: View {
    var ziel: Ziel
    @Environment(Speicher.self) private var speicher

    var body: some View {
        AbschnittKopf(titel: "Verfeinern") { Text("optional").foregroundStyle(Farbe.zweitrangig) }
        GruppierteListe {
            ForEach(ZielTeil.allCases, id: \.self) { t in
                NavigationLink(value: ZielTeilAuswahl(id: ziel.id, teil: t)) {
                    HStack(spacing: 12) {
                        Image(systemName: t.symbol).font(.body.weight(.semibold)).foregroundStyle(Color(hex: ziel.farbe)).frame(width: 32)
                        Text(t.titel).font(.zeile).foregroundStyle(Farbe.text)
                        Spacer(minLength: 8)
                        Text(wert(t)).font(.unterzeile).foregroundStyle(Farbe.zweitrangig).lineLimit(1)
                        Image(systemName: "chevron.right").font(.footnote.weight(.bold)).foregroundStyle(Farbe.pfeil)
                    }
                    .padding(.horizontal, 14).frame(minHeight: Mass.zeileKompakt).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(t.titel), \(wert(t))")
            }
        }
    }

    private func wert(_ t: ZielTeil) -> String {
        let z = speicher.zustand, T = speicher.heute
        switch t {
        case .aufgaben:
            let offen = z.aufgaben.filter { $0.zielID == ziel.id && !$0.erledigt }.count
            return offen == 0 ? "keine offen" : "\(offen) offen"
        case .habits:
            let n = z.habits.filter { h in h.zielID == ziel.id || ziel.schritte.contains { $0.habitID == h.id } }.count
            return n == 0 ? "keine" : "\(n)"
        case .termine:
            let n = z.termine.filter { $0.zielID == ziel.id }.count
            return n == 0 ? "keine" : "\(n) Serie\(n == 1 ? "" : "n")"
        case .einsatz: return "\(Zahl.dauer(Fortschritt.zeit(ziel: ziel.id, in: z, von: T.montag, bis: T))) diese Woche"
        case .details: return ziel.faellig.datum().formatted(.dateTime.day().month(.abbreviated).year().locale(Locale(identifier: "de_DE")))
        }
    }
}

/// Eine Unterseite des Ziels: Satz oben (was und warum), dann genau ein Teil.
struct ZielTeilSeite: View {
    var id: UUID
    var teil: ZielTeil
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav
    @Environment(\.dismiss) private var dismiss
    @State private var loeschenFragen = false

    var body: some View {
        if let g = speicher.zustand.ziel(id) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: teil.symbol).font(.body.weight(.semibold)).foregroundStyle(Color(hex: g.farbe))
                            .frame(width: 36, height: 36).background(Color(hex: g.farbe).opacity(0.14), in: Circle())
                        Text(teil.erklaerung).font(.unterzeile).foregroundStyle(Farbe.zweitrangig).fixedSize(horizontal: false, vertical: true)
                    }
                    switch teil {
                    case .aufgaben: ZielAufgaben(ziel: g)
                    case .habits: ZielHabits(ziel: g)
                    case .termine: ZielTermine(ziel: g)
                    case .einsatz: ZielEinsatz(ziel: g)
                    case .details: details(g)
                    }
                }
                .padding(Mass.rand).padding(.bottom, 24)
                .frame(maxWidth: 720).frame(maxWidth: .infinity)
            }
            .background(Farbe.grund.ignoresSafeArea())
            .navigationTitle(teil.titel)
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("Ziel wirklich löschen?", isPresented: $loeschenFragen, titleVisibility: .visible) {
                Button("Löschen", role: .destructive) {
                    let zid = g.id
                    nav.fortschrittPfad = NavigationPath()
                    speicher.aendern { $0.zielLoeschen(zid) }
                }
            } message: { Text("Aufgaben, Habits und Termine bleiben erhalten.") }
        } else {
            ContentUnavailableView("Ziel nicht gefunden", systemImage: "target")
        }
    }

    @ViewBuilder private func details(_ g: Ziel) -> some View {
        AbschnittKopf(titel: "Fakten")
        GruppierteListe {
            FaktZeile("Titel", wert: g.titel) { nav.blatt = .zielBearbeiten(g.id, .titel) }
            FaktZeile("Bis wann", wert: g.faellig.datum().formatted(.dateTime.day().month(.wide).year().locale(Locale(identifier: "de_DE")))) { nav.blatt = .zielBearbeiten(g.id, .faellig) }
            FaktZeile("Bereich", wert: g.bereich) { nav.blatt = .zielBearbeiten(g.id, .bereich) }
            FaktZeile("Warum", wert: g.warum.isEmpty ? "–" : g.warum) { nav.blatt = .zielBearbeiten(g.id, .warum) }
            FaktZeile(titel: "Aussehen", wert: {
                HStack(spacing: 8) {
                    Image(systemName: g.symbol).font(.footnote.weight(.semibold)).foregroundStyle(Color(hex: g.farbe))
                    Circle().fill(Color(hex: g.farbe)).frame(width: 16, height: 16)
                }
            }) { nav.blatt = .zielBearbeiten(g.id, .aussehen) }
        }
        Button(g.status == .erreicht ? "Wieder aktiv setzen" : "Als erreicht markieren") {
            let zid = g.id, neu: ZielStatus = g.status == .erreicht ? .aktiv : .erreicht
            speicher.aendern { s in if let i = s.ziele.firstIndex(where: { $0.id == zid }) { s.ziele[i].status = neu } }
        }
        .font(.zeile).frame(maxWidth: .infinity, minHeight: 50)
        .background(Farbe.karte, in: RoundedRectangle(cornerRadius: Mass.karte, style: .continuous))
        .padding(.top, Mass.abschnitt)
        Button("Ziel löschen", role: .destructive) { loeschenFragen = true }
            .font(.zeile).frame(maxWidth: .infinity, minHeight: 50)
            .background(Farbe.karte, in: RoundedRectangle(cornerRadius: Mass.karte, style: .continuous))
            .padding(.top, 12)
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
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(schritt.titel).font(.zeile).foregroundStyle(Farbe.text).lineLimit(2)
                        Text(unterzeile(st)).font(.unterzeile).foregroundStyle(st.hinweis == nil ? Farbe.zweitrangig : Farbe.warnung).lineLimit(1)
                    }
                    Spacer(minLength: 8)
                    Text(Zahl.prozent(st.anteil)).font(.kompass(.subheadline, .bold)).foregroundStyle(st.anteil >= 1 ? Farbe.freude : Farbe.zweitrangig).monospacedDigit()
                    Image(systemName: "chevron.right").font(.footnote.weight(.bold)).foregroundStyle(Farbe.pfeil)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Bearbeiten")
            .padding(.trailing, 16)
        }
        .frame(minHeight: Mass.zeile)
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
        var teile = [st.text]
        let erreicht = Fortschritt.erreichteSchwellen(schritt, in: speicher.zustand, heute: speicher.heute).count
        if let n = schritt.schwellen?.count, n > 0 { teile.append("\(erreicht) von \(n) Zwischenständen") }
        if st.gewicht > 1 { teile.append(st.gewicht == 3 ? "zählt dreifach" : "zählt doppelt") }
        return teile.joined(separator: " · ")
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
                    Haken(an: h.voll(am: T), farbe: Color(hex: h.farbe), beschriftung: h.titel) {
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
                .onTapGesture { nav.oeffneHabit(h.id) }
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
