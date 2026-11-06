import AppKit

// MARK: - Main Window Controller

class MainWindowController: NSWindowController {
    
    // MARK: - Properties
    
    private let directoryState = DirectoryState()
    private var toolbar: NSToolbar?
    
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
        
        // Setup toolbar
        setupToolbar(for: window)
        
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
    
    // MARK: - Toolbar Setup
    
    private func setupToolbar(for window: NSWindow) {
        let toolbar = ToolbarBuilder.buildToolbar(delegate: self)
        window.toolbar = toolbar
        window.toolbarStyle = .unified
        self.toolbar = toolbar
    }
    
    // MARK: - Toolbar Actions
    
    @objc func goBack(_ sender: Any?) {
        // Will be implemented in next step
    }
    
    @objc func goForward(_ sender: Any?) {
        // Will be implemented in next step
    }
    
    @objc func goUp(_ sender: Any?) {
        // Will be implemented in next step
    }
    
    @objc func refresh(_ sender: Any?) {
        directoryState.reload()
    }
}

// MARK: - NSWindowDelegate

extension MainWindowController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        // Clean up resources when window closes
    }
}

// MARK: - NSToolbarDelegate

extension MainWindowController: NSToolbarDelegate {
    
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        // Return item for identifier
        guard let identifier = ToolbarItemIdentifier(rawValue: itemIdentifier.rawValue) else {
            return nil
        }
        
        switch identifier {
        case .back:
            let item = ToolbarBuilder.createToolbarItem(identifier: .back, label: "Back", symbol: "chevron.backward")
            item.target = self
            item.action = #selector(goBack)
            return item
        case .forward:
            let item = ToolbarBuilder.createToolbarItem(identifier: .forward, label: "Forward", symbol: "chevron.forward")
            item.target = self
            item.action = #selector(goForward)
            return item
        case .up:
            let item = ToolbarBuilder.createToolbarItem(identifier: .up, label: "Up", symbol: "chevron.up")
            item.target = self
            item.action = #selector(goUp)
            return item
        case .refresh:
            let item = ToolbarBuilder.createToolbarItem(identifier: .refresh, label: "Refresh", symbol: "arrow.clockwise")
            item.target = self
            item.action = #selector(refresh)
            return item
        case .copy:
            let item = ToolbarBuilder.createToolbarItem(identifier: .copy, label: "Copy", symbol: "doc.on.doc")
            return item
        case .paste:
            let item = ToolbarBuilder.createToolbarItem(identifier: .paste, label: "Paste", symbol: "doc.on.clipboard")
            return item
        case .cut:
            let item = ToolbarBuilder.createToolbarItem(identifier: .cut, label: "Cut", symbol: "scissors")
            return item
        }
    }
    
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [
            ToolbarItemIdentifier.back.identifier,
            ToolbarItemIdentifier.forward.identifier,
            ToolbarItemIdentifier.up.identifier,
            .space,
            ToolbarItemIdentifier.refresh.identifier,
            .flexibleSpace,
            ToolbarItemIdentifier.cut.identifier,
            ToolbarItemIdentifier.copy.identifier,
            ToolbarItemIdentifier.paste.identifier
        ]
    }
    
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        toolbarDefaultItemIdentifiers(toolbar)
    }
}