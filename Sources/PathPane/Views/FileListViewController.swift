import AppKit
import UniformTypeIdentifiers

// MARK: - File List View Controller

class FileListViewController: NSViewController {
    
    // MARK: - Properties
    
    let directoryState: DirectoryState
    private let settings = SettingsManager.shared
    private var trackingArea: NSTrackingArea?
    
    // MARK: - UI Elements
    
    private lazy var scrollView: NSScrollView = {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        return scrollView
    }()
    
    private lazy var tableView: NSTableView = {
        let tableView = NSTableView()
        tableView.style = .plain
        tableView.rowSizeStyle = .default
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.selectionHighlightStyle = .regular
        tableView.allowsMultipleSelection = true
        tableView.allowsEmptySelection = true
        return tableView
    }()
    
    private let nameColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("name"))
    private let sizeColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("size"))
    private let modifiedColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("modified"))
    private let kindColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("kind"))
    
    // MARK: - Initialization
    
    init(directoryState: DirectoryState) {
        self.directoryState = directoryState
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func loadView() {
        view = NSView()
        view.wantsLayer = true
        
        setupSubviews()
        setupConstraints()
        setupTrackingArea()
        loadInitialData()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        updateTrackingArea()
    }
    
    // MARK: - Setup
    
    private func setupSubviews() {
        // Name column
        nameColumn.title = "Name"
        nameColumn.width = 300
        nameColumn.minWidth = 150
        tableView.addTableColumn(nameColumn)
        
        // Size column
        sizeColumn.title = "Size"
        sizeColumn.width = 100
        sizeColumn.minWidth = 80
        sizeColumn.maxWidth = 150
        tableView.addTableColumn(sizeColumn)
        
        // Modified column
        modifiedColumn.title = "Modified"
        modifiedColumn.width = 180
        modifiedColumn.minWidth = 120
        tableView.addTableColumn(modifiedColumn)
        
        // Kind column
        kindColumn.title = "Kind"
        kindColumn.width = 120
        kindColumn.minWidth = 80
        tableView.addTableColumn(kindColumn)
        
        // Set data source and delegate
        tableView.dataSource = self
        tableView.delegate = self
        tableView.target = self
        tableView.doubleAction = #selector(handleDoubleClick)

        // Setup context menu
        tableView.menu = buildContextMenu()

        // Add to scroll view
        scrollView.documentView = tableView
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func loadInitialData() {
        directoryState.load(url: directoryState.currentURL) { [weak self] result in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
    }
    
    // MARK: - Public Methods
    
    func reloadData() {
        tableView.reloadData()
    }
    
    private func setupTrackingArea() {
        let options: NSTrackingArea.Options = [
            .mouseMoved,
            .activeInKeyWindow,
            .inVisibleRect
        ]
        
        trackingArea = NSTrackingArea(
            rect: NSRect.zero,
            options: options,
            owner: tableView,
            userInfo: nil
        )
    }
    
    private func updateTrackingArea() {
        if let area = trackingArea {
            tableView.removeTrackingArea(area)
        }
        
        if settings.selectionBehavior == .hoverSelect {
            if let area = trackingArea {
                tableView.addTrackingArea(area)
            }
        }
    }
    
    // MARK: - Context Menu
    
    private func buildContextMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self
        
        menu.addItem(
            NSMenuItem(
                title: "Open",
                action: #selector(openSelectedItems),
                keyEquivalent: ""
            )
        )
        
        let openWithItem = NSMenuItem(
            title: "Open With",
            action: nil,
            keyEquivalent: ""
        )
        openWithItem.submenu = NSMenu()
        menu.addItem(openWithItem)
        
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(
            NSMenuItem(
                title: "Cut",
                action: #selector(cutSelectedItems),
                keyEquivalent: ""
            )
        )
        
        menu.addItem(
            NSMenuItem(
                title: "Copy",
                action: #selector(copySelectedItems),
                keyEquivalent: ""
            )
        )
        
        menu.addItem(
            NSMenuItem(
                title: "Paste",
                action: #selector(pasteItems),
                keyEquivalent: ""
            )
        )
        
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(
            NSMenuItem(
                title: "Rename",
                action: #selector(renameSelectedItem),
                keyEquivalent: ""
            )
        )
        
        menu.addItem(
            NSMenuItem(
                title: "Move to Trash",
                action: #selector(moveToTrash),
                keyEquivalent: ""
            )
        )
        
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(
            NSMenuItem(
                title: "Get Info",
                action: #selector(getInfoForSelectedItem),
                keyEquivalent: ""
            )
        )
        
        return menu
    }
    
    @objc private func openSelectedItems() {
        let selectedRows = tableView.selectedRowIndexes
        guard !selectedRows.isEmpty else { return }
        
        for row in selectedRows {
            guard row < directoryState.items.count else { continue }
            let item = directoryState.items[row]
            
            if item.isDirectory {
                directoryState.load(url: item.url) { [weak self] result in
                    DispatchQueue.main.async {
                        self?.tableView.reloadData()
                    }
                }
                break // Only open one directory
            } else {
                NSWorkspace.shared.open(item.url)
            }
        }
    }
    
    @objc private func cutSelectedItems() {
        copySelectedItems()
        // Mark as cut operation - will be handled in paste
        UserDefaults.standard.set(true, forKey: "PathPane_IsCutOperation")
    }
    
    @objc private func copySelectedItems() {
        let selectedRows = tableView.selectedRowIndexes
        guard !selectedRows.isEmpty else { return }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        var urls: [URL] = []
        for row in selectedRows {
            guard row < directoryState.items.count else { continue }
            urls.append(directoryState.items[row].url)
        }
        
        pasteboard.writeObjects(urls as [NSURL])
        UserDefaults.standard.set(false, forKey: "PathPane_IsCutOperation")
    }
    
    @objc private func pasteItems() {
        let pasteboard = NSPasteboard.general
        guard let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] else {
            return
        }

        let isCut = UserDefaults.standard.bool(forKey: "PathPane_IsCutOperation")
        let destinationDir = directoryState.currentURL

        for sourceURL in urls {
            var destinationURL = destinationDir.appendingPathComponent(sourceURL.lastPathComponent)

            // Handle name conflicts
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                destinationURL = uniqueURL(for: destinationURL)
            }

            do {
                if isCut {
                    try FileManager.default.moveItem(at: sourceURL, to: destinationURL)
                } else {
                    try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
                }
            } catch {
                print("Error pasting \(sourceURL): \(error)")
            }
        }

        // Clear pasteboard after cut operation
        if isCut {
            pasteboard.clearContents()
            UserDefaults.standard.set(false, forKey: "PathPane_IsCutOperation")
        }

        directoryState.reload()
        tableView.reloadData()
    }

    private func uniqueURL(for url: URL) -> URL {
        let directory = url.deletingLastPathComponent()
        let fileName = url.deletingPathExtension().lastPathComponent
        let fileExtension = url.pathExtension

        var newURL = url
        var counter = 1

        while FileManager.default.fileExists(atPath: newURL.path) {
            let newFileName = counter == 1 ? "\(fileName) copy" : "\(fileName) copy \(counter)"
            newURL = directory.appendingPathComponent(newFileName).appendingPathExtension(fileExtension)
            counter += 1
        }

        return newURL
    }

    @objc private func renameSelectedItem() {
        let selectedRow = tableView.selectedRow
        guard selectedRow >= 0, selectedRow < directoryState.items.count else { return }
        
        // TODO: Implement rename dialog or inline editing
        print("Rename: \(directoryState.items[selectedRow].name)")
    }
    
    @objc private func moveToTrash() {
        let selectedRows = tableView.selectedRowIndexes
        guard !selectedRows.isEmpty else { return }
        
        for row in selectedRows {
            guard row < directoryState.items.count else { continue }
            let item = directoryState.items[row]
            
            do {
                var resultURL: NSURL?
                try FileManager.default.trashItem(at: item.url, resultingItemURL: &resultURL)
            } catch {
                print("Error moving to trash \(item.url): \(error)")
            }
        }
        
        directoryState.reload()
        tableView.reloadData()
    }
    
    @objc private func getInfoForSelectedItem() {
        let selectedRow = tableView.selectedRow
        guard selectedRow >= 0, selectedRow < directoryState.items.count else { return }
        
        let item = directoryState.items[selectedRow]
        NSWorkspace.shared.activateFileViewerSelecting([item.url])
    }
    
    // MARK: - Navigation
    
    private func openSelectedItem() {
        let selectedRow = tableView.selectedRow
        guard selectedRow >= 0, selectedRow < directoryState.items.count else { return }
        
        let item = directoryState.items[selectedRow]
        
        if item.isDirectory {
            // Navigate into directory
            directoryState.load(url: item.url) { [weak self] result in
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                    self?.tableView.scrollRowToVisible(0)
                }
            }
        } else {
            // Open file with default application
            NSWorkspace.shared.open(item.url)
        }
    }
    
    private func handleSingleClick() {
        if settings.selectionBehavior == .hoverSelect {
            // In hover mode, single click opens the item
            openSelectedItem()
        }
        // In click mode, single click just selects (default behavior)
    }
}

// MARK: - Keyboard Handling

extension FileListViewController {
    
    override func keyDown(with event: NSEvent) {
        // Handle Enter key
        if event.keyCode == 36 { // Return key
            openSelectedItem()
        } else if event.keyCode == 51 { // Delete key
            // Will be handled later for move to trash
            super.keyDown(with: event)
        } else {
            super.keyDown(with: event)
        }
    }
    
    @objc private func handleDoubleClick() {
        openSelectedItem()
    }
    
    override func mouseMoved(with event: NSEvent) {
        guard settings.selectionBehavior == .hoverSelect else { return }
        
        // Get row under mouse
        let point = tableView.convert(event.locationInWindow, from: nil)
        let row = tableView.row(at: point)
        
        // Select row if valid
        if row >= 0 && row < directoryState.items.count {
            tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        }
    }
}

// MARK: - NSTableViewDataSource

extension FileListViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        directoryState.items.count
    }
}

// MARK: - NSTableViewDelegate

extension FileListViewController: NSTableViewDelegate {
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        // In hover mode, we don't need to do anything special
        // In click mode, this is just selection
        if settings.selectionBehavior == .clickSelect {
            // Handle single click in click mode
            // For now, selection is handled automatically
        }
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return true
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < directoryState.items.count else { return nil }
        let item = directoryState.items[row]
        
        // Determine which column
        if tableColumn == nameColumn {
            return createNameCell(for: item, row: row)
        } else if tableColumn == sizeColumn {
            return createSizeCell(for: item, row: row)
        } else if tableColumn == modifiedColumn {
            return createModifiedCell(for: item, row: row)
        } else if tableColumn == kindColumn {
            return createKindCell(for: item, row: row)
        }
        
        return nil
    }
    
    // MARK: - Cell Creation
    
    private func createNameCell(for item: FileItem, row: Int) -> NSView? {
        let cellIdentifier = NSUserInterfaceItemIdentifier("NameCell")
        var cell = tableView.makeView(withIdentifier: cellIdentifier, owner: nil) as? NSTableCellView
        
        if cell == nil {
            cell = NSTableCellView()
            cell?.identifier = cellIdentifier
            
            let textField = NSTextField()
            textField.isEditable = false
            textField.isBordered = false
            textField.backgroundColor = .clear
            textField.translatesAutoresizingMaskIntoConstraints = false
            cell?.addSubview(textField)
            cell?.textField = textField
            
            let imageView = NSImageView()
            imageView.translatesAutoresizingMaskIntoConstraints = false
            cell?.addSubview(imageView)
            cell?.imageView = imageView
            
            NSLayoutConstraint.activate([
                imageView.leadingAnchor.constraint(equalTo: cell!.leadingAnchor, constant: 4),
                imageView.centerYAnchor.constraint(equalTo: cell!.centerYAnchor),
                imageView.widthAnchor.constraint(equalToConstant: 16),
                imageView.heightAnchor.constraint(equalToConstant: 16),
                
                textField.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 4),
                textField.trailingAnchor.constraint(equalTo: cell!.trailingAnchor, constant: -4),
                textField.centerYAnchor.constraint(equalTo: cell!.centerYAnchor)
            ])
        }
        
        cell?.textField?.stringValue = item.name
        cell?.imageView?.image = NSWorkspace.shared.icon(forFile: item.url.path)
        cell?.imageView?.image?.size = NSSize(width: 16, height: 16)
        
        return cell
    }
    
    private func createSizeCell(for item: FileItem, row: Int) -> NSView? {
        let cellIdentifier = NSUserInterfaceItemIdentifier("SizeCell")
        var cell = tableView.makeView(withIdentifier: cellIdentifier, owner: nil) as? NSTableCellView
        
        if cell == nil {
            cell = NSTableCellView()
            cell?.identifier = cellIdentifier
            
            let textField = NSTextField()
            textField.isEditable = false
            textField.isBordered = false
            textField.backgroundColor = .clear
            textField.alignment = .right
            textField.translatesAutoresizingMaskIntoConstraints = false
            cell?.addSubview(textField)
            cell?.textField = textField
            
            NSLayoutConstraint.activate([
                textField.leadingAnchor.constraint(equalTo: cell!.leadingAnchor, constant: 4),
                textField.trailingAnchor.constraint(equalTo: cell!.trailingAnchor, constant: -4),
                textField.centerYAnchor.constraint(equalTo: cell!.centerYAnchor)
            ])
        }
        
        // Format size
        if item.isDirectory {
            cell?.textField?.stringValue = "--"
        } else {
            let formatter = ByteCountFormatter()
            formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
            formatter.countStyle = .file
            cell?.textField?.stringValue = formatter.string(fromByteCount: Int64(item.fileSize))
        }
        
        return cell
    }
    
    private func createModifiedCell(for item: FileItem, row: Int) -> NSView? {
        let cellIdentifier = NSUserInterfaceItemIdentifier("ModifiedCell")
        var cell = tableView.makeView(withIdentifier: cellIdentifier, owner: nil) as? NSTableCellView
        
        if cell == nil {
            cell = NSTableCellView()
            cell?.identifier = cellIdentifier
            
            let textField = NSTextField()
            textField.isEditable = false
            textField.isBordered = false
            textField.backgroundColor = .clear
            textField.translatesAutoresizingMaskIntoConstraints = false
            cell?.addSubview(textField)
            cell?.textField = textField
            
            NSLayoutConstraint.activate([
                textField.leadingAnchor.constraint(equalTo: cell!.leadingAnchor, constant: 4),
                textField.trailingAnchor.constraint(equalTo: cell!.trailingAnchor, constant: -4),
                textField.centerYAnchor.constraint(equalTo: cell!.centerYAnchor)
            ])
        }
        
        // Format date
        if let date = item.modificationDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            cell?.textField?.stringValue = formatter.string(from: date)
        } else {
            cell?.textField?.stringValue = "--"
        }
        
        return cell
    }
    
    private func createKindCell(for item: FileItem, row: Int) -> NSView? {
        let cellIdentifier = NSUserInterfaceItemIdentifier("KindCell")
        var cell = tableView.makeView(withIdentifier: cellIdentifier, owner: nil) as? NSTableCellView
        
        if cell == nil {
            cell = NSTableCellView()
            cell?.identifier = cellIdentifier
            
            let textField = NSTextField()
            textField.isEditable = false
            textField.isBordered = false
            textField.backgroundColor = .clear
            textField.translatesAutoresizingMaskIntoConstraints = false
            cell?.addSubview(textField)
            cell?.textField = textField
            
            NSLayoutConstraint.activate([
                textField.leadingAnchor.constraint(equalTo: cell!.leadingAnchor, constant: 4),
                textField.trailingAnchor.constraint(equalTo: cell!.trailingAnchor, constant: -4),
                textField.centerYAnchor.constraint(equalTo: cell!.centerYAnchor)
            ])
        }
        
        // Determine kind
        if item.isDirectory {
            cell?.textField?.stringValue = "Folder"
        } else {
            // Use modern UTType API
            let type = UTType(filenameExtension: item.fileExtension) ?? .item
            let description = type.localizedDescription ?? "Document"
            cell?.textField?.stringValue = description
        }
        
        return cell
    }
}

// MARK: - NSMenuDelegate

extension FileListViewController: NSMenuDelegate {
    
    func menuNeedsUpdate(_ menu: NSMenu) {
        let selectedRows = tableView.selectedRowIndexes
        let hasSelection = !selectedRows.isEmpty
        let hasSingleSelection = selectedRows.count == 1
        
        // Update menu items based on selection
        for item in menu.items {
            switch item.title {
            case "Open":
                item.isEnabled = hasSelection
            case "Open With":
                item.isEnabled = hasSingleSelection && !selectedRows.contains(where: { $0 < directoryState.items.count && directoryState.items[$0].isDirectory })
                // Build "Open With" submenu if single file selected
                if item.isEnabled, let submenu = item.submenu {
                    submenu.removeAllItems()
                    if let row = selectedRows.first, row < directoryState.items.count {
                        let fileItem = directoryState.items[row]
                        buildOpenWithMenu(for: fileItem, in: submenu)
                    }
                }
            case "Cut", "Copy":
                item.isEnabled = hasSelection
            case "Paste":
                let pasteboard = NSPasteboard.general
                item.isEnabled = pasteboard.canReadItem(withDataConformingToTypes: [NSPasteboard.PasteboardType.fileURL.rawValue])
            case "Rename":
                item.isEnabled = hasSingleSelection
            case "Move to Trash":
                item.isEnabled = hasSelection
            case "Get Info":
                item.isEnabled = hasSingleSelection
            default:
                break
            }
        }
    }
    
    private func buildOpenWithMenu(for item: FileItem, in menu: NSMenu) {
        guard !item.isDirectory else { return }
        
        // Get applications that can open this file
        let urls = NSWorkspace.shared.urlsForApplications(toOpen: item.url)
        
        if urls.isEmpty {
            let item = NSMenuItem(title: "No Applications Available", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
        } else {
            for appURL in urls {
                let appName = appURL.deletingLastPathComponent().lastPathComponent
                let menuItem = NSMenuItem(
                    title: appName,
                    action: #selector(openWithApplication(_:)),
                    keyEquivalent: ""
                )
                menuItem.representedObject = appURL
                menu.addItem(menuItem)
            }
        }
    }
    
    @objc private func openWithApplication(_ sender: NSMenuItem) {
        guard let appURL = sender.representedObject as? URL else { return }
        
        let selectedRows = tableView.selectedRowIndexes
        for row in selectedRows {
            guard row < directoryState.items.count else { continue }
            let item = directoryState.items[row]
            NSWorkspace.shared.open([item.url], withApplicationAt: appURL, configuration: NSWorkspace.OpenConfiguration())
        }
    }
}