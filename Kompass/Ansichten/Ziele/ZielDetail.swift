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
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ZielStandKarte(ziel: g)
                    WichtigsteEinstellungen(ziel: g)
                    MeilensteinListe(ziel: g)
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
}

// MARK: Stand – minimal

/// Wie weit du bist, in einem Blick: Ring, Prozent, Lage, Restzeit, was als Nächstes zählt. Die Analyse steht im Rückblick.
private struct ZielStandKarte: View {
    var ziel: Ziel
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav

    var body: some View {
        let z = speicher.zustand
        let T = speicher.heute
        let kurs = Kurs.aufKurs(ziel, in: z, heute: T)
        let naechster = Fortschritt.naechsterSchritt(ziel, in: z, heute: T)
        Verlaufskarte(farben: Farbe.verlauf(ziel.farbe)) {
            HStack(spacing: 16) {
                ZStack {
                    Circle().stroke(.white.opacity(0.25), lineWidth: 8)
                    Circle().trim(from: 0, to: max(0.001, kurs.fortschritt)).stroke(.white, style: StrokeStyle(lineWidth: 8, lineCap: .round)).rotationEffect(.degrees(-90))
                    Image(systemName: ziel.symbol).font(.system(size: 22, weight: .bold))
                }
                .frame(width: 78, height: 78)
                VStack(alignment: .leading, spacing: 2) {
                    Text(Zahl.prozent(kurs.fortschritt)).font(.grosseZahl).contentTransition(.numericText())
                    Text("\(kurs.lage.text.prefix(1).uppercased() + kurs.lage.text.dropFirst()) · \(Kurs.bisText(ziel.faellig, heute: T))")
                        .font(.unterzeile).opacity(0.92).lineLimit(2)
                }
                Spacer(minLength: 0)
                Button { nav.blatt = .rechnung(ziel.id) } label: { Image(systemName: "info.circle").font(.title3).opacity(0.85) }
                    .accessibilityLabel("So wird gerechnet")
            }
            if ziel.status == .erreicht {
                Text("Geschafft – dieses Ziel ist erreicht.").font(.unterzeile.weight(.semibold)).padding(.top, 10)
            } else if let n = naechster {
                Text("Als Nächstes: \(n.aufgabe?.titel ?? n.schritt.titel)").font(.unterzeile.weight(.semibold)).lineLimit(1).padding(.top, 10)
            }
            Button { nav.bereich = .rueckblick } label: {
                HStack(spacing: 6) {
                    Text("Analyse im Rückblick")
                    Image(systemName: "arrow.right")
                }
                .font(.kompass(.subheadline, .bold)).foregroundStyle(Color(hex: ziel.farbe))
                .padding(.horizontal, 14).frame(minHeight: 40)
                .background(.white, in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 12)
        }
    }
}

// MARK: Die wichtigsten Einstellungen

/// Vier Kacheln wie Konten-Kacheln in Gapless: Bis wann · Warum · Name · Verfeinern (hervorgehoben).
private struct WichtigsteEinstellungen: View {
    var ziel: Ziel
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav

    var body: some View {
        let T = speicher.heute
        let c = Color(hex: ziel.farbe)
        AbschnittKopf(titel: "Einstellungen")
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            EinstellKachel(symbol: "calendar", titel: "Bis wann", wert: ziel.faellig.datum().formatted(.dateTime.day().month(.abbreviated).year().locale(Locale(identifier: "de_DE"))),
                           unter: Kurs.bisText(ziel.faellig, heute: T), farbe: c) { nav.blatt = .zielBearbeiten(ziel.id, .faellig) }
            EinstellKachel(symbol: "heart.fill", titel: "Warum", wert: ziel.warum.isEmpty ? "Noch offen" : ziel.warum,
                           unter: ziel.warum.isEmpty ? "Hilft beim Dranbleiben" : nil, farbe: c, hinweis: ziel.warum.isEmpty) { nav.blatt = .zielBearbeiten(ziel.id, .warum) }
            EinstellKachel(symbol: "textformat", titel: "Name", wert: ziel.titel, unter: ziel.bereich, farbe: c) { nav.blatt = .zielBearbeiten(ziel.id, .titel) }
            NavigationLink(value: ZielTeilAuswahl(id: ziel.id, teil: .verfeinern)) {
                EinstellKachelInhalt(symbol: "slider.horizontal.3", titel: "Verfeinern", wert: "Aufgaben, Habits …", unter: "Termine, Details", farbe: c, hervor: true)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("ziel.verfeinern")
        }
    }
}

private struct EinstellKachel: View {
    var symbol: String
    var titel: String
    var wert: String
    var unter: String?
    var farbe: Color
    var hinweis = false
    var aktion: () -> Void
    var body: some View {
        Button(action: aktion) { EinstellKachelInhalt(symbol: symbol, titel: titel, wert: wert, unter: unter, farbe: farbe, hinweis: hinweis) }
            .buttonStyle(.plain)
    }
}

private struct EinstellKachelInhalt: View {
    var symbol: String
    var titel: String
    var wert: String
    var unter: String?
    var farbe: Color
    var hinweis = false
    var hervor = false
    /// Verlauf von Weiß zur Farbe (Kacheln unter „Verfeinern › Mehr“)
    var verlauf = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                Image(systemName: symbol).font(.system(size: 15, weight: .bold)).foregroundStyle(.white)
                    .frame(width: 36, height: 36).background(farbe.gradient, in: Circle())
                Spacer()
                if hinweis {
                    Image(systemName: "exclamationmark").font(.caption.weight(.heavy)).foregroundStyle(.white)
                        .frame(width: 22, height: 22).background(Farbe.warnung, in: Circle())
                }
            }
            Spacer(minLength: 6)
            Text(titel).font(.kompass(.subheadline, .heavy)).foregroundStyle(Farbe.text)
            Text(wert).font(.unterzeile).foregroundStyle(Farbe.text).lineLimit(1)
            if let unter { Text(unter).font(.klein).foregroundStyle(Farbe.zweitrangig).lineLimit(1) }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: verlauf ? 108 : 128, alignment: .topLeading)
        .background {
            if verlauf {
                LinearGradient(stops: [.init(color: Farbe.karte, location: 0.35), .init(color: farbe.opacity(0.22), location: 1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Farbe.karte)
            }
        }
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(hervor ? farbe : farbe.opacity(verlauf ? 0.15 : 0), lineWidth: hervor ? 2 : 1))
        .accessibilityElement(children: .combine)
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
        case .aufgaben: "Aufgaben mit diesem Ziel fallen in den nächsten offenen Meilenstein. Ohne passenden Meilenstein zählen sie als Einsatz."
        case .habits: "Ein Habit zählt in die Prozente, wenn ein Meilenstein ihn misst – sonst als Einsatz."
        case .termine: "Termin-Serien aus dem Kalender: jeder stattgefundene Termin zählt in einen Zahl- oder Zeit-Meilenstein oder als Einsatz."
        case .einsatz: "Fokuszeit und Termine für dieses Ziel. Einsatz zeigt, was du investierst – die Prozente ändert er nicht."
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
                    HStack(alignment: .center, spacing: 12) {
                        Image(systemName: teil.symbol).font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
                            .frame(width: 40, height: 40).background(Color(hex: g.farbe).gradient, in: Circle())
                        Text(teil.erklaerung).font(.unterzeile).foregroundStyle(Farbe.text.opacity(0.8)).fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(LinearGradient(colors: [Farbe.karte, Color(hex: g.farbe).opacity(0.14)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    switch teil {
                    case .verfeinern: VerfeinernInhalt(ziel: g)
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
        let c = Color(hex: g.farbe)
        let de = Locale(identifier: "de_DE")
        // Aussehen als Vorschau – so sieht das Ziel überall aus
        Button { nav.blatt = .zielBearbeiten(g.id, .aussehen) } label: {
            HStack(spacing: 14) {
                Image(systemName: g.symbol).font(.system(size: 22, weight: .bold)).foregroundStyle(.white)
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

        Button(role: .destructive) { loeschenFragen = true } label: {
            Label("Ziel löschen", systemImage: "trash").font(.zeile).frame(maxWidth: .infinity, minHeight: 50)
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
        if !ziel.schritte.isEmpty {
            Text("Antippen zum Ändern. Je wichtiger ein Meilenstein, desto mehr zählt er – Kompass rechnet neu, wenn einer dazukommt oder wegfällt.")
                .font(.unterzeile).foregroundStyle(Farbe.zweitrangig).fixedSize(horizontal: false, vertical: true).padding(.bottom, 10)
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
                Image(systemName: "plus").font(.system(size: 15, weight: .heavy)).foregroundStyle(.white)
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
