import AppKit

// MARK: - File List View Controller

class FileListViewController: NSViewController {
    
    // MARK: - Properties
    
    let directoryState: DirectoryState
    
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
        tableView.headerView = nil
        return tableView
    }()
    
    private let nameColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("name"))
    
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
        loadInitialData()
    }
    
    // MARK: - Setup
    
    private func setupSubviews() {
        // Add table column
        nameColumn.title = "Name"
        nameColumn.width = 300
        nameColumn.minWidth = 100
        nameColumn.maxWidth = 1000
        tableView.addTableColumn(nameColumn)
        
        // Set data source and delegate
        tableView.dataSource = self
        tableView.delegate = self
        
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
}

// MARK: - NSTableViewDataSource

extension FileListViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        directoryState.items.count
    }
}

// MARK: - NSTableViewDelegate

extension FileListViewController: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < directoryState.items.count else { return nil }
        
        let item = directoryState.items[row]
        
        // Create or reuse cell
        let cellIdentifier = NSUserInterfaceItemIdentifier("FileCell")
        var cell = tableView.makeView(withIdentifier: cellIdentifier, owner: nil) as? NSTableCellView
        
        if cell == nil {
            cell = NSTableCellView()
            cell?.identifier = cellIdentifier
            
            // Add text field
            let textField = NSTextField()
            textField.isEditable = false
            textField.isBordered = false
            textField.backgroundColor = .clear
            textField.translatesAutoresizingMaskIntoConstraints = false
            cell?.addSubview(textField)
            cell?.textField = textField
            
            // Add icon
            let imageView = NSImageView()
            imageView.translatesAutoresizingMaskIntoConstraints = false
            cell?.addSubview(imageView)
            cell?.imageView = imageView
            
            // Layout
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
        
        // Configure cell
        cell?.textField?.stringValue = item.name
        cell?.imageView?.image = NSWorkspace.shared.icon(forFile: item.url.path)
        cell?.imageView?.image?.size = NSSize(width: 16, height: 16)
        
        return cell
    }
}