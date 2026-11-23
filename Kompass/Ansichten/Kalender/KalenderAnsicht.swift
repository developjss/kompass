import SwiftUI

/// Kalender (Planen + Kalender in einem), grobe Fassung: Wochenleiste, Tag mit Terminen und Aufgaben, Eingang.
/// [OFFEN] Stundenraster mit Ziehen & Ablegen wie im Klick-Dummy.
struct KalenderAnsicht: View {
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav
    @State private var gewaehlt: Tag?

    var body: some View {
        let z = speicher.zustand
        let T = speicher.heute
        let tag = gewaehlt ?? T
        let e = z.einstellungen
        let termine = Beispieltermine.termine(am: tag, google: e.googleBeispiel, apple: e.appleBeispiel, heute: T)
        let aufgaben = z.aufgaben.filter { $0.datum == tag }.sorted { $0.reihenfolge < $1.reihenfolge }
        let eingang = z.aufgaben.filter { $0.datum == nil && !$0.erledigt }.sorted { $0.reihenfolge < $1.reihenfolge }

        Seite(titel: "Kalender", info: .kalender) {
            HStack {
                Button { gewaehlt = tag.plus(tage: -7) } label: { Image(systemName: "chevron.left").frame(width: 44, height: 44) }
                    .accessibilityLabel("Woche zurück")
                Spacer()
                Text(tag.datum().formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "de_DE"))))
                    .font(.kompass(.headline, .bold))
                Spacer()
                Button { gewaehlt = tag.plus(tage: 7) } label: { Image(systemName: "chevron.right").frame(width: 44, height: 44) }
                    .accessibilityLabel("Woche vor")
            }
            .foregroundStyle(Farbe.akzent)

            Wochenleiste(gewaehlt: tag, heute: T) { gewaehlt = $0 }
                .padding(.bottom, 8)

            if tag != T {
                Button("Heute") { gewaehlt = nil }.font(.kompass(.subheadline, .bold))
                    .padding(.horizontal, 14).frame(minHeight: 36).background(Farbe.akzentWeich, in: Capsule())
            }

            if !(e.googleBeispiel || e.appleBeispiel) {
                PfeilZeile(symbol: "calendar.badge.plus", text: "Google- oder Apple-Kalender verbinden") { nav.blatt = .einstellungen }
                    .padding(.top, 12)
            }

            AbschnittKopf(titel: "Termine")
            GruppierteListe {
                let mitZeit = aufgaben.filter { $0.uhrzeit != nil }
                let liste = Zeitleiste.eintraege(termine: termine, aufgaben: mitZeit, zustand: z)
                if liste.isEmpty { LeerZeile(text: "Keine Termine an diesem Tag.") }
                ForEach(liste) { ZeitleistenZeile(eintrag: $0) }
            }

            AbschnittKopf(titel: "Ohne Uhrzeit")
            GruppierteListe {
                ForEach(aufgaben.filter { $0.uhrzeit == nil }) { AufgabeZeile(aufgabe: $0) }
                AufgabeHinzufuegen(platzhalter: "Aufgabe", datum: tag, prio: .normal)
            }

            AbschnittKopf(titel: "Eingang") { Text("\(eingang.count)").foregroundStyle(Farbe.zweitrangig) }
            GruppierteListe {
                if eingang.isEmpty { LeerZeile(text: "Leer – gut so.") }
                ForEach(eingang) { AufgabeZeile(aufgabe: $0) }
                AufgabeHinzufuegen(platzhalter: "Idee", datum: nil, prio: .normal)
            }
        }
    }
}

private struct Wochenleiste: View {
    var gewaehlt: Tag
    var heute: Tag
    var waehlen: (Tag) -> Void
    @Environment(Speicher.self) private var speicher
    private let namen = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]

    var body: some View {
        let z = speicher.zustand
        HStack(spacing: 6) {
            ForEach(0..<7, id: \.self) { i in
                let d = gewaehlt.montag.plus(tage: i)
                let n = z.aufgaben.filter { $0.datum == d && !$0.erledigt }.count
                    + Beispieltermine.termine(am: d, google: z.einstellungen.googleBeispiel, apple: z.einstellungen.appleBeispiel, heute: heute).count
                let an = d == gewaehlt
                Button { waehlen(d) } label: {
                    VStack(spacing: 3) {
                        Text(namen[i]).font(.klein).foregroundStyle(an ? .white.opacity(0.85) : Farbe.zweitrangig)
                        Text("\(d.tag)").font(.kompass(.title3, .bold)).foregroundStyle(an ? .white : (d == heute ? Farbe.akzent : Farbe.text))
                        Text(String(repeating: "•", count: min(n, 3))).font(.caption2).foregroundStyle(an ? .white : Farbe.akzent).frame(height: 10)
                    }
                    .frame(maxWidth: .infinity, minHeight: 64)
                    .background(an ? Farbe.akzent : Farbe.karte, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(d.datum().formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "de_DE")))), \(n) Einträge")
                .accessibilityAddTraits(an ? .isSelected : [])
            }
        }
    }
}
