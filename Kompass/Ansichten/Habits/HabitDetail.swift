import SwiftUI

/// Ein Habit als Seite – minimal und geführt wie ein Ziel: oben der Stand von heute mit genau einer Handlung
/// (Analyse im Rückblick), darunter die wichtigsten Einstellungen als Kacheln (Wann · Wie viel · Erinnerung · Verfeinern),
/// darunter, wofür der Habit zählt. Alles Weitere unter „Verfeinern“.
struct HabitDetail: View {
    var id: UUID
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav

    var body: some View {
        let z = speicher.zustand
        if let h = z.habit(id) {
            let c = Color(hex: h.farbe)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HabitStandKarte(habit: h)

                    AbschnittKopf(titel: "Einstellungen")
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        Button { nav.blatt = .habitBearbeiten(h.id, .rhythmus) } label: {
                            EinstellKachelInhalt(symbol: "calendar", titel: "Wann", wert: HabitRechnung.haeufigkeit(h),
                                                 unter: h.uhrzeit.map { "um \(Tagesplan.uhr($0))" } ?? "ohne feste Uhrzeit", farbe: c)
                        }
                        .buttonStyle(DruckStil())
                        Button { nav.blatt = .habitBearbeiten(h.id, .menge) } label: {
                            EinstellKachelInhalt(symbol: "gauge.with.dots.needle.33percent", titel: "Wie viel", wert: mengeText(h), unter: nil, farbe: c)
                        }
                        .buttonStyle(DruckStil())
                        Button { nav.blatt = .habitBearbeiten(h.id, .erinnerung) } label: {
                            EinstellKachelInhalt(symbol: "bell.fill", titel: "Erinnerung", wert: erinnerungText(h), unter: nil, farbe: c,
                                                 hinweis: h.erinnerung == nil)
                        }
                        .buttonStyle(DruckStil())
                        NavigationLink(value: HabitTeilAuswahl(id: h.id, teil: .verfeinern)) {
                            EinstellKachelInhalt(symbol: "slider.horizontal.3", titel: "Verfeinern", wert: "Name, Ziel, Kalender …", unter: "Tage nachtragen", farbe: c, hervor: true)
                        }
                        .buttonStyle(DruckStil())
                        .accessibilityIdentifier("habit.verfeinern")
                    }

                    ZaehltIn(habit: h)
                }
                .padding(Mass.rand)
                .padding(.bottom, 24)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .background(Farbe.grund.ignoresSafeArea())
            .navigationTitle(h.titel)
            .navigationBarTitleDisplayMode(.inline)
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

/// Stand von heute in Habit-Farbe: Ring (Anteil heute) mit Symbol, große Aussage, Serie, eine Handlung, Analyse im Rückblick.
private struct HabitStandKarte: View {
    var habit: Habit
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav

    var body: some View {
        let T = speicher.heute
        let geplant = HabitRechnung.geplant(habit, am: T)
        let voll = habit.voll(am: T)
        let anteil = habit.anteil(am: T)
        let serie = HabitRechnung.serie(habit, heute: T)
        let wochen: Bool = { if case .proWoche = habit.rhythmus { return true } else { return false } }()
        Verlaufskarte(farben: Farbe.verlauf(habit.farbe)) {
            HStack(spacing: 16) {
                ZStack {
                    Circle().stroke(.white.opacity(0.25), lineWidth: 8)
                    if anteil > 0 { Circle().trim(from: 0, to: anteil).stroke(.white, style: StrokeStyle(lineWidth: 8, lineCap: .round)).rotationEffect(.degrees(-90)) }
                    Image(systemName: voll ? "checkmark" : habit.symbol).font(.system(size: 22, weight: .bold))
                }
                .frame(width: 78, height: 78)
                VStack(alignment: .leading, spacing: 3) {
                    Text(!geplant ? "Heute frei" : habit.menge != nil ? HabitRechnung.mengenText(habit, am: T) : (voll ? "Heute erledigt" : "Heute offen"))
                        .font(.kompass(.title2, .heavy)).contentTransition(.numericText()).fixedSize(horizontal: false, vertical: true)
                    Text(serie > 0 ? "Serie \(serie) \(wochen ? "Wochen" : "Tage")" : "Noch keine Serie").font(.unterzeile).opacity(0.92)
                }
                Spacer(minLength: 0)
            }
            HStack(spacing: 10) {
                if geplant {
                    Button {
                        if habit.menge != nil { nav.blatt = .habitMenge(habit.id, tag: T.text) }
                        else { let hid = habit.id; speicher.aendern { $0.habitUmschalten(hid, am: T) } }
                    } label: {
                        Label(habit.menge != nil ? "Menge eintragen" : (voll ? "Rückgängig" : "Abhaken"),
                              systemImage: habit.menge != nil ? "plus" : (voll ? "arrow.uturn.backward" : "checkmark"))
                            .font(.kompass(.subheadline, .bold)).foregroundStyle(Color(hex: habit.farbe))
                            .padding(.horizontal, 16).frame(minHeight: 40).background(.white, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
                Button { nav.bereich = .rueckblick } label: {
                    HStack(spacing: 6) { Text("Analyse"); Image(systemName: "arrow.right") }
                        .font(.kompass(.subheadline, .bold)).foregroundStyle(.white)
                        .padding(.horizontal, 14).frame(minHeight: 40).background(.white.opacity(0.2), in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Analyse im Rückblick")
            }
            .padding(.top, 12)
        }
        .accessibilityElement(children: .contain)
    }
}

/// Unterseiten eines Habits (Verfeinern).
enum HabitTeil: String, Hashable { case verfeinern, nachtragen }
struct HabitTeilAuswahl: Hashable { var id: UUID; var teil: HabitTeil }

/// Verfeinern: Kacheln für alles Weitere – Name, Aussehen, Im Kalender, Ziel, Tage nachtragen – und Löschen.
struct HabitTeilSeite: View {
    var id: UUID
    var teil: HabitTeil
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav
    @Environment(\.dismiss) private var dismiss
    @State private var loeschenFragen = false

    var body: some View {
        let z = speicher.zustand
        let T = speicher.heute
        if let h = z.habit(id) {
            let c = Color(hex: h.farbe)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 12) {
                        Image(systemName: teil == .verfeinern ? "slider.horizontal.3" : "calendar.badge.clock").font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
                            .frame(width: 40, height: 40).background(c.gradient, in: Circle())
                        Text(teil == .verfeinern ? "Alles Weitere zu deinem Habit – antippen zum Ändern." : "Vergessen abzuhaken? Tipp auf einen Tag, um ihn nachzutragen.")
                            .font(.unterzeile).foregroundStyle(Farbe.text.opacity(0.8)).fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                    .background(LinearGradient(colors: [Farbe.karte, c.opacity(0.14)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                in: RoundedRectangle(cornerRadius: 20, style: .continuous))

                    if teil == .verfeinern {
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                            kachel("textformat", "Name", h.titel, nil) { nav.blatt = .habitBearbeiten(h.id, .titel) }
                            kachel("paintpalette.fill", "Aussehen", "Symbol und Farbe", nil) { nav.blatt = .habitBearbeiten(h.id, .aussehen) }
                            kachel("clock", "Im Kalender", h.uhrzeit.map { "\(Tagesplan.uhr($0)) · \(h.dauerMinuten) Min" } ?? "ohne Uhrzeit", nil) { nav.blatt = .habitBearbeiten(h.id, .kalender) }
                            kachel("target", "Ziel", z.ziel(h.zielID)?.titel ?? "keins", z.ziel(h.zielID) == nil ? "zählt für kein Ziel" : nil) { nav.blatt = .habitBearbeiten(h.id, .ziel) }
                            NavigationLink(value: HabitTeilAuswahl(id: h.id, teil: .nachtragen)) {
                                EinstellKachelInhalt(symbol: "calendar.badge.clock", titel: "Tage nachtragen", wert: "letzte 14 Tage", unter: nil, farbe: c, verlauf: true)
                            }
                            .buttonStyle(DruckStil())
                        }
                        .padding(.top, 16)
                        Button(role: .destructive) { loeschenFragen = true } label: {
                            Label("Habit löschen", systemImage: "trash").font(.zeile).frame(maxWidth: .infinity, minHeight: 50)
                                .background(Farbe.karte, in: RoundedRectangle(cornerRadius: Mass.karte, style: .continuous))
                        }
                        .padding(.top, Mass.abschnitt)
                    } else {
                        AbschnittKopf(titel: "Letzte 14 Tage")
                        GruppierteListe {
                            ForEach(0..<14, id: \.self) { i in
                                let d = T.plus(tage: -i)
                                if d >= h.angelegt, HabitRechnung.geplant(h, am: d) || h.eintraege[d] != nil {
                                    VerlaufZeile(habit: h, tag: d, heute: T)
                                }
                            }
                        }
                    }
                }
                .padding(Mass.rand).padding(.bottom, 24)
                .frame(maxWidth: 720).frame(maxWidth: .infinity)
            }
            .background(Farbe.grund.ignoresSafeArea())
            .navigationTitle(teil == .verfeinern ? "Verfeinern" : "Tage nachtragen")
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("Habit wirklich löschen?", isPresented: $loeschenFragen, titleVisibility: .visible) {
                Button("Löschen", role: .destructive) {
                    let hid = h.id
                    nav.fortschrittPfad = NavigationPath()
                    speicher.aendern { $0.habitLoeschen(hid) }
                }
            } message: { Text("Einträge und Serie gehen verloren. Meilensteine bleiben und zeigen „Habit wählen“.") }
        } else {
            ContentUnavailableView("Habit nicht gefunden", systemImage: "questionmark")
        }
    }

    private func kachel(_ symbol: String, _ titel: String, _ wert: String, _ unter: String?, _ aktion: @escaping () -> Void) -> some View {
        Button(action: aktion) {
            EinstellKachelInhalt(symbol: symbol, titel: titel, wert: wert, unter: unter, farbe: Color(hex: speicher.zustand.habit(id)?.farbe ?? "#3B4CCA"), verlauf: true)
        }
        .buttonStyle(DruckStil())
    }
}

/// Ein Tag im Verlauf: Datum · Stand rechts · dünner Balken bei Mengen.
private struct VerlaufZeile: View {
    var habit: Habit
    var tag: Tag
    var heute: Tag
    @Environment(Navigation.self) private var nav
    @Environment(Speicher.self) private var speicher

    var body: some View {
        let voll = habit.voll(am: tag)
        let anteil = habit.anteil(am: tag)
        Button {
            if habit.menge != nil { nav.blatt = .habitMenge(habit.id, tag: tag.text) }
            else { let hid = habit.id, d = tag; speicher.aendern { $0.habitUmschalten(hid, am: d) } }
        } label: {
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
        .accessibilityHint(habit.menge == nil ? "Abhaken oder zurücknehmen" : "Menge nachtragen")
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
            AbschnittKopf(titel: "Zählt für")
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
