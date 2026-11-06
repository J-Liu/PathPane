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
    private var window: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        createMainWindow()
    }
    
    private func createMainWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "PathPane"
        window.center()
        window.makeKeyAndOrderFront(nil)
        
        self.window = window
    }
}