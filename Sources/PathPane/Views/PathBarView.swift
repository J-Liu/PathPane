// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright © 2026 Jia Liu

import AppKit

// MARK: - Path Bar View

class PathBarView: NSView {
    
    // MARK: - Properties
    
    var currentURL: URL? {
        didSet {
            updatePathDisplay()
        }
    }
    
    var onPathSubmit: ((URL) -> Void)?
    
    private lazy var completionWindow = PathCompletionWindow()
    
    var isEditable: Bool {
        get { pathTextField.isEditable }
        set {
            pathTextField.isEditable = newValue
            if newValue {
                pathTextField.backgroundColor = NSColor.textBackgroundColor
                pathTextField.isBezeled = true
                pathTextField.bezelStyle = .roundedBezel
            } else {
                pathTextField.backgroundColor = .clear
                pathTextField.isBezeled = false
            }
        }
    }
    
    // MARK: - UI Elements
    
    private lazy var pathTextField: PathTextField = {
        let textField = PathTextField()
        textField.isEditable = false
        textField.isBordered = false
        textField.backgroundColor = .clear
        textField.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        textField.textColor = .labelColor
        textField.lineBreakMode = .byTruncatingHead
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.target = self
        textField.action = #selector(handlePathSubmit)
        textField.delegate = self
        textField.wantsLayer = true
        textField.layer?.cornerRadius = 4
        textField.onKeyDown = { [weak self] event in
            self?.handleKeyDown(event) ?? false
        }
        return textField
    }()
    
    override func keyDown(with event: NSEvent) {
        if handleKeyDown(event) {
            return
        }
        super.keyDown(with: event)
    }
    
    private lazy var containerView: NSView = {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        view.layer?.cornerRadius = 4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: - Initialization
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupSubviews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupSubviews() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        
        addSubview(containerView)
        containerView.addSubview(pathTextField)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            containerView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            
            pathTextField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            pathTextField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            pathTextField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
    }
    
    // MARK: - Update
    
    private func updatePathDisplay() {
        guard let url = currentURL else {
            pathTextField.stringValue = ""
            return
        }
        pathTextField.stringValue = url.path
    }
    
    // MARK: - Public Methods
    
    func activateForEditing() {
        isEditable = true
        window?.makeFirstResponder(pathTextField)
        
        // Select all text
        DispatchQueue.main.async {
            self.pathTextField.currentEditor()?.selectAll(nil)
        }
    }
    
    func deactivateEditing() {
        isEditable = false
        completionWindow.hide()
        window?.makeFirstResponder(nil)
    }
    
    // MARK: - Path Completion
    
    private func updateCompletions(for input: String) {
        // Expand tilde
        let expanded = NSString(string: input).expandingTildeInPath
        
        // Get parent directory and prefix
        let url = URL(fileURLWithPath: expanded)
        let parentURL = url.deletingLastPathComponent()
        let prefix = url.lastPathComponent
        
        // Check if parent exists
        guard FileManager.default.fileExists(atPath: parentURL.path) else {
            completionWindow.hide()
            return
        }
        
        // List contents of parent directory
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: parentURL,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
            
            // Filter by prefix
            let matching = contents
                .filter { $0.lastPathComponent.lowercased().hasPrefix(prefix.lowercased()) }
                .map { $0.lastPathComponent }
            
            // Show completions
            if !matching.isEmpty {
                let textFieldRect = pathTextField.bounds
                completionWindow.showCompletions(matching, relativeTo: textFieldRect, in: pathTextField)
                
                completionWindow.onCompletionSelected = { [weak self] completion in
                    self?.insertCompletion(completion, for: input)
                }
            } else {
                completionWindow.hide()
            }
        } catch {
            completionWindow.hide()
        }
    }
    
    private func insertCompletion(_ completion: String, for input: String) {
        let expanded = NSString(string: input).expandingTildeInPath
        let url = URL(fileURLWithPath: expanded)
        let parentPath = url.deletingLastPathComponent().path
        
        // Build new path
        let newPath = parentPath + "/" + completion
        pathTextField.stringValue = newPath
        
        // Move cursor to end
        if let editor = pathTextField.currentEditor() {
            editor.selectedRange = NSRange(location: newPath.count, length: 0)
        }
    }
    
    func handleKeyDown(_ event: NSEvent) -> Bool {
        guard pathTextField.isEditable else { return false }
        
        if event.keyCode == 125 { // Down arrow
            completionWindow.selectNext()
            return true
        } else if event.keyCode == 126 { // Up arrow
            completionWindow.selectPrevious()
            return true
        } else if event.keyCode == 36 { // Return
            if completionWindow.isVisible {
                completionWindow.confirmSelection()
                return true
            }
        } else if event.keyCode == 53 { // Escape
            completionWindow.hide()
            return true
        }
        
        return false
    }
    
    func textField() -> NSTextField {
        return pathTextField
    }
    
    // MARK: - Actions
    
    @objc private func handlePathSubmit() {
        let inputPath = pathTextField.stringValue
        
        // Expand tilde
        let expandedPath = NSString(string: inputPath).expandingTildeInPath
        let url = URL(fileURLWithPath: expandedPath)
        
        // Validate path
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
        
        if exists && isDirectory.boolValue {
            // Valid directory, navigate to it
            onPathSubmit?(url)
            deactivateEditing()
        } else {
            // Invalid path, restore original and beep
            NSSound.beep()
            updatePathDisplay()
            pathTextField.selectText(nil)
        }
    }
    
    // MARK: - Layout
    
    override var intrinsicContentSize: NSSize {
        return NSSize(width: NSView.noIntrinsicMetric, height: 36)
    }
}

// MARK: - NSTextFieldDelegate

extension PathBarView: NSTextFieldDelegate {
    
    func controlTextDidChange(_ obj: Notification) {
        // Update completions as user types
        let currentText = pathTextField.stringValue
        updateCompletions(for: currentText)
    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
        // Handle loss of focus
        if !pathTextField.isEditable {
            return
        }
        
        // Hide completion window
        completionWindow.hide()
    }
}