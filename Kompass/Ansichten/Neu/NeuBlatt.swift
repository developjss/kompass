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

    enum Schritt: Int, CaseIterable { case was, titel, wann, details, fertig }

    init(art: NeuArt?) {
        _art = State(initialValue: art)
        _schritt = State(initialValue: art == nil ? .was : .titel)
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

    private var schritte: [Schritt] { Schritt.allCases }
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
                        .foregroundStyle(.white)
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
        case .wann: schritt = .titel
        case .details: schritt = .wann
        case .fertig: schritt = .details
        }
    }

    private func weiter() {
        guard gueltig else { return }
        switch schritt {
        case .was: schritt = .titel
        case .titel: schritt = .wann
        case .wann: schritt = .details
        case .details: schritt = .fertig
        case .fertig: anlegen()
        }
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
        case .fertig: return true
        }
    }

    private var hinweisUnten: String {
        switch schritt {
        case .titel: return art == .habit ? "Aus dem Titel schlägt Kompass Menge und Einheit vor." : art == .ziel ? "Aus dem Titel kommen Meilenstein-Vorlagen." : "Kurz und klar – du kannst alles später ändern."
        case .wann: return art == .aufgabe ? "Ohne Uhrzeit schlägt der Kalender sie unter „Empfehlung“ vor – ziehbar in den Tag." : art == .habit ? "Mit fester Uhrzeit steht der Habit als Block im Kalender." : ""
        case .details: return "Alles hier ist optional."
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
            case .ziel: return "Meilensteine"
            case nil: return ""
            }
        case .fertig: return "Passt das so?"
        }
    }

    private var unterfrage: String? {
        switch (schritt, art) {
        case (.was, _): return "Eine Sache, ein Schritt nach dem anderen."
        case (.details, .habit): return "Halb geschafft zählt halb – zum Beispiel 10 von 20 Minuten."
        case (.details, .ziel): return gewaehlteVorlage.map { "Vorlage: \($0.kurz)" }
        case (.wann, .ziel): return "„Auf Kurs“ vergleicht den Fortschritt mit der Zeit bis dahin."
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
        if art == .aufgabe || art == .termin {
            let beispiele = art == .aufgabe ? ["Flugschule anrufen", "Paket zur Post", "Kapitel 4 lesen"] : ["Fahrstunde", "Zahnarzt", "Training"]
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
            zielKarte
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
        case nil: EmptyView()
        }
    }
    @State private var zielBereich: String?

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
            if let h = z.habit(terminHabitID) { t.append("Erfüllt „\(h.titel)“") }
        case .habit:
            t.append(mitMenge ? "\(Zahl.text(menge, stellen: 1)) \(habitEinheit.name) · \(rhythmusText)" : rhythmusText)
            if let u = habitUhrzeit { t.append("Im Kalender um \(Tagesplan.uhr(u))") }
            if let e = erinnerung { t.append("Erinnerung \(Tagesplan.uhr(e))") }
        case .ziel:
            t.append("Bis \(faellig.formatted(.dateTime.day().month(.wide).year().locale(Locale(identifier: "de_DE"))))")
            if let g = gewaehlteVorlage { t.append(g.kurz) }
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
            let schritt = g?.schritte.first { $0.art == .zeit || $0.art == .zahl }
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
            if h.erinnerung != nil {
                Task { await Erinnerungen.aktiv.erlaubnis(); speicher.aendern { $0.habits.append(h) } }
            } else {
                speicher.aendern { $0.habits.append(h) }
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
            speicher.aendern { $0.ziele.append(g) }
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
        case .termin: [Color(hex: "#0E5A8A"), Color(hex: "#2F8FD6")]
        case .habit: Farbe.violett
        case .ziel: Farbe.gruen
        }
    }
}

/// Aufgabe bearbeiten: Titel, Datum, Wichtig, Wiederholung, Ziel, Notizen; Löschen (nur diese / Serie beenden).
struct AufgabeBlatt: View {
    var id: UUID
    @Environment(Speicher.self) private var speicher
    @Environment(\.dismiss) private var dismiss

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
