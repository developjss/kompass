import SwiftUI

/// Ein Habit als Seite (habits-v2.md §7, wie eine Gapless-Transaktion): Kopfkarte, Heute, Stand,
/// Fakten-Zeilen mit Pfeil (jede öffnet ihren Editor), letzte 14 Tage, „Zählt in“, Löschen.
struct HabitDetail: View {
    var id: UUID
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav
    @Environment(\.dismiss) private var dismiss
    @State private var loeschenFragen = false

    var body: some View {
        let z = speicher.zustand
        let T = speicher.heute
        if let h = z.habit(id) {
            let c = Color(hex: h.farbe)
            let wochen: Bool = { if case .proWoche = h.rhythmus { return true } else { return false } }()
            let serie = HabitRechnung.serie(h, heute: T)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Kopf(habit: h, serie: serie, wochen: wochen)

                    AbschnittKopf(titel: "Heute") { Text(HabitRechnung.geplant(h, am: T) ? "" : "nicht geplant").foregroundStyle(Farbe.zweitrangig) }
                    GruppierteListe {
                        HStack(spacing: 10) {
                            Haken(an: h.voll(am: T), farbe: c, beschriftung: h.titel) { speicher.aendern { $0.habitUmschalten(h.id, am: T) } }
                                .padding(.leading, 4)
                            Text(h.voll(am: T) ? "Erledigt" : "Abhaken").font(.zeile).foregroundStyle(Farbe.text)
                            Spacer()
                            Text(HabitRechnung.mengenText(h, am: T)).font(.unterzeile).foregroundStyle(h.voll(am: T) ? Farbe.freude : Farbe.zweitrangig).padding(.trailing, 16)
                        }
                        .frame(minHeight: Mass.zeileKompakt)
                        if h.menge != nil {
                            FaktZeile("Menge eintragen", wert: h.einheit?.name ?? "") { nav.blatt = .habitMenge(h.id, tag: T.text) }
                        }
                    }

                    AbschnittKopf(titel: "Stand")
                    HStack(spacing: 10) {
                        WertKachel(titel: "Serie", wert: "\(serie)", einheit: wochen ? "Wo." : "Tage")
                        WertKachel(titel: "Beste", wert: "\(HabitRechnung.besteSerie(h, heute: T))", einheit: wochen ? "Wo." : "Tage")
                        WertKachel(titel: "Quote", wert: Zahl.prozent(HabitRechnung.quote(h, heute: T)), einheit: "30 Tage")
                    }

                    AbschnittKopf(titel: "Fakten")
                    GruppierteListe {
                        FaktZeile("Titel", wert: h.titel) { nav.blatt = .habitBearbeiten(h.id, .titel) }
                        FaktZeile("Menge", wert: mengeText(h)) { nav.blatt = .habitBearbeiten(h.id, .menge) }
                        FaktZeile("Rhythmus", wert: HabitRechnung.haeufigkeit(h)) { nav.blatt = .habitBearbeiten(h.id, .rhythmus) }
                        FaktZeile("Im Kalender", wert: h.uhrzeit.map { "\(Tagesplan.uhr($0)) · \(h.dauerMinuten) Min" } ?? "ohne Uhrzeit") { nav.blatt = .habitBearbeiten(h.id, .kalender) }
                        FaktZeile("Erinnerung", wert: erinnerungText(h)) { nav.blatt = .habitBearbeiten(h.id, .erinnerung) }
                        FaktZeile("Ziel", wert: z.ziel(h.zielID)?.titel ?? "keins") { nav.blatt = .habitBearbeiten(h.id, .ziel) }
                        FaktZeile(titel: "Aussehen", wert: {
                            HStack(spacing: 8) {
                                Image(systemName: h.symbol).font(.footnote.weight(.semibold)).foregroundStyle(c)
                                Circle().fill(c).frame(width: 16, height: 16)
                            }
                        }) { nav.blatt = .habitBearbeiten(h.id, .aussehen) }
                    }

                    AbschnittKopf(titel: "Letzte 14 Tage")
                    GruppierteListe {
                        ForEach(0..<14, id: \.self) { i in
                            let d = T.plus(tage: -i)
                            if d >= h.angelegt, HabitRechnung.geplant(h, am: d) || h.eintraege[d] != nil {
                                VerlaufZeile(habit: h, tag: d, heute: T)
                            }
                        }
                    }

                    ZaehltIn(habit: h)

                    Button("Habit löschen", role: .destructive) { loeschenFragen = true }
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
            .navigationTitle(h.titel)
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("Habit wirklich löschen?", isPresented: $loeschenFragen, titleVisibility: .visible) {
                Button("Löschen", role: .destructive) {
                    let hid = h.id
                    speicher.aendern { $0.habitLoeschen(hid) }
                    dismiss()
                }
            } message: { Text("Einträge und Serie gehen verloren. Meilensteine bleiben und zeigen „Habit wählen“.") }
        } else {
            ContentUnavailableView("Habit nicht gefunden", systemImage: "questionmark", description: Text("Er wurde vielleicht gelöscht."))
        }
    }

    private func mengeText(_ h: Habit) -> String {
        guard let m = h.menge else { return "nur abhaken" }
        let je: String = { if case .proWoche = h.rhythmus { return "je Mal" } else { return "pro Tag" } }()
        return "\(Zahl.text(m, stellen: 1)) \(h.einheit?.name ?? "") \(je)"
    }

    private func erinnerungText(_ h: Habit) -> String {
        guard let e = h.erinnerung else { return "aus" }
        return Erinnerungen.aktiv.status == .abgelehnt ? "\(Beispieltermine.uhrzeit(e)) · Mitteilungen aus" : Beispieltermine.uhrzeit(e)
    }
}

/// Kopfkarte in Habit-Farbe: Soll, Stand heute, Serie; rechts das Symbol.
private struct Kopf: View {
    var habit: Habit
    var serie: Int
    var wochen: Bool
    @Environment(Speicher.self) private var speicher

    var body: some View {
        let T = speicher.heute
        let voll = habit.voll(am: T)
        Verlaufskarte(farben: Farbe.verlauf(habit.farbe)) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    KartenLabel(text: HabitRechnung.sollText(habit))
                    Text(heuteText(T, voll: voll)).font(.kompass(.title, .heavy)).contentTransition(.numericText())
                    Text(serie > 0 ? "Serie \(serie) \(wochen ? "Wochen" : "Tage")" : "Noch keine Serie").font(.unterzeile).opacity(0.9)
                }
                Spacer(minLength: 8)
                Image(systemName: habit.symbol).font(.system(size: 26, weight: .semibold))
                    .frame(width: 56, height: 56).background(.white.opacity(0.2), in: Circle())
            }
            if habit.menge != nil { Balken(anteil: habit.anteil(am: T)).padding(.top, 8) }
        }
        .accessibilityElement(children: .combine)
    }

    private func heuteText(_ T: Tag, voll: Bool) -> String {
        if !HabitRechnung.geplant(habit, am: T) { return "Heute frei" }
        if habit.menge != nil { return HabitRechnung.mengenText(habit, am: T) }
        return voll ? "Heute erledigt" : "Heute offen"
    }
}

/// Ein Tag im Verlauf: Datum · Stand rechts · dünner Balken bei Mengen.
private struct VerlaufZeile: View {
    var habit: Habit
    var tag: Tag
    var heute: Tag
    @Environment(Navigation.self) private var nav

    var body: some View {
        let voll = habit.voll(am: tag)
        let anteil = habit.anteil(am: tag)
        Button { if habit.menge != nil { nav.blatt = .habitMenge(habit.id, tag: tag.text) } } label: {
            HStack(spacing: 12) {
                Circle().fill(voll ? Color(hex: habit.farbe) : (anteil > 0 ? Color(hex: habit.farbe).opacity(0.4) : Farbe.linie)).frame(width: 10, height: 10)
                VStack(alignment: .leading, spacing: 3) {
                    Text(tag == heute ? "Heute" : tag == heute.plus(tage: -1) ? "Gestern" : tag.datum().formatted(.dateTime.weekday(.wide).day().month(.abbreviated).locale(Locale(identifier: "de_DE"))))
                        .font(.zeile).foregroundStyle(Farbe.text)
                    if habit.menge != nil, anteil > 0, !voll {
                        Balken(anteil: anteil, farbe: Color(hex: habit.farbe), spur: Farbe.linie, hoehe: 3).padding(.trailing, 60)
                    }
                }
                Spacer()
                Text(HabitRechnung.mengenText(habit, am: tag)).font(.unterzeile).foregroundStyle(voll ? Farbe.freude : Farbe.zweitrangig).monospacedDigit()
            }
            .padding(.horizontal, 16)
            .frame(minHeight: Mass.zeileKompakt)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(habit.menge == nil)
        .accessibilityHint(habit.menge == nil ? "" : "Menge nachtragen")
    }
}

/// Meilensteine, in denen dieser Habit zählt – Tipp öffnet das Ziel.
private struct ZaehltIn: View {
    var habit: Habit
    @Environment(Speicher.self) private var speicher

    var body: some View {
        let z = speicher.zustand
        let treffer = z.ziele.flatMap { g in g.schritte.filter { $0.art == .habit && $0.habitID == habit.id }.map { (g, $0) } }
        let einsatz = z.ziel(habit.zielID).map { g in treffer.contains { $0.0.id == g.id } ? nil : g } ?? nil
        if !treffer.isEmpty || einsatz != nil {
            AbschnittKopf(titel: "Zählt in")
            GruppierteListe {
                ForEach(treffer, id: \.1.id) { g, s in
                    NavigationLink(value: ZielAuswahl(id: g.id)) {
                        HStack(spacing: 12) {
                            SymbolKachel(symbol: g.symbol, farbe: Color(hex: g.farbe))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(g.titel).font(.zeile).foregroundStyle(Farbe.text).lineLimit(1)
                                Text("Meilenstein „\(s.titel)“ · \(Fortschritt.stand(s, in: z, heute: speicher.heute).text)").font(.unterzeile).foregroundStyle(Farbe.zweitrangig).lineLimit(1)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.footnote.weight(.bold)).foregroundStyle(Farbe.pfeil)
                        }
                        .padding(.horizontal, 12).frame(minHeight: Mass.zeile).contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                if let g = einsatz {
                    NavigationLink(value: ZielAuswahl(id: g.id)) {
                        HStack(spacing: 12) {
                            SymbolKachel(symbol: g.symbol, farbe: Color(hex: g.farbe))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(g.titel).font(.zeile).foregroundStyle(Farbe.text).lineLimit(1)
                                Text("nur Einsatz – ändert die Prozente nicht").font(.unterzeile).foregroundStyle(Farbe.zweitrangig)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.footnote.weight(.bold)).foregroundStyle(Farbe.pfeil)
                        }
                        .padding(.horizontal, 12).frame(minHeight: Mass.zeile).contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: Eine Zeile bearbeiten

/// Editor für genau eine Zeile der Habit-Seite (Titel, Menge, Rhythmus, Erinnerung, Ziel, Aussehen).
struct HabitFeldBlatt: View {
    var habitID: UUID
    var feld: HabitFeld
    @Environment(Speicher.self) private var speicher
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var h: Habit?
    @State private var rhythmusArt: NeuBlatt.RhythmusArt = .taeglich
    @State private var tage: Set<Int> = [1, 2, 3, 4, 5]
    @State private var proWoche = 3
    @State private var mitMenge = false
    @State private var menge: Double = 20
    @State private var einheit: Einheit = .minuten

    private let namen = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]
    private let symbole = ["book.fill", "graduationcap.fill", "figure.run", "figure.walk", "dumbbell.fill", "bicycle", "figure.yoga", "drop.fill",
                           "fork.knife", "bed.double.fill", "leaf.fill", "music.note", "pencil", "hand.raised.fill", "moon.fill", "star.fill", "heart.fill", "checkmark.seal.fill"]

    var body: some View {
        NavigationStack {
            Form {
                if h != nil {
                    switch feld {
                    case .titel: titelTeil
                    case .menge: mengeTeil
                    case .rhythmus: rhythmusTeil
                    case .kalender: kalenderTeil
                    case .erinnerung: erinnerungTeil
                    case .ziel: zielTeil
                    case .aussehen: aussehenTeil
                    }
                }
            }
            .navigationTitle(titel)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Sichern", action: sichern).disabled(!gueltig) }
            }
            .onAppear(perform: laden)
        }
        .presentationDetents([.medium, .large])
    }

    private var titel: String {
        switch feld {
        case .titel: "Titel"
        case .menge: "Menge"
        case .rhythmus: "Wie oft"
        case .kalender: "Im Kalender"
        case .erinnerung: "Erinnerung"
        case .ziel: "Ziel"
        case .aussehen: "Aussehen"
        }
    }

    private var gueltig: Bool {
        guard let h else { return false }
        switch feld {
        case .titel: return !h.titel.trimmingCharacters(in: .whitespaces).isEmpty
        case .menge: return !mitMenge || menge > 0
        case .rhythmus: return rhythmusArt != .tage || !tage.isEmpty
        default: return true
        }
    }

    // MARK: Teile

    private var titelTeil: some View {
        Section {
            TextField("Titel", text: Binding(get: { h?.titel ?? "" }, set: { h?.titel = $0 }))
        } footer: { Text("Serie und Einträge bleiben erhalten.") }
    }

    private var mengeTeil: some View {
        Section {
            Toggle("Mit Menge", isOn: $mitMenge)
            if mitMenge {
                LabeledContent("Soll pro Tag") {
                    TextField("20", value: $menge, format: .number.locale(Locale(identifier: "de_DE"))).multilineTextAlignment(.trailing).keyboardType(.decimalPad)
                }
                ChipReihe(titel: "Einheit", auswahl: Einheit.allCases.map { ($0.name, $0 == einheit) }) { einheit = Einheit.allCases[$0] }
            }
        } footer: {
            Text(mitMenge ? "Teilmengen zählen anteilig: 10 von 20 Minuten = halb. Alte Einträge werden am neuen Soll gemessen." : "Ohne Menge hakst du den Habit einfach ab.")
        }
    }

    private var rhythmusTeil: some View {
        Section {
            ChipReihe(titel: "Wie oft", auswahl: NeuBlatt.RhythmusArt.allCases.map { ($0.rawValue, $0 == rhythmusArt) }) { rhythmusArt = NeuBlatt.RhythmusArt.allCases[$0] }
            if rhythmusArt == .tage {
                HStack(spacing: 6) {
                    ForEach(1...7, id: \.self) { d in
                        Button(namen[d - 1]) { if tage.contains(d) { tage.remove(d) } else { tage.insert(d) } }
                            .buttonStyle(.bordered).tint(tage.contains(d) ? Farbe.akzent : .gray)
                            .accessibilityAddTraits(tage.contains(d) ? .isSelected : [])
                    }
                }
            }
            if rhythmusArt == .proWoche { Stepper("\(proWoche)× pro Woche", value: $proWoche, in: 1...7) }
        } footer: { Text("„n-mal pro Woche“: die Serie zählt erfüllte Wochen.") }
    }

    @ViewBuilder private var kalenderTeil: some View {
        let u = h?.uhrzeit
        Section {
            ChipReihe(titel: "Feste Uhrzeit", auswahl: [("keine", u == nil)] + [7, 12, 18, 21].map { ("\($0):00", u == $0 * 60) }) { i in
                h?.uhrzeit = i == 0 ? nil : [7, 12, 18, 21][i - 1] * 60
            }
            if u != nil {
                DatePicker("Uhrzeit", selection: Binding(get: { uhr(u ?? 0) }, set: { h?.uhrzeit = minuten($0) }), displayedComponents: .hourAndMinute)
                ChipReihe(titel: "Dauer", auswahl: [("aus Menge", h?.dauer == nil)] + [15, 30, 45, 60, 90].map { ("\($0) Min", h?.dauer == $0) }) { i in
                    h?.dauer = i == 0 ? nil : [15, 30, 45, 60, 90][i - 1]
                }
            }
        } footer: {
            Text(u == nil ? "Ohne Uhrzeit schlägt der Kalender ihn unter „Empfehlung“ vor – von dort ziehst du ihn in den Tag." : "Steht an jedem geplanten Tag als Block im Kalender und unter „Als Nächstes“.")
        }
    }

    @ViewBuilder private var erinnerungTeil: some View {
        let e = h?.erinnerung
        Section {
            ChipReihe(titel: "Uhrzeit", auswahl: [("aus", e == nil)] + [7, 12, 18, 21].map { ("\($0):00", e == $0 * 60) }) { i in
                h?.erinnerung = i == 0 ? nil : [7, 12, 18, 21][i - 1] * 60
            }
            if e != nil {
                DatePicker("Uhrzeit", selection: Binding(get: { uhr(e ?? 0) }, set: { h?.erinnerung = minuten($0) }), displayedComponents: .hourAndMinute)
            }
        } footer: {
            Text("Zur Uhrzeit kommt eine Mitteilung, solange der Habit an dem Tag offen ist.")
        }
        if Erinnerungen.aktiv.status == .abgelehnt {
            Section {
                Button("Mitteilungen in den Einstellungen erlauben") {
                    if let u = URL(string: UIApplication.openNotificationSettingsURLString) { openURL(u) }
                }
            } footer: { Text("Mitteilungen sind für Kompass ausgeschaltet. Die Uhrzeit wird trotzdem gespeichert.") }
        }
    }

    private var zielTeil: some View {
        Section {
            Picker("Ziel", selection: Binding(get: { h?.zielID }, set: { h?.zielID = $0 })) {
                Text("Keins").tag(UUID?.none)
                ForEach(speicher.zustand.ziele.filter { $0.status == .aktiv }) { Text($0.titel).tag(UUID?.some($0.id)) }
            }
            .pickerStyle(.inline).labelsHidden()
        } footer: { Text("Ob der Habit in die Prozente zählt, legst du im Ziel unter Meilensteine fest.") }
    }

    private var aussehenTeil: some View {
        Group {
            Section("Farbe") {
                FliessLayout(abstand: 8) {
                    ForEach(Farbe.ziele, id: \.self) { f in
                        Button { h?.farbe = f } label: {
                            Circle().fill(Color(hex: f)).frame(width: 30, height: 30)
                                .overlay(Circle().strokeBorder(.white, lineWidth: h?.farbe == f ? 3 : 0))
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Farbe \(f)")
                        .accessibilityAddTraits(h?.farbe == f ? .isSelected : [])
                    }
                }
            }
            Section("Symbol") {
                FliessLayout(abstand: 8) {
                    ForEach(symbole, id: \.self) { s in
                        let an = h?.symbol == s
                        Button { h?.symbol = s } label: {
                            Image(systemName: s).font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(an ? .white : Color(hex: h?.farbe ?? "#3B4CCA"))
                                .frame(width: 44, height: 44)
                                .background(an ? Color(hex: h?.farbe ?? "#3B4CCA") : Color(hex: h?.farbe ?? "#3B4CCA").opacity(0.14), in: Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(s)
                        .accessibilityAddTraits(an ? .isSelected : [])
                    }
                }
            }
        }
    }

    // MARK: Laden und Sichern

    private func laden() {
        guard h == nil, let x = speicher.zustand.habit(habitID) else { return }
        h = x
        mitMenge = x.menge != nil
        menge = x.menge ?? HabitVorschlag.fuer(x.titel).menge ?? 20
        einheit = x.einheit ?? HabitVorschlag.fuer(x.titel).einheit ?? .minuten
        switch x.rhythmus {
        case .taeglich: rhythmusArt = .taeglich
        case .wochentage(let t): rhythmusArt = t == [1, 2, 3, 4, 5] ? .werktags : .tage; tage = t
        case .proWoche(let n): rhythmusArt = .proWoche; proWoche = n
        }
    }

    private func sichern() {
        guard var neu = h else { return }
        switch feld {
        case .menge:
            neu.menge = mitMenge ? menge : nil
            neu.einheit = mitMenge ? einheit : nil
        case .rhythmus:
            switch rhythmusArt {
            case .taeglich: neu.rhythmus = .taeglich
            case .werktags: neu.rhythmus = .wochentage([1, 2, 3, 4, 5])
            case .tage: neu.rhythmus = .aus(tagen: tage)
            case .proWoche: neu.rhythmus = .proWoche(proWoche)
            }
        default: break
        }
        neu.titel = neu.titel.trimmingCharacters(in: .whitespaces)
        let fertig = neu
        if feld == .erinnerung, fertig.erinnerung != nil {
            Task { await Erinnerungen.aktiv.erlaubnis(); speicher.aendern { $0.habitSpeichern(fertig) } }
        } else {
            speicher.aendern { $0.habitSpeichern(fertig) }
        }
        dismiss()
    }

    private func uhr(_ m: Int) -> Date { Calendar.kompass.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: m / 60, minute: m % 60)) ?? Date() }
    private func minuten(_ d: Date) -> Int { let k = Calendar.kompass.dateComponents([.hour, .minute], from: d); return (k.hour ?? 0) * 60 + (k.minute ?? 0) }
}
