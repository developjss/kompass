import SwiftUI
import PhotosUI

/// Neuer Habit (über das Plus) – Aussehen 1:1 nach Opals Regel-Blatt („Weekend Limit“), noch ohne Funktion.
/// Namen und Felder werden im nächsten Schritt angepasst. Maße und Farben aus den Vorlagen (Blatt #2C2C2C, Gruppen #363636).
struct HabitNeuBlatt: View {
    @Environment(\.dismiss) private var dismiss
    @State private var tage: Set<Int> = [6, 7]
    /// Zähler je Tag fürs Wackeln, wenn der letzte Tag abgewählt werden soll
    @State private var wackeln = [Int](repeating: 0, count: 7)
    @Environment(\.accessibilityReduceMotion) private var ruhig
    @State private var name = ""
    /// Eigenes Bild (nil = Standardbild „habit-1“)
    @State private var bild: UIImage?
    /// Einheit und Tagesziel (nur Aussehen, noch nicht gespeichert)
    @State private var einheit: Einheit = HabitNeuBlatt.startEinheit
    @State private var ziel: Double = HabitNeuBlatt.startEinheit.standard
    @State private var unterblatt: Unterblatt?

    enum Unterblatt: String, Identifiable { case bild, einheit, ziel; var id: String { rawValue } }

    /// Für Testbilder: `-einheit <id>` wählt die Einheit vor.
    static var startEinheit: Einheit {
        let a = ProcessInfo.processInfo.arguments
        if let i = a.firstIndex(of: "-einheit"), i + 1 < a.count, let e = Einheit.alle.first(where: { $0.id == a[i + 1] }) { return e }
        return .minuten
    }
    @FocusState private var schreibt: Bool

    var body: some View {
        VStack(spacing: 12) {
            // Kopf: Schließen · Titel · Bearbeiten
            ZStack {
                // Name des Habits: kleines Feld in grauer Kapsel, mittig
                TextField("", text: $name, prompt: Text("Name").foregroundStyle(Color(0x8E8E93)))
                    .font(.system(size: 17, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .focused($schreibt)
                    .submitLabel(.done)
                    .padding(.horizontal, 14)
                    .frame(width: 180, height: 38)
                    .background(Color(0x3A3A3A).opacity(0.75), in: Capsule())
                    .overlay { Capsule().strokeBorder(Color.white.opacity(schreibt ? 0.22 : 0.08), lineWidth: 0.5) }
                    .tint(Color(Dunkel.akzentA))
                    .accessibilityLabel("Name des Habits")
                HStack {
                    BlattKnopf(symbol: "xmark", beschriftung: "Schließen") { dismiss() }
                    Spacer()
                    BlattKnopf(symbol: "pencil", beschriftung: "Bearbeiten") {}
                }
            }
            .padding(.bottom, 8)

            BlattGruppe {
                Button { unterblatt = .bild } label: {
                    BlattZeile(titel: "Bild") {
                        HabitVorschau(bild: bild, groesse: 26)
                        Image(systemName: "chevron.right").font(.system(size: 14, weight: .semibold)).foregroundStyle(Color(0x9A9A9E))
                    }
                }
                .buttonStyle(.plain)
            }

            BlattGruppe {
                Button { unterblatt = .einheit } label: {
                    BlattZeile(titel: "Einheit") { BlattWert(einheit.name) }
                }
                .buttonStyle(.plain)
                BlattTrenner()
                Button { unterblatt = .ziel } label: {
                    BlattZeile(titel: "Ziel", unter: "Täglich") {
                        if einheit.auswahl == .keine {
                            Text(einheit.text(ziel)).font(.system(size: 17)).foregroundStyle(Color(0x9A9A9E))
                        } else {
                            BlattWert(einheit.text(ziel))
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(einheit.auswahl == .keine)
            }

            BlattGruppe {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("An diesen Tagen").font(.system(size: 17))
                        Spacer()
                        Text(Wochentage.text(tage)).font(.system(size: 17)).foregroundStyle(Color(0x9A9A9E))
                            .contentTransition(.opacity)
                            .animation(.easeInOut(duration: 0.2), value: tage)
                    }
                    .accessibilityElement(children: .combine)
                    HStack(spacing: 0) {
                        ForEach(0..<7, id: \.self) { i in
                            TagKreis(buchstabe: Wochentage.buchstaben[i], name: Wochentage.namen[i],
                                     an: tage.contains(i + 1), wackeln: wackeln[i]) {
                                let geaendert = withAnimation(ruhig ? nil : .spring(response: 0.28, dampingFraction: 0.62)) {
                                    Wochentage.umschalten(i + 1, in: &tage)
                                }
                                if !geaendert, !ruhig { withAnimation(.linear(duration: 0.36)) { wackeln[i] += 1 } }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .sensoryFeedback(.selection, trigger: tage)
                }
                .padding(.horizontal, 18).padding(.vertical, 14)
            }

            BlattGruppe {
                BlattZeile(titel: "Schwierigkeit") {
                    Text("Leicht").font(.system(size: 17)).foregroundStyle(Color(0x9A9A9E))
                    Image(systemName: "chevron.right").font(.system(size: 14, weight: .semibold)).foregroundStyle(Color(0x9A9A9E))
                }
            }
            .padding(.top, 10)

            (Text("Damit nur die Nutzung auf diesem iPhone zählt, schalte in den Bildschirmzeit-Einstellungen „Geräteübergreifend teilen“ aus. ")
             + Text("Mehr dazu").underline().foregroundColor(Color(0x9EF0CF)))
                .font(.system(size: 13)).foregroundStyle(Color(0x8E8E93))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)

            Spacer(minLength: 4)

            HaltenKnopf(titel: "Gedrückt halten zum Festlegen") { dismiss() }
        }
        .padding(.horizontal, 16)
        .padding(.top, 18)
        .padding(.bottom, 20)
        .foregroundStyle(DFarbe.text)
        .sheet(item: $unterblatt) { b in
            switch b {
            case .bild: BildWahlBlatt(bild: $bild)
            case .einheit: EinheitBlatt(einheit: $einheit)
            case .ziel: ZielBlatt(einheit: einheit, wert: $ziel)
            }
        }
        .onChange(of: einheit) { _, neu in ziel = neu.standard }
        .task {
            // Für Testbilder: `-einheitWahl` / `-zielWahl` öffnet das Unterblatt direkt
            let a = ProcessInfo.processInfo.arguments
            guard a.contains("-einheitWahl") || a.contains("-zielWahl") else { return }
            try? await Task.sleep(for: .seconds(0.8))
            unterblatt = a.contains("-einheitWahl") ? .einheit : .ziel
        }
        .presentationDetents([.height(612)])
        .presentationBackground { ZStack { Rectangle().fill(.ultraThinMaterial); Color(0x2C2C2C).opacity(0.62) } }
        .presentationCornerRadius(Dunkel.blattRadius)
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }
}

/// Runder Knopf im Blattkopf (Ø 44, etwas heller als das Blatt).
struct BlattKnopf: View {
    var symbol: String
    var beschriftung: String
    var aktion: () -> Void
    var body: some View {
        Button(action: aktion) {
            Image(systemName: symbol).font(.system(size: 16, weight: .semibold))
                .frame(width: 44, height: 44)
                .background(Color(0x3F3F3F), in: Circle())
                .foregroundStyle(DFarbe.text)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(beschriftung)
    }
}

struct BlattGruppe<Inhalt: View>: View {
    @ViewBuilder var inhalt: Inhalt
    var body: some View {
        VStack(spacing: 0) { inhalt }
            .background(Color(0x3A3A3A).opacity(0.75), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Color.white.opacity(0.06), lineWidth: 0.5) }
    }
}

struct BlattZeile<Rechts: View>: View {
    var titel: String
    var unter: String?
    @ViewBuilder var rechts: Rechts
    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(titel).font(.system(size: 17))
                if let unter { Text(unter).font(.system(size: 15)).foregroundStyle(Color(0x9A9A9E)) }
            }
            Spacer()
            rechts
        }
        .padding(.horizontal, 18)
        .frame(minHeight: unter == nil ? 52 : 62)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// BlattWert mit Auf-/Ab-Pfeilen (Auswahl-Rad folgt mit der Funktion).
struct BlattWert: View {
    var text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        HStack(spacing: 6) {
            Text(text).font(.system(size: 17)).foregroundStyle(Color(0x9A9A9E))
            Image(systemName: "chevron.up.chevron.down").font(.system(size: 13, weight: .semibold)).foregroundStyle(Color(0x9A9A9E))
        }
    }
}

struct BlattTrenner: View {
    var body: some View { Rectangle().fill(Color.white.opacity(0.08)).frame(height: 0.5).padding(.leading, 18) }
}

/// Vorschau des Habit-Bilds: eigenes Bild oder Standardbild, rund wie in der Habit-Reihe.
private struct HabitVorschau: View {
    var bild: UIImage?
    var groesse: CGFloat
    var body: some View {
        Group {
            if let bild { Image(uiImage: bild).resizable().scaledToFill() } else { Image("habit-1").resizable().scaledToFill() }
        }
        .frame(width: groesse, height: groesse)
        .clipShape(Circle())
        .overlay { Circle().strokeBorder(Color(0x2B2B2D), lineWidth: max(1, groesse * 0.055)) }
        .accessibilityHidden(true)
    }
}

/// Bild wählen: große Vorschau, Empfehlung zur Größe, Fotos öffnen, Standardbild zurück – gleiches Blatt-Design.
private struct BildWahlBlatt: View {
    @Binding var bild: UIImage?
    @Environment(\.dismiss) private var dismiss
    @State private var auswahl: PhotosPickerItem?
    @State private var laedt = false
    @State private var fehler = false

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Text("Bild").font(.system(size: 18, weight: .semibold))
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").font(.system(size: 16, weight: .semibold))
                            .frame(width: 44, height: 44).background(Color(0x3F3F3F), in: Circle())
                    }
                    .buttonStyle(.plain).accessibilityLabel("Schließen")
                    Spacer()
                }
            }

            ZStack {
                HabitVorschau(bild: bild, groesse: 120)
                if laedt { ProgressView().tint(.white) }
                Image(systemName: "play.fill").font(.system(size: 34)).foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.45), radius: 5, y: 1).offset(x: 2).opacity(laedt ? 0 : 1)
            }
            .padding(.top, 4)

            // Empfehlung zur Bildgröße
            VStack(spacing: 4) {
                Text("Empfehlung").font(.system(size: 13, weight: .semibold)).foregroundStyle(Color(0x9EF0CF))
                Text("Quadratisch, mindestens 600 × 600 Pixel. Das Motiv in die Mitte – der Rand wird rund abgeschnitten.")
                    .font(.system(size: 15)).foregroundStyle(Color(0x9A9A9E)).multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 18).padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(Color(0x3A3A3A).opacity(0.75), in: RoundedRectangle(cornerRadius: 22, style: .continuous))

            if fehler {
                Text("Das Bild konnte nicht geladen werden. Bitte ein anderes wählen.").font(.system(size: 13)).foregroundStyle(DFarbe.rot)
            }

            PhotosPicker(selection: $auswahl, matching: .images) {
                Label("Aus Fotos wählen", systemImage: "photo.on.rectangle")
                    .font(.system(size: 17, weight: .medium))
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .background(Color.white, in: Capsule())
                    .foregroundStyle(.black)
            }
            .buttonStyle(.plain)

            Button { bild = nil; dismiss() } label: {
                Text("Standardbild verwenden").font(.system(size: 15, weight: .medium)).foregroundStyle(Color(0x9A9A9E))
                    .frame(minHeight: 44)
            }
            .buttonStyle(.plain)
            .opacity(bild == nil ? 0.4 : 1)
            .disabled(bild == nil)
        }
        .padding(.horizontal, 16).padding(.top, 18).padding(.bottom, 16)
        .foregroundStyle(DFarbe.text)
        .onChange(of: auswahl) { _, neu in
            guard let neu else { return }
            laedt = true; fehler = false
            Task {
                let daten = try? await neu.loadTransferable(type: Data.self)
                await MainActor.run {
                    laedt = false
                    if let d = daten, let b = UIImage(data: d) { bild = b; dismiss() } else { fehler = true }
                }
            }
        }
        .presentationDetents([.height(450)])
        .presentationBackground { ZStack { Rectangle().fill(.ultraThinMaterial); Color(0x2C2C2C).opacity(0.62) } }
        .presentationCornerRadius(Dunkel.blattRadius)
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }
}

/// Ein Tag im Blatt: weißer Kreis = gewählt. Antippen schaltet um, beim letzten Tag wackelt der Kreis.
private struct TagKreis: View {
    var buchstabe: String
    var name: String
    var an: Bool
    var wackeln: Int
    var tippen: () -> Void

    var body: some View {
        Button(action: tippen) {
            Text(buchstabe).font(.system(size: 14, weight: .semibold))
                .foregroundStyle(an ? Color.black : DFarbe.text)
                .frame(width: 36, height: 36)
                .background {
                    ZStack {
                        Circle().fill(Color(0x242424))
                        Circle().fill(.white).scaleEffect(an ? 1 : 0.4).opacity(an ? 1 : 0)
                    }
                }
                .overlay { Circle().strokeBorder(Color.white.opacity(an ? 0 : 0.08), lineWidth: 0.5) }
                .scaleEffect(an ? 1 : 0.96)
                .frame(width: 44, height: 44)
                .contentShape(Circle())
                .padding(.vertical, -4)   // größere Tippfläche, Zeile bleibt 36 pt hoch wie im Vorbild
        }
        .buttonStyle(.plain)
        .modifier(Wackeln(anzahl: CGFloat(wackeln)))
        .accessibilityLabel(name)
        .accessibilityAddTraits(an ? .isSelected : [])
        .accessibilityHint(an ? "Tippen zum Abwählen" : "Tippen zum Auswählen")
    }
}

/// Kurzes Wackeln zur Seite (3 Ausschläge je Auslösung).
private struct Wackeln: GeometryEffect {
    var anzahl: CGFloat
    var animatableData: CGFloat {
        get { anzahl }
        set { anzahl = newValue }
    }
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 4 * sin(anzahl * .pi * 6), y: 0))
    }
}
