import SwiftUI
import UniformTypeIdentifiers

// Ziehen im Kalender (24.11.2026): Einträge behalten beim Ziehen ihre Größe; eine Vorschau zeigt genau,
// wo sie landen (Uhrzeit auf 15 Minuten gerastet). Halten (0,3 s) und ziehen; über den oberen Rand = ohne Uhrzeit.

/// Reine Rechnung fürs Raster (testbar).
enum Zeitraster {
    /// Minute an einer y-Position der Zeitleiste, auf 15 Minuten gerundet.
    nonisolated static func minute(y: CGFloat, hoehe: CGFloat, von: Int) -> Int {
        let m = Double(von * 60) + Double(y / hoehe) * 60
        return Int((m / 15).rounded()) * 15
    }

    /// Neuer Start nach einer Verschiebung um `dy`, gerastet und so begrenzt, dass der Eintrag in `von…bis` bleibt.
    nonisolated static func verschoben(start: Int, dauer: Int, dy: CGFloat, hoehe: CGFloat, von: Int, bis: Int) -> Int {
        let roh = Double(start) + Double(dy / hoehe) * 60
        let gerastet = Int((roh / 15).rounded()) * 15
        return min(max(von * 60, gerastet), bis * 60 - max(5, dauer))
    }

    /// Wurde der Eintrag über den oberen Rand gezogen (mehr als eine halbe Stunde vor Beginn der Zeitleiste)?
    nonisolated static func ueberRand(start: Int, dy: CGFloat, hoehe: CGFloat, von: Int) -> Bool {
        Double(start) + Double(dy / hoehe) * 60 < Double(von * 60 - 30)
    }

    /// Tagesversatz in der Woche aus der waagerechten Verschiebung (Spaltenbreite inkl. Abstand).
    nonisolated static func tage(dx: CGFloat, spalte: CGFloat) -> Int {
        Int((dx / spalte).rounded())
    }
}

/// Was gerade aus der Vorschlags-Leiste gezogen wird – damit die Vorschau in der Zeitleiste Titel und Länge kennt.
@MainActor
@Observable
final class ZiehZustand {
    static let shared = ZiehZustand()
    var titel = ""
    var dauer = 60
    var farbe = "#3A7262"
    private init() {}
}

/// Vorschau-Kachel: so groß wie der Eintrag, gestrichelter Rand, Uhrzeit.
struct ZiehGeist: View {
    var titel: String
    var farbe: String
    var start: Int
    var dauer: Int
    var body: some View {
        let c = Color(hex: farbe)
        VStack(alignment: .leading, spacing: 1) {
            Text(titel).font(.kompass(.subheadline, .bold)).foregroundStyle(Farbe.text).lineLimit(2)
            Text("\(Tagesplan.uhr(start))–\(Tagesplan.uhr(start + dauer))").font(.footnote.weight(.semibold).monospacedDigit()).foregroundStyle(Farbe.akzent)
        }
        .padding(.horizontal, 8).padding(.vertical, 5)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(c.opacity(0.22), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(Farbe.akzent, style: StrokeStyle(lineWidth: 2, dash: [6, 4])))
        .shadow(color: .black.opacity(0.18), radius: 10, y: 6)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Ablage aus der Vorschlags-Leiste mit Vorschau an der Stelle, an der losgelassen wird.
struct ZeitAblage: ViewModifier {
    var hoehe: CGFloat
    var von: Int
    var bis: Int
    /// Abstand des Rasters vom oberen und linken Rand
    var oben: CGFloat
    var links: CGFloat
    var aktion: ([String], Int) -> Bool
    @State private var minute: Int?
    @State private var abgelegt = 0

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .topLeading) {
                if let m = minute {
                    let z = ZiehZustand.shared
                    GeometryReader { g in
                        ZiehGeist(titel: z.titel, farbe: z.farbe, start: m, dauer: z.dauer)
                            .frame(width: max(40, g.size.width - links - 4), height: max(26, CGFloat(z.dauer) / 60 * hoehe - 2))
                            .offset(x: links, y: oben + CGFloat(m - von * 60) / 60 * hoehe + 1)
                    }
                    .transition(.opacity)
                }
            }
            .onDrop(of: [UTType.text, UTType.plainText, UTType.utf8PlainText], delegate: Delegat(
                setzen: { y in
                    let z = ZiehZustand.shared
                    let m = Zeitraster.minute(y: y - oben - CGFloat(z.dauer) / 60 * hoehe / 2, hoehe: hoehe, von: von)
                    let neu = min(max(von * 60, m), bis * 60 - max(5, z.dauer))
                    if neu != minute { withAnimation(.snappy(duration: 0.12)) { minute = neu } }
                },
                weg: { withAnimation(.snappy(duration: 0.12)) { minute = nil } },
                ablegen: { text in
                    let m = minute
                    minute = nil
                    guard let m else { return }
                    if aktion([text], m) { abgelegt += 1 }
                }))
            .sensoryFeedback(.selection, trigger: minute)
            .sensoryFeedback(.success, trigger: abgelegt)
    }

    private struct Delegat: DropDelegate {
        var setzen: (CGFloat) -> Void
        var weg: () -> Void
        var ablegen: (String) -> Void

        func dropEntered(info: DropInfo) { setzen(info.location.y) }
        func dropUpdated(info: DropInfo) -> DropProposal? { setzen(info.location.y); return DropProposal(operation: .move) }
        func dropExited(info: DropInfo) { weg() }
        func performDrop(info: DropInfo) -> Bool {
            guard let p = info.itemProviders(for: [UTType.text, UTType.plainText, UTType.utf8PlainText]).first else { weg(); return false }
            _ = p.loadObject(ofClass: NSString.self) { obj, _ in
                let text = (obj as? NSString).map { $0 as String }
                Task { @MainActor in if let text { ablegen(text) } else { weg() } }
            }
            return true
        }
    }
}

extension View {
    func zeitAblage(hoehe: CGFloat, von: Int, bis: Int, oben: CGFloat = 0, links: CGFloat = 0,
                    _ aktion: @escaping ([String], Int) -> Bool) -> some View {
        modifier(ZeitAblage(hoehe: hoehe, von: von, bis: bis, oben: oben, links: links, aktion: aktion))
    }

    /// Ziehquelle für Vorschläge: merkt Titel, Länge und Farbe für die Vorschau.
    func vorschlagZiehen(_ nutzlast: String, titel: String, dauer: Int, farbe: String, symbol: String) -> some View {
        onDrag {
            ZiehZustand.shared.titel = titel
            ZiehZustand.shared.dauer = max(15, dauer)
            ZiehZustand.shared.farbe = farbe
            return NSItemProvider(object: nutzlast as NSString)
        } preview: {
            Label(titel, systemImage: symbol).font(.kompass(.subheadline, .bold)).padding(.horizontal, 12).padding(.vertical, 8)
                .background(Farbe.karte, in: Capsule()).overlay(Capsule().strokeBorder(Color(hex: farbe), lineWidth: 2))
        }
    }
}

// MARK: Wiederkehrende Termine: nur dieser oder alle?

/// Eine Änderung an einem wiederkehrenden Termin, die noch gefragt werden muss.
struct SerienAuftrag: Identifiable {
    let id = UUID()
    var titel: String
    /// Kompass: „Alle Termine der Serie“; Apple/Google: „Diesen und alle folgenden“ (so arbeitet der Kalender)
    var allesText: String
    var ausfuehren: (_ nurDieser: Bool) -> Void

    @MainActor
    static func fuer(_ b: Tagesplan.Block, ausfuehren: @escaping (Bool) -> Void) -> SerienAuftrag {
        SerienAuftrag(titel: b.titel, allesText: b.eigenID != nil ? "Alle Termine der Serie" : "Diesen und alle folgenden", ausfuehren: ausfuehren)
    }
}

extension View {
    /// Fragt bei wiederkehrenden Terminen: nur dieser Termin oder die Serie.
    func serienFrage(_ auftrag: Binding<SerienAuftrag?>) -> some View {
        confirmationDialog("Wiederkehrender Termin", isPresented: Binding(get: { auftrag.wrappedValue != nil }, set: { if !$0 { auftrag.wrappedValue = nil } }),
                           titleVisibility: .visible, presenting: auftrag.wrappedValue) { a in
            Button("Nur dieser Termin") { a.ausfuehren(true) }
            Button(a.allesText) { a.ausfuehren(false) }
            Button("Abbrechen", role: .cancel) {}
        } message: { a in
            Text("„\(a.titel)“ wiederholt sich. Soll die Änderung nur für diesen Termin gelten?")
        }
    }
}
