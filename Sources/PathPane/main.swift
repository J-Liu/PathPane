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
    private var settingsWindowController: SettingsWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        createMainWindow()
        setupMainMenu()
    }

    private func setupMainMenu() {
        let mainMenu = MenuBuilder.buildMainMenu()
        NSApplication.shared.mainMenu = mainMenu

        // Set up View menu delegate
        viewMenuDelegate = ViewMenuDelegate(mainWindowController: windowController)
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

    // MARK: - Settings and About

    @objc func showSettings() {
        let settingsWC = SettingsWindowController.shared

        // If window is open and showing About tab, switch to General tab
        if settingsWC.window?.isVisible == true {
            if let tabView = (settingsWC.window?.contentView as? NSView)?.subviews.first as? NSTabView,
               let selectedTab = tabView.selectedTabViewItem,
               selectedTab.identifier as? String == "about" {
                settingsWC.selectTab(withIdentifier: "general")
            }
        } else {
            // Open window with General tab
            settingsWC.selectTab(withIdentifier: "general")
            settingsWC.showWindow(nil)
        }

        // Bring window to front
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func showAbout() {
        let settingsWC = SettingsWindowController.shared

        // If window is open, switch to About tab
        if settingsWC.window?.isVisible == true {
            settingsWC.selectTab(withIdentifier: "about")
        } else {
            // Open window with About tab
            settingsWC.selectTab(withIdentifier: "about")
            settingsWC.showWindow(nil)
        }

        // Bring window to front
        NSApp.activate(ignoringOtherApps: true)
    }
}