import XCTest

final class TickletUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
        addUIInterruptionMonitor(withDescription: "Input Source Dialog") { _ in
            XCUIApplication().typeKey(.escape, modifierFlags: [])
            return true
        }
    }

    @MainActor
    func testAddTask() throws {
        let app = launchApp()
        let listName = uniqueName(prefix: "List")
        let taskTitle = uniqueName(prefix: "Buy milk")

        createList(listName, app: app)
        selectList(listName, app: app)
        addTask(taskTitle, app: app)

        XCTAssertTrue(elementWithLabel(taskTitle, in: app).waitForExistence(timeout: 2))
    }

    @MainActor
    func testCompleteTaskMovesItemToCompletedSection() throws {
        let app = launchApp()
        let listName = uniqueName(prefix: "List")
        let taskTitle = uniqueName(prefix: "Finish report")

        createList(listName, app: app)
        selectList(listName, app: app)
        addTask(taskTitle, app: app)
        XCTAssertFalse(completedSection(in: app).exists)

        let completeButton = firstTaskCompleteButton(in: app)
        XCTAssertTrue(completeButton.waitForExistence(timeout: 2))
        clickCenter(of: completeButton)

        XCTAssertFalse(elementWithLabel(taskTitle, in: app).waitForExistence(timeout: 1))
        XCTAssertTrue(completedSection(in: app).waitForExistence(timeout: 2))

        openCompletedSection(app: app)
    }

    @MainActor
    func testStarFilterShowsOnlyStarredTasks() throws {
        let app = launchApp()
        let listName = uniqueName(prefix: "List")
        let starredTitle = uniqueName(prefix: "Star me")
        let plainTitle = uniqueName(prefix: "Leave me")

        createList(listName, app: app)
        selectList(listName, app: app)
        addTask(starredTitle, app: app)
        addTask(plainTitle, app: app)

        let starredTaskLabel = elementWithLabel(starredTitle, in: app)
        XCTAssertTrue(starredTaskLabel.waitForExistence(timeout: 2))
        starredTaskLabel.click()

        let starButton = firstTaskStarButton(in: app)
        XCTAssertTrue(starButton.waitForExistence(timeout: 2))
        clickCenter(of: starButton)

        let filterButton = app.buttons["header-filter-toggle"]
        XCTAssertTrue(filterButton.waitForExistence(timeout: 2))
        clickCenter(of: filterButton)

        XCTAssertTrue(elementWithLabel(starredTitle, in: app).waitForExistence(timeout: 2))
        XCTAssertFalse(elementWithLabel(plainTitle, in: app).exists)
    }

    @MainActor
    func testSwitchListShowsTasksForSelectedList() throws {
        let app = launchApp()
        let listName = uniqueName(prefix: "Work")
        let taskA = uniqueName(prefix: "Task A")
        let taskB = uniqueName(prefix: "Task B")

        addTask(taskA, app: app)
        createList(listName, app: app)
        selectList(listName, app: app)
        addTask(taskB, app: app)

        XCTAssertTrue(elementWithLabel(taskB, in: app).waitForExistence(timeout: 2))
        XCTAssertFalse(elementWithLabel(taskA, in: app).exists)

        selectList("マイタスク", app: app)
        XCTAssertTrue(elementWithLabel(taskA, in: app).waitForExistence(timeout: 2))
        XCTAssertFalse(elementWithLabel(taskB, in: app).exists)
    }

    @MainActor
    func testDeleteListRemovesItFromPickerAndFallsBackToDefault() throws {
        let app = launchApp()
        let listName = uniqueName(prefix: "Delete")
        let taskTitle = uniqueName(prefix: "Task")

        createList(listName, app: app)
        selectList(listName, app: app)
        addTask(taskTitle, app: app)

        openHeaderActionsMenu(app: app)
        let deleteItem = app.menuItems["リストを削除"]
        XCTAssertTrue(deleteItem.waitForExistence(timeout: 2))
        deleteItem.click()

        let dialog = app.descendants(matching: .any)["delete-list-dialog"]
        XCTAssertTrue(dialog.waitForExistence(timeout: 2))
        XCTAssertTrue(app.statusItems.firstMatch.exists)

        let deleteButton = app.buttons["delete-list-confirm"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 2))
        deleteButton.click()

        XCTAssertTrue(app.staticTexts["マイタスク"].waitForExistence(timeout: 2))

        let picker = app.descendants(matching: .any)["header-list-picker"]
        XCTAssertTrue(picker.waitForExistence(timeout: 2))
        picker.click()
        XCTAssertFalse(app.menuItems[listName].waitForExistence(timeout: 1))
    }

    @MainActor
    func testDeleteListCancelKeepsListAvailable() throws {
        let app = launchApp()
        let listName = uniqueName(prefix: "Keep")

        createList(listName, app: app)
        selectList(listName, app: app)

        openHeaderActionsMenu(app: app)
        let deleteItem = app.menuItems["リストを削除"]
        XCTAssertTrue(deleteItem.waitForExistence(timeout: 2))
        deleteItem.click()

        let cancelButton = app.buttons["delete-list-cancel"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 2))
        cancelButton.click()

        XCTAssertFalse(app.descendants(matching: .any)["delete-list-dialog"].exists)

        let picker = app.descendants(matching: .any)["header-list-picker"]
        XCTAssertTrue(picker.waitForExistence(timeout: 2))
        picker.click()
        XCTAssertTrue(app.menuItems[listName].waitForExistence(timeout: 2))
    }
}

private extension TickletUITests {
    @MainActor
    func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        let statusItem = app.statusItems.firstMatch
        XCTAssertTrue(statusItem.waitForExistence(timeout: 5))
        statusItem.click()
        return app
    }

    @MainActor
    func addTask(_ title: String, app: XCUIApplication) {
        dismissTransientDialogIfNeeded(in: app)
        let field = app.descendants(matching: .textField).firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 2))
        field.click()
        field.typeText(title)
        field.typeKey(.return, modifierFlags: [])
        app.typeKey(.escape, modifierFlags: [])
        dismissTransientDialogIfNeeded(in: app)
    }

    @MainActor
    func createList(_ name: String, app: XCUIApplication) {
        let picker = app.descendants(matching: .any)["header-list-picker"]
        XCTAssertTrue(picker.waitForExistence(timeout: 2))
        picker.click()
        let createMenuItem = app.menuItems["新しいリスト"]
        XCTAssertTrue(createMenuItem.waitForExistence(timeout: 2))
        createMenuItem.click()

        let field = app.descendants(matching: .any)["create-list-field"]
        XCTAssertTrue(field.waitForExistence(timeout: 2))
        field.click()
        field.typeText(name)
        let submitButton = app.descendants(matching: .any)["create-list-submit"]
        XCTAssertTrue(submitButton.waitForExistence(timeout: 2))
        submitButton.click()
    }

    @MainActor
    func selectList(_ name: String, app: XCUIApplication) {
        let picker = app.descendants(matching: .any)["header-list-picker"]
        XCTAssertTrue(picker.waitForExistence(timeout: 2))
        picker.click()
        let menuItem = app.menuItems[name]
        XCTAssertTrue(menuItem.waitForExistence(timeout: 2))
        menuItem.click()
    }

    @MainActor
    func openHeaderActionsMenu(app: XCUIApplication) {
        let menu = app.buttons["header-actions-menu"]
        XCTAssertTrue(menu.waitForExistence(timeout: 2))
        menu.click()
    }

    @MainActor
    func openCompletedSection(app: XCUIApplication) {
        let section = completedSection(in: app)
        XCTAssertTrue(section.waitForExistence(timeout: 2))
        section.click()
    }

    @MainActor
    func firstTaskCompleteButton(in app: XCUIApplication) -> XCUIElement {
        let query = app.buttons
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", "task-complete-"))
        return query.element(boundBy: max(query.count - 1, 0))
    }

    @MainActor
    func firstTaskStarButton(in app: XCUIApplication) -> XCUIElement {
        app.buttons
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", "task-star-"))
            .firstMatch
    }

    @MainActor
    func completedSection(in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)["completed-section"]
    }

    @MainActor
    func clickCenter(of element: XCUIElement) {
        dismissTransientDialogIfNeeded(in: XCUIApplication())
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()
    }

    @MainActor
    func elementWithLabel(_ label: String, in app: XCUIApplication) -> XCUIElement {
        let staticText = app.staticTexts[label]
        if staticText.exists {
            return staticText
        }

        return app.descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@", label))
            .firstMatch
    }

    @MainActor
    func dismissTransientDialogIfNeeded(in app: XCUIApplication) {
        let dialog = app.dialogs.firstMatch
        guard dialog.exists else { return }
        app.typeKey(.escape, modifierFlags: [])
    }

    func uniqueName(prefix: String) -> String {
        let suffix = UUID().uuidString.prefix(6)
        return "\(prefix) \(suffix)"
    }
}
