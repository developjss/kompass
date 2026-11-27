import SwiftUI

/// Blatt beim Antippen eines Habits – Aufbau 1:1 wie Opals „New Rule“-Blatt: Kopf mit Schließen und Titel,
/// darunter Kacheln (131 × 138 pt im Vorbild, Radius 24, Zeichen im Akzent-Verlauf oben links, Titel und graue Zeile unten).
/// „Erledigt“ fährt im selben Blatt eine Seite mit dem Compass-Balken herein (wie Opals Schwierigkeits-Seite).
struct HabitAuswahlBlatt: View {
    /// Das Habit; „Bearbeiten“ ändert es direkt (gilt, solange die App offen ist)
    @Binding var habit: Habit
    /// Gespeicherter Fortschritt heute (nur solange die App offen ist)
    @Binding var wert: Double
    /// Entfernt das Habit (nach der Rückfrage im Bearbeiten-Blatt)
    var loeschen: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var ruhig
    @State private var erledigtSeite: Bool
    /// Fokus: ganzer Bildschirm mit Timer
    @State private var fokusOffen = false
    /// Bearbeiten öffnet das Blatt „Neuer Habit“ – gefüllt mit diesem Habit
    @State private var bearbeitenOffen = false

    init(habit: Binding<Habit>, wert: Binding<Double>, startErledigt: Bool = false, loeschen: @escaping () -> Void = {}) {
        _habit = habit; _wert = wert; self.loeschen = loeschen
        _erledigtSeite = State(initialValue: startErledigt)
    }

    var body: some View {
        ZStack {
            if erledigtSeite {
                ErledigtSeite(habit: habit, wert: $wert) { wechsel(false) }
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                auswahl.transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16).padding(.top, 18).padding(.bottom, 16)
        .habitBlatt(hoehe: erledigtSeite ? 420 : 384)
        .fullScreenCover(isPresented: $fokusOffen) { FokusAnsicht(habit: habit, wert: $wert) }
        .sheet(isPresented: $bearbeitenOffen) {
            HabitNeuBlatt(habit: habit, speichern: { neu in
                // andere Einheit: bisheriger Fortschritt passt nicht mehr
                if neu.einheit != habit.einheit { wert = 0 } else { wert = min(wert, neu.tagesziel) }
                habit = neu
            }, loeschen: {
                bearbeitenOffen = false
                loeschen()
            })
        }
        .task {
            // Für Testbilder: `-bearbeiten` / `-fokus` öffnet das Blatt bzw. den Fokus direkt
            let a = ProcessInfo.processInfo.arguments
            guard a.contains("-bearbeiten") || a.contains("-fokus") else { return }
            try? await Task.sleep(for: .seconds(0.8))
            if a.contains("-fokus") { fokusOffen = true } else { bearbeitenOffen = true }
        }
    }

    private func wechsel(_ an: Bool) {
        withAnimation(ruhig ? nil : .spring(response: 0.42, dampingFraction: 0.86)) { erledigtSeite = an }
    }

    private var auswahl: some View {
        let status = Fortschritt.status(wert: wert, ziel: habit.tagesziel)
        let anteil = Fortschritt.anteil(wert: wert, ziel: habit.tagesziel)
        return VStack(spacing: 0) {
            // Kopf wie Opals Timer-Blatt: Schließen links, großes Bild mittig, Name darunter
            ZStack(alignment: .top) {
                HStack { BlattKnopf(symbol: "xmark", beschriftung: "Schließen") { dismiss() }; Spacer() }
                ZStack {
                    habit.bildAnsicht.resizable().scaledToFill()
                        .frame(width: 112, height: 112).clipShape(Circle())
                    Circle().strokeBorder(Color(0x2B2B2D), lineWidth: 5).frame(width: 124, height: 124)
                    Circle().strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5).frame(width: 112, height: 112)
                    // heutiger Fortschritt als türkiser Bogen
                    Circle().trim(from: 0, to: anteil)
                        .stroke(LinearGradient(colors: [Color(0x39DAD7), Color(0xA7FFFF)], startPoint: .top, endPoint: .bottom),
                                style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 119, height: 119)
                        .shadow(color: Color(0x2FD0D1).opacity(0.7), radius: 4)
                        .opacity(anteil > 0 ? 1 : 0)
                }
                .frame(width: 124, height: 124)
                .shadow(color: .black.opacity(0.45), radius: 18, y: 8)
                .accessibilityHidden(true)
                .padding(.top, 4)
            }

            VStack(spacing: 4) {
                Text(status == .erledigt ? "Heute erledigt" : "Heute · \(Fortschritt.text(wert: wert, einheit: habit.einheit, ziel: habit.tagesziel))")
                    .font(.system(size: 15, weight: .semibold)).monospacedDigit()
                    .foregroundStyle(DFarbe.akzent)
                Text(habit.name).font(.system(size: 28, weight: .semibold)).accessibilityAddTraits(.isHeader)
            }
            .padding(.top, 16)
            .accessibilityElement(children: .combine)

            HStack(spacing: 10) {
                Kachel(symbol: "checkmark", titel: "Erledigt", unter: "Eintragen", hervor: status != .erledigt) { wechsel(true) }
                Kachel(symbol: "timer", titel: "Fokus", unter: "Timer starten") { fokusOffen = true }
                Kachel(symbol: "pencil", titel: "Bearbeiten", unter: "Habit ändern") { bearbeitenOffen = true }
            }
            .padding(.top, 24)
            Spacer(minLength: 0)
        }
        .background(alignment: .top) {
            // Schein in der Farbe des Bilds von oben, wie bei Opals Regel-Blatt
            habit.bildAnsicht.resizable().scaledToFill()
                .frame(width: 320, height: 220).blur(radius: 60).opacity(0.55)
                .mask(RadialGradient(colors: [.black, .clear], center: .top, startRadius: 10, endRadius: 230))
                .offset(y: -60)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}

/// Kachel im Aufbau von Opals „New Rule“-Kacheln, verfeinert: Glas mit heller Oberkante, Zeichen im getönten Kreis,
/// Titel und eine graue Zeile unten. Die wichtigste Kachel leuchtet leicht im Akzent.
private struct Kachel: View {
    var symbol: String
    var titel: String
    var unter: String
    var hervor = false
    var aktion: () -> Void

    var body: some View {
        Button(action: aktion) {
            VStack(alignment: .leading, spacing: 0) {
                Image(systemName: symbol).font(.system(size: 17, weight: .bold))
                    .foregroundStyle(LinearGradient(colors: DFarbe.akzentFarben, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 38, height: 38)
                    .background {
                        Circle().fill(LinearGradient(colors: [Color(Dunkel.akzentA).opacity(0.16), Color(Dunkel.akzentB).opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    }
                    .overlay { Circle().strokeBorder(Color(Dunkel.akzentB).opacity(0.22), lineWidth: 0.5) }
                Spacer(minLength: 10)
                Text(titel).font(.system(size: 17, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.75)
                Text(unter).font(.system(size: 13)).foregroundStyle(Color(0x8E8E93)).lineLimit(1).minimumScaleFactor(0.8)
                    .padding(.top, 2)
            }
            .padding(.horizontal, 14).padding(.top, 14).padding(.bottom, 15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 128)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(LinearGradient(colors: [Color.white.opacity(0.11), Color.white.opacity(0.05)], startPoint: .top, endPoint: .bottom))
                    if hervor {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(RadialGradient(colors: [Color(Dunkel.akzentB).opacity(0.16), .clear], center: .topLeading, startRadius: 0, endRadius: 140))
                    }
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(LinearGradient(colors: [.white.opacity(hervor ? 0.28 : 0.18), .white.opacity(0.04)], startPoint: .top, endPoint: .bottom), lineWidth: 0.8)
            }
            .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(KachelDruck())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

/// Leichtes Eindrücken beim Tippen.
private struct KachelDruck: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Seite „Erledigt“

/// Aufbau wie Opals Schwierigkeits-Seite: Zurück, Verlaufs-Etikett, großer Titel, Erklärung, Regler.
/// Ganz nach rechts = sofort erledigt (mit Feier). Teilwert = erst mit der weißen Kapsel bestätigen. Korrigieren jederzeit.
struct ErledigtSeite: View {
    var habit: Habit
    @Binding var wert: Double
    var zurueck: () -> Void

    @State private var anteil: Double = 0
    @State private var feier = 0
    @Environment(\.accessibilityReduceMotion) private var ruhig

    private var ziel: Double { habit.tagesziel }
    private var entwurf: Double { Fortschritt.wert(anteil: anteil, einheit: habit.einheit, ziel: ziel) }
    private var status: Fortschritt.Status { Fortschritt.status(wert: entwurf, ziel: ziel) }
    private var ungespeichert: Bool { abs(entwurf - wert) > 0.000_001 && status != .erledigt }

    var body: some View {
        VStack(spacing: 0) {
            HStack { BlattKnopf(symbol: "chevron.left", beschriftung: "Zurück", aktion: zurueck); Spacer() }

            VStack(spacing: 8) {
                VerlaufEtikett(text: habit.name, groesse: 17)
                Text(titel).font(.system(size: 30, weight: .bold)).monospacedDigit()
                    .contentTransition(.numericText())
                // leere Zeile behält ihren Platz, damit der Balken beim Ziehen nicht springt
                Text(unterzeile.isEmpty ? " " : unterzeile).font(.system(size: 17)).foregroundStyle(Color(0x9A9A9E))
                    .multilineTextAlignment(.center)
            }
            .animation(.snappy(duration: 0.25), value: titel)
            .padding(.top, 4)
            .accessibilityElement(children: .combine)

            CompassBalken(anteil: $anteil,
                          wertText: Fortschritt.text(wert: entwurf, einheit: habit.einheit, ziel: ziel),
                          stufen: stufen, feier: feier) { ende in
                anteil = Fortschritt.anteil(wert: Fortschritt.wert(anteil: ende, einheit: habit.einheit, ziel: ziel), ziel: ziel)
                if anteil >= 1, wert < ziel {
                    wert = ziel
                    feier += 1
                } else if habit.einheit.auswahl == .keine, anteil < 1, wert >= ziel {
                    wert = 0
                }
            }
            .padding(.horizontal, 6)
            .padding(.top, 58)

            ZStack {
                if ungespeichert {
                    Button {
                        withAnimation(.snappy) { wert = entwurf }
                    } label: {
                        Text(Fortschritt.speichernText(wert: entwurf, einheit: habit.einheit, ziel: ziel))
                            .font(.system(size: 17, weight: .medium)).monospacedDigit()
                            .frame(maxWidth: .infinity, minHeight: 54)
                            .background(Color.white, in: Capsule())
                            .foregroundStyle(.black)
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }
            }
            .frame(height: 54)
            .padding(.top, 34)
            .animation(.snappy(duration: 0.25), value: ungespeichert)

            Spacer(minLength: 0)
        }
        .onAppear { anteil = Fortschritt.anteil(wert: wert, ziel: ziel) }
        .sensoryFeedback(.success, trigger: feier)
    }

    /// Anzahl Raststufen für das Antippen-Feedback beim Ziehen
    private var stufen: Int {
        habit.einheit.auswahl == .keine ? 1 : max(1, Int((ziel / Fortschritt.schritt(habit.einheit)).rounded()))
    }

    private var titel: String {
        switch status {
        case .offen: "Noch offen"
        case .teilweise: "\(Fortschritt.prozent(wert: entwurf, ziel: ziel)) % geschafft"
        case .erledigt: "Erledigt"
        }
    }

    private var unterzeile: String {
        switch status {
        case .offen: "Zieh den Kompass nach rechts."
        case .teilweise: ungespeichert ? "" : "Gespeichert – du kannst jederzeit weitermachen."
        case .erledigt: "Tagesziel geschafft. Zurückziehen korrigiert."
        }
    }
}

// MARK: - Compass-Balken

/// Balken nach der Vorlage des Gründers im Aufbau von Opals Schwierigkeits-Regler: Spur 35 pt, links türkis gefüllt mit
/// Lichtstaub und leuchtenden Kanten, rechts klares Glas, Griff = gläserner Kompass (48 pt) mit Nadel. Wert läuft über dem Griff mit.
struct CompassBalken: View {
    @Binding var anteil: Double
    var wertText: String
    var stufen: Int
    var feier: Int
    var losgelassen: (Double) -> Void

    @Environment(\.accessibilityReduceMotion) private var ruhig
    @State private var ziehtGerade = false
    @State private var drehung: Double = 0
    @State private var blitz = false
    @State private var funken = true
    /// Breite der Wert-Beschriftung, damit sie am Rand nie abgeschnitten wird
    @State private var etikettBreite: CGFloat = 120

    private let spur: CGFloat = 35
    private let knopf: CGFloat = 48

    var body: some View {
        GeometryReader { g in
            let w = g.size.width
            let x = CGFloat(anteil) * (w - knopf)
            ZStack(alignment: .leading) {
                // leere Spur: klares Glas
                Capsule().fill(LinearGradient(colors: [Color(0x1A2B2B).opacity(0.55), Color(0x1B352E).opacity(0.55)], startPoint: .leading, endPoint: .trailing))
                    .overlay { Capsule().strokeBorder(Color.white.opacity(0.22), lineWidth: 0.75) }
                    .frame(height: spur)

                // gefüllter Teil
                ZStack {
                    Capsule().fill(LinearGradient(colors: [Color(0x022F2E), Color(0x024C49), Color(0x00706B)], startPoint: .leading, endPoint: .trailing))
                    Funkelstaub().clipShape(Capsule())
                    Capsule().strokeBorder(LinearGradient(colors: [Color(0x39DAD7).opacity(0.5), Color(0x87E0DD)], startPoint: .leading, endPoint: .trailing), lineWidth: 1.2)
                        .blur(radius: 1.5)
                    Capsule().strokeBorder(Color(0xA7FFFF).opacity(0.75), lineWidth: 0.6)
                    Capsule().fill(Color(0xA7FFFF)).opacity(blitz ? 0.55 : 0)
                }
                .frame(width: x + knopf / 2 + spur / 2, height: spur)
                .shadow(color: Color(0x2FD0D1).opacity(0.55), radius: 12)

                // Funken bei „erledigt“
                ForEach(0..<14, id: \.self) { i in
                    let winkel = Double(i) / 14 * 2 * .pi
                    Circle().fill(Color(0xA7FFFF)).frame(width: i % 3 == 0 ? 4 : 2.5, height: i % 3 == 0 ? 4 : 2.5)
                        .offset(x: x + knopf / 2 - 2 + (funken ? cos(winkel) * 52 : 0), y: funken ? sin(winkel) * 52 : 0)
                        .opacity(funken ? 0 : 1)
                        .allowsHitTesting(false)
                }

                // Griff
                CompassKnopf(groesse: knopf, drehung: drehung)
                    .scaleEffect(ziehtGerade ? 1.08 : 1)
                    .offset(x: x)

                // Wert über dem Kompass
                Text(wertText).font(.system(size: 15, weight: .semibold)).monospacedDigit()
                    .fixedSize()
                    .padding(.horizontal, 10).frame(height: 26)
                    .background(Color.black.opacity(0.35), in: Capsule())
                    .overlay { Capsule().strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5) }
                    .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { etikettBreite = $0 }
                    .position(x: min(max(x + knopf / 2, etikettBreite / 2), w - etikettBreite / 2), y: -24)
                    .animation(.snappy(duration: 0.15), value: wertText)
            }
            .frame(height: knopf)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { z in
                    if !ziehtGerade { withAnimation(.spring(response: 0.25)) { ziehtGerade = true } }
                    anteil = Double(min(max((z.location.x - knopf / 2) / max(w - knopf, 1), 0), 1))
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.3)) { ziehtGerade = false }
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { losgelassen(anteil) }
                })
        }
        .frame(height: knopf)
        .sensoryFeedback(.selection, trigger: Int((anteil * Double(stufen)).rounded()))
        .onChange(of: feier) { _, _ in feiern() }
        .accessibilityElement()
        .accessibilityLabel("Fortschritt")
        .accessibilityValue(wertText)
        .accessibilityAdjustableAction { r in
            let schritt = 1 / Double(max(stufen, 1))
            switch r {
            case .increment: losgelassen(min(anteil + schritt, 1))
            case .decrement: losgelassen(max(anteil - schritt, 0))
            @unknown default: break
            }
        }
    }

    /// Nadel dreht einmal, Spur leuchtet auf, Funken sprühen (nicht bei „Bewegung reduzieren“).
    private func feiern() {
        guard !ruhig else { return }
        withAnimation(.spring(response: 0.9, dampingFraction: 0.7)) { drehung += 360 }
        withAnimation(.easeOut(duration: 0.12)) { blitz = true }
        withAnimation(.easeIn(duration: 0.6).delay(0.12)) { blitz = false }
        var ohne = Transaction(); ohne.disablesAnimations = true
        withTransaction(ohne) { funken = false }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(20))
            withAnimation(.easeOut(duration: 0.75)) { funken = true }
        }
    }
}

/// Gläserner Kompass als Griff: dunkles Türkis, Skala, leuchtende Nadel, heller Glasrand.
struct CompassKnopf: View {
    var groesse: CGFloat
    var drehung: Double

    var body: some View {
        ZStack {
            Circle().fill(RadialGradient(colors: [Color(0x0B5552), Color(0x023B39), Color(0x01201F)], center: .center, startRadius: 0, endRadius: groesse / 2))
            // Skala
            ForEach(0..<24, id: \.self) { i in
                Rectangle().fill(Color.white.opacity(i % 6 == 0 ? 0.55 : 0.28))
                    .frame(width: 0.8, height: i % 6 == 0 ? groesse * 0.1 : groesse * 0.06)
                    .offset(y: -groesse * 0.34)
                    .rotationEffect(.degrees(Double(i) * 15))
            }
            // Nadel
            NadelForm().fill(LinearGradient(colors: [Color(0xE8FFFF), Color(0x2FD0D1)], startPoint: .top, endPoint: .center))
                .frame(width: groesse * 0.14, height: groesse * 0.62)
                .shadow(color: Color(0x2FD0D1).opacity(0.9), radius: 3)
                .rotationEffect(.degrees(45 + drehung))
            Circle().fill(Color(0xA5FDFF)).frame(width: groesse * 0.09, height: groesse * 0.09)
            // Glas
            Circle().fill(LinearGradient(colors: [.white.opacity(0.28), .clear, .clear, .white.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing))
            Circle().strokeBorder(LinearGradient(colors: [Color(0xF0FFFF).opacity(0.95), Color(0x78CECD).opacity(0.35), Color(0xF0FFFF).opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2)
        }
        .frame(width: groesse, height: groesse)
        .shadow(color: Color(0x2FD0D1).opacity(0.65), radius: 10)
        .shadow(color: .black.opacity(0.35), radius: 4, y: 2)
        .accessibilityHidden(true)
    }
}

/// Kompassnadel: schmale Raute, oben hell, unten dunkler.
private struct NadelForm: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.midY))
        p.addLine(to: CGPoint(x: r.midX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.midY))
        p.closeSubpath()
        return p
    }
}

/// Feiner türkiser Staub im gefüllten Balken, leicht funkelnd (ruht bei „Bewegung reduzieren“).
private struct Funkelstaub: View {
    @Environment(\.accessibilityReduceMotion) private var ruhig
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: ruhig)) { k in
            let t = ruhig ? 0 : k.date.timeIntervalSinceReferenceDate
            Canvas { ctx, g in
                var s: UInt64 = 0xC0FF_EE11
                func zufall() -> Double {
                    s &+= 0x9E37_79B9_7F4A_7C15
                    var z = s
                    z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
                    z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
                    return Double(z ^ (z >> 31)) / Double(UInt64.max)
                }
                // Staub wandert langsam nach rechts zum Kompass (wie beim Aufladen), schwebt leicht auf und ab und funkelt.
                // Feste Breite fürs Wandern, damit die Punkte beim Ziehen nicht springen.
                let bahn: CGFloat = 400
                let n = Int(bahn / 2.4)
                for _ in 0..<n {
                    let x0 = zufall() * bahn, y0 = zufall() * g.height
                    let tempo = 5 + zufall() * 13
                    let r = 0.3 + zufall() * 0.6
                    let p = zufall() * 6.28
                    let x = (x0 + t * tempo).truncatingRemainder(dividingBy: bahn) - (bahn - g.width)
                    guard x > -2 else { continue }
                    let y = y0 + sin(t * 0.9 + p) * 2.2
                    let a = 0.3 + 0.55 * (0.5 + 0.5 * sin(t * 1.4 + p))
                    ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r * 2, height: r * 2)), with: .color(Color(0x9FFFFF).opacity(a)))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

extension Habit {
    /// Bild zum Anzeigen: eigenes Foto, sonst das Bild aus den Assets.
    var bildAnsicht: Image {
        if let d = bildDaten, let b = UIImage(data: d) { return Image(uiImage: b) }
        return Image(bild)
    }
}
