import XCTest

/// UI-Tests über die ganze App (Full-Test): jeder Tab, die wichtigsten Abläufe, große Schrift.
/// Start immer mit frischen Demo-Daten („-demoNeu“), Ergebnisse als Bildschirmfotos im Testbericht.
@MainActor
final class KompassUITests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
    }

    private func starten(_ extra: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-demoNeu"] + extra
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 15), "Tab-Leiste erscheint nicht")
        return app
    }

    private func foto(_ app: XCUIApplication, _ name: String) {
        let a = XCTAttachment(screenshot: app.screenshot())
        a.name = name
        a.lifetime = .keepAlways
        add(a)
    }

    private func tab(_ app: XCUIApplication, _ name: String) {
        let b = app.tabBars.buttons[name]
        XCTAssertTrue(b.waitForExistence(timeout: 5), "Tab \(name) fehlt")
        b.tap()
    }

    /// Text irgendwo auf dem Bildschirm (auch in Knöpfen und Zellen)
    private func sichtbar(_ app: XCUIApplication, _ text: String, timeout: TimeInterval = 5) -> Bool {
        app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch.waitForExistence(timeout: timeout)
    }

    // MARK: Rundgang

    func testRundgangAlleTabs() {
        let app = starten()
        XCTAssertTrue(sichtbar(app, "Home"))
        XCTAssertTrue(sichtbar(app, "Dein Tag im Blick"))
        XCTAssertTrue(sichtbar(app, "Heute offen"))
        foto(app, "Home")

        tab(app, "Kalender")
        XCTAssertTrue(app.buttons["Tag"].waitForExistence(timeout: 5))
        XCTAssertTrue(sichtbar(app, "Als Nächstes"))
        foto(app, "Kalender Tag")

        tab(app, "Assistent")
        XCTAssertTrue(app.textViews.firstMatch.waitForExistence(timeout: 5) || app.textFields.firstMatch.waitForExistence(timeout: 2))
        foto(app, "Lotse")

        tab(app, "Fortschritt")
        XCTAssertTrue(app.buttons["Ziele"].waitForExistence(timeout: 5))
        XCTAssertTrue(sichtbar(app, "Auf Kurs"))
        foto(app, "Fortschritt Ziele")
        app.buttons["Habits"].tap()
        XCTAssertTrue(sichtbar(app, "geschafft"))
        foto(app, "Fortschritt Habits")

        tab(app, "Rückblick")
        XCTAssertTrue(sichtbar(app, "deiner Pläne geschafft"))
        XCTAssertTrue(sichtbar(app, "Fokuszeit"))
        foto(app, "Rückblick")
    }

    // MARK: Kalender

    func testKalenderAnsichtenUmschalten() {
        let app = starten()
        tab(app, "Kalender")
        for (knopf, erwartet) in [("Woche", "Empfehlung"), ("Monat", "Tag ›"), ("Jahr", "Je dunkler"), ("Tag", "Empfehlung")] {
            app.buttons[knopf].firstMatch.tap()
            XCTAssertTrue(sichtbar(app, erwartet), "\(knopf): „\(erwartet)“ fehlt")
            foto(app, "Kalender \(knopf)")
        }
        // Vor und zurück blättern, dann „Heute“
        app.buttons["Weiter"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Heute"].waitForExistence(timeout: 3))
        app.buttons["Heute"].tap()
    }

    /// Geführtes Anlegen: Titel → Wann → Details → Fertig → Anlegen
    func testTerminAnlegenGefuehrt() {
        let app = starten()
        tab(app, "Kalender")
        app.buttons["+ Neu"].tap()
        let titel = app.textViews.firstMatch.waitForExistence(timeout: 5) ? app.textViews.firstMatch : app.textFields.firstMatch
        XCTAssertTrue(titel.waitForExistence(timeout: 5))
        titel.tap()
        titel.typeText("UI Testtermin")
        let weiter = app.buttons["neu.weiter"]
        XCTAssertTrue(weiter.waitForExistence(timeout: 3))
        weiter.tap()                                   // → Wann
        XCTAssertTrue(sichtbar(app, "Wann findet er statt?"))
        foto(app, "Neu Termin Wann")
        weiter.tap()                                   // → Details
        XCTAssertTrue(sichtbar(app, "Zählt er für etwas?"))
        weiter.tap()                                   // → Fertig
        XCTAssertTrue(sichtbar(app, "Passt das so?"))
        foto(app, "Neu Termin Fertig")
        weiter.tap()                                   // Anlegen
        XCTAssertTrue(sichtbar(app, "UI Testtermin", timeout: 5), "Neuer Termin erscheint nicht")
    }

    /// Erster Schritt „Was möchtest du anlegen?“ mit vier Kacheln, Habit-Vorschlag aus dem Titel
    func testNeuWasUndHabitVorschlag() {
        let app = starten()
        app.buttons["+ Neu"].firstMatch.tap()
        XCTAssertTrue(sichtbar(app, "Was möchtest du anlegen?"))
        foto(app, "Neu Was")
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Habit")).firstMatch.tap()
        let titel = app.textViews.firstMatch.waitForExistence(timeout: 5) ? app.textViews.firstMatch : app.textFields.firstMatch
        titel.tap()
        titel.typeText("20 Minuten lesen")
        XCTAssertTrue(sichtbar(app, "Vorschlag übernehmen: 20 Minuten pro Tag") || sichtbar(app, "20 Minuten pro Tag"), "Kein Vorschlag aus dem Titel")
        foto(app, "Neu Habit Vorschlag")
    }

    /// Dein Tag als Reel: Start, Slides, Fertig
    func testTagReel() {
        let app = starten()
        let karte = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Dein Tag im Blick")).firstMatch
        XCTAssertTrue(karte.waitForExistence(timeout: 5))
        karte.tap()
        let weiter = app.buttons["reel.weiter"]
        XCTAssertTrue(weiter.waitForExistence(timeout: 5), "Reel öffnet nicht")
        foto(app, "Reel 1")
        var n = 0
        while weiter.exists && n < 8 { weiter.tap(); n += 1; usleep(300_000) }
        XCTAssertTrue(sichtbar(app, "Dein Tag im Blick", timeout: 5), "Reel schließt nicht")
    }

    // MARK: Home

    func testAufgabeAnlegenUndAbhaken() {
        let app = starten()
        let feld = app.textFields["Aufgabe für heute"]
        var versuche = 0
        while !feld.isHittable && versuche < 6 { app.swipeUp(); versuche += 1 }
        XCTAssertTrue(feld.waitForExistence(timeout: 5))
        feld.tap()
        feld.typeText("UI Aufgabe\n")
        // Der Haken trägt den Titel als Beschriftung und „offen“/„erledigt“ als Wert
        let haken = app.buttons.matching(NSPredicate(format: "label == %@ AND value == %@", "UI Aufgabe", "offen")).firstMatch
        XCTAssertTrue(haken.waitForExistence(timeout: 5), "Neue Aufgabe erscheint nicht")
        haken.tap()
        // Erledigtes verschwindet aus „Heute offen“ und zählt oben in der Jetzt-Karte mit
        let weg = NSPredicate(format: "exists == false")
        expectation(for: weg, evaluatedWith: haken)
        waitForExpectations(timeout: 5)
        foto(app, "Aufgabe erledigt")
    }

    func testJetztKarteHatAktion() {
        let app = starten()
        let knoepfe = ["Fokus starten", "Menge eintragen", "Abhaken", "Im Kalender", "Plan für morgen", "Fokus öffnen"]
        XCTAssertTrue(knoepfe.contains { app.buttons[$0].waitForExistence(timeout: 2) }, "Jetzt-Karte ohne Knopf")
    }

    // MARK: Fortschritt

    func testHabitSeiteUndEditor() {
        let app = starten()
        tab(app, "Fortschritt")
        app.buttons["Habits"].tap()
        // Zeile unter „Diese Woche“ öffnet die Habit-Seite (die Heute-Zeile öffnet „Menge eintragen“)
        let zeile = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@ AND label CONTAINS %@", "Buch lesen", "diese Woche")).firstMatch
        var versuche = 0
        while !zeile.isHittable && versuche < 8 { app.swipeUp(); versuche += 1 }
        zeile.tap()
        XCTAssertTrue(sichtbar(app, "Fakten"), "Habit-Seite öffnet nicht")
        foto(app, "Habit-Seite")
        let titelZeile = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Titel")).firstMatch
        versuche = 0
        while !titelZeile.isHittable && versuche < 6 { app.swipeUp(); versuche += 1 }
        titelZeile.tap()
        XCTAssertTrue(app.buttons["Sichern"].waitForExistence(timeout: 5), "Editor öffnet nicht")
        app.buttons["Abbrechen"].tap()
    }

    func testZielSeite() {
        let app = starten()
        tab(app, "Fortschritt")
        app.buttons["Ziele"].tap()
        let karte = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "%")).element(boundBy: 0)
        XCTAssertTrue(karte.waitForExistence(timeout: 5))
        karte.tap()
        XCTAssertTrue(sichtbar(app, "Meilensteine"), "Ziel-Seite öffnet nicht")
        XCTAssertTrue(sichtbar(app, "Einstellungen") && sichtbar(app, "Bis wann"), "Einstellungs-Kacheln fehlen")
        foto(app, "Ziel-Seite")
        // Verfeinern-Kachel → Kacheln (Aufgaben … Details, Geschafft?) → Details
        app.buttons["ziel.verfeinern"].tap()
        XCTAssertTrue(sichtbar(app, "Geschafft?") || sichtbar(app, "Aufgaben"), "Verfeinern öffnet nicht")
        let details = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Details")).firstMatch
        for _ in 0..<6 where !details.isHittable { app.swipeUp() }
        details.tap()
        XCTAssertTrue(sichtbar(app, "Worum es geht"), "Details-Seite öffnet nicht")
        XCTAssertTrue(sichtbar(app, "Ziel löschen"), "Löschen fehlt in Details")
        foto(app, "Ziel Details")
    }

    // MARK: Lotse

    func testLotseBeantwortetAlsNaechstes() {
        let app = starten()
        tab(app, "Assistent")
        let feld = app.textViews.firstMatch.exists ? app.textViews.firstMatch : app.textFields.firstMatch
        XCTAssertTrue(feld.waitForExistence(timeout: 5))
        feld.tap()
        feld.typeText("Was steht als Nächstes an?")
        app.buttons["lotse.senden"].tap()
        XCTAssertTrue(sichtbar(app, "Als Nächstes:", timeout: 10) || sichtbar(app, "In den nächsten 7 Tagen", timeout: 2), "Lotse antwortet nicht")
        foto(app, "Lotse Antwort")
    }

    /// Befund aus dem UI-Test: die Senden-Taste der Tastatur muss senden (mehrzeiliges Feld)
    func testLotseSendetMitTastatur() {
        let app = starten()
        tab(app, "Assistent")
        let feld = app.textViews.firstMatch.exists ? app.textViews.firstMatch : app.textFields.firstMatch
        XCTAssertTrue(feld.waitForExistence(timeout: 5))
        feld.tap()
        feld.typeText("Wie voll ist mein Tag?\n")
        XCTAssertTrue(sichtbar(app, "verplant", timeout: 10), "Tastatur-Senden schickt nicht ab")
    }

    // MARK: Barrierefreiheit

    func testGrosseSchriftAlleTabs() {
        let app = starten(["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityL"])
        for t in ["Home", "Kalender", "Fortschritt", "Rückblick"] {
            tab(app, t)
            sleep(1)
            foto(app, "Große Schrift \(t)")
        }
    }
}
