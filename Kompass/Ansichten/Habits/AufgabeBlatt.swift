import SwiftUI

/// Blatt beim Antippen einer Aufgabe – Aufbau wie das Habit-Blatt (nach Opals „Study Time“): großes rundes Bild mit Ring,
/// Status in Verlaufsschrift, großer Name. Darunter die Schritte als Glas-Liste zum Abhaken und unten der Compass-Balken
/// für die ganze Aufgabe. Oben rechts Fokus und Bearbeiten.
struct AufgabeBlatt: View {
    @Binding var aufgabe: Aufgabe
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var ruhig
    @State private var anteil: Double = 0
    @State private var feier = 0
    @State private var fokusOffen = false
    @State private var hinweis = false

    var body: some View {
        VStack(spacing: 0) {
            kopf
            ScrollView {
                VStack(spacing: 0) {
                    VStack(spacing: 4) {
                        Text(AufgabenRegel.zeile(aufgabe)).font(.system(size: 15, weight: .semibold)).monospacedDigit()
                            .foregroundStyle(DFarbe.akzent)
                            .contentTransition(.opacity)
                        Text(aufgabe.name).font(.system(size: 28, weight: .semibold)).accessibilityAddTraits(.isHeader)
                    }
                    .animation(.snappy(duration: 0.25), value: AufgabenRegel.zeile(aufgabe))
                    .padding(.top, 14)
                    .accessibilityElement(children: .combine)

                    if !aufgabe.schritte.isEmpty { schritte.padding(.top, 22) }
                }
                .padding(.bottom, 12)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)

            CompassBalken(anteil: $anteil,
                          wertText: aufgabe.erledigt ? "Erledigt" : "Ganz nach rechts = erledigt",
                          stufen: 1, feier: feier) { ende in
                if ende >= 0.97 {
                    anteil = 1
                    if !aufgabe.erledigt {
                        withAnimation(ruhig ? nil : .spring(response: 0.35, dampingFraction: 0.7)) { AufgabenRegel.setzeErledigt(true, in: &aufgabe) }
                        feier += 1
                    }
                } else {
                    anteil = 0
                    if aufgabe.erledigt {
                        withAnimation(.snappy) { AufgabenRegel.setzeErledigt(false, in: &aufgabe) }
                    }
                }
            }
            .padding(.horizontal, 6)
            .padding(.top, 40)
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 16).padding(.top, 18).padding(.bottom, 16)
        .background(alignment: .top) {
            // Schein in der Farbe des Bilds von oben
            Image(aufgabe.bild).resizable().scaledToFill()
                .frame(width: 320, height: 220).blur(radius: 60).opacity(0.5)
                .mask(RadialGradient(colors: [.black, .clear], center: .top, startRadius: 10, endRadius: 230))
                .offset(y: -60)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .onAppear { anteil = aufgabe.erledigt ? 1 : 0 }
        .onChange(of: aufgabe.erledigt) { _, fertig in withAnimation(.spring(response: 0.4)) { anteil = fertig ? 1 : 0 } }
        .sensoryFeedback(.success, trigger: feier)
        .habitBlatt(hoehe: hoehe)
        .fullScreenCover(isPresented: $fokusOffen) {
            // Fokus für die Aufgabe: wie ein Habit ohne Zeit (Dauer frei), am Ende Abfrage „erledigt?“
            FokusAnsicht(habit: Habit(id: "aufgabe-\(aufgabe.id)", name: aufgabe.name, bild: aufgabe.bild,
                                      einheit: .keine, tagesziel: 1, tage: Set(1...7)),
                         wert: Binding(get: { aufgabe.erledigt ? 1 : 0 },
                                       set: { v in AufgabenRegel.setzeErledigt(v >= 1, in: &aufgabe) }))
        }
        .alert("Bearbeiten kommt im nächsten Schritt", isPresented: $hinweis) { Button("OK", role: .cancel) {} }
    }

    /// Höhe passt sich der Zahl der Schritte an (höchstens fast ganzer Bildschirm).
    private var hoehe: CGFloat {
        min(372 + CGFloat(aufgabe.schritte.count) * 52 + (aufgabe.schritte.isEmpty ? 0 : 22), 760)
    }

    private var kopf: some View {
        ZStack(alignment: .top) {
            HStack(alignment: .top) {
                BlattKnopf(symbol: "xmark", beschriftung: "Schließen") { dismiss() }
                Spacer()
                HStack(spacing: 10) {
                    BlattKnopf(symbol: "timer", beschriftung: "Fokus") { fokusOffen = true }
                    // PLATZHALTER: Bearbeiten (gleiches Blatt wie Anlegen) folgt im nächsten Schritt
                    BlattKnopf(symbol: "pencil", beschriftung: "Bearbeiten") { hinweis = true }
                }
            }
            HabitRund(bild: aufgabe.bild, anteil: AufgabenRegel.anteil(aufgabe), durchmesser: 112)
                .shadow(color: .black.opacity(0.45), radius: 18, y: 8)
                .padding(.top, 4)
        }
    }

    private var schritte: some View {
        BlattGruppe {
            ForEach(Array(aufgabe.schritte.enumerated()), id: \.element.id) { i, s in
                if i > 0 { BlattTrenner() }
                Button {
                    let warErledigt = aufgabe.erledigt
                    withAnimation(ruhig ? nil : .spring(response: 0.3, dampingFraction: 0.65)) {
                        AufgabenRegel.umschalten(s.id, in: &aufgabe)
                    }
                    if aufgabe.erledigt && !warErledigt { feier += 1 }
                } label: {
                    HStack(spacing: 14) {
                        AbhakKreis(an: s.erledigt)
                        Text(s.text).font(.system(size: 17))
                            .foregroundStyle(s.erledigt ? Color(0x8E8E93) : DFarbe.text)
                            .strikethrough(s.erledigt, color: Color(0x8E8E93))
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .frame(minHeight: 52)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.selection, trigger: s.erledigt)
                .accessibilityLabel(s.text)
                .accessibilityAddTraits(s.erledigt ? .isSelected : [])
                .accessibilityHint(s.erledigt ? "Tippen zum Öffnen" : "Tippen zum Abhaken")
            }
        }
    }
}

/// Runder Abhak-Kreis: offen feine Kante, erledigt im Akzent-Verlauf mit dunklem Haken.
private struct AbhakKreis: View {
    var an: Bool
    var body: some View {
        ZStack {
            Circle().strokeBorder(Color.white.opacity(an ? 0 : 0.35), lineWidth: 1.5)
            Circle().fill(LinearGradient(colors: DFarbe.akzentFarben, startPoint: .topLeading, endPoint: .bottomTrailing))
                .scaleEffect(an ? 1 : 0.3).opacity(an ? 1 : 0)
            Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundStyle(.black)
                .scaleEffect(an ? 1 : 0.3).opacity(an ? 1 : 0)
        }
        .frame(width: 26, height: 26)
        .shadow(color: Color(Dunkel.akzentB).opacity(an ? 0.45 : 0), radius: 6)
    }
}
