import XCTest

/// Rundgang durch das Gerüst: drei Tabs sind da und öffnen ihre Seite.
final class CompassUITests: XCTestCase {
    @MainActor
    func testDreiTabs() {
        let app = XCUIApplication()
        app.launch()
        for titel in ["Home", "Meine Apps", "Timer"] {
            let tab = app.tabBars.buttons[titel]
            XCTAssertTrue(tab.waitForExistence(timeout: 5), "Tab \(titel) fehlt")
            tab.tap()
        }
    }
}
