import SwiftUI

/// Ziel im Detail – minimal und geführt: oben, wie weit du bist (Analyse im Rückblick), darunter die wichtigsten
/// Einstellungen als Kacheln (Bis wann · Warum · Name · Verfeinern), darunter die Meilensteine mit ihrem Anteil am Ziel.
struct ZielDetail: View {
    var id: UUID
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav

    var body: some View {
        let z = speicher.zustand
        if let g = z.ziel(id) {
            let T = speicher.heute
            let kurs = Kurs.aufKurs(g, in: z, heute: T)
            let naechster = Fortschritt.naechsterSchritt(g, in: z, heute: T)
            BuehnenSeite(wort: Self.wort(g, kurs: kurs), marke: {
                ZurueckKnopf()
                MarkenTitel(text: g.titel)
                Spacer(minLength: 8)
                RahmenKnopf(symbol: "info", beschriftung: "So wird gerechnet") { nav.blatt = .rechnung(g.id) }
            }) {
                VornKarte {
                    Etikett(text: g.status == .erreicht ? "Geschafft" : "Dein nächster Schritt")
                    Text(g.status == .erreicht ? "Dieses Ziel ist erreicht." : (naechster.map { $0.aufgabe?.titel ?? $0.schritt.titel } ?? "Meilenstein wählen"))
                        .font(.karteTitel).foregroundStyle(Farbe.text).fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 8) {
                        if let a = naechster?.aufgabe {
                            Button { nav.blatt = .fokus(a.id) } label: { Label("Fokus starten", systemImage: "play.fill") }.buttonStyle(.haupt)
                        } else if let s = naechster?.schritt {
                            Button { nav.blatt = .meilenstein(ziel: g.id, schritt: s.id) } label: { Label("Öffnen", systemImage: "flag.fill") }.buttonStyle(.haupt)
                        } else if g.status != .erreicht {
                            Button { nav.blatt = .meilenstein(ziel: g.id, schritt: nil) } label: { Label("Meilenstein anlegen", systemImage: "plus") }.buttonStyle(.haupt)
                        }
                        Button { nav.zeigeAnalyse(ziel: g.id) } label: { Label("Analyse", systemImage: "chart.line.uptrend.xyaxis") }.buttonStyle(.leise)
                    }
                    .padding(.top, 4)
                    Text(Kurs.bisText(g.faellig, heute: T) + (g.warum.isEmpty ? "" : " · \(g.warum)"))
                        .font(.klein).foregroundStyle(Farbe.zweitrangig).lineLimit(2)
                }

                VStack(alignment: .leading, spacing: 12) {
                    MeilensteinListe(ziel: g)
                    // Alles Weitere liegt hinter einer Zeile (Hick): Frist, Warum, Name, Aufgaben, Habits, Termine
                    NavigationLink(value: ZielTeilAuswahl(id: g.id, teil: .verfeinern)) {
                        HStack(spacing: 12) {
                            ZeichenKreis(symbol: "slider.horizontal.3")
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Verfeinern").font(.zeile).foregroundStyle(Farbe.text)
                                Text("Frist · Warum · Name · Verbundenes").font(.klein).foregroundStyle(Farbe.zweitrangig)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.footnote.weight(.bold)).foregroundStyle(Farbe.pfeil)
                        }
                        .padding(.horizontal, 16).frame(minHeight: Mass.zeile)
                        .background(Farbe.karte, in: RoundedRectangle(cornerRadius: Mass.karte, style: .continuous))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("ziel.verfeinern")
                    .padding(.top, 8)
                }
                .padding(.horizontal, Mass.rand).padding(.top, 12)
            }
        } else {
            ContentUnavailableView("Ziel nicht gefunden", systemImage: "target", description: Text("Es wurde vielleicht gelöscht."))
                .background(Farbe.grund.ignoresSafeArea())
        }
    }

    /// Das Wort: Prozent und Lage (§4), darunter der Zieltitel.
    nonisolated static func wort(_ g: Ziel, kurs: Kurs.Ergebnis) -> Wort {
        // Lange Lagen („hinterher“, „überfällig“) passen in voller Größe nicht in die Zeile
        Wort(zeilen: [Zahl.prozent(kurs.fortschritt)], akzent: kurs.lage.text + ".", groesse: kurs.lage.text.count > 8 ? 64 : Wort.riesig)
    }

}

// MARK: Verfeinern – alles Weitere auf eigenen Seiten

/// Teile der Ziel-Seite, die nur bei Bedarf geöffnet werden.
enum ZielTeil: String, Hashable, CaseIterable {
    case verfeinern, aufgaben, habits, termine, einsatz, details

    /// Die Teile, die unter „Verfeinern“ als Zeilen stehen
    static let mehr: [ZielTeil] = [.aufgaben, .habits, .termine, .einsatz, .details]

    var titel: String {
        switch self {
        case .verfeinern: "Verfeinern"
        case .aufgaben: "Aufgaben"
        case .habits: "Habits"
        case .termine: "Termine"
        case .einsatz: "Einsatz"
        case .details: "Details"
        }
    }
    var symbol: String {
        switch self {
        case .verfeinern: "slider.horizontal.3"
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
        case .verfeinern: "Alles rund um dein Ziel. Die Meilensteine änderst du direkt auf der Ziel-Seite."
        case .aufgaben: "Zählen in den nächsten offenen Meilenstein – sonst als Einsatz."
        case .habits: "Zählt in die Prozente, wenn ein Meilenstein den Habit misst – sonst als Einsatz."
        case .termine: "Jeder stattgefundene Termin zählt in einen Meilenstein – sonst als Einsatz."
        case .einsatz: "Fokuszeit und Termine für dieses Ziel. Die Prozente ändert das nicht."
        case .details: "Name, Frist, Bereich, Warum und Aussehen – antippen zum Ändern."
        }
    }
}

/// Für NavigationLink(value:) auf einen Teil eines Ziels
struct ZielTeilAuswahl: Hashable { var id: UUID; var teil: ZielTeil }

/// Verfeinern: alles rund ums Ziel außer den Meilensteinen (die stehen auf der Ziel-Seite) – als Kacheln.
private struct VerfeinernInhalt: View {
    var ziel: Ziel
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav

    var body: some View {
        let c = Color(hex: ziel.farbe)
        let erreicht = ziel.status == .erreicht
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ForEach([ZielTeil.aufgaben, .habits, .termine, .einsatz, .details], id: \.self) { t in
                NavigationLink(value: ZielTeilAuswahl(id: ziel.id, teil: t)) {
                    EinstellKachelInhalt(symbol: t.symbol, titel: t.titel, wert: wert(t), unter: unter(t), farbe: c, verlauf: true)
                        .frame(minHeight: 132)
                }
                .buttonStyle(DruckStil())
            }
            Button {
                let zid = ziel.id, neu: ZielStatus = erreicht ? .aktiv : .erreicht
                speicher.aendern { s in if let i = s.ziele.firstIndex(where: { $0.id == zid }) { s.ziele[i].status = neu } }
            } label: {
                EinstellKachelInhalt(symbol: erreicht ? "arrow.uturn.backward" : "flag.checkered", titel: erreicht ? "Erreicht" : "Geschafft?",
                                     wert: erreicht ? "Wieder aktiv setzen" : "Als erreicht markieren", unter: nil,
                                     farbe: erreicht ? Farbe.freude : c, verlauf: true)
                    .frame(minHeight: 132)
            }
            .buttonStyle(DruckStil())
            .accessibilityIdentifier("ziel.erreicht")
        }
        .padding(.top, 16)
    }

    private func unter(_ t: ZielTeil) -> String? {
        switch t {
        case .einsatz: "diese Woche"
        case .details: "Aussehen, löschen"
        default: nil
        }
    }

    private func wert(_ t: ZielTeil) -> String {
        let z = speicher.zustand, T = speicher.heute
        switch t {
        case .verfeinern: return ""
        case .aufgaben:
            let offen = z.aufgaben.filter { $0.zielID == ziel.id && !$0.erledigt }.count
            return offen == 0 ? "keine offen" : "\(offen) offen"
        case .habits:
            let n = z.habits.filter { h in h.zielID == ziel.id || ziel.schritte.contains { $0.habitID == h.id } }.count
            return n == 0 ? "keine" : "\(n)"
        case .termine:
            let n = z.termine.filter { $0.zielID == ziel.id }.count
            return n == 0 ? "keine" : "\(n) Serie\(n == 1 ? "" : "n")"
        case .einsatz: return Zahl.dauer(Fortschritt.zeit(ziel: ziel.id, in: z, von: T.montag, bis: T))
        case .details: return "Name, Frist, Bereich"
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
                    if teil != .verfeinern && teil != .details {
                    HStack(alignment: .center, spacing: 12) {
                        Image(systemName: teil.symbol).font(.system(size: 16, weight: .bold)).foregroundStyle(Farbe.aufTon)
                            .frame(width: 40, height: 40).background(Color(hex: g.farbe).gradient, in: Circle())
                        Text(teil.erklaerung).font(.unterzeile).foregroundStyle(Farbe.text.opacity(0.8)).fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(LinearGradient(colors: [Farbe.karte, Color(hex: g.farbe).opacity(0.14)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        }
                    switch teil {
                    case .verfeinern: VerfeinernInhalt(ziel: g)
                    case .aufgaben: ZielAufgaben(ziel: g)
                    case .habits: ZielHabits(ziel: g).padding(.top, 16)
                    case .termine: ZielTermine(ziel: g).padding(.top, 16)
                    case .einsatz: ZielEinsatz(ziel: g).padding(.top, 16)
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
        let c = Color(hex: g.farbe)
        let de = Locale(identifier: "de_DE")
        // Aussehen als Vorschau – so sieht das Ziel überall aus
        Button { nav.blatt = .zielBearbeiten(g.id, .aussehen) } label: {
            HStack(spacing: 14) {
                Image(systemName: g.symbol).font(.system(size: 22, weight: .bold)).foregroundStyle(Farbe.aufTon)
                    .frame(width: 56, height: 56).background(LinearGradient(colors: Farbe.verlauf(g.farbe), startPoint: .bottomTrailing, endPoint: .topLeading), in: Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text(g.titel).font(.kompass(.headline, .heavy)).foregroundStyle(Farbe.text).lineLimit(2)
                    Text("Aussehen ändern").font(.unterzeile).foregroundStyle(c)
                }
                Spacer()
                Image(systemName: "paintpalette.fill").foregroundStyle(c).frame(width: 34, height: 34).background(c.opacity(0.12), in: Circle())
            }
            .padding(16)
            .background(Farbe.karte, in: RoundedRectangle(cornerRadius: Mass.karte, style: .continuous))
        }
        .buttonStyle(DruckStil())
        .padding(.top, 16)

        AbschnittKopf(titel: "Worum es geht")
        GruppierteListe {
            FaktZeile("Name", wert: g.titel) { nav.blatt = .zielBearbeiten(g.id, .titel) }
            FaktZeile("Warum", wert: g.warum.isEmpty ? "–" : g.warum) { nav.blatt = .zielBearbeiten(g.id, .warum) }
            FaktZeile("Bereich", wert: g.bereich) { nav.blatt = .zielBearbeiten(g.id, .bereich) }
        }

        AbschnittKopf(titel: "Zeitraum")
        GruppierteListe {
            FaktZeile("Bis wann", wert: g.faellig.datum().formatted(.dateTime.day().month(.wide).year().locale(de))) { nav.blatt = .zielBearbeiten(g.id, .faellig) }
            HStack {
                Text("Angelegt").font(.zeile).foregroundStyle(Farbe.text)
                Spacer()
                Text(g.angelegt.datum().formatted(.dateTime.day().month(.wide).year().locale(de))).font(.zeile).foregroundStyle(Farbe.zweitrangig)
            }
            .padding(.horizontal, 16).frame(minHeight: Mass.zeileKompakt)
        }

        Button { loeschenFragen = true } label: {
            Label("Ziel löschen", systemImage: "trash").font(.zeile).foregroundStyle(Farbe.warnung).frame(maxWidth: .infinity, minHeight: 50)
                .background(Farbe.karte, in: RoundedRectangle(cornerRadius: Mass.karte, style: .continuous))
        }
        .padding(.top, Mass.abschnitt)
        Text("Aufgaben, Habits und Termine bleiben erhalten.").font(.klein).foregroundStyle(Farbe.zweitrangig)
            .frame(maxWidth: .infinity).padding(.top, 6)
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
    @Environment(Navigation.self) private var nav

    var body: some View {
        AbschnittKopf(titel: "Meilensteine") {
            Button { nav.blatt = .rechnung(ziel.id) } label: { Image(systemName: "info.circle") }
                .accessibilityLabel("So wird gerechnet")
        }
        VStack(spacing: 10) {
            NeuerMeilensteinKnopf(ziel: ziel)
            if ziel.schritte.isEmpty {
                Text("Woran misst du das Ziel? Etwas Neues oder etwas, das du schon machst – Kompass fragt dich durch.")
                    .font(.unterzeile).foregroundStyle(Farbe.zweitrangig).frame(maxWidth: .infinity, alignment: .leading)
            }
            ForEach(ziel.schritte) { s in MeilensteinKarte(ziel: ziel, schritt: s) }
        }
    }
}

/// Ein Meilenstein als Karte: Ring mit Messart-Symbol, Titel, Stand, Anteil am Ziel (Chip), Fortschritt, Pfeil.
private struct MeilensteinKarte: View {
    var ziel: Ziel
    var schritt: Schritt
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav

    var body: some View {
        let z = speicher.zustand
        let T = speicher.heute
        let st = Fortschritt.stand(schritt, in: z, heute: T)
        let c = Color(hex: ziel.farbe)
        let anteil = Fortschritt.anteilVorschau(ziel, gewicht: st.gewicht, ersetzt: schritt.id)
        let fertig = st.anteil >= 1
        Button { nav.blatt = .meilenstein(ziel: ziel.id, schritt: schritt.id) } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(c.opacity(0.10))
                    if st.anteil > 0 {
                        Circle().trim(from: 0, to: st.anteil).stroke(fertig ? Farbe.freude : c, style: StrokeStyle(lineWidth: 4, lineCap: .round)).rotationEffect(.degrees(-90))
                    }
                    Image(systemName: fertig ? "checkmark" : schritt.art.symbol).font(.system(size: 16, weight: .bold)).foregroundStyle(fertig ? Farbe.freude : c)
                }
                .frame(width: 48, height: 48)
                VStack(alignment: .leading, spacing: 5) {
                    Text(schritt.titel).font(.zeile).foregroundStyle(Farbe.text).lineLimit(2).multilineTextAlignment(.leading)
                    Text(st.hinweis ?? st.text).font(.unterzeile).foregroundStyle(st.hinweis == nil ? Farbe.zweitrangig : Farbe.warnung).lineLimit(1)
                    Text("zählt \(Zahl.prozent(anteil))").font(.klein).foregroundStyle(c)
                        .padding(.horizontal, 8).frame(minHeight: 22).background(c.opacity(0.12), in: Capsule())
                }
                Spacer(minLength: 6)
                Text(Zahl.prozent(st.anteil)).font(.kompass(.headline, .heavy)).monospacedDigit().foregroundStyle(fertig ? Farbe.freude : Farbe.text)
                Image(systemName: "chevron.right").font(.footnote.weight(.heavy)).foregroundStyle(c)
                    .frame(width: 30, height: 30).background(c.opacity(0.12), in: Circle())
            }
            .padding(14)
            .background(Farbe.karte, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(c.opacity(0.16), lineWidth: 1))
            .shadow(color: c.opacity(0.08), radius: 8, y: 3)
        }
        .buttonStyle(DruckStil())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(schritt.titel), \(st.text), macht \(Zahl.prozent(anteil)) des Ziels aus")
        .accessibilityHint("Öffnet den Meilenstein")
        .accessibilityAddTraits(.isButton)
        .contextMenu {
            Button(schritt.geschafft ? "Wieder öffnen" : "Abhaken", systemImage: "checkmark") {
                speicher.aendern { $0.schrittUmschalten(ziel: ziel.id, schritt: schritt.id, heute: T) }
            }
            Button("Löschen", systemImage: "trash", role: .destructive) {
                speicher.aendern { $0.schrittLoeschen(ziel: ziel.id, schritt: schritt.id) }
            }
        }
    }
}

/// „+ Meilenstein“ als gestrichelte Karte – geführt anlegen.
private struct NeuerMeilensteinKnopf: View {
    var ziel: Ziel
    @Environment(Navigation.self) private var nav

    var body: some View {
        let c = Color(hex: ziel.farbe)
        Button { nav.blatt = .meilenstein(ziel: ziel.id, schritt: nil) } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus").font(.system(size: 15, weight: .heavy)).foregroundStyle(Farbe.aufTon)
                    .frame(width: 30, height: 30).background(c.gradient, in: Circle())
                VStack(alignment: .leading, spacing: 1) {
                    Text(ziel.schritte.isEmpty ? "Ersten Meilenstein anlegen" : "Meilenstein hinzufügen").font(.zeile).foregroundStyle(c)
                    Text("neu oder aus Aufgaben, Terminen, Habits").font(.klein).foregroundStyle(Farbe.zweitrangig)
                }
                Spacer()
            }
            .padding(14)
            .background(c.opacity(0.06), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(c.opacity(0.45), style: StrokeStyle(lineWidth: 1.5, dash: [6, 5])))
        }
        .buttonStyle(DruckStil())
        .accessibilityIdentifier("meilenstein.neu")
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
        AbschnittKopf(titel: "Offen") { Text("\(erledigt) erledigt").foregroundStyle(Farbe.zweitrangig) }
        GruppierteListe {
            ForEach(alle ? offen : Array(offen.prefix(5))) { a in
                AufgabeZeile(aufgabe: a, datumZeigen: true, zielZeigen: false)
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
