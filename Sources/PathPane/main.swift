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
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMainMenu()
        createMainWindow()
    }
    
    private func setupMainMenu() {
        NSApplication.shared.mainMenu = MenuBuilder.buildMainMenu()
    }
    
    private func createMainWindow() {
        let windowController = MainWindowController()
        windowController.showWindow()
        self.windowController = windowController
    }
}