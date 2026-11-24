import SwiftUI

// Meilensteine geführt: antippen → ruhige Übersicht mit genau einer Hauptaktion und „Anpassen“-Kacheln;
// neu anlegen → Fragen Schritt für Schritt (Name · Woran merkst du es · Wert · Wie wichtig · Passt das so?).
// Rechnen tut nur `Fortschritt` (Anteil = Gewicht ÷ Σ Gewicht, rechenregeln.md §1). Der Nutzer wird gefragt, nicht ausgefragt.

private let de = Locale(identifier: "de_DE")

/// Einstieg aus `Navigation.Blatt.meilenstein`: bestehend → Übersicht, neu → geführter Ablauf.
struct MeilensteinBlatt: View {
    var zielID: UUID
    var schrittID: UUID?
    @Environment(Speicher.self) private var speicher

    var body: some View {
        if let sid = schrittID, speicher.zustand.schritt(sid, in: zielID) != nil {
            MeilensteinUebersicht(zielID: zielID, schrittID: sid)
        } else {
            MeilensteinAssistent(zielID: zielID, vorhanden: nil, nur: nil)
        }
    }
}

// MARK: Übersicht eines Meilensteins

private struct MeilensteinUebersicht: View {
    var zielID: UUID
    var schrittID: UUID
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav
    @Environment(\.dismiss) private var dismiss
    @State private var bearbeiten: MeilensteinAssistent.Frage?
    @State private var loeschenFragen = false
    @State private var neuerStand: Double?

    var body: some View {
        let z = speicher.zustand
        let T = speicher.heute
        if let g = z.ziel(zielID), let s = z.schritt(schrittID, in: zielID) {
            let st = Fortschritt.stand(s, in: z, heute: T)
            let c = Color(hex: g.farbe)
            let anteil = Fortschritt.anteilVorschau(g, gewicht: Fortschritt.gewicht(s), ersetzt: s.id)
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Stand: Ring, Titel, wie gemessen, Anteil am Ziel
                        HStack(spacing: 16) {
                            ZStack {
                                Circle().stroke(.white.opacity(0.25), lineWidth: 7)
                                Circle().trim(from: 0, to: max(0.001, st.anteil)).stroke(.white, style: StrokeStyle(lineWidth: 7, lineCap: .round)).rotationEffect(.degrees(-90))
                                Text(Zahl.prozent(st.anteil)).font(.kompass(.subheadline, .heavy)).monospacedDigit().minimumScaleFactor(0.7)
                            }
                            .frame(width: 72, height: 72)
                            VStack(alignment: .leading, spacing: 4) {
                                Label(s.art.frageKurz, systemImage: s.art.symbol).font(.klein).opacity(0.9)
                                Text(s.titel).font(.kompass(.title3, .heavy)).fixedSize(horizontal: false, vertical: true)
                                Text(st.text).font(.unterzeile).opacity(0.9)
                            }
                        }
                        .foregroundStyle(.white)
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(LinearGradient(colors: Farbe.verlauf(g.farbe), startPoint: .bottomTrailing, endPoint: .topLeading),
                                    in: RoundedRectangle(cornerRadius: Mass.verlaufskarte, style: .continuous))
                        .accessibilityElement(children: .combine)

                        Text(AntwortText.inline("Macht **\(Zahl.prozent(anteil))** von „\(g.titel)“ aus."))
                            .font(.unterzeile).foregroundStyle(Farbe.zweitrangig)

                        hauptaktion(g: g, s: s, st: st, c: c)

                        Text("Anpassen").font(.abschnitt).foregroundStyle(Farbe.text).padding(.top, 8).accessibilityAddTraits(.isHeader)
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                            AnpassKachel(symbol: "textformat", titel: "Name", wert: s.titel, farbe: c) { bearbeiten = .titel }
                            AnpassKachel(symbol: s.art.symbol, titel: "Woran merkst du es?", wert: s.art.frageKurz, farbe: c) { bearbeiten = .art }
                            if s.art != .aufgaben {
                                AnpassKachel(symbol: "target", titel: "Ziel-Wert", wert: zielWertText(s), farbe: c) { bearbeiten = .wert }
                            }
                            AnpassKachel(symbol: "scalemass", titel: "Wie wichtig?", wert: "\(MeilensteinAssistent.wichtigName(s.gewicht)) · \(Zahl.prozent(anteil))", farbe: c) { bearbeiten = .wichtig }
                        }

                        Button(role: .destructive) { loeschenFragen = true } label: {
                            Label("Meilenstein löschen", systemImage: "trash").font(.zeile).frame(maxWidth: .infinity, minHeight: 50)
                                .background(Farbe.karte, in: RoundedRectangle(cornerRadius: Mass.karte, style: .continuous))
                        }
                        .padding(.top, 8)
                    }
                    .padding(Mass.rand).padding(.bottom, 24)
                    .frame(maxWidth: 720).frame(maxWidth: .infinity)
                }
                .background(Farbe.grund.ignoresSafeArea())
                .navigationTitle("Meilenstein")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Fertig") { dismiss() } } }
                .sheet(item: $bearbeiten) { f in MeilensteinAssistent(zielID: zielID, vorhanden: s, nur: f) }
                .confirmationDialog(loeschenText(g, s), isPresented: $loeschenFragen, titleVisibility: .visible) {
                    Button("Löschen", role: .destructive) {
                        let zid = zielID, sid = schrittID
                        dismiss()
                        speicher.aendern { $0.schrittLoeschen(ziel: zid, schritt: sid) }
                    }
                }
            }
        }
    }

    /// Was beim Löschen mit den Anteilen passiert – Kompass verteilt neu.
    private func loeschenText(_ g: Ziel, _ s: Schritt) -> String {
        let rest = Fortschritt.anteileOhne(g, ohne: s.id)
        if rest.isEmpty { return "Löschen? Das Ziel hat dann keinen Meilenstein mehr und steht bei 0 %." }
        return "Löschen? Danach zählen: " + rest.map { "\($0.0.titel) \(Zahl.prozent($0.1))" }.joined(separator: " · ") + ". Aufgaben und Termine bleiben."
    }

    private func zielWertText(_ s: Schritt) -> String {
        switch s.art {
        case .aufgaben: return ""
        case .zahl: return "\(Zahl.text(s.start ?? 0)) → \(Zahl.text(s.soll ?? 0)) \(s.einheit ?? "")"
        case .zeit: return "\(Zahl.text(s.soll ?? 0)) Stunden"
        case .habit: return s.modus == .wochen ? "\(Zahl.text(s.soll ?? 0)) Wochen" : "\(Zahl.text(s.soll ?? 0))-mal"
        }
    }

    /// Genau eine Handlung je Messart – das, was den Meilenstein voranbringt.
    @ViewBuilder
    private func hauptaktion(g: Ziel, s: Schritt, st: Fortschritt.SchrittStand, c: Color) -> some View {
        let T = speicher.heute
        VStack(alignment: .leading, spacing: 12) {
            switch s.art {
            case .aufgaben:
                let liste = speicher.zustand.aufgaben.filter { $0.schrittID == s.id }
                Text(s.geschafft ? "Geschafft." : "Geschafft? Dann abhaken.").font(.kompass(.headline, .bold))
                gross(s.geschafft ? "Wieder öffnen" : "Abhaken", s.geschafft ? "arrow.uturn.backward" : "checkmark", voll: !s.geschafft) {
                    speicher.aendern { $0.schrittUmschalten(ziel: g.id, schritt: s.id, heute: T) }
                }
                if !liste.isEmpty || !s.geschafft {
                    Text("Teilaufgaben füllen ihn bis 90 %.").font(.klein).foregroundStyle(Farbe.zweitrangig)
                    ForEach(liste) { a in
                        Button { speicher.aendern { $0.umschalten(a.id, jetzt: speicher.jetzt()) } } label: {
                            Label(a.titel, systemImage: a.erledigt ? "checkmark.circle.fill" : "circle")
                                .font(.zeile).foregroundStyle(a.erledigt ? Farbe.zweitrangig : Farbe.text)
                                .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                    }
                    AufgabeHinzufuegen(platzhalter: "Teilaufgabe hinzufügen", datum: nil, prio: .hoch, zielID: g.id, schrittID: s.id)
                        .background(Farbe.grund, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            case .zahl:
                let ausTerminen = speicher.zustand.termine.filter { $0.schrittID == s.id }
                    .reduce(0) { n, l in n + l.vorkommen.filter { $0.tag >= l.seit && $0.tag <= T }.count }
                Text(ausTerminen > 0 ? "Selbst eingetragen" : "Wo stehst du gerade?").font(.kompass(.headline, .bold))
                HStack(spacing: 10) {
                    TextField("Stand", value: Binding(get: { neuerStand ?? s.aktuell ?? s.start ?? 0 }, set: { neuerStand = $0 }), format: .number.locale(de))
                        .font(.kompass(.title, .heavy)).keyboardType(.decimalPad).monospacedDigit()
                        .padding(.horizontal, 14).frame(minHeight: 56)
                        .background(Farbe.grund, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    if let e = s.einheit, !e.isEmpty { Text(e).font(.kompass(.title3, .bold)).foregroundStyle(Farbe.zweitrangig) }
                }
                if ausTerminen > 0 {
                    Label("Dazu zählen \(ausTerminen) Termine aus dem Kalender automatisch.", systemImage: "calendar.badge.checkmark")
                        .font(.klein).foregroundStyle(Farbe.zweitrangig)
                }
                Text("Ziel: \(Zahl.text(s.soll ?? 0)) \(s.einheit ?? "") · Start: \(Zahl.text(s.start ?? 0))").font(.klein).foregroundStyle(Farbe.zweitrangig)
                gross("Eintragen", "checkmark", voll: true) {
                    guard let w = neuerStand else { return }
                    speicher.aendern { $0.zahlEintragen(w, ziel: g.id, schritt: s.id, heute: T) }
                    neuerStand = nil
                }
                .disabled(neuerStand == nil)
                .opacity(neuerStand == nil ? 0.5 : 1)
            case .zeit:
                Text("Zeit sammelst du mit dem Fokus-Timer.").font(.kompass(.headline, .bold))
                Text("Starte Fokus bei einer Aufgabe dieses Ziels – jede Minute zählt hier. Zugeordnete Termine zählen auch.").font(.unterzeile).foregroundStyle(Farbe.zweitrangig)
                gross("Aufgabe dafür wählen", "plus", voll: true) { dismiss(); nav.blatt = .aufgabeZuZiel(g.id) }
            case .habit:
                let h = speicher.zustand.habit(s.habitID)
                Text(h.map { "Über „\($0.titel)“" } ?? "Kein Habit gewählt").font(.kompass(.headline, .bold))
                Text("Jedes Abhaken des Habits zählt hier – du musst nichts eintragen.").font(.unterzeile).foregroundStyle(Farbe.zweitrangig)
                if let h { gross("Habit öffnen", "repeat", voll: true) { dismiss(); nav.oeffneHabit(h.id) } }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Farbe.karte, in: RoundedRectangle(cornerRadius: Mass.karte, style: .continuous))
    }

    private func gross(_ text: String, _ symbol: String, voll: Bool, _ aktion: @escaping () -> Void) -> some View {
        Button(action: aktion) {
            Label(text, systemImage: symbol).font(.kompass(.headline, .bold))
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(voll ? Farbe.akzent : Farbe.akzentWeich, in: Capsule())
                .foregroundStyle(voll ? .white : Farbe.akzent)
        }
        .buttonStyle(.plain)
    }
}

/// Weiße Kachel mit Symbol-Kreis, Frage und aktuellem Wert – antippen öffnet genau diese Frage.
private struct AnpassKachel: View {
    var symbol: String
    var titel: String
    var wert: String
    var farbe: Color
    var aktion: () -> Void

    var body: some View {
        Button(action: aktion) {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: symbol).font(.system(size: 15, weight: .bold)).foregroundStyle(.white)
                    .frame(width: 34, height: 34).background(farbe.gradient, in: Circle())
                Spacer(minLength: 4)
                Text(titel).font(.kompass(.subheadline, .bold)).foregroundStyle(Farbe.text).lineLimit(2).fixedSize(horizontal: false, vertical: true)
                Text(wert).font(.klein).foregroundStyle(Farbe.zweitrangig).lineLimit(1)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
            .background(Farbe.karte, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Ändern")
    }
}

// MARK: Geführter Ablauf (neu oder eine einzelne Frage)

struct MeilensteinAssistent: View {
    enum Frage: String, Identifiable, CaseIterable { case titel, art, wert, wichtig, fertig; var id: String { rawValue } }

    var zielID: UUID
    /// gesetzt = bestehender Meilenstein wird geändert
    var vorhanden: Schritt?
    /// gesetzt = nur diese eine Frage, dann sichern
    var nur: Frage?

    @Environment(Speicher.self) private var speicher
    @Environment(\.dismiss) private var dismiss
    @State private var e = Schritt(titel: "")
    @State private var frage: Frage = .titel
    @State private var geladen = false
    @State private var neuerHabit = false
    @State private var habitTitel = ""
    @State private var schwellenText = ""
    @FocusState private var fokus: Bool

    static func wichtigName(_ g: Int) -> String { g == 3 ? "Groß" : g == 2 ? "Mittel" : "Klein" }

    private var ablauf: [Frage] { e.art == .aufgaben ? [.titel, .art, .wichtig, .fertig] : Frage.allCases }
    private var position: Int { ablauf.firstIndex(of: frage) ?? 0 }

    var body: some View {
        let g = speicher.zustand.ziel(zielID)
        VStack(spacing: 0) {
            kopf
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(ueberschrift).font(.kompass(.title, .heavy)).foregroundStyle(Farbe.text).fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    if let u = unterzeile { Text(u).font(.unterzeile).foregroundStyle(Farbe.zweitrangig).fixedSize(horizontal: false, vertical: true) }
                    if let g { inhalt(g) }
                }
                .padding(.horizontal, Mass.rand).padding(.top, 8).padding(.bottom, 24)
                .frame(maxWidth: 720).frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollDismissesKeyboard(.interactively)
            fuss
        }
        .background(Farbe.grund.ignoresSafeArea())
        .presentationDragIndicator(.visible)
        .onAppear(perform: laden)
    }

    // MARK: Kopf, Fuß, Texte

    private var kopf: some View {
        VStack(spacing: 10) {
            HStack {
                Button { zurueck() } label: {
                    Image(systemName: nur != nil || frage == ablauf.first ? "xmark" : "chevron.left")
                        .font(.body.weight(.semibold)).frame(width: 44, height: 44)
                        .background(Farbe.karte, in: Circle()).foregroundStyle(Farbe.text)
                }
                .accessibilityLabel(nur != nil || frage == ablauf.first ? "Abbrechen" : "Zurück")
                Spacer()
                Text(vorhanden == nil ? "Neuer Meilenstein" : "Meilenstein ändern").font(.kompass(.subheadline, .bold)).foregroundStyle(Farbe.zweitrangig)
                Spacer()
                Color.clear.frame(width: 44, height: 44)
            }
            if nur == nil {
                HStack(spacing: 6) {
                    ForEach(Array(ablauf.enumerated()), id: \.offset) { i, _ in
                        Capsule().fill(i <= position ? Farbe.akzent : Farbe.akzentWeich).frame(height: 5)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Schritt \(position + 1) von \(ablauf.count)")
            }
        }
        .padding(.horizontal, Mass.rand).padding(.top, 12).padding(.bottom, 6)
    }

    private var fuss: some View {
        Button(action: weiter) {
            Text(knopfText).font(.kompass(.headline, .bold))
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(gueltig ? Farbe.akzent : Farbe.akzent.opacity(0.35), in: Capsule())
                .foregroundStyle(.white)
        }
        .disabled(!gueltig)
        .buttonStyle(.plain)
        .padding(.horizontal, Mass.rand).padding(.vertical, 10)
        .background(Farbe.grund)
        .accessibilityIdentifier("meilenstein.weiter")
    }

    private var knopfText: String {
        if nur != nil { return "Sichern" }
        return frage == .fertig ? (vorhanden == nil ? "Anlegen" : "Sichern") : "Weiter"
    }

    private var ueberschrift: String {
        switch frage {
        case .titel: "Wie heißt der Meilenstein?"
        case .art: "Woran merkst du, dass er geschafft ist?"
        case .wert:
            switch e.art {
            case .zahl: "Von wo nach wo?"
            case .zeit: "Wie viele Stunden ungefähr?"
            case .habit: "Welcher Habit, wie oft?"
            case .aufgaben: ""
            }
        case .wichtig: "Wie wichtig ist er für das Ziel?"
        case .fertig: "Passt das so?"
        }
    }

    private var unterzeile: String? {
        switch frage {
        case .titel: "Ein Zwischenziel auf dem Weg, z. B. „Theorieprüfung“."
        case .art: "Danach rechnet Kompass den Fortschritt – du musst nichts ausrechnen."
        case .wert:
            switch e.art {
            case .zahl: "Kompass rechnet den Weg dazwischen in Prozent um."
            case .zeit: "Gezählt werden Fokus-Minuten und zugeordnete Termine."
            case .habit: "Jedes Abhaken zählt – du trägst nichts ein."
            case .aufgaben: nil
            }
        case .wichtig: "Kompass verteilt die 100 % deines Ziels automatisch nach Wichtigkeit."
        case .fertig: nil
        }
    }

    // MARK: Inhalt je Frage

    @ViewBuilder
    private func inhalt(_ g: Ziel) -> some View {
        switch frage {
        case .titel:
            TextField("Name", text: $e.titel)
                .font(.kompass(.title2, .bold)).focused($fokus).submitLabel(.next).onSubmit(weiter)
                .padding(.horizontal, 16).frame(minHeight: 60)
                .background(Farbe.karte, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .onAppear { fokus = true }
            let vorschlaege = vorlagen(g)
            if !vorschlaege.isEmpty && vorhanden == nil {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Passt einer davon?", systemImage: "sparkles").font(.klein).foregroundStyle(Farbe.akzent)
                    ForEach(vorschlaege) { v in
                        Button { uebernehmen(v) } label: {
                            HStack(spacing: 12) {
                                Image(systemName: v.art.symbol).foregroundStyle(Color(hex: g.farbe)).frame(width: 28)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(v.titel).font(.zeile).foregroundStyle(Farbe.text)
                                    Text("\(v.art.frageKurz) · \(Self.wichtigName(v.gewicht))").font(.klein).foregroundStyle(Farbe.zweitrangig)
                                }
                                Spacer()
                                Image(systemName: "arrow.right.circle.fill").font(.title3).foregroundStyle(Farbe.akzent)
                            }
                            .padding(12).background(Farbe.karte, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        case .art:
            VStack(spacing: 10) {
                ForEach(SchrittArt.allCases, id: \.self) { a in
                    WahlKachel(symbol: a.symbol, titel: a.frageLang, beispiel: a.beispiel, an: e.art == a, farbe: Color(hex: g.farbe)) { e.art = a }
                }
            }
        case .wert: wertFrage(g)
        case .wichtig:
            VStack(spacing: 10) {
                ForEach([1, 2, 3], id: \.self) { w in
                    let anteil = Fortschritt.anteilVorschau(g, gewicht: w, ersetzt: vorhanden?.id)
                    WahlKachel(symbol: w == 3 ? "star.fill" : w == 2 ? "star.leadinghalf.filled" : "star",
                               titel: Self.wichtigName(w) + (w == 3 ? " · entscheidend" : w == 2 ? " · wichtig" : " · nebenbei"),
                               beispiel: "Macht dann \(Zahl.prozent(anteil)) deines Ziels aus", an: e.gewicht == w, farbe: Color(hex: g.farbe)) { e.gewicht = w }
                }
            }
        case .fertig: zusammenfassung(g)
        }
    }

    @ViewBuilder
    private func wertFrage(_ g: Ziel) -> some View {
        switch e.art {
        case .aufgaben: EmptyView()
        case .zahl:
            VStack(spacing: 12) {
                zahlBox("Heute", wert: Binding(get: { e.start ?? 0 }, set: { e.start = $0 }))
                Image(systemName: "arrow.down").font(.title3.weight(.bold)).foregroundStyle(Farbe.akzent)
                zahlBox("Ziel", wert: Binding(get: { e.soll ?? 0 }, set: { e.soll = $0 }))
            }
            ChipReihe(titel: "Einheit", auswahl: ["kg", "€", "km", "Stück", "%", "Seiten"].map { ($0, e.einheit == $0) }) { i in
                e.einheit = ["kg", "€", "km", "Stück", "%", "Seiten"][i]
            }
            TextField("Andere Einheit", text: Binding(get: { e.einheit ?? "" }, set: { e.einheit = $0 })).font(.zeile)
                .padding(.horizontal, 14).frame(minHeight: 48).background(Farbe.karte, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            VStack(alignment: .leading, spacing: 6) {
                TextField("Zwischenstände (optional), z. B. 80; 78", text: $schwellenText).font(.zeile).keyboardType(.numbersAndPunctuation)
                    .padding(.horizontal, 14).frame(minHeight: 48).background(Farbe.karte, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                Text("Kompass hakt sie selbst ab, sobald dein Stand sie erreicht.").font(.klein).foregroundStyle(Farbe.zweitrangig)
            }
        case .zeit:
            let lern = speicher.zustand.lernen.zeitVerhaeltnisse
            ChipReihe(titel: "Schnell wählen", auswahl: [5.0, 10, 20, 40, 80].map { ("\(Int($0)) h", e.soll == $0) }) { i in e.soll = [5.0, 10, 20, 40, 80][i] }
            zahlBox("Stunden", wert: Binding(get: { e.soll ?? 0 }, set: { e.soll = $0 }))
            if let soll = e.soll, soll > 0, abs(LernRechnung.zeitfaktor(lern) - 1) >= 0.05 {
                let v = LernRechnung.vorschlagStunden(soll, verhaeltnisse: lern)
                Button { e.soll = v } label: {
                    Label("Du brauchst meist länger als geplant – lieber \(Zahl.text(v)) h?", systemImage: "lightbulb").font(.unterzeile)
                }
            }
        case .habit:
            VStack(spacing: 8) {
                ForEach(speicher.zustand.habits) { h in
                    WahlKachel(symbol: h.symbol, titel: h.titel, beispiel: nil, an: !neuerHabit && e.habitID == h.id, farbe: Color(hex: h.farbe)) {
                        neuerHabit = false; e.habitID = h.id
                        if (e.soll ?? 0) == 0 { e.soll = vorschlag(h, g) }
                    }
                }
                WahlKachel(symbol: "plus", titel: "Neuer Habit", beispiel: nil, an: neuerHabit, farbe: Color(hex: g.farbe)) { neuerHabit = true }
                if neuerHabit {
                    TextField("z. B. 30 Fragen üben", text: $habitTitel).font(.zeile)
                        .padding(.horizontal, 14).frame(minHeight: 48).background(Farbe.karte, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
            ChipReihe(titel: "Zählen", auswahl: [("Wie oft insgesamt", e.modus == .anzahl), ("Wochen am Stück", e.modus == .wochen)]) { i in
                e.habitModus = i == 0 ? .anzahl : .wochen
                if let h = speicher.zustand.habit(e.habitID), !neuerHabit { e.soll = vorschlag(h, g) }
            }
            zahlBox(e.modus == .wochen ? "Wochen" : "Mal", wert: Binding(get: { e.soll ?? 0 }, set: { e.soll = $0 }))
            if let h = speicher.zustand.habit(e.habitID), !neuerHabit {
                Text("Vorschlag aus deinem Verlauf bis zur Frist: \(Zahl.text(vorschlag(h, g)))").font(.klein).foregroundStyle(Farbe.zweitrangig)
            }
        }
    }

    @ViewBuilder
    private func zusammenfassung(_ g: Ziel) -> some View {
        let andere = g.schritte.filter { $0.id != vorhanden?.id }
        let alle = andere + [e]
        let anteile = Fortschritt.anteile(alle.map(Fortschritt.gewicht))
        VStack(alignment: .leading, spacing: 10) {
            Label(e.titel, systemImage: e.art.symbol).font(.kompass(.title3, .heavy)).foregroundStyle(Farbe.text)
            Text(satz).font(.unterzeile).foregroundStyle(Farbe.zweitrangig).fixedSize(horizontal: false, vertical: true)
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .background(Farbe.karte, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

        Text("So teilt sich dein Ziel auf").font(.kompass(.headline, .bold)).foregroundStyle(Farbe.text).padding(.top, 4)
        VStack(spacing: 10) {
            ForEach(Array(zip(alle, anteile).enumerated()), id: \.offset) { i, p in
                let neu = i == alle.count - 1
                HStack(spacing: 10) {
                    Text(p.0.titel.isEmpty ? "Neu" : p.0.titel).font(.unterzeile.weight(neu ? .bold : .regular)).foregroundStyle(Farbe.text).lineLimit(1)
                    Spacer()
                    Text(Zahl.prozent(p.1)).font(.unterzeile.weight(.bold)).monospacedDigit().foregroundStyle(neu ? Color(hex: g.farbe) : Farbe.zweitrangig)
                }
                Balken(anteil: p.1, farbe: neu ? Color(hex: g.farbe) : Farbe.zweitrangig.opacity(0.5), spur: Farbe.linie)
            }
        }
        .padding(16).background(Farbe.karte, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        Text("Die Prozente rechnet Kompass – kommt ein Meilenstein dazu oder fällt einer weg, verteilt sich alles neu.")
            .font(.klein).foregroundStyle(Farbe.zweitrangig)
    }

    private var satz: String {
        let wie: String
        switch e.art {
        case .aufgaben: wie = "Du hakst ihn ab, wenn er geschafft ist. Teilaufgaben füllen ihn bis 90 %."
        case .zahl: wie = "Von \(Zahl.text(e.start ?? 0)) bis \(Zahl.text(e.soll ?? 0)) \(e.einheit ?? "") – du trägst ab und zu den Stand ein."
        case .zeit: wie = "\(Zahl.text(e.soll ?? 0)) Stunden – Fokus-Minuten und Termine zählen automatisch."
        case .habit:
            let name = neuerHabit ? habitTitel : (speicher.zustand.habit(e.habitID)?.titel ?? "")
            wie = "Über „\(name)“: \(Zahl.text(e.soll ?? 0)) \(e.modus == .wochen ? "Wochen am Stück" : "Mal") – Abhaken zählt automatisch."
        }
        return wie + " Wichtigkeit: \(Self.wichtigName(e.gewicht))."
    }

    private func zahlBox(_ titel: String, wert: Binding<Double>) -> some View {
        HStack {
            Text(titel).font(.zeile).foregroundStyle(Farbe.zweitrangig)
            Spacer()
            TextField(titel, value: wert, format: .number.locale(de))
                .font(.kompass(.title2, .heavy)).monospacedDigit().multilineTextAlignment(.trailing).keyboardType(.decimalPad)
        }
        .padding(.horizontal, 16).frame(minHeight: 60)
        .background(Farbe.karte, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    // MARK: Logik

    private func vorlagen(_ g: Ziel) -> [Schritt] {
        return (ZielVorschlag.fuer(g.titel).first?.schritte ?? [])
            .filter { v in !g.schritte.contains { ZielVorschlag.aehnlich($0.titel, v.titel) } }.prefix(3).map { $0 }
    }

    private func uebernehmen(_ v: Schritt) {
        var x = v
        x.id = e.id
        x.seit = speicher.heute
        e = x
        frage = .fertig
    }

    private func vorschlag(_ h: Habit, _ g: Ziel) -> Double {
        e.modus == .wochen ? LernRechnung.vorschlagWochen(h, heute: speicher.heute, bis: g.faellig) : LernRechnung.vorschlagAnzahl(h, heute: speicher.heute, bis: g.faellig)
    }

    private var gueltig: Bool {
        switch frage {
        case .titel: return !e.titel.trimmingCharacters(in: .whitespaces).isEmpty
        case .art, .wichtig: return true
        case .wert, .fertig:
            switch e.art {
            case .aufgaben: return !e.titel.trimmingCharacters(in: .whitespaces).isEmpty
            case .zahl: return (e.soll ?? 0) != (e.start ?? 0)
            case .zeit: return (e.soll ?? 0) > 0
            case .habit: return (e.soll ?? 0) > 0 && (neuerHabit ? !habitTitel.trimmingCharacters(in: .whitespaces).isEmpty : e.habitID != nil)
            }
        }
    }

    private func laden() {
        guard !geladen else { return }
        geladen = true
        if let v = vorhanden { e = v } else { e = Schritt(titel: "", seit: speicher.heute) }
        schwellenText = (e.schwellen ?? []).map { Zahl.text($0) }.joined(separator: "; ")
        if let n = nur { frage = n }
    }

    private func zurueck() {
        guard nur == nil, let i = ablauf.firstIndex(of: frage), i > 0 else { dismiss(); return }
        frage = ablauf[i - 1]
    }

    private func weiter() {
        guard gueltig else { return }
        if nur != nil || frage == .fertig { sichern(); return }
        // Art gewechselt → der Wert passt evtl. nicht mehr: Vorschlag aus dem Titel
        if frage == .art, e.art == .zahl, e.soll == nil, let g = speicher.zustand.ziel(zielID) {
            e.soll = ZielVorschlag.zahlImTitel(e.titel) ?? ZielVorschlag.zahlImTitel(g.titel)
        }
        if let i = ablauf.firstIndex(of: frage), i + 1 < ablauf.count { frage = ablauf[i + 1] }
    }

    private func sichern() {
        var x = e
        x.titel = x.titel.trimmingCharacters(in: .whitespaces)
        let T = speicher.heute
        let titelHabit = habitTitel.trimmingCharacters(in: .whitespaces)
        let neu = neuerHabit && x.art == .habit
        if x.art == .habit { x.seit = x.seit ?? T }
        if x.art == .zahl {
            if x.aktuell == nil { x.aktuell = x.start ?? 0 }
            let w = schwellenText.split(whereSeparator: { ";/ \n".contains($0) })
                .compactMap { Double($0.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")) }
            x.schwellen = w.isEmpty ? nil : w
        }
        let zid = zielID
        speicher.aendern { s in
            if neu {
                let farbe = s.ziel(zid)?.farbe ?? Farbe.ziele[0]
                let h = Habit(titel: titelHabit, farbe: farbe, symbol: "star.fill", wochentage: [1, 2, 3, 4, 5, 6, 7], zielID: zid, angelegt: T)
                s.habits.append(h)
                x.habitID = h.id
            }
            s.schrittSpeichern(x, ziel: zid)
        }
        dismiss()
    }
}

/// Große Auswahl-Kachel: Symbol im Kreis, Titel, Beispiel; gewählt = Rand und Haken.
private struct WahlKachel: View {
    var symbol: String
    var titel: String
    var beispiel: String?
    var an: Bool
    var farbe: Color
    var aktion: () -> Void

    var body: some View {
        Button(action: aktion) {
            HStack(spacing: 14) {
                Image(systemName: symbol).font(.system(size: 17, weight: .bold)).foregroundStyle(.white)
                    .frame(width: 42, height: 42).background(farbe.gradient, in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(titel).font(.zeile).foregroundStyle(Farbe.text).fixedSize(horizontal: false, vertical: true)
                    if let beispiel { Text(beispiel).font(.unterzeile).foregroundStyle(Farbe.zweitrangig) }
                }
                Spacer(minLength: 6)
                Image(systemName: an ? "checkmark.circle.fill" : "circle").font(.title3).foregroundStyle(an ? Farbe.akzent : Farbe.linie)
            }
            .padding(14)
            .background(Farbe.karte, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(an ? Farbe.akzent : .clear, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(an ? [.isButton, .isSelected] : .isButton)
    }
}

extension SchrittArt {
    /// Antwort auf „Woran merkst du es?“ – kurz
    var frageKurz: String {
        switch self {
        case .aufgaben: "Abhaken"
        case .zahl: "Zahl erreichen"
        case .zeit: "Zeit investieren"
        case .habit: "Regelmäßig tun"
        }
    }
    var frageLang: String {
        switch self {
        case .aufgaben: "Ich hake es ab"
        case .zahl: "Eine Zahl erreichen"
        case .zeit: "Zeit investieren"
        case .habit: "Regelmäßig etwas tun"
        }
    }
    var beispiel: String {
        switch self {
        case .aufgaben: "z. B. Prüfung bestanden, Antrag abgeschickt"
        case .zahl: "z. B. 75 kg, 10.000 €, 30 Fahrstunden"
        case .zeit: "z. B. 20 Stunden lernen"
        case .habit: "z. B. 3× pro Woche laufen"
        }
    }
}
