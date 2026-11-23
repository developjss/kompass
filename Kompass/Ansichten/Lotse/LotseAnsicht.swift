import SwiftUI

/// Der Assistent (Tab in der Mitte): leerer Chat mit KI-Zeichen und Vorschlägen; frühere Chats oben links; Eingabe mit „+“-Menü, Mikrofon und Senden.
struct LotseAnsicht: View {
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav
    @State private var eingabe = ""
    @State private var denkt = false
    @State private var menue = false
    @FocusState private var fokus: Bool

    var body: some View {
        let chat = speicher.zustand.chat
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                RunderKnopf(symbol: "clock.arrow.circlepath", beschriftung: "Frühere Chats") { nav.blatt = .chats }
                HStack(spacing: 8) {
                    AssistentZeichen(groesse: 30)
                    Text("Assistent").font(.kompass(.title2, .heavy)).foregroundStyle(Farbe.text).accessibilityAddTraits(.isHeader)
                }
                Spacer(minLength: 8)
                if !chat.isEmpty {
                    RunderKnopf(symbol: "square.and.pencil", beschriftung: "Neuer Chat") { Lotse.neuerChat(speicher: speicher) }
                }
                RunderKnopf(symbol: "info", beschriftung: "Erklärung") { nav.blatt = .info(.lotse) }
            }
            .padding(.horizontal, Mass.rand).padding(.top, 14)
            StatusPille().padding(.horizontal, Mass.rand).padding(.top, 10)

            if chat.isEmpty {
                Begruessung(frage: senden)
            } else {
                Verlauf(denkt: denkt)
            }
            Eingabe
        }
        .frame(maxWidth: 720)
        .frame(maxWidth: .infinity)
        .background(alignment: .top) {
            LinearGradient(stops: [.init(color: Farbe.grundOben, location: 0), .init(color: Farbe.grund, location: 0.64)], startPoint: .top, endPoint: .bottom)
                .frame(height: 420).ignoresSafeArea()
        }
        .background(Farbe.grund.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $menue) { PlusMenue(frage: senden) }
    }

    // MARK: Eingabe

    private var Eingabe: some View {
        let leer = eingabe.trimmingCharacters(in: .whitespaces).isEmpty
        return HStack(spacing: 8) {
            Button { menue = true } label: {
                Image(systemName: "plus").font(.body.weight(.semibold))
                    .frame(width: 44, height: 44).background(Farbe.karte, in: Circle()).foregroundStyle(Farbe.text)
            }
            .accessibilityLabel("Mehr: Aufgabe anlegen, Ziel besprechen, Woche planen")
            HStack(spacing: 4) {
                TextField("Frag den Assistenten …", text: $eingabe, axis: .vertical)
                    .lineLimit(1...4)
                    .font(.kompass(.body, .medium))
                    .focused($fokus)
                    .submitLabel(.send)
                    .onSubmit { senden(eingabe) }
                    // Mehrzeiliges Feld: die Senden-Taste der Tastatur fügt „\n“ ein → als Senden behandeln
                    .onChange(of: eingabe) { _, neu in
                        if neu.hasSuffix("\n") {
                            let text = String(neu.dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
                            if text.isEmpty { eingabe = "" } else { senden(text) }
                        }
                    }
                if leer {
                    Button { fokus = true } label: {
                        Image(systemName: "mic").frame(width: 40, height: 40).foregroundStyle(Farbe.zweitrangig)
                    }
                    .accessibilityLabel("Diktieren (Mikrofon-Taste der Tastatur)")
                } else {
                    Button { senden(eingabe) } label: {
                        Image(systemName: "arrow.up").font(.body.weight(.bold))
                            .frame(width: 34, height: 34).background(Farbe.akzent, in: Circle()).foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                    }
                    .disabled(denkt)
                    .accessibilityLabel("Senden")
                    .accessibilityIdentifier("lotse.senden")
                }
            }
            .padding(.leading, 14).padding(.trailing, 4).padding(.vertical, 4)
            .frame(minHeight: 48)
            .background(Farbe.karte, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .padding(.horizontal, Mass.rand)
        .padding(.vertical, 8)
    }

    private func senden(_ text: String) {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty, !denkt else { return }
        eingabe = ""
        denkt = true
        Task {
            await Lotse.fragen(t, speicher: speicher)
            denkt = false
        }
    }
}

// MARK: Bausteine

/// „3 freie Fragen heute“ · „Pro“ · „Regeln auf dem Gerät“ – tippbar zu Kompass Pro
private struct StatusPille: View {
    @Environment(Navigation.self) private var nav
    @Environment(Speicher.self) private var speicher

    var body: some View {
        let stand = LotseStand.geteilt
        let pro = speicher.zustand.einstellungen.pro || stand.kontingent?.pro == true
        let text: String = {
            if Sprachmodelle.aktiv == nil { return "Regeln auf dem Gerät" }
            if pro { return "Pro · unbegrenzt" }
            if let k = stand.kontingent { return "\(k.frei) freie Fragen heute" }
            return "Freie Fragen heute"
        }()
        HStack {
            Button { nav.blatt = .pro } label: {
                Label(text, systemImage: Sprachmodelle.aktiv == nil ? "iphone" : (pro ? "checkmark.seal.fill" : "sparkles"))
                    .font(.klein).foregroundStyle(pro ? Farbe.freude : Farbe.zweitrangig)
                    .padding(.horizontal, 12).frame(minHeight: 32)
                    .background(Farbe.karte.opacity(0.7), in: Capsule())
            }
            .accessibilityHint("Öffnet Kompass Pro")
            Spacer()
            if let f = stand.letzterFehler {
                Text(f).font(.klein).foregroundStyle(Farbe.warnung).lineLimit(1)
                    .onAppear { Task { try? await Task.sleep(for: .seconds(6)); stand.letzterFehler = nil } }
            }
        }
    }
}

/// Leerer Chat: Zeichen und Satz in der Mitte, drei Vorschläge unten (wie in der Vorlage).
private struct Begruessung: View {
    var frage: (String) -> Void
    private let vorschlaege: [(String, String)] = [
        ("calendar", Werkzeuge.werkzeug(.naechstes).beispiele[0]),
        ("gauge.with.dots.needle.67percent", Werkzeuge.werkzeug(.tagesplan).beispiele[0]),
        ("target", Werkzeuge.werkzeug(.fortschrittErklaeren).beispiele[0]),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            AssistentZeichen(groesse: 88, schein: true).accessibilityHidden(true)
            Text("Bereit, wenn du es bist.")
                .font(.kompass(.title, .heavy)).foregroundStyle(Farbe.text)
                .multilineTextAlignment(.center).padding(.top, 18)
            Text("Zu deinem Tag, deinen Zielen – oder ganz allgemein.")
                .font(.unterzeile).foregroundStyle(Farbe.zweitrangig).padding(.top, 6)
            Spacer()
            VStack(alignment: .leading, spacing: 4) {
                ForEach(vorschlaege, id: \.1) { symbol, text in
                    Button { frage(text) } label: {
                        HStack(spacing: 14) {
                            Image(systemName: symbol).font(.body.weight(.semibold)).foregroundStyle(Farbe.akzent).frame(width: 28)
                            Text(text).font(.zeile).foregroundStyle(Farbe.text).multilineTextAlignment(.leading)
                            Spacer()
                        }
                        .padding(.horizontal, 12).frame(minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Mass.rand)
            .padding(.bottom, 4)
        }
    }
}

private struct Verlauf: View {
    var denkt: Bool
    @Environment(Speicher.self) private var speicher

    var body: some View {
        ScrollViewReader { leser in
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(speicher.zustand.chat) { n in Blase(nachricht: n) }
                    if denkt {
                        HStack(spacing: 8) { ProgressView(); Text("Denkt nach …").font(.unterzeile).foregroundStyle(Farbe.zweitrangig) }
                            .padding(.leading, 12)
                    }
                    Color.clear.frame(height: 1).id("ende")
                }
                .padding(.horizontal, Mass.rand).padding(.vertical, 12)
            }
            .onChange(of: speicher.zustand.chat.count) { _, _ in withAnimation { leser.scrollTo("ende", anchor: .bottom) } }
            .onChange(of: denkt) { _, _ in withAnimation { leser.scrollTo("ende", anchor: .bottom) } }
            .onAppear { leser.scrollTo("ende", anchor: .bottom) }
            .scrollDismissesKeyboard(.interactively)
        }
    }
}

/// Das „+“-Menü: was der Lotse tun kann, als Liste mit Symbol, Titel und Unterzeile (wie in der Vorlage).
private struct PlusMenue: View {
    var frage: (String) -> Void
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let ziele = speicher.zustand.ziele.filter { $0.status == .aktiv }
        NavigationStack {
            List {
                Section {
                    Eintrag(symbol: "checklist", titel: "Aufgabe anlegen", unter: "Sag es mir – oder trag sie selbst ein") {
                        dismiss(); nav.blatt = .neu(.aufgabe)
                    }
                    Eintrag(symbol: "calendar", titel: "Woche planen", unter: "Termine und Aufgaben je Tag") { senden(Werkzeuge.werkzeug(.woche).beispiele[0]) }
                    Eintrag(symbol: "clock", titel: "Freie Zeit finden", unter: "Lücken zwischen Terminen") { senden(Werkzeuge.werkzeug(.freieZeit).beispiele[0]) }
                    Eintrag(symbol: "chart.bar", titel: "Wochen-Analyse", unter: "Fokuszeit, Habits, Ziele") { senden(Werkzeuge.werkzeug(.analyse).beispiele[0]) }
                    Eintrag(symbol: "questionmark.circle", titel: "Hilfe zur App", unter: "Wie Kompass rechnet und funktioniert") { senden(Werkzeuge.werkzeug(.hilfe).beispiele[0]) }
                }
                if !ziele.isEmpty {
                    Section("Ziel besprechen") {
                        ForEach(ziele) { g in
                            Eintrag(symbol: g.symbol, titel: g.titel, unter: "Stand, nächster Hebel, Prognose", farbe: Color(hex: g.farbe)) {
                                senden("Wie läuft \(g.titel)?")
                            }
                        }
                    }
                }
                Section {
                    Button("Neuer Chat", systemImage: "square.and.pencil") { Lotse.neuerChat(speicher: speicher); dismiss() }
                    Button("Frühere Chats", systemImage: "clock.arrow.circlepath") { dismiss(); nav.blatt = .chats }
                }
            }
            .navigationTitle("Assistent")
            .navigationBarTitleDisplayMode(.inline)
            .schliessenKnopf()
        }
        .presentationDetents([.medium, .large])
    }

    private func senden(_ t: String) { dismiss(); frage(t) }

    private struct Eintrag: View {
        var symbol: String
        var titel: String
        var unter: String
        var farbe: Color = Farbe.akzent
        var aktion: () -> Void
        var body: some View {
            Button(action: aktion) {
                HStack(spacing: 14) {
                    Image(systemName: symbol).foregroundStyle(farbe).frame(width: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(titel).font(.zeile).foregroundStyle(Farbe.text)
                        Text(unter).font(.unterzeile).foregroundStyle(Farbe.zweitrangig)
                    }
                }
            }
        }
    }
}

private struct Blase: View {
    var nachricht: ChatNachricht
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav

    var body: some View {
        let nutzer = nachricht.rolle == .nutzer
        HStack(alignment: .top, spacing: 8) {
            if nutzer { Spacer(minLength: 48) } else { AssistentZeichen(groesse: 26).padding(.top, 8).accessibilityHidden(true) }
            VStack(alignment: .leading, spacing: 8) {
                if nutzer {
                    Text(nachricht.text)
                        .font(.kompass(.body, .semibold))
                        .foregroundStyle(.white)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    AntwortText(text: nachricht.text)
                        .font(.kompass(.body, .regular))
                        .textSelection(.enabled)
                }
                if !nutzer, let a = nachricht.aktion {
                    Button(aktionText(a)) { ausfuehren(a) }
                        .font(.kompass(.subheadline, .bold)).foregroundStyle(Farbe.akzent)
                }
                if !nutzer {
                    HStack(spacing: 4) {
                        Daumen(an: nachricht.rueckmeldung == true, symbol: "hand.thumbsup", beschriftung: "Gute Antwort") { Lotse.rueckmeldung(true, nachricht: nachricht.id, speicher: speicher) }
                        Daumen(an: nachricht.rueckmeldung == false, symbol: "hand.thumbsdown", beschriftung: "Schlechte Antwort") { Lotse.rueckmeldung(false, nachricht: nachricht.id, speicher: speicher) }
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(nutzer ? AnyShapeStyle(Farbe.akzent) : AnyShapeStyle(Farbe.karte), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            if !nutzer { Spacer(minLength: 24) }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(nutzer ? "Du: \(nachricht.text)" : "Assistent: \(AntwortText.ohneZeichen(nachricht.text))")
    }

    private func aktionText(_ a: ChatNachricht.Aktion) -> String {
        switch a {
        case .ziel: "Ziel öffnen ›"
        case .aufgabe: "Aufgabe öffnen ›"
        case .habit: "Habit öffnen ›"
        case .bereich(let b): "\(Bereich(rawValue: b)?.titel ?? "Bereich") öffnen ›"
        case .pro: "Kompass Pro ansehen ›"
        }
    }

    private func ausfuehren(_ a: ChatNachricht.Aktion) {
        switch a {
        case .ziel(let id): nav.oeffneZiel(id)
        case .aufgabe(let id): nav.blatt = .aufgabe(id)
        case .habit(let id): nav.oeffneHabit(id)
        case .bereich(let b): if let x = Bereich(rawValue: b) { nav.bereich = x }
        case .pro: nav.blatt = .pro
        }
    }
}

private struct Daumen: View {
    var an: Bool
    var symbol: String
    var beschriftung: String
    var aktion: () -> Void
    var body: some View {
        Button(action: aktion) {
            Image(systemName: an ? symbol + ".fill" : symbol).font(.footnote)
                .foregroundStyle(an ? Farbe.akzent : Farbe.pfeil)
                .frame(width: 36, height: 32)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(beschriftung)
        .accessibilityAddTraits(an ? .isSelected : [])
    }
}


// MARK: KI-Zeichen und Verlauf

/// Das Zeichen des Assistenten: Verlauf Indigo → Violett, Glasring, Funken. Überall gleich (Tab, Kopf, Blasen, Home).
struct AssistentZeichen: View {
    var groesse: CGFloat = 32
    var schein = false
    var body: some View {
        ZStack {
            Circle().fill(LinearGradient(colors: [Farbe.indigo[0], Farbe.violett[1]], startPoint: .bottomLeading, endPoint: .topTrailing))
            Circle().strokeBorder(.white.opacity(0.45), lineWidth: max(1, groesse / 28))
            Circle().fill(.white.opacity(0.18)).frame(width: groesse * 0.7, height: groesse * 0.7).blur(radius: groesse / 6).offset(x: -groesse / 6, y: -groesse / 6)
            Image(systemName: "sparkles").font(.system(size: groesse * 0.46, weight: .bold)).foregroundStyle(.white)
        }
        .frame(width: groesse, height: groesse)
        .shadow(color: schein ? Farbe.violett[0].opacity(0.45) : .clear, radius: groesse / 4, y: groesse / 8)
        .accessibilityLabel("Assistent")
    }
}

/// Frühere Chats: erste Frage als Titel, Datum; antippen öffnet, wischen löscht.
struct ChatVerlaufBlatt: View {
    @Environment(Speicher.self) private var speicher
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                let chats = speicher.zustand.chatVerlauf
                if chats.isEmpty {
                    Text("Noch keine früheren Chats. Jeder Start der App beginnt einen neuen Chat.").foregroundStyle(.secondary)
                }
                ForEach(chats) { c in
                    Button {
                        Lotse.chatOeffnen(c.id, speicher: speicher)
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(c.titel).font(.zeile).foregroundStyle(Farbe.text).lineLimit(2)
                            Text("\(c.start.formatted(.dateTime.day().month(.abbreviated).hour().minute().locale(Locale(identifier: "de_DE")))) · \(c.nachrichten.count) Nachrichten")
                                .font(.unterzeile).foregroundStyle(Farbe.zweitrangig)
                        }
                    }
                }
                .onDelete { i in for x in i { Lotse.chatLoeschen(chats[x].id, speicher: speicher) } }
            }
            .navigationTitle("Frühere Chats")
            .navigationBarTitleDisplayMode(.inline)
            .schliessenKnopf()
        }
        .presentationDetents([.medium, .large])
    }
}
