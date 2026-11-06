import AppKit

// Main entry point for PathPane application
@main
struct PathPaneApp {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}

// MARK: - Application Delegate

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowController: MainWindowController?
    private var viewMenuDelegate: ViewMenuDelegate?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMainMenu()
        createMainWindow()
    }

    private func setupMainMenu() {
        let mainMenu = MenuBuilder.buildMainMenu()
        NSApplication.shared.mainMenu = mainMenu

        // Set up View menu delegate
        viewMenuDelegate = ViewMenuDelegate()
        if let viewMenuItem = mainMenu.items.first(where: { $0.title == "View" }),
           let viewMenu = viewMenuItem.submenu {
            viewMenu.delegate = viewMenuDelegate
        }
    }

    private func createMainWindow() {
        let windowController = MainWindowController()
        windowController.showWindow()
        self.windowController = windowController
    }
}