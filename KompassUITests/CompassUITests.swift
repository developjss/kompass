import XCTest

/// Rundgang durch das Gerüst: drei Tabs sind da und öffnen ihre Seite.
final class CompassUITests: XCTestCase {
    @MainActor
    func testDreiTabs() {
        let app = XCUIApplication()
        app.launch()
        for kennung in ["tab.home", "tab.apps", "tab.timer"] {
            let tab = app.buttons[kennung]
            XCTAssertTrue(tab.waitForExistence(timeout: 5), "Tab \(kennung) fehlt")
            tab.tap()
        }
    }
}
