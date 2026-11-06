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