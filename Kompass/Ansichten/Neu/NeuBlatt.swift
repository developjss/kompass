import SwiftUI

/// Anlegen, geführt wie der „Personal check“ in Gapless: eine Frage je Schritt, Fortschrittsbalken oben,
/// großer Weiter-Knopf unten. Was → Titel → Wann → Details → Fertig. Aufgabe, Termin, Habit oder Ziel.
struct NeuBlatt: View {
    @State private var art: NeuArt?
    @State private var schritt: Schritt
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav
    @Environment(\.dismiss) private var dismiss
    @FocusState private var titelFokus: Bool

    enum Schritt: Int, CaseIterable { case was, titel, wann, details, verbinden, fertig }

    init(art: NeuArt?, tag: Tag? = nil, start: Int? = nil) {
        _art = State(initialValue: art)
        _schritt = State(initialValue: art == nil ? .was : .titel)
        if let tag { _datum = State(initialValue: tag.datum()) }
        if let start {
            _terminStart = State(initialValue: start)
            _terminEnde = State(initialValue: min(24 * 60 - 1, start + 60))
        }
    }

    // Gemeinsam
    @State private var titel = ""
    @State private var zielID: UUID?
    @State private var kategorie: Kategorie?
    // Aufgabe
    @State private var wannWahl: WannWahl = .heute
    @State private var datum = Date()
    @State private var wichtig = false
    @State private var wiederholung: Wiederholung = .nie
    @State private var mitUhrzeit = false
    @State private var uhrzeit = 9 * 60
    @State private var dauer = 60
    // Termin
    @State private var terminStart = 15 * 60
    @State private var terminEnde = 16 * 60
    @State private var terminHabitID: UUID?
    /// Meilenstein, in den der Termin zählt (nil + nurEinsatz = zählt nur als Einsatz; nil sonst = erster passender)
    @State private var terminSchrittID: UUID?
    @State private var terminNurEinsatz = false
    // Habit
    @State private var rhythmusArt: RhythmusArt = .taeglich
    @State private var tage: Set<Int> = [1, 2, 3, 4, 5]
    @State private var proWoche = 3
    @State private var mitMenge = false
    @State private var menge: Double = 20
    @State private var habitEinheit: Einheit = .minuten
    @State private var erinnerung: Int?
    @State private var habitUhrzeit: Int?
    @State private var vorschlagGenutzt = false
    @State private var symbol = "star.fill"
    // Ziel
    @State private var fristWahl = 1
    @State private var faellig = Calendar.kompass.date(byAdding: .month, value: 6, to: Date()) ?? Date()
    @State private var vorlage: Int? = 0
    @State private var start = 0.0
    @State private var zielwert = 100.0
    @State private var einheit = ""
    @State private var zahlAngefasst = false
    @State private var warum = ""
    // Verbinden: was schon dafür zählt (Ziel) bzw. wozu der Habit gehört
    @State private var zaehlenHabits: Set<UUID> = []
    @State private var zaehlenSerien: Set<String> = []
    @State private var zaehlenAufgaben: Set<UUID> = []
    @State private var mitBisherigen = true
    @State private var alsMeilenstein = true
    @State private var nachgetragen: Set<Int> = []
    @State private var erfuelltDurch: UUID?

    enum WannWahl: String, CaseIterable { case heute = "Heute", morgen = "Morgen", datum = "Datum", eingang = "Ohne Datum" }
    enum RhythmusArt: String, CaseIterable { case taeglich = "Täglich", werktags = "Werktags", tage = "Wochentage", proWoche = "n-mal pro Woche" }
    private let namen = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]

    var body: some View {
        VStack(spacing: 0) {
            kopf
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(frage).font(.kompass(.title, .heavy)).foregroundStyle(Farbe.text).fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    if let u = unterfrage { Text(u).font(.unterzeile).foregroundStyle(Farbe.zweitrangig) }
                    inhalt
                }
                .padding(.horizontal, Mass.rand).padding(.top, 8).padding(.bottom, 24)
                .frame(maxWidth: 720).frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollDismissesKeyboard(.interactively)
            fuss
        }
        .background(Farbe.grund.ignoresSafeArea())
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .onChange(of: schritt) { _, neu in titelFokus = neu == .titel }
        .onAppear { if schritt == .titel { titelFokus = true } }
    }

    // MARK: Kopf und Fuß

    /// Gewählter Meilenstein des Termins: ausdrücklich gewählt, sonst der erste passende (Zeit/Zahl), außer „Nur Einsatz“.
    private var terminSchritt: Kompass.Schritt? {
        guard let g = speicher.zustand.ziel(zielID) else { return nil }
        let passend = g.schritte.filter { $0.art == .zeit || $0.art == .zahl }
        if let id = terminSchrittID, let s = passend.first(where: { $0.id == id }) { return s }
        return terminNurEinsatz ? nil : passend.first
    }

    private var schritte: [Schritt] { art == .habit || art == .ziel ? Schritt.allCases : Schritt.allCases.filter { $0 != .verbinden } }
    private var position: Int { schritte.firstIndex(of: schritt) ?? 0 }

    private var kopf: some View {
        VStack(spacing: 10) {
            HStack {
                Button { zurueck() } label: {
                    Image(systemName: schritt == .was || (schritt == .titel && artVorgegeben) ? "xmark" : "chevron.left")
                        .font(.body.weight(.semibold)).frame(width: 44, height: 44)
                        .background(Farbe.karte, in: Circle()).foregroundStyle(Farbe.text)
                }
                .accessibilityLabel(schritt == .was || (schritt == .titel && artVorgegeben) ? "Abbrechen" : "Zurück")
                Spacer()
                Text(art.map { "Neu: \($0.name)" } ?? "Neu").font(.kompass(.subheadline, .bold)).foregroundStyle(Farbe.zweitrangig)
                Spacer()
                Button("Abbrechen") { dismiss() }.font(.kompass(.subheadline, .bold)).foregroundStyle(Farbe.akzent).frame(minHeight: 44)
                    .opacity(schritt == .was ? 0 : 1)
            }
            HStack(spacing: 6) {
                ForEach(Array(schritte.enumerated()), id: \.offset) { i, _ in
                    Capsule().fill(i <= position ? Farbe.akzent : Farbe.akzentWeich).frame(height: 5)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Schritt \(position + 1) von \(schritte.count)")
        }
        .padding(.horizontal, Mass.rand).padding(.top, 12).padding(.bottom, 6)
    }

    @ViewBuilder private var fuss: some View {
        if schritt != .was {
            VStack(spacing: 8) {
                Button(action: weiter) {
                    Text(schritt == .fertig ? "Anlegen" : "Weiter").font(.kompass(.headline, .bold))
                        .frame(maxWidth: .infinity, minHeight: 54)
                        .background(gueltig ? Farbe.akzent : Farbe.akzent.opacity(0.35), in: Capsule())
                        .foregroundStyle(Farbe.aufFarbe)
                }
                .disabled(!gueltig)
                .buttonStyle(.plain)
                .accessibilityIdentifier("neu.weiter")
                if schritt != .fertig {
                    Text(hinweisUnten).font(.klein).foregroundStyle(Farbe.zweitrangig).lineLimit(2).multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, Mass.rand).padding(.vertical, 10)
            .background(Farbe.grund)
        }
    }

    private var artVorgegeben: Bool { art != nil && schritt == .titel && !kamVonWas }
    @State private var kamVonWas = false

    private func zurueck() {
        switch schritt {
        case .was: dismiss()
        case .titel: if kamVonWas { schritt = .was } else { dismiss() }
        default: if position > 0 { schritt = schritte[position - 1] }
        }
    }

    private func weiter() {
        guard gueltig else { return }
        if schritt == .fertig { anlegen(); return }
        if position + 1 < schritte.count { schritt = schritte[position + 1] }
    }

    private var gueltig: Bool {
        switch schritt {
        case .was: return art != nil
        case .titel: return !titel.trimmingCharacters(in: .whitespaces).isEmpty
        case .wann:
            if art == .habit { return rhythmusArt != .tage || !tage.isEmpty }
            if art == .termin { return terminEnde > terminStart }
            return true
        case .details: return art != .habit || !mitMenge || menge > 0
        case .verbinden, .fertig: return true
        }
    }

    private var hinweisUnten: String {
        switch schritt {
        case .titel: return art == .habit ? "Aus dem Titel schlägt Kompass Menge und Einheit vor." : art == .ziel ? "Aus dem Titel kommen Meilenstein-Vorlagen." : "Kurz und klar – du kannst alles später ändern."
        case .wann: return art == .aufgabe ? "Ohne Uhrzeit schlägt der Kalender sie unter „Empfehlung“ vor – ziehbar in den Tag." : art == .habit ? "Mit fester Uhrzeit steht der Habit als Block im Kalender." : ""
        case .details: return "Alles hier ist optional."
        case .verbinden: return art == .ziel ? "Jedes Ausgewählte wird ein Meilenstein – Kompass zählt automatisch." : "Optional – du kannst es später unter Verfeinern ändern."
        default: return ""
        }
    }

    // MARK: Fragen

    private var frage: String {
        switch schritt {
        case .was: return "Was möchtest du anlegen?"
        case .titel:
            switch art {
            case .aufgabe: return "Was ist zu tun?"
            case .termin: return "Wie heißt der Termin?"
            case .habit: return "Was willst du regelmäßig tun?"
            case .ziel: return "Wohin willst du?"
            case nil: return ""
            }
        case .wann:
            switch art {
            case .aufgabe: return "Wann?"
            case .termin: return "Wann findet er statt?"
            case .habit: return "Wie oft?"
            case .ziel: return "Bis wann?"
            case nil: return ""
            }
        case .details:
            switch art {
            case .aufgabe: return "Noch Details?"
            case .termin: return "Zählt er für etwas?"
            case .habit: return "Mit Menge?"
            case .ziel: return "Meilensteine und Warum"
            case nil: return ""
            }
        case .verbinden: return art == .ziel ? "Was zählt schon dafür?" : "Gehört er zu etwas?"
        case .fertig: return "Passt das so?"
        }
    }

    private var unterfrage: String? {
        switch (schritt, art) {
        case (.was, _): return "Eine Sache, ein Schritt nach dem anderen."
        case (.details, .habit): return "Halb geschafft zählt halb – zum Beispiel 10 von 20 Minuten."
        case (.details, .ziel): return gewaehlteVorlage.map { "Vorlage: \($0.kurz)" }
        case (.wann, .ziel): return "„Auf Kurs“ vergleicht den Fortschritt mit der Zeit bis dahin."
        case (.verbinden, .ziel): return "Habits, Termine und Aufgaben, die du schon hast – auch Vergangenes kann mitzählen."
        case (.verbinden, .habit): return "Ein Ziel, für das er zählt, Tage, an denen du es schon gemacht hast, oder ein Termin, der ihn erfüllt."
        default: return nil
        }
    }

    // MARK: Inhalt je Schritt

    @ViewBuilder private var inhalt: some View {
        switch schritt {
        case .was: wasTeil
        case .titel: titelTeil
        case .wann: wannTeil
        case .details: detailsTeil
        case .verbinden: verbindenTeil
        case .fertig: fertigTeil
        }
    }

    private var wasTeil: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ForEach([NeuArt.aufgabe, .termin, .habit, .ziel], id: \.self) { a in
                Button { art = a; kamVonWas = true; schritt = .titel } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: a.symbol).font(.system(size: 18, weight: .bold))
                            .frame(width: 40, height: 40).background(.white.opacity(0.22), in: Circle())
                            .overlay(Circle().strokeBorder(.white.opacity(0.35), lineWidth: 1))
                        Spacer(minLength: 4)
                        Text(a.name).font(.kompass(.headline, .bold))
                        Text(a.erklaerung).font(.klein).opacity(0.9).lineLimit(2).fixedSize(horizontal: false, vertical: true)
                    }
                    .foregroundStyle(.white)
                    .padding(14)
                    .frame(maxWidth: .infinity, minHeight: 136, alignment: .topLeading)
                    .background {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(LinearGradient(colors: a.verlauf, startPoint: .bottomTrailing, endPoint: .topLeading))
                            .overlay(alignment: .topLeading) { Circle().fill(.white.opacity(0.18)).frame(width: 120).blur(radius: 30).offset(x: -30, y: -40) }
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .shadow(color: a.verlauf[0].opacity(0.3), radius: 10, y: 5)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(a.name): \(a.erklaerung)")
            }
        }
    }

    @ViewBuilder private var titelTeil: some View {
        TextField(platzhalter, text: $titel, axis: .vertical)
            .font(.kompass(.title2, .bold)).lineLimit(1...3)
            .focused($titelFokus)
            .submitLabel(.next)
            .onSubmit { if gueltig { weiter() } }
            .padding(16)
            .background(Farbe.karte, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Farbe.akzent.opacity(titelFokus ? 0.6 : 0), lineWidth: 2))
            .accessibilityIdentifier("neu.titel")
        if art == .habit {
            let v = vorschlag
            if !titel.trimmingCharacters(in: .whitespaces).isEmpty, v.einheit != nil || v.nurAbhaken {
                Vorschlagskarte(text: v.nurAbhaken ? "Einfach abhaken – ohne Menge" : "\(Zahl.text(v.menge ?? 0)) \(v.einheit?.name ?? "") pro Tag", an: vorschlagGenutzt) {
                    vorschlagUebernehmen(v)
                }
            }
        }
        if art == .ziel, !titel.trimmingCharacters(in: .whitespaces).isEmpty {
            let v = vorlagen
            ChipReihe(titel: "Meilenstein-Vorlage", auswahl: v.enumerated().map { ($0.element.name, vorlage == $0.offset) } + [("Ohne", vorlage == nil)]) { i in
                vorlage = i < v.count ? i : nil; zahlAngefasst = false
            }
            if let g = gewaehlteVorlage { Text(g.kurz).font(.klein).foregroundStyle(Farbe.zweitrangig) }
        }
        if titel.trimmingCharacters(in: .whitespaces).isEmpty || art == .aufgabe || art == .termin {
            let beispiele: [String] = switch art {
            case .aufgabe: ["Flugschule anrufen", "Paket zur Post", "Kapitel 4 lesen"]
            case .termin: ["Fahrstunde", "Zahnarzt", "Training"]
            case .habit: ["20 Minuten lesen", "10.000 Schritte", "Sport 3× pro Woche"]
            case .ziel: ["Halbmarathon laufen", "Führerschein Klasse B", "10.000 € sparen"]
            case nil: []
            }
            ChipReihe(titel: "Zum Beispiel", auswahl: beispiele.map { ($0, titel == $0) }) { titel = beispiele[$0] }
        }
    }

    @ViewBuilder private var wannTeil: some View {
        switch art {
        case .aufgabe:
            Karte {
                ChipReihe(titel: "Tag", auswahl: WannWahl.allCases.map { ($0.rawValue, $0 == wannWahl) }) { wannWahl = WannWahl.allCases[$0] }
                if wannWahl == .datum { DatePicker("Datum", selection: $datum, displayedComponents: .date).font(.zeile) }
            }
            if wannWahl != .eingang {
                Karte {
                    ChipReihe(titel: "Uhrzeit", auswahl: [("keine", !mitUhrzeit)] + [9, 12, 15, 18].map { ("\($0):00", mitUhrzeit && uhrzeit == $0 * 60) }) { i in
                        mitUhrzeit = i > 0; if i > 0 { uhrzeit = [9, 12, 15, 18][i - 1] * 60 }
                    }
                    if mitUhrzeit {
                        DatePicker("Genau", selection: Binding(get: { uhr(uhrzeit) }, set: { uhrzeit = minuten($0) }), displayedComponents: .hourAndMinute).font(.zeile)
                        ChipReihe(titel: "Dauer", auswahl: [15, 30, 60, 90, 120].map { (dauerText($0), $0 == dauer) }) { dauer = [15, 30, 60, 90, 120][$0] }
                    }
                }
            }
        case .termin:
            Karte {
                DatePicker("Tag", selection: $datum, displayedComponents: .date).font(.zeile)
                DatePicker("Von", selection: Binding(get: { uhr(terminStart) }, set: { let d = terminEnde - terminStart; terminStart = minuten($0); terminEnde = min(24 * 60 - 1, terminStart + max(d, 15)) }), displayedComponents: .hourAndMinute).font(.zeile)
                DatePicker("Bis", selection: Binding(get: { uhr(terminEnde) }, set: { terminEnde = max(terminStart + 5, minuten($0)) }), displayedComponents: .hourAndMinute).font(.zeile)
                ChipReihe(titel: "Dauer", auswahl: [30, 60, 90, 120].map { (dauerText($0), terminEnde - terminStart == $0) }) { terminEnde = min(24 * 60 - 1, terminStart + [30, 60, 90, 120][$0]) }
            }
        case .habit:
            Karte {
                ChipReihe(titel: "Rhythmus", auswahl: RhythmusArt.allCases.map { ($0.rawValue, $0 == rhythmusArt) }) { rhythmusArt = RhythmusArt.allCases[$0] }
                if rhythmusArt == .tage {
                    ChipReihe(titel: "Tage", auswahl: (1...7).map { (namen[$0 - 1], tage.contains($0)) }) { i in let d = i + 1; if tage.contains(d) { tage.remove(d) } else { tage.insert(d) } }
                }
                if rhythmusArt == .proWoche { Stepper("\(proWoche)× pro Woche", value: $proWoche, in: 1...7).font(.zeile) }
            }
            Karte {
                ChipReihe(titel: "Feste Uhrzeit im Kalender", auswahl: [("keine", habitUhrzeit == nil)] + [7, 12, 18, 21].map { ("\($0):00", habitUhrzeit == $0 * 60) }) { i in
                    habitUhrzeit = i == 0 ? nil : [7, 12, 18, 21][i - 1] * 60
                }
                if habitUhrzeit != nil {
                    DatePicker("Genau", selection: Binding(get: { uhr(habitUhrzeit ?? 0) }, set: { habitUhrzeit = minuten($0) }), displayedComponents: .hourAndMinute).font(.zeile)
                }
            }
        case .ziel:
            Karte {
                let fristen = ["In 3 Monaten", "In 6 Monaten", "In 1 Jahr", "Datum"]
                ChipReihe(titel: "Frist", auswahl: fristen.enumerated().map { ($0.element, fristWahl == $0.offset) }) { i in
                    fristWahl = i
                    let monate = [3, 6, 12]
                    if i < 3 { faellig = Calendar.kompass.date(byAdding: .month, value: monate[i], to: speicher.heute.datum()) ?? faellig }
                }
                if fristWahl == 3 { DatePicker("Bis wann", selection: $faellig, displayedComponents: .date).font(.zeile) }
                else { Text(faellig.formatted(.dateTime.day().month(.wide).year().locale(Locale(identifier: "de_DE")))).font(.unterzeile).foregroundStyle(Farbe.zweitrangig) }
            }
        case nil: EmptyView()
        }
    }

    @ViewBuilder private var detailsTeil: some View {
        switch art {
        case .aufgabe:
            Karte {
                ChipReihe(titel: "Wichtigkeit", auswahl: [("Wichtig", wichtig), ("Normal", !wichtig)]) { wichtig = $0 == 0 }
                ChipReihe(titel: "Wiederholen", auswahl: Wiederholung.allCases.map { ($0.name, $0 == wiederholung) }) { wiederholung = Wiederholung.allCases[$0] }
            }
            zielKarte
            kategorieKarte
        case .termin:
            zielKarte
            if let g = speicher.zustand.ziel(zielID) {
                let passend = g.schritte.filter { $0.art == .zeit || $0.art == .zahl }
                let gewaehlt = terminSchritt
                Karte {
                    if passend.isEmpty {
                        Label("Zählt als Einsatz – ändert die Prozente nicht. Für Prozente braucht das Ziel einen Meilenstein „Zeit“ oder „Zahl“.", systemImage: "info.circle")
                            .font(.klein).foregroundStyle(Farbe.zweitrangig).fixedSize(horizontal: false, vertical: true)
                    } else {
                        ChipReihe(titel: "Zählt in", auswahl: [("Nur Einsatz", gewaehlt == nil)] + passend.map { ("\($0.titel) · \($0.art == .zeit ? "Dauer" : "je 1")", $0.id == gewaehlt?.id) }) { i in
                            terminNurEinsatz = i == 0
                            terminSchrittID = i == 0 ? nil : passend[i - 1].id
                        }
                    }
                }
            }
            Karte {
                let habits = speicher.zustand.habits
                if !habits.isEmpty {
                    ChipReihe(titel: "Erfüllt einen Habit", auswahl: [("Keinen", terminHabitID == nil)] + habits.map { ($0.titel, $0.id == terminHabitID) }) { i in
                        terminHabitID = i == 0 ? nil : habits[i - 1].id
                    }
                }
                ChipReihe(titel: "Wiederholen", auswahl: Wiederholung.allCases.map { ($0.name, $0 == wiederholung) }) { wiederholung = Wiederholung.allCases[$0] }
            }
            kategorieKarte
        case .habit:
            Karte {
                ChipReihe(titel: "Menge", auswahl: [("Nur abhaken", !mitMenge), ("Mit Menge", mitMenge)]) { mitMenge = $0 == 1 }
                if mitMenge {
                    HStack {
                        Text("Soll pro Tag").font(.zeile)
                        Spacer()
                        TextField("20", value: $menge, format: .number.locale(Locale(identifier: "de_DE"))).multilineTextAlignment(.trailing).keyboardType(.decimalPad)
                            .font(.kompass(.title3, .bold)).frame(width: 90).padding(8).background(Farbe.grund, in: RoundedRectangle(cornerRadius: 10))
                    }
                    ChipReihe(titel: "Einheit", auswahl: Einheit.allCases.map { ($0.name, $0 == habitEinheit) }) { habitEinheit = Einheit.allCases[$0] }
                }
            }
            Karte {
                ChipReihe(titel: "Erinnerung", auswahl: [("aus", erinnerung == nil)] + [7, 12, 18, 21].map { ("\($0):00", erinnerung == $0 * 60) }) { i in
                    erinnerung = i == 0 ? nil : [7, 12, 18, 21][i - 1] * 60
                }
                if erinnerung != nil {
                    DatePicker("Genau", selection: Binding(get: { uhr(erinnerung ?? 0) }, set: { erinnerung = minuten($0) }), displayedComponents: .hourAndMinute).font(.zeile)
                }
            }
        case .ziel:
            if let zs = zahlSchritt {
                Karte {
                    Text("Zahl-Meilenstein „\(zs.titel)“").font(.zeile)
                    HStack(spacing: 10) {
                        zahlFeld("Start", wert: Binding(get: { zahlAngefasst ? start : (zs.start ?? 0) }, set: { zahlAnfassen(zs); start = $0 }))
                        zahlFeld("Ziel", wert: Binding(get: { zahlAngefasst ? zielwert : (zs.soll ?? 100) }, set: { zahlAnfassen(zs); zielwert = $0 }))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Einheit").font(.klein).foregroundStyle(Farbe.zweitrangig)
                            TextField("kg", text: Binding(get: { zahlAngefasst ? einheit : (zs.einheit ?? "") }, set: { zahlAnfassen(zs); einheit = $0 }))
                                .font(.kompass(.title3, .bold)).padding(8).background(Farbe.grund, in: RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
            } else {
                Karte { Text(gewaehlteVorlage.map { "Meilensteine: \($0.kurz)" } ?? "Ohne Vorlage – Meilensteine legst du im Ziel an.").font(.unterzeile).foregroundStyle(Farbe.zweitrangig) }
            }
            Karte {
                let bereiche = ["Lernen", "Gesundheit", "Finanzen", "Arbeit", "Familie", "Allgemein"]
                ChipReihe(titel: "Bereich", auswahl: bereiche.map { ($0, $0 == (zielBereich ?? gewaehlteVorlage?.bereich ?? "Allgemein")) }) { zielBereich = bereiche[$0] }
            }
            Karte {
                Text("Warum ist es dir wichtig?").font(.zeile)
                TextField("z. B. unabhängig unterwegs sein", text: $warum, axis: .vertical).font(.unterzeile).lineLimit(1...3)
                Text("Hilft beim Dranbleiben – steht später auf der Ziel-Seite.").font(.klein).foregroundStyle(Farbe.zweitrangig)
            }
        case nil: EmptyView()
        }
    }
    @State private var zielBereich: String?

    @ViewBuilder private var verbindenTeil: some View {
        let z = speicher.zustand
        let T = speicher.heute
        if art == .ziel {
            if !z.habits.isEmpty {
                Karte {
                    ChipReihe(titel: "Habits", auswahl: z.habits.map { ($0.titel, zaehlenHabits.contains($0.id)) }) { i in
                        let id = z.habits[i].id; if zaehlenHabits.contains(id) { zaehlenHabits.remove(id) } else { zaehlenHabits.insert(id) }
                    }
                }
            }
            let serien = Array(MeilensteinQuelle.serien(zustand: z, ziel: UUID(), heute: T, jetzt: speicher.jetztMinuten, termine: speicher.termine(am:)).prefix(8))
            if !serien.isEmpty {
                Karte {
                    let doppelt = Dictionary(grouping: serien, by: \.titel).filter { $0.value.count > 1 }.keys
                    ChipReihe(titel: "Termine (jeder zählt einmal)", auswahl: serien.map { sr in
                        let quelle = sr.id.split(separator: ":").first.map { String($0).capitalized } ?? ""
                        return ("\(sr.titel)\(doppelt.contains(sr.titel) ? " (\(quelle))" : "") · \(sr.bisher)", zaehlenSerien.contains(sr.id))
                    }) { i in
                        let id = serien[i].id; if zaehlenSerien.contains(id) { zaehlenSerien.remove(id) } else { zaehlenSerien.insert(id) }
                    }
                }
            }
            let aufgaben = Array(z.aufgaben.filter { $0.zielID == nil }.sorted { ($0.erledigt ? 1 : 0, $0.reihenfolge) < ($1.erledigt ? 1 : 0, $1.reihenfolge) }.prefix(10))
            if !aufgaben.isEmpty {
                Karte {
                    ChipReihe(titel: "Aufgaben (auch erledigte)", auswahl: aufgaben.map { (($0.erledigt ? "✓ " : "") + $0.titel, zaehlenAufgaben.contains($0.id)) }) { i in
                        let id = aufgaben[i].id; if zaehlenAufgaben.contains(id) { zaehlenAufgaben.remove(id) } else { zaehlenAufgaben.insert(id) }
                    }
                }
            }
            if !(zaehlenHabits.isEmpty && zaehlenSerien.isEmpty) {
                Karte {
                    Toggle(isOn: $mitBisherigen) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Bisheriges mitzählen").font(.zeile)
                            Text("Was du schon gemacht hast, zählt ab Start mit.").font(.klein).foregroundStyle(Farbe.zweitrangig)
                        }
                    }
                    .tint(Farbe.akzent)
                }
            }
            if z.habits.isEmpty && serien.isEmpty && aufgaben.isEmpty {
                Karte { Text("Noch nichts da – Meilensteine legst du später direkt im Ziel an.").font(.unterzeile).foregroundStyle(Farbe.zweitrangig) }
            }
        } else {
            zielKarte
            if zielID != nil {
                Karte {
                    Toggle(isOn: $alsMeilenstein) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Zählt in die Prozente").font(.zeile)
                            Text(alsMeilenstein ? "Wird ein Meilenstein im Ziel – jedes Abhaken zählt." : "Nur Einsatz – ändert die Prozente nicht.").font(.klein).foregroundStyle(Farbe.zweitrangig)
                        }
                    }
                    .tint(Farbe.akzent)
                }
            }
            Karte {
                let tage = (1...7).map { T.plus(tage: -$0) }
                ChipReihe(titel: "Schon gemacht? (letzte 7 Tage)", auswahl: tage.enumerated().map { i, d in
                    (i == 0 ? "Gestern" : namen[d.wochentag - 1], nachgetragen.contains(i + 1))
                }) { i in let k = i + 1; if nachgetragen.contains(k) { nachgetragen.remove(k) } else { nachgetragen.insert(k) } }
            }
            let serienTermine = Dictionary(grouping: z.eigeneTermine.filter { $0.wiederholung != .nie }, by: \.titel).compactMap { $0.value.first }
            if !serienTermine.isEmpty {
                Karte {
                    ChipReihe(titel: "Wird durch einen Termin erfüllt", auswahl: [("Keinen", erfuelltDurch == nil)] + serienTermine.map { ($0.titel, erfuelltDurch == $0.id) }) { i in
                        erfuelltDurch = i == 0 ? nil : serienTermine[i - 1].id
                    }
                }
            }
        }
    }

    private var zielKarte: some View {
        Karte {
            let ziele = speicher.zustand.ziele.filter { $0.status == .aktiv }
            if ziele.isEmpty {
                Text("Noch kein Ziel – später zuordnen.").font(.unterzeile).foregroundStyle(Farbe.zweitrangig)
            } else {
                ChipReihe(titel: art == .termin ? "Zählt für ein Ziel" : "Gehört zu einem Ziel", auswahl: [("Keins", zielID == nil)] + ziele.map { ($0.titel, $0.id == zielID) }) { i in
                    zielID = i == 0 ? nil : ziele[i - 1].id
                }
            }
        }
    }

    private var kategorieKarte: some View {
        Karte {
            ChipReihe(titel: "Kategorie (Farbe ohne Ziel)", auswahl: Kategorie.allCases.map { ($0.name, $0 == kategorie) }) { i in
                let k = Kategorie.allCases[i]; kategorie = kategorie == k ? nil : k
            }
        }
    }

    private var fertigTeil: some View {
        let farben = art?.verlauf ?? Farbe.indigo
        return VStack(alignment: .leading, spacing: 12) {
            Verlaufskarte(farben: farben) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        KartenLabel(text: art?.name ?? "Neu")
                        Text(titel.trimmingCharacters(in: .whitespaces)).font(.kompass(.title2, .heavy)).fixedSize(horizontal: false, vertical: true)
                        ForEach(zusammenfassung, id: \.self) { Text($0).font(.unterzeile).opacity(0.92) }
                    }
                    Spacer()
                    Image(systemName: art?.symbol ?? "plus").font(.system(size: 20, weight: .semibold))
                        .frame(width: 44, height: 44).background(.white.opacity(0.2), in: Circle())
                }
            }
            Text("Alles lässt sich später auf der Seite ändern.").font(.klein).foregroundStyle(Farbe.zweitrangig)
        }
    }

    private var zusammenfassung: [String] {
        let z = speicher.zustand
        var t: [String] = []
        switch art {
        case .aufgabe:
            t.append(wannWahl == .eingang ? "Ohne Datum (Eingang)" : "\(wannWahl == .datum ? datum.formatted(.dateTime.day().month(.wide).locale(Locale(identifier: "de_DE"))) : wannWahl.rawValue)" + (mitUhrzeit ? " · \(Tagesplan.uhr(uhrzeit)) · \(dauerText(dauer))" : ""))
            if wichtig { t.append("Wichtig") }
            if wiederholung != .nie { t.append("Wiederholt sich \(wiederholung.name.lowercased())") }
        case .termin:
            t.append("\(datum.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "de_DE")))) · \(Tagesplan.uhr(terminStart))–\(Tagesplan.uhr(terminEnde))")
            if wiederholung != .nie { t.append("Wiederholt sich \(wiederholung.name.lowercased())") }
            if let g = z.ziel(zielID) { t.append(terminSchritt.map { "Zählt in „\($0.titel)“" } ?? "Einsatz für „\(g.titel)“") }
            if let h = z.habit(terminHabitID) { t.append("Erfüllt „\(h.titel)“") }
        case .habit:
            t.append(mitMenge ? "\(Zahl.text(menge, stellen: 1)) \(habitEinheit.name) · \(rhythmusText)" : rhythmusText)
            if let u = habitUhrzeit { t.append("Im Kalender um \(Tagesplan.uhr(u))") }
            if let e = erinnerung { t.append("Erinnerung \(Tagesplan.uhr(e))") }
            if zielID != nil { t.append(alsMeilenstein ? "Zählt als Meilenstein" : "Nur Einsatz fürs Ziel") }
            if !nachgetragen.isEmpty { t.append("\(nachgetragen.count) Tag\(nachgetragen.count == 1 ? "" : "e") nachgetragen") }
            if let id = erfuelltDurch, let et = z.eigeneTermine.first(where: { $0.id == id }) { t.append("Erfüllt durch „\(et.titel)“") }
        case .ziel:
            t.append("Bis \(faellig.formatted(.dateTime.day().month(.wide).year().locale(Locale(identifier: "de_DE"))))")
            if let g = gewaehlteVorlage { t.append(g.kurz) }
            let extra = zaehlenHabits.count + zaehlenSerien.count + (zaehlenAufgaben.isEmpty ? 0 : 1)
            if extra > 0 { t.append("+ \(extra) Meilenstein\(extra == 1 ? "" : "e") aus Bestehendem" + (mitBisherigen ? ", Bisheriges zählt mit" : "")) }
            if !warum.trimmingCharacters(in: .whitespaces).isEmpty { t.append("Warum: \(warum.trimmingCharacters(in: .whitespaces))") }
        case nil: break
        }
        if let g = z.ziel(zielID), art != .ziel { t.append("Ziel: \(g.titel)") }
        if let k = kategorie, zielID == nil, art != .ziel, art != .habit { t.append("Kategorie: \(k.name)") }
        return t
    }

    private var rhythmusText: String {
        switch rhythmusArt {
        case .taeglich: "täglich"
        case .werktags: "werktags"
        case .tage: tage.sorted().map { namen[$0 - 1] }.joined(separator: ", ")
        case .proWoche: "\(proWoche)× pro Woche"
        }
    }

    // MARK: Bausteine

    private struct Karte<Inhalt: View>: View {
        @ViewBuilder var inhalt: Inhalt
        var body: some View {
            VStack(alignment: .leading, spacing: 12) { inhalt }
                .padding(16).frame(maxWidth: .infinity, alignment: .leading)
                .background(Farbe.karte, in: RoundedRectangle(cornerRadius: Mass.karte, style: .continuous))
        }
    }

    private struct Vorschlagskarte: View {
        var text: String
        var an: Bool
        var aktion: () -> Void
        var body: some View {
            Button(action: aktion) {
                HStack(spacing: 12) {
                    AssistentZeichen(groesse: 32)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Vorschlag").font(.klein).foregroundStyle(Farbe.zweitrangig)
                        Text(text).font(.zeile).foregroundStyle(Farbe.text)
                    }
                    Spacer()
                    Image(systemName: an ? "checkmark.circle.fill" : "plus.circle").font(.title3).foregroundStyle(an ? Farbe.freude : Farbe.akzent)
                }
                .padding(14)
                .background(Farbe.karte, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(an ? Farbe.freude : Farbe.akzentWeich, lineWidth: 1.5))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Vorschlag übernehmen: \(text)")
        }
    }

    private func zahlFeld(_ titel: String, wert: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(titel).font(.klein).foregroundStyle(Farbe.zweitrangig)
            TextField("0", value: wert, format: .number.locale(Locale(identifier: "de_DE"))).keyboardType(.decimalPad)
                .font(.kompass(.title3, .bold)).padding(8).background(Farbe.grund, in: RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: Vorschläge und Vorlagen

    private var vorschlag: HabitVorschlag.Vorschlag { HabitVorschlag.fuer(titel) }
    private var vorlagen: [ZielVorschlag.Vorlage] { ZielVorschlag.fuer(titel) }
    private var gewaehlteVorlage: ZielVorschlag.Vorlage? { vorlage.flatMap { $0 < vorlagen.count ? vorlagen[$0] : nil } }
    private var zahlSchritt: Kompass.Schritt? { gewaehlteVorlage?.schritte.first { $0.art == .zahl } }

    private func vorschlagUebernehmen(_ v: HabitVorschlag.Vorschlag) {
        vorschlagGenutzt = true
        symbol = v.symbol
        if v.nurAbhaken { mitMenge = false; return }
        mitMenge = true
        if let m = v.menge { menge = m }
        if let e = v.einheit { habitEinheit = e }
    }

    private func zahlAnfassen(_ zs: Kompass.Schritt) {
        guard !zahlAngefasst else { return }
        zahlAngefasst = true
        start = zs.start ?? 0; zielwert = zs.soll ?? 100; einheit = zs.einheit ?? ""
    }

    private func uhr(_ m: Int) -> Date { Calendar.kompass.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: m / 60, minute: m % 60)) ?? Date() }
    private func minuten(_ d: Date) -> Int { let k = Calendar.kompass.dateComponents([.hour, .minute], from: d); return (k.hour ?? 0) * 60 + (k.minute ?? 0) }
    private func dauerText(_ m: Int) -> String { m < 60 ? "\(m) Min" : m % 60 == 0 ? "\(m / 60) h" : "1,5 h" }

    private var habitRhythmus: Rhythmus {
        switch rhythmusArt {
        case .taeglich: .taeglich
        case .werktags: .wochentage([1, 2, 3, 4, 5])
        case .tage: .aus(tagen: tage)
        case .proWoche: .proWoche(proWoche)
        }
    }

    private var platzhalter: String {
        switch art {
        case .termin: "z. B. Fahrstunde"
        case .aufgabe: "z. B. Flugschule anrufen"
        case .habit: "z. B. 20 Minuten lesen"
        case .ziel: "z. B. Halbmarathon laufen"
        case nil: ""
        }
    }

    // MARK: Anlegen

    private func anlegen() {
        let t = titel.trimmingCharacters(in: .whitespaces)
        let k = speicher.kalender
        let heute = speicher.heute
        switch art {
        case .aufgabe:
            let tag: Tag? = switch wannWahl {
            case .heute: heute
            case .morgen: heute.plus(tage: 1)
            case .datum: Tag(datum, kalender: k)
            case .eingang: nil
            }
            let w = wiederholung, z = zielID, p: Prioritaet = wichtig ? .hoch : .normal
            let u = tag != nil && mitUhrzeit ? uhrzeit : nil, du = dauer, kat = kategorie
            speicher.aendern { s in
                let a = s.aufgabeAnlegen(t, datum: tag, prio: p, zielID: z, heute: heute)
                if let i = s.aufgaben.firstIndex(where: { $0.id == a.id }) {
                    s.aufgaben[i].wiederholung = w; s.aufgaben[i].uhrzeit = u; s.aufgaben[i].dauer = du; s.aufgaben[i].kategorie = kat
                }
            }
        case .termin:
            let g = speicher.zustand.ziel(zielID)
            let schritt = terminSchritt
            let neu = EigenerTermin(titel: t, tag: Tag(datum, kalender: k), start: terminStart, ende: terminEnde, kategorie: kategorie,
                                    zielID: g?.id, schrittID: schritt?.id, habitID: terminHabitID, wiederholung: wiederholung)
            speicher.aendern { $0.terminSpeichern(neu) }
        case .habit:
            let farbe = Farbe.ziele[speicher.zustand.habits.count % Farbe.ziele.count]
            let v = vorschlag
            var h = Habit(titel: t, farbe: farbe, symbol: vorschlagGenutzt ? symbol : (v.symbol == "star.fill" ? "star.fill" : v.symbol),
                          rhythmus: habitRhythmus, menge: mitMenge ? menge : nil, einheit: mitMenge ? habitEinheit : nil,
                          erinnerung: erinnerung, zielID: zielID, angelegt: heute)
            h.uhrzeit = habitUhrzeit
            let tageZurueck = nachgetragen.sorted()
            if let weitest = tageZurueck.last { h.angelegt = heute.plus(tage: -weitest) }
            let ziel = speicher.zustand.ziel(zielID)
            let meilenstein: Kompass.Schritt? = (ziel != nil && alsMeilenstein) ? {
                let soll = MeilensteinQuelle.habitSollBisFrist(h, ab: heute, bis: ziel!.faellig) + Double(tageZurueck.count)
                return Kompass.Schritt(titel: t, art: .habit, seit: h.angelegt, soll: soll, habitID: h.id)
            }() : nil
            let termin = erfuelltDurch
            let speichern: (inout Zustand) -> Void = { s in
                s.habits.append(h)
                for k in tageZurueck { s.habitUmschalten(h.id, am: heute.plus(tage: -k)) }
                if let m = meilenstein, let zid = ziel?.id { s.schrittSpeichern(m, ziel: zid) }
                if let tid = termin, let i = s.eigeneTermine.firstIndex(where: { $0.id == tid }) { s.eigeneTermine[i].habitID = h.id }
            }
            if h.erinnerung != nil {
                Task { await Erinnerungen.aktiv.erlaubnis(); speicher.aendern(speichern) }
            } else {
                speicher.aendern(speichern)
            }
        case .ziel:
            let farbe = Farbe.ziele[speicher.zustand.ziele.count % Farbe.ziele.count]
            let vl = gewaehlteVorlage
            var g = Ziel(titel: t, farbe: farbe, symbol: vl?.symbol ?? "target", bereich: zielBereich ?? vl?.bereich ?? "Allgemein", faellig: Tag(faellig, kalender: k), angelegt: heute)
            g.schritte = (vl?.schritte ?? []).map { s in
                var s = s
                if s.art == .zahl {
                    if zahlAngefasst { s.start = start; s.soll = zielwert; s.einheit = einheit.isEmpty ? nil : einheit }
                    s.aktuell = s.start
                    s.verlauf = s.start.map { [VerlaufPunkt(tag: heute, wert: $0)] }
                }
                if s.art == .habit { s.seit = heute }
                return s
            }
            g.warum = warum.trimmingCharacters(in: .whitespaces)
            // Was schon dafür zählt (rechenregeln.md §3 „Meilenstein aus Bestehendem“)
            let z = speicher.zustand
            let mit = mitBisherigen
            let fristTag = Tag(faellig, kalender: k)
            for hid in zaehlenHabits {
                guard let h = z.habit(hid) else { continue }
                let bisher = mit ? MeilensteinQuelle.habitBisher(h, modus: .anzahl, heute: heute) : 0
                g.schritte.append(Kompass.Schritt(titel: h.titel, art: .habit, seit: mit ? h.angelegt : heute,
                                                  soll: MeilensteinQuelle.habitSollBisFrist(h, ab: heute, bis: fristTag) + bisher, habitID: h.id))
            }
            let serien = MeilensteinQuelle.serien(zustand: z, ziel: UUID(), heute: heute, jetzt: speicher.jetztMinuten, termine: speicher.termine(am:))
                .filter { zaehlenSerien.contains($0.id) }
            var verknuepfungen: [(MeilensteinQuelle.Serie, UUID, Tag)] = []
            for sr in serien {
                let sch = Kompass.Schritt(titel: sr.titel, art: .zahl, soll: Double(max(1, (mit ? sr.bisher : 0) + sr.kommend)), start: 0, aktuell: 0, einheit: "Termine")
                g.schritte.append(sch)
                verknuepfungen.append((sr, sch.id, mit ? (sr.erster ?? heute) : heute))
            }
            let aufgabenIDs = zaehlenAufgaben
            var aufgabenSchritt: Kompass.Schritt?
            if !aufgabenIDs.isEmpty {
                let erledigt = aufgabenIDs.allSatisfy { id in z.aufgaben.first { $0.id == id }?.erledigt == true }
                aufgabenSchritt = Kompass.Schritt(titel: aufgabenIDs.count == 1 ? (z.aufgaben.first { $0.id == aufgabenIDs.first! }?.titel ?? "Aufgabe") : "Aufgaben erledigen",
                                                  art: .aufgaben, geschafft: erledigt)
                g.schritte.append(aufgabenSchritt!)
            }
            let gid = g.id
            speicher.aendern { s in
                s.ziele.append(g)
                for hid in zaehlenHabits { if let i = s.habits.firstIndex(where: { $0.id == hid }), s.habits[i].zielID == nil { s.habits[i].zielID = gid } }
                for (sr, sid, seit) in verknuepfungen { s.terminVerknuepfen(serie: sr.id, titel: sr.titel, ziel: gid, schritt: sid, seit: seit) }
                if let a = aufgabenSchritt { for id in aufgabenIDs { s.aufgabeZuordnen(id, ziel: gid, schritt: a.id, automatisch: false, heute: heute) } }
            }
        case nil: break
        }
        dismiss()
    }
}

extension NeuArt {
    var name: String {
        switch self {
        case .aufgabe: "Aufgabe"
        case .termin: "Termin"
        case .habit: "Habit"
        case .ziel: "Ziel"
        }
    }
    var symbol: String {
        switch self {
        case .aufgabe: "checkmark.circle"
        case .termin: "calendar"
        case .habit: "repeat"
        case .ziel: "target"
        }
    }
    var erklaerung: String {
        switch self {
        case .aufgabe: "Einmal erledigen"
        case .termin: "Feste Zeit im Kalender"
        case .habit: "Regelmäßig tun"
        case .ziel: "Wohin du willst"
        }
    }
    var verlauf: [Color] {
        switch self {
        case .aufgabe: Farbe.indigo
        case .termin: [Color(roh: "#0E1A2F"), Color(roh: "#1F4560")]
        case .habit: Farbe.violett
        case .ziel: Farbe.gruen
        }
    }
}

/// Aufgabe bearbeiten: Titel, Datum, Wichtig, Wiederholung, Ziel, Notizen; Löschen (nur diese / Serie beenden).
struct AufgabeBlatt: View {
    var id: UUID
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav
    @Environment(\.dismiss) private var dismiss

    /// Welcher Meilenstein zählt die Aufgabe (§3): „Aufgaben“ zählt erledigte einmalige, „Zeit“ die Fokuszeit.
    /// Ohne passenden Meilenstein zählt sie nur als Einsatz – das wird gesagt, nicht verschwiegen.
    @ViewBuilder private func meilensteinWahl(_ a: Aufgabe, _ g: Ziel) -> some View {
        let passend = g.schritte.filter { $0.art == .aufgaben || $0.art == .zeit }
        if !passend.isEmpty {
            Picker("Zählt in", selection: Binding(get: { a.schrittID }, set: { neu in
                let h = speicher.heute
                speicher.aendern { $0.aufgabeZuordnen(id, ziel: g.id, schritt: neu, automatisch: false, heute: h) }
            })) {
                Text("Nur Einsatz").tag(UUID?.none)
                ForEach(passend) { s in Text("\(s.titel) · \(s.art == .zeit ? "Fokuszeit" : "erledigt")").tag(UUID?.some(s.id)) }
            }
            .accessibilityIdentifier("aufgabe.meilenstein")
        }
        let s = g.schritte.first { $0.id == a.schrittID }
        if s == nil {
            VStack(alignment: .leading, spacing: 6) {
                Label("Zählt nicht in die Prozente, nur als Einsatz.", systemImage: "info.circle")
                    .font(.footnote).foregroundStyle(Farbe.zweitrangig)
                if passend.isEmpty {
                    Button("Meilenstein „Aufgaben“ anlegen") { nav.blatt = .meilenstein(ziel: g.id, schritt: nil) }
                        .font(.footnote.weight(.semibold))
                }
            }
        } else if s?.art == .aufgaben && !a.einmalig {
            Label("Wiederkehrende Aufgaben zählen hier nicht – nur einmalige.", systemImage: "info.circle")
                .font(.footnote).foregroundStyle(Farbe.zweitrangig)
        }
    }

    var body: some View {
        NavigationStack {
            if let a = speicher.zustand.aufgabe(id) {
                Form {
                    Section {
                        TextField("Titel", text: feld(\.titel))
                        Toggle("Erledigt", isOn: Binding(get: { a.erledigt }, set: { _ in speicher.aendern { $0.umschalten(id, jetzt: speicher.jetzt()) } }))
                        Toggle("Wichtig", isOn: Binding(get: { a.prio == .hoch }, set: { neu in speicher.aendern { s in setze(&s) { $0.prio = neu ? .hoch : .normal } } }))
                    }
                    Section {
                        Toggle("Mit Datum", isOn: Binding(get: { a.datum != nil }, set: { neu in
                            let h = speicher.heute
                            speicher.aendern { s in setze(&s) { $0.datum = neu ? h : nil } }
                        }))
                        if let d = a.datum {
                            DatePicker("Datum", selection: Binding(get: { d.datum() }, set: { neu in
                                let t = Tag(neu, kalender: speicher.kalender)
                                speicher.aendern { s in setze(&s) { $0.datum = t } }
                            }), displayedComponents: .date)
                            Toggle("Mit Uhrzeit", isOn: Binding(get: { a.uhrzeit != nil }, set: { neu in
                                speicher.aendern { s in setze(&s) { $0.uhrzeit = neu ? 9 * 60 : nil } }
                            }))
                            if let u = a.uhrzeit {
                                DatePicker("Uhrzeit", selection: Binding(get: { Calendar.kompass.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: u / 60, minute: u % 60)) ?? Date() }, set: { neu in
                                    let k = Calendar.kompass.dateComponents([.hour, .minute], from: neu)
                                    let m = (k.hour ?? 0) * 60 + (k.minute ?? 0)
                                    speicher.aendern { s in setze(&s) { $0.uhrzeit = m } }
                                }), displayedComponents: .hourAndMinute)
                                ChipReihe(titel: "Dauer", auswahl: [15, 30, 60, 90, 120].map { ($0 < 60 ? "\($0) Min" : $0 % 60 == 0 ? "\($0 / 60) h" : "1,5 h", $0 == a.dauer) }) { i in
                                    let du = [15, 30, 60, 90, 120][i]
                                    speicher.aendern { s in setze(&s) { $0.dauer = du } }
                                }
                            }
                        }
                        Picker("Wiederholen", selection: feld(\.wiederholung)) {
                            ForEach(Wiederholung.allCases, id: \.self) { Text($0.name).tag($0) }
                        }
                        Picker("Ziel", selection: Binding(get: { a.zielID }, set: { neu in
                            let h = speicher.heute
                            speicher.aendern { s in
                                let schritt = Fortschritt.naechsterOffenerSchritt(s.ziel(neu), in: s, heute: h)?.id
                                setze(&s) { $0.zielID = neu; $0.schrittID = schritt }
                            }
                        })) {
                            Text("Keins").tag(UUID?.none)
                            ForEach(speicher.zustand.ziele) { Text($0.titel).tag(UUID?.some($0.id)) }
                        }
                        if let g = speicher.zustand.ziel(a.zielID) {
                            meilensteinWahl(a, g)
                        }
                        ChipReihe(titel: "Kategorie", auswahl: Kategorie.allCases.map { ($0.name, $0 == a.kategorie) }) { i in
                            let k = Kategorie.allCases[i]
                            speicher.aendern { s in setze(&s) { $0.kategorie = $0.kategorie == k ? nil : k } }
                        }
                        if a.fokusSekunden > 0 { LabeledContent("Fokuszeit", value: Zahl.dauer(a.fokusSekunden)) }
                    }
                    Section("Notizen") { TextField("Notizen", text: feld(\.notizen), axis: .vertical) }
                    Section {
                        Button("Löschen", role: .destructive) {
                            speicher.aendern { $0.loeschen(id, heute: speicher.heute) }
                            dismiss()
                        }
                        if !a.einmalig {
                            Button("Serie beenden", role: .destructive) {
                                speicher.aendern { $0.loeschen(id, serieBeenden: true, heute: speicher.heute) }
                                dismiss()
                            }
                        }
                    }
                }
                .navigationTitle("Aufgabe")
                .navigationBarTitleDisplayMode(.inline)
                .schliessenKnopf()
            } else {
                ContentUnavailableView("Aufgabe nicht gefunden", systemImage: "checklist", description: Text("Sie wurde vielleicht gelöscht."))
            }
        }
    }

    private func setze(_ s: inout Zustand, _ f: (inout Aufgabe) -> Void) {
        if let i = s.aufgaben.firstIndex(where: { $0.id == id }) { f(&s.aufgaben[i]) }
    }

    private func feld<W>(_ pfad: WritableKeyPath<Aufgabe, W>) -> Binding<W> {
        Binding(
            get: { speicher.zustand.aufgabe(id)![keyPath: pfad] },
            set: { neu in speicher.aendern { s in if let i = s.aufgaben.firstIndex(where: { $0.id == id }) { s.aufgaben[i][keyPath: pfad] = neu } } }
        )
    }
}


/// Auswahl als Chips in einer Zeile (umbrechend) – wie „How often“ in Gapless statt Picker-Rad.
struct ChipReihe: View {
    var titel: String
    /// (Text, gewählt)
    var auswahl: [(String, Bool)]
    var waehlen: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(titel).font(.unterzeile).foregroundStyle(Farbe.zweitrangig)
            FliessLayout(abstand: 8) {
                ForEach(Array(auswahl.enumerated()), id: \.offset) { i, a in
                    Button { waehlen(i) } label: {
                        Text(a.0).font(.kompass(.subheadline, .semibold))
                            .padding(.horizontal, 12).frame(minHeight: 36)
                            .background(a.1 ? Farbe.akzent : Farbe.akzentWeich, in: Capsule())
                            .foregroundStyle(a.1 ? .white : Farbe.akzent)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(a.1 ? .isSelected : [])
                }
            }
        }
        .padding(.vertical, 4)
    }
}

/// Einfaches umbrechendes Layout für Chips.
struct FliessLayout: Layout {
    var abstand: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let breite = proposal.width ?? 320
        var x: CGFloat = 0, y: CGFloat = 0, zeile: CGFloat = 0
        for s in subviews {
            let g = s.sizeThatFits(.unspecified)
            if x > 0, x + g.width > breite { x = 0; y += zeile + abstand; zeile = 0 }
            x += g.width + abstand
            zeile = max(zeile, g.height)
        }
        return CGSize(width: breite, height: y + zeile)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, zeile: CGFloat = 0
        for s in subviews {
            let g = s.sizeThatFits(.unspecified)
            if x > bounds.minX, x + g.width > bounds.maxX { x = bounds.minX; y += zeile + abstand; zeile = 0 }
            s.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(g))
            x += g.width + abstand
            zeile = max(zeile, g.height)
        }
    }
}
