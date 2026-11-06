import AppKit

// MARK: - Main Window Controller

class MainWindowController: NSWindowController {
    
    // MARK: - Properties
    
    private let tabManager = TabManager.shared
    private var toolbar: NSToolbar?
    private var tabBarView: TabBarView?
    private var dualPaneContainer: DualPaneContainerView?
    
    // Dual pane support
    var isDualPaneMode: Bool = false {
        didSet {
            dualPaneContainer?.isDualPaneMode = isDualPaneMode
        }
    }
    private var leftContentViewController: ContentViewController?
    private var rightContentViewController: ContentViewController?
    private var activePane: PanePosition = .left
    
    enum PanePosition {
        case left
        case right
    }
    
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
        
        super.init(window: window)
        
        // Setup content view with tab bar
        setupContentView(for: window)
        
        // Setup toolbar
        setupToolbar(for: window)
        
        // Set window delegate
        window.delegate = self
        
        // Load initial tab
        updateActiveTab()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Setup
    
    private func setupContentView(for window: NSWindow) {
        guard let contentView = window.contentView else { return }
        
        // Create tab bar
        let tabBar = TabBarView()
        tabBar.delegate = self
        tabBar.translatesAutoresizingMaskIntoConstraints = false
        
        // Create dual pane container
        let dualPane = DualPaneContainerView()
        dualPane.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(tabBar)
        contentView.addSubview(dualPane)
        
        NSLayoutConstraint.activate([
            tabBar.topAnchor.constraint(equalTo: contentView.topAnchor),
            tabBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tabBar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            tabBar.heightAnchor.constraint(equalToConstant: 32),
            
            dualPane.topAnchor.constraint(equalTo: tabBar.bottomAnchor),
            dualPane.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            dualPane.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            dualPane.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        self.tabBarView = tabBar
        self.dualPaneContainer = dualPane
        
        // Update tab bar
        updateTabBar()
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
    
    // MARK: - Tab Management
    
    private func updateTabBar() {
        guard let tabBarView = tabBarView else { return }
        tabBarView.updateTabs(tabManager.tabs, activeIndex: tabManager.activeTabIndex)
    }
    
    private func updateActiveTab() {
        guard let dualPane = dualPaneContainer,
              let activeTab = tabManager.activeTab else { return }
        
        // Create new left content view controller for active tab
        let leftVC = ContentViewController(directoryState: activeTab.directoryState)
        leftContentViewController = leftVC
        dualPane.leftContentView = leftVC.view
        
        // Create right content view controller for dual pane mode if needed
        if isDualPaneMode {
            let rightDirectoryState = DirectoryState(initialURL: activeTab.directoryState.currentURL)
            let rightVC = ContentViewController(directoryState: rightDirectoryState)
            rightContentViewController = rightVC
            dualPane.rightContentView = rightVC.view
        }
        
        // Update tab bar
        updateTabBar()
    }
    
    @objc func createNewTab() {
        tabManager.createNewTab()
        updateActiveTab()
    }
    
    @objc func closeCurrentTab() {
        tabManager.closeTab(at: tabManager.activeTabIndex)
        updateActiveTab()
    }
    
    @objc func selectNextTab() {
        tabManager.nextTab()
        updateActiveTab()
    }
    
    @objc func selectPreviousTab() {
        tabManager.previousTab()
        updateActiveTab()
    }
    
    // MARK: - Dual Pane Mode
    
    @objc func toggleDualPaneMode() {
        isDualPaneMode.toggle()
        
        if isDualPaneMode && rightContentViewController == nil {
            // Create right pane with current directory
            if let activeTab = tabManager.activeTab {
                let rightDirectoryState = DirectoryState(initialURL: activeTab.directoryState.currentURL)
                let rightVC = ContentViewController(directoryState: rightDirectoryState)
                rightContentViewController = rightVC
                dualPaneContainer?.rightContentView = rightVC.view
            }
        }
    }
    
    // MARK: - Toolbar Actions
    
    @objc func goBack(_ sender: Any?) {
        tabManager.activeTab?.directoryState.goBack()
        reloadCurrentView()
    }
    
    @objc func goForward(_ sender: Any?) {
        tabManager.activeTab?.directoryState.goForward()
        reloadCurrentView()
    }
    
    @objc func goUp(_ sender: Any?) {
        tabManager.activeTab?.directoryState.goUp()
        reloadCurrentView()
    }
    
    @objc func refresh(_ sender: Any?) {
        tabManager.activeTab?.directoryState.reload()
        reloadCurrentView()
    }
    
    @objc func goToFolder(_ sender: Any?) {
        if let fileVC = contentViewController as? ContentViewController {
            fileVC.activatePathBarForEditing()
        }
    }
    
    // MARK: - View Mode Actions
    
    @objc func switchToListView(_ sender: Any?) {
        if let fileVC = contentViewController as? ContentViewController {
            fileVC.switchToViewMode(.list)
        }
    }
    
    @objc func switchToIconView(_ sender: Any?) {
        if let fileVC = contentViewController as? ContentViewController {
            fileVC.switchToViewMode(.icon)
        }
    }
    
    @objc func switchToThumbnailView(_ sender: Any?) {
        if let fileVC = contentViewController as? ContentViewController {
            fileVC.switchToViewMode(.thumbnail)
        }
    }

    // MARK: - Hidden Files

    @objc func toggleHiddenFiles(_ sender: Any?) {
        tabManager.activeTab?.directoryState.showHiddenFiles.toggle()
        reloadCurrentView()
    }

    private func reloadCurrentView() {
        if activePane == .left {
            leftContentViewController?.reloadCurrentView()
            leftContentViewController?.updatePathBar()
        } else {
            rightContentViewController?.reloadCurrentView()
            rightContentViewController?.updatePathBar()
        }
    }
}

// MARK: - TabBarViewDelegate

extension MainWindowController: TabBarViewDelegate {
    
    func tabBarViewDidRequestNewTab() {
        createNewTab()
    }
    
    func tabBarView(_ view: TabBarView, didSelectTabAt index: Int) {
        tabManager.switchToTab(at: index)
        updateActiveTab()
    }
    
    func tabBarView(_ view: TabBarView, didRequestCloseTabAt index: Int) {
        tabManager.closeTab(at: index)
        updateActiveTab()
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