import AppKit

// MARK: - Main Window Controller

class MainWindowController: NSWindowController {
    
    // MARK: - Properties
    
    private let directoryState = DirectoryState()
    
    // MARK: - Initialization
    
    init() {
        // Create window with minimum size
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        // Set minimum size
        window.minSize = NSSize(width: 600, height: 400)
        
        // Set window title
        window.title = "PathPane"
        
        // Configure window appearance
        window.titlebarAppearsTransparent = false
        window.titleVisibility = .visible
        
        // Create content view controller
        let contentVC = ContentViewController(directoryState: directoryState)
        
        super.init(window: window)
        
        // Set content view controller
        contentViewController = contentVC
        
        // Set window delegate
        window.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Window Management
    
    func showWindow() {
        window?.center()
        window?.makeKeyAndOrderFront(nil)
    }
}

// MARK: - NSWindowDelegate

extension MainWindowController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        // Clean up resources when window closes
    }
}