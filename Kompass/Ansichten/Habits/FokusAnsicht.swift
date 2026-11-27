import SwiftUI
import UIKit

/// Fokus – ganzer Bildschirm. Aufbau wie Opals Timer-Seite: große Uhr in der Mitte, darunter Schnellwahl-Kapseln
/// und Lineal, unten „Gedrückt halten zum Starten“. Läuft der Timer, zählt die Uhr herunter; Pause, Weiter und
/// Ziehen zum Beenden. Läuft der Timer ab, gilt das Habit als erledigt. Hintergrund: Bild des Gründers („fokus-grund“).
struct FokusAnsicht: View {
    var habit: Habit
    /// Fortschritt heute – wird am Ende nach der Regel `Fokus.ergebnis` gesetzt
    @Binding var wert: Double

    enum Phase: Equatable { case einstellen, laeuft, pause, fertig }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var ruhig
    @Environment(\.scenePhase) private var szene
    @State private var phase: Phase = .einstellen
    /// Dauer für Habits ohne Zeit-Einheit (einstellbar)
    @State private var minuten: Double = Double(Fokus.freieMinuten)
    /// Feste Dauer bei Habits mit Zeit-Einheit (nil = einstellbar)
    private let fest: Int?
    /// Ende des laufenden Timers (läuft auch im Hintergrund weiter, weil die Uhr am Datum hängt)
    @State private var ende: Date?
    /// Restzeit beim Pausieren
    @State private var rest: Int = 0
    @State private var gesamt: Int = 0
    @State private var feier = 0

    init(habit: Habit, wert: Binding<Double>) {
        self.habit = habit
        _wert = wert
        fest = Fokus.festeSekunden(einheit: habit.einheit, ziel: habit.tagesziel, wert: wert.wrappedValue)
        // Für Testbilder: `-fokusSekunden <n>` startet sofort mit kurzer Dauer
        let a = ProcessInfo.processInfo.arguments
        if let i = a.firstIndex(of: "-fokusSekunden"), i + 1 < a.count, let s = Int(a[i + 1]) {
            _phase = State(initialValue: .laeuft)
            _ende = State(initialValue: Date().addingTimeInterval(TimeInterval(s)))
            _gesamt = State(initialValue: s)
        }
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.25)) { k in
            let sekunden = restSekunden(jetzt: k.date)
            ZStack {
                hintergrund

                VStack(spacing: 0) {
                    kopf
                    Spacer(minLength: 0)
                    VStack(spacing: 18) {
                        FokusUhr(text: Fokus.uhr(sekunden), leuchtet: phase != .pause, feier: feier)
                        unterUhr(sekunden: sekunden)
                    }
                    Spacer(minLength: 0)
                    unten
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .onChange(of: sekunden == 0 && phase == .laeuft) { _, abgelaufen in
                if abgelaufen { abschliessen(fertig: true) }
            }
        }
        .foregroundStyle(DFarbe.text)
        .preferredColorScheme(.dark)
        .statusBarHidden(phase == .laeuft)
        .onChange(of: phase) { _, p in UIApplication.shared.isIdleTimerDisabled = (p == .laeuft || p == .pause) }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = (phase == .laeuft)
            if phase == .laeuft { FokusLive.starten(name: habit.name, gesamt: gesamt, rest: gesamt) }
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            if phase != .fertig { FokusLive.beendenSofort() }
        }
        .sensoryFeedback(.success, trigger: feier)
        .sensoryFeedback(.impact(weight: .medium), trigger: phase)
    }

    // MARK: Teile

    private var hintergrund: some View {
        GeometryReader { g in
            ZStack {
                Color.black
                Image("fokus-grund").resizable().scaledToFill()
                    .frame(width: g.size.width, height: g.size.height).clipped()
                    .opacity(phase == .pause ? 0.55 : 1)
                // Lichtkegel über der Uhr (türkis), atmet leicht, solange der Timer läuft
                RadialGradient(colors: [Color(0x2FD0D1).opacity(phase == .pause ? 0.12 : 0.3), .clear],
                               center: UnitPoint(x: 0.5, y: 0.42), startRadius: 10, endRadius: g.size.width * 0.75)
                    .blendMode(.screen)
                LinearGradient(colors: [.clear, .black.opacity(0.65)], startPoint: UnitPoint(x: 0.5, y: 0.6), endPoint: .bottom)
            }
            .animation(.easeInOut(duration: 0.6), value: phase)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private var kopf: some View {
        ZStack {
            VerlaufEtikett(text: habit.name, groesse: 15)
            HStack {
                if phase == .einstellen || phase == .fertig {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").font(.system(size: 17, weight: .semibold))
                            .frame(width: 46, height: 46)
                            .background { ZStack { Circle().fill(.ultraThinMaterial); Circle().fill(Color.black.opacity(0.25)) } }
                            .overlay { Circle().strokeBorder(Color.white.opacity(0.14), lineWidth: 0.5) }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Schließen")
                    .transition(.opacity)
                }
                Spacer()
            }
        }
        .frame(height: 46)
        .environment(\.colorScheme, .dark)
    }

    @ViewBuilder
    private func unterUhr(sekunden: Int) -> some View {
        switch phase {
        case .einstellen:
            if let fest {
                // Zeit kommt vom Habit – nichts einzustellen
                VStack(spacing: 6) {
                    Text(Einheit.zeit(sekunden: fest)).font(.system(size: 22, weight: .semibold))
                    Text(fest < habit.einheit.sekunden(habit.tagesziel) ? "Restzeit bis zum Tagesziel" : "Tagesziel")
                        .font(.system(size: 16)).foregroundStyle(Color.white.opacity(0.6))
                }
                .accessibilityElement(children: .combine)
            } else {
                LinealWahl(einheit: .minuten, wert: $minuten)
                    .padding(.horizontal, -4)
                    .transition(.opacity)
            }
        case .laeuft, .pause:
            VStack(spacing: 6) {
                Text(phase == .pause ? "Pausiert" : "Fokus läuft").font(.system(size: 22, weight: .semibold))
                Text(zeile(sekunden: sekunden)).font(.system(size: 16)).foregroundStyle(Color.white.opacity(0.6)).monospacedDigit()
            }
            .contentTransition(.opacity)
            .accessibilityElement(children: .combine)
        case .fertig:
            VStack(spacing: 6) {
                Text("Geschafft").font(.system(size: 30, weight: .bold))
                Text("\(habit.name) ist für heute erledigt.").font(.system(size: 17)).foregroundStyle(Color.white.opacity(0.7))
            }
            .transition(.scale(scale: 0.9).combined(with: .opacity))
            .accessibilityElement(children: .combine)
        }
    }

    private func zeile(sekunden: Int) -> String {
        let fokussiert = max(gesamt - sekunden, 0)
        return "\(Fokus.uhr(fokussiert)) fokussiert · \(Fortschritt.text(wert: wert, einheit: habit.einheit, ziel: habit.tagesziel))"
    }

    @ViewBuilder
    private var unten: some View {
        switch phase {
        case .einstellen:
            HaltenKnopf(titel: "Gedrückt halten zum Starten") { starten() }
        case .laeuft:
            weisseKapsel(titel: "Pause", symbol: "pause.fill") { pausieren() }
        case .pause:
            VStack(spacing: 14) {
                weisseKapsel(titel: "Weiter", symbol: "play.fill") { weiter() }
                BeendenBalken { abschliessen(fertig: false) }
            }
        case .fertig:
            weisseKapsel(titel: "Fertig", symbol: nil) { dismiss() }
        }
    }

    private func weisseKapsel(titel: String, symbol: String?, aktion: @escaping () -> Void) -> some View {
        Button(action: aktion) {
            HStack(spacing: 8) {
                if let symbol { Image(systemName: symbol).font(.system(size: 15, weight: .semibold)) }
                Text(titel).font(.system(size: 17, weight: .medium))
            }
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(Color.white, in: Capsule())
            .foregroundStyle(.black)
        }
        .buttonStyle(.plain)
    }

    // MARK: Ablauf

    private func restSekunden(jetzt: Date) -> Int {
        switch phase {
        case .einstellen: return fest ?? Int(minuten) * 60
        case .laeuft: return max(Int((ende ?? jetzt).timeIntervalSince(jetzt).rounded(.up)), 0)
        case .pause: return rest
        case .fertig: return 0
        }
    }

    private func starten() {
        gesamt = fest ?? Int(minuten) * 60
        ende = Date().addingTimeInterval(TimeInterval(gesamt))
        withAnimation(ruhig ? nil : .spring(response: 0.5, dampingFraction: 0.85)) { phase = .laeuft }
        FokusLive.starten(name: habit.name, gesamt: gesamt, rest: gesamt)
    }

    private func pausieren() {
        rest = restSekunden(jetzt: Date())
        FokusLive.pausieren(gesamt: gesamt, rest: rest)
        withAnimation(.easeInOut(duration: 0.3)) { phase = .pause }
    }

    private func weiter() {
        ende = Date().addingTimeInterval(TimeInterval(rest))
        FokusLive.weiter(name: habit.name, gesamt: gesamt, rest: rest)
        withAnimation(.easeInOut(duration: 0.3)) { phase = .laeuft }
    }

    /// Timer abgelaufen (erledigt) oder früher beendet (Zeit wird gutgeschrieben).
    private func abschliessen(fertig: Bool) {
        let fokussiert = max(gesamt - (fertig ? 0 : restSekunden(jetzt: Date())), 0)
        wert = Fokus.ergebnis(wert: wert, einheit: habit.einheit, ziel: habit.tagesziel, sekunden: fokussiert, fertig: fertig)
        if fertig {
            // Zweimal vibrieren – nur wenn das Ende gerade eben war (nicht beim späteren Zurückkommen in die App)
            if let ende, Date().timeIntervalSince(ende) < 3 { FokusLive.doppeltVibrieren() }
            FokusLive.fertig(gesamt: gesamt)
            feier += 1
            withAnimation(ruhig ? nil : .spring(response: 0.5, dampingFraction: 0.75)) { phase = .fertig }
        } else {
            FokusLive.beendenSofort()
            dismiss()
        }
    }
}

// MARK: - Uhr

/// Uhr im Glas nach dem Bild des Gründers: dicke Glaskapsel mit türkisem Leuchten an Ober- und Unterkante,
/// dunkles Feld, Ziffern aus Segmenten (wie eine Digitaluhr), schwach sichtbare unbeleuchtete Segmente.
struct FokusUhr: View {
    var text: String
    var leuchtet: Bool
    var feier: Int
    @State private var puls = false
    @Environment(\.accessibilityReduceMotion) private var ruhig

    var body: some View {
        let breite: CGFloat = 316, hoehe: CGFloat = 150
        ZStack {
            // äußeres Glas
            RoundedRectangle(cornerRadius: 62, style: .continuous)
                .fill(LinearGradient(colors: [Color(0x0E3A37).opacity(0.75), Color(0x06201F).opacity(0.85)], startPoint: .top, endPoint: .bottom))
                .background(RoundedRectangle(cornerRadius: 62, style: .continuous).fill(.ultraThinMaterial))
            RoundedRectangle(cornerRadius: 62, style: .continuous)
                .strokeBorder(LinearGradient(colors: [Color(0xBFFFF5).opacity(0.85), Color(0x2FD0D1).opacity(0.35), Color(0xBFFFF5).opacity(0.7)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 3)
            // inneres Feld
            RoundedRectangle(cornerRadius: 48, style: .continuous)
                .fill(LinearGradient(colors: [Color(0x0A2C2A), Color(0x041615)], startPoint: .top, endPoint: .bottom))
                .padding(14)
            RoundedRectangle(cornerRadius: 48, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                .padding(14)
            // Glanz oben links
            RoundedRectangle(cornerRadius: 48, style: .continuous)
                .fill(LinearGradient(colors: [.white.opacity(0.14), .clear], startPoint: .topLeading, endPoint: UnitPoint(x: 0.4, y: 0.5)))
                .padding(14)
            // Lichtstreifen oben und unten
            VStack {
                Capsule().fill(Color(0xA7FFFF)).frame(width: 120, height: 2).blur(radius: 1.5)
                Spacer()
                Capsule().fill(Color(0xA7FFFF)).frame(width: 90, height: 2).blur(radius: 1.5)
            }
            .padding(.vertical, 1)
            .opacity(leuchtet ? 1 : 0.35)

            SegmentText(text: text)
                .frame(height: 64)
                .padding(.horizontal, 34)
                .opacity(leuchtet ? 1 : 0.55)
        }
        .frame(width: breite, height: hoehe)
        .shadow(color: Color(0x2FD0D1).opacity(leuchtet ? (puls ? 0.75 : 0.5) : 0.15), radius: puls ? 30 : 22)
        .scaleEffect(puls ? 1.03 : 1)
        .onChange(of: feier) { _, _ in
            guard !ruhig else { return }
            withAnimation(.easeOut(duration: 0.25)) { puls = true }
            withAnimation(.easeInOut(duration: 0.6).delay(0.25)) { puls = false }
        }
        .accessibilityElement()
        .accessibilityLabel("Restzeit")
        .accessibilityValue(text)
    }
}

/// Ziffern aus sieben Segmenten (eigene Zeichnung, keine fremde Schrift). Unterstützt 0–9 und „:“.
struct SegmentText: View {
    var text: String
    var body: some View {
        GeometryReader { g in
            let h = g.size.height
            let w = h * 0.52
            let lueckeZiffer = h * 0.16
            let breiteDoppelpunkt = h * 0.3
            let zeichen = Array(text)
            let gesamt = zeichen.reduce(CGFloat(0)) { $0 + ($1 == ":" ? breiteDoppelpunkt : w) } + lueckeZiffer * CGFloat(max(zeichen.count - 1, 0))
            let f = min(1, g.size.width / max(gesamt, 1))
            HStack(spacing: lueckeZiffer * f) {
                ForEach(Array(zeichen.enumerated()), id: \.offset) { _, c in
                    if c == ":" {
                        Doppelpunkt().frame(width: breiteDoppelpunkt * f, height: h * f)
                    } else {
                        Ziffer(wert: Int(String(c)) ?? 0).frame(width: w * f, height: h * f)
                    }
                }
            }
            .frame(width: g.size.width, height: h)
        }
    }
}

private struct Ziffer: View {
    var wert: Int
    // Segmente a b c d e f g
    private static let karte: [[Bool]] = [
        [true, true, true, true, true, true, false],     // 0
        [false, true, true, false, false, false, false], // 1
        [true, true, false, true, true, false, true],    // 2
        [true, true, true, true, false, false, true],    // 3
        [false, true, true, false, false, true, true],   // 4
        [true, false, true, true, false, true, true],    // 5
        [true, false, true, true, true, true, true],     // 6
        [true, true, true, false, false, false, false],  // 7
        [true, true, true, true, true, true, true],      // 8
        [true, true, true, true, false, true, true],     // 9
    ]

    var body: some View {
        let an = Ziffer.karte[min(max(wert, 0), 9)]
        ZStack {
            ForEach(0..<7, id: \.self) { i in
                SegmentForm(index: i)
                    .fill(an[i] ? Color(0xC8FFF4) : Color(0xC8FFF4).opacity(0.06))
            }
        }
        .shadow(color: Color(0x2FD0D1).opacity(0.9), radius: 6)
        .animation(.easeInOut(duration: 0.12), value: wert)
    }
}

/// Ein Segment als Sechseck mit schrägen Enden.
private struct SegmentForm: Shape {
    var index: Int
    func path(in r: CGRect) -> Path {
        let w = r.width, h = r.height
        let d = w * 0.17          // Dicke
        let s = d / 2
        let luecke = d * 0.18
        func waagrecht(_ y: CGFloat) -> Path {
            var p = Path()
            let x0 = s + luecke, x1 = w - s - luecke
            p.move(to: CGPoint(x: x0, y: y))
            p.addLine(to: CGPoint(x: x0 + s, y: y - s))
            p.addLine(to: CGPoint(x: x1 - s, y: y - s))
            p.addLine(to: CGPoint(x: x1, y: y))
            p.addLine(to: CGPoint(x: x1 - s, y: y + s))
            p.addLine(to: CGPoint(x: x0 + s, y: y + s))
            p.closeSubpath()
            return p
        }
        func senkrecht(_ x: CGFloat, _ y0: CGFloat, _ y1: CGFloat) -> Path {
            var p = Path()
            let a = y0 + luecke, b = y1 - luecke
            p.move(to: CGPoint(x: x, y: a))
            p.addLine(to: CGPoint(x: x + s, y: a + s))
            p.addLine(to: CGPoint(x: x + s, y: b - s))
            p.addLine(to: CGPoint(x: x, y: b))
            p.addLine(to: CGPoint(x: x - s, y: b - s))
            p.addLine(to: CGPoint(x: x - s, y: a + s))
            p.closeSubpath()
            return p
        }
        let oben = s, mitte = h / 2, unten = h - s
        let links = s, rechts = w - s
        switch index {
        case 0: return waagrecht(oben)
        case 1: return senkrecht(rechts, oben, mitte)
        case 2: return senkrecht(rechts, mitte, unten)
        case 3: return waagrecht(unten)
        case 4: return senkrecht(links, mitte, unten)
        case 5: return senkrecht(links, oben, mitte)
        default: return waagrecht(mitte)
        }
    }
}

private struct Doppelpunkt: View {
    var body: some View {
        GeometryReader { g in
            let d = g.size.width * 0.6
            VStack(spacing: g.size.height * 0.22) {
                RoundedRectangle(cornerRadius: d * 0.2).fill(Color(0xC8FFF4)).frame(width: d, height: d)
                RoundedRectangle(cornerRadius: d * 0.2).fill(Color(0xC8FFF4)).frame(width: d, height: d)
            }
            .frame(width: g.size.width, height: g.size.height)
            .shadow(color: Color(0x2FD0D1).opacity(0.9), radius: 6)
        }
    }
}

// MARK: - Beenden

/// Glas-Spur mit weißem Griff: ganz nach rechts ziehen beendet den Fokus (gegen versehentliches Beenden).
struct BeendenBalken: View {
    var beenden: () -> Void
    @State private var x: CGFloat = 0
    private let hoehe: CGFloat = 58
    private let griff: CGFloat = 50

    var body: some View {
        GeometryReader { g in
            let weg = g.size.width - griff - 8
            ZStack(alignment: .leading) {
                Capsule().fill(.ultraThinMaterial)
                Capsule().fill(Color.black.opacity(0.25))
                Capsule().strokeBorder(Color.white.opacity(0.16), lineWidth: 0.75)
                Text("Zum Beenden ziehen").font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.55 * (1 - x / max(weg, 1))))
                    .frame(maxWidth: .infinity)
                Circle().fill(.white).frame(width: griff, height: griff)
                    .overlay { Image(systemName: "chevron.right").font(.system(size: 17, weight: .bold)).foregroundStyle(.black) }
                    .offset(x: 4 + x)
                    .gesture(DragGesture()
                        .onChanged { z in x = min(max(z.translation.width, 0), weg) }
                        .onEnded { _ in
                            if x >= weg * 0.92 { x = weg; beenden() } else { withAnimation(.spring(response: 0.35)) { x = 0 } }
                        })
            }
            .environment(\.colorScheme, .dark)
        }
        .frame(height: hoehe)
        .accessibilityElement()
        .accessibilityLabel("Fokus beenden")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { beenden() }
    }
}
