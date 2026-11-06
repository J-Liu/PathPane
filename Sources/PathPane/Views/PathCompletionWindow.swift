// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright © 2026 Jia Liu

import AppKit

// MARK: - Path Completion Window

class PathCompletionWindow: NSPanel {
    
    // MARK: - Properties
    
    private var completions: [String] = []
    private var selectedIndex = 0
    var onCompletionSelected: ((String) -> Void)?
    
    // MARK: - UI Elements
    
    private lazy var tableView: NSTableView = {
        let tableView = NSTableView()
        tableView.style = .plain
        tableView.rowSizeStyle = .default
        tableView.selectionHighlightStyle = .regular
        tableView.usesAlternatingRowBackgroundColors = false
        tableView.headerView = nil
        return tableView
    }()
    
    private lazy var scrollView: NSScrollView = {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.documentView = tableView
        return scrollView
    }()
    
    private let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("completion"))
    
    // MARK: - Initialization
    
    init() {
        super.init(contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
                   styleMask: [.borderless, .nonactivatingPanel],
                   backing: .buffered,
                   defer: false)
        
        setupUI()
    }
    
    private func setupUI() {
        column.width = 280
        tableView.addTableColumn(column)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.target = self
        tableView.doubleAction = #selector(handleDoubleAction)
        
        contentView = scrollView
        hasShadow = true
        level = .floating
    }
    
    // MARK: - Public Methods
    
    func showCompletions(_ completions: [String], relativeTo rect: NSRect, in view: NSView) {
        self.completions = completions
        selectedIndex = 0
        tableView.reloadData()
        
        guard !completions.isEmpty else {
            orderOut(nil)
            return
        }
        
        // Calculate position
        let screenRect = view.window?.convertToScreen(rect) ?? rect
        setFrameOrigin(NSPoint(x: screenRect.origin.x, y: screenRect.origin.y - 200))
        
        // Show and bring to front
        makeKeyAndOrderFront(nil)
    }
    
    func hide() {
        orderOut(nil)
    }
    
    func selectNext() {
        guard !completions.isEmpty else { return }
        selectedIndex = (selectedIndex + 1) % completions.count
        tableView.selectRowIndexes(IndexSet(integer: selectedIndex), byExtendingSelection: false)
        tableView.scrollRowToVisible(selectedIndex)
    }
    
    func selectPrevious() {
        guard !completions.isEmpty else { return }
        selectedIndex = (selectedIndex - 1 + completions.count) % completions.count
        tableView.selectRowIndexes(IndexSet(integer: selectedIndex), byExtendingSelection: false)
        tableView.scrollRowToVisible(selectedIndex)
    }
    
    func confirmSelection() {
        guard selectedIndex >= 0 && selectedIndex < completions.count else { return }
        onCompletionSelected?(completions[selectedIndex])
        hide()
    }
    
    // MARK: - Actions
    
    @objc private func handleDoubleAction() {
        confirmSelection()
    }
}

// MARK: - NSTableViewDataSource

extension PathCompletionWindow: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        completions.count
    }
}

// MARK: - NSTableViewDelegate

extension PathCompletionWindow: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < completions.count else { return nil }
        
        let cellIdentifier = NSUserInterfaceItemIdentifier("CompletionCell")
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
        
        cell?.textField?.stringValue = completions[row]
        return cell
    }
}