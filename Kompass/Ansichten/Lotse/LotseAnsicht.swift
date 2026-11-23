import SwiftUI

/// Der Lotse: Chat mit Vorschlägen, Antworten mit Sprung in die App, Daumen hoch/runter.
struct LotseAnsicht: View {
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav
    @State private var eingabe = ""
    @State private var denkt = false
    @FocusState private var fokus: Bool

    var body: some View {
        let chat = speicher.zustand.chat
        VStack(spacing: 0) {
            ScrollViewReader { leser in
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        SeitenKopf(titel: "Lotse", info: .lotse, neu: nil, neuZeigen: false)
                            .padding(.top, 14)
                        if chat.isEmpty { Begruessung(frage: senden) }
                        ForEach(chat) { n in Blase(nachricht: n) }
                        if denkt {
                            HStack(spacing: 8) { ProgressView(); Text("Einen Moment …").font(.unterzeile).foregroundStyle(Farbe.zweitrangig) }
                                .padding(.leading, 12)
                        }
                        Color.clear.frame(height: 1).id("ende")
                    }
                    .padding(.horizontal, Mass.rand)
                    .padding(.bottom, 12)
                    .frame(maxWidth: 720)
                    .frame(maxWidth: .infinity)
                }
                .onChange(of: chat.count) { _, _ in withAnimation { leser.scrollTo("ende", anchor: .bottom) } }
                .onAppear { leser.scrollTo("ende", anchor: .bottom) }
                .scrollDismissesKeyboard(.interactively)
            }
            if !chat.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Werkzeuge.vorschlaege.prefix(4), id: \.self) { v in
                            Button(v) { senden(v) }.buttonStyle(ChipStil())
                        }
                    }
                    .padding(.horizontal, Mass.rand)
                }
                .padding(.bottom, 8)
            }
            Eingabe
        }
        .background(alignment: .top) {
            LinearGradient(stops: [.init(color: Farbe.grundOben, location: 0), .init(color: Farbe.grund, location: 0.64)], startPoint: .top, endPoint: .bottom)
                .frame(height: 420).ignoresSafeArea()
        }
        .background(Farbe.grund.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var Eingabe: some View {
        HStack(spacing: 8) {
            TextField("Frag den Lotsen …", text: $eingabe, axis: .vertical)
                .lineLimit(1...4)
                .font(.kompass(.body, .medium))
                .focused($fokus)
                .submitLabel(.send)
                .onSubmit { senden(eingabe) }
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(Farbe.karte, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            Button { senden(eingabe) } label: {
                Image(systemName: "arrow.up").font(.body.weight(.bold))
                    .frame(width: 44, height: 44)
                    .background(eingabe.trimmingCharacters(in: .whitespaces).isEmpty ? Farbe.akzentWeich : Farbe.akzent, in: Circle())
                    .foregroundStyle(eingabe.trimmingCharacters(in: .whitespaces).isEmpty ? Farbe.akzent : .white)
            }
            .disabled(eingabe.trimmingCharacters(in: .whitespaces).isEmpty || denkt)
            .accessibilityLabel("Senden")
            Menu {
                Button("Verlauf löschen", systemImage: "trash", role: .destructive) { Lotse.verlaufLoeschen(speicher: speicher) }
                Text("Antwortet mit: \(Sprachmodelle.beschreibung)")
            } label: {
                Image(systemName: "ellipsis").frame(width: 44, height: 44).foregroundStyle(Farbe.zweitrangig)
            }
            .accessibilityLabel("Mehr")
        }
        .padding(.horizontal, Mass.rand)
        .padding(.bottom, 8)
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

private struct Begruessung: View {
    var frage: (String) -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Verlaufskarte(farben: Farbe.indigo) {
                KartenLabel(text: "Dein Lotse")
                Text("Frag mich, was heute ansteht, wann du Zeit hast oder warum ein Ziel bei 54 % steht.")
                    .font(.kompass(.title3, .bold)).fixedSize(horizontal: false, vertical: true)
                Text("Ich kenne deine Ziele, Habits, Aufgaben und Termine – und lege Aufgaben für dich an.").font(.unterzeile).opacity(0.9)
            }
            Text("Zum Beispiel").font(.klein).foregroundStyle(Farbe.zweitrangig).padding(.leading, 4)
            VStack(spacing: 8) {
                ForEach(Werkzeuge.vorschlaege, id: \.self) { v in
                    Button { frage(v) } label: {
                        HStack {
                            Text(v).font(.zeile).foregroundStyle(Farbe.text).multilineTextAlignment(.leading)
                            Spacer()
                            Image(systemName: "arrow.up.right").font(.footnote.weight(.bold)).foregroundStyle(Farbe.akzent)
                        }
                        .padding(.horizontal, 16).frame(minHeight: Mass.zeileKompakt)
                        .background(Farbe.karte, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(.plain)
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
        HStack {
            if nutzer { Spacer(minLength: 48) }
            VStack(alignment: .leading, spacing: 8) {
                Text(nachricht.text)
                    .font(.kompass(.body, nutzer ? .semibold : .medium))
                    .foregroundStyle(nutzer ? .white : Farbe.text)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
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
        .accessibilityLabel(nutzer ? "Du: \(nachricht.text)" : "Lotse: \(nachricht.text)")
    }

    private func aktionText(_ a: ChatNachricht.Aktion) -> String {
        switch a {
        case .ziel: "Ziel öffnen ›"
        case .aufgabe: "Aufgabe öffnen ›"
        case .bereich(let b): "\(Bereich(rawValue: b)?.titel ?? "Bereich") öffnen ›"
        }
    }

    private func ausfuehren(_ a: ChatNachricht.Aktion) {
        switch a {
        case .ziel(let id): nav.oeffneZiel(id)
        case .aufgabe(let id): nav.blatt = .aufgabe(id)
        case .bereich(let b): if let x = Bereich(rawValue: b) { nav.bereich = x }
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

struct ChipStil: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.kompass(.footnote, .semibold))
            .lineLimit(1)
            .padding(.horizontal, 12).frame(minHeight: 34)
            .background(Farbe.karte, in: Capsule())
            .foregroundStyle(Farbe.text)
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}
