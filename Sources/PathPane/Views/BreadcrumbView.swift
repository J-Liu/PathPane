// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright © 2026 Jia Liu

import AppKit

// MARK: - Breadcrumb Button

class BreadcrumbButton: NSButton {
    
    // MARK: - Properties
    
    var url: URL?
}

// MARK: - Breadcrumb View

class BreadcrumbView: NSView {
    
    // MARK: - Properties
    
    var currentURL: URL? {
        didSet {
            updateBreadcrumbs()
        }
    }
    
    var onBreadcrumbClick: ((URL) -> Void)?
    
    // MARK: - UI Elements
    
    private let stackView: NSStackView = {
        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.spacing = 0
        stack.alignment = .centerY
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
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
        
        addSubview(stackView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -8),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)
        ])
    }
    
    // MARK: - Update
    
    private func updateBreadcrumbs() {
        // Clear existing buttons
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        guard let url = currentURL else { return }
        
        // Build path components
        var components: [(name: String, url: URL)] = []
        var currentPath = url
        
        // Add components from current to root
        while currentPath.path != "/" {
            components.insert((currentPath.lastPathComponent, currentPath), at: 0)
            currentPath = currentPath.deletingLastPathComponent()
        }
        
        // Add root
        components.insert(("/", URL(fileURLWithPath: "/")), at: 0)
        
        // Limit display if too long
        let maxDisplay = 10
        var startIndex = 0
        if components.count > maxDisplay {
            startIndex = components.count - maxDisplay
            addEllipsisButton()
        }
        
        // Create buttons for each component
        for (index, component) in components.enumerated() {
            if index < startIndex { continue }
            
            // Add separator
            if index > 0 {
                addSeparator()
            }
            
            // Add button
            addButton(name: component.name, url: component.url, isLast: index == components.count - 1)
        }
    }
    
    private func addEllipsisButton() {
        let ellipsis = NSTextField(labelWithString: "…")
        ellipsis.textColor = .secondaryLabelColor
        ellipsis.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        stackView.addArrangedSubview(ellipsis)
        
        addSeparator()
    }
    
    private func addSeparator() {
        let separator = NSTextField(labelWithString: "›")
        separator.textColor = .tertiaryLabelColor
        separator.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        separator.alignment = .center
        stackView.addArrangedSubview(separator)
    }
    
    private func addButton(name: String, url: URL, isLast: Bool) {
        let button = BreadcrumbButton(title: name, target: nil, action: nil)
        button.isBordered = false
        button.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        button.bezelStyle = .inline
        button.target = self
        button.action = #selector(handleBreadcrumbClick(_:))
        button.url = url
        
        // Set text color through attributed title
        let color: NSColor = isLast ? .labelColor : .secondaryLabelColor
        let attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: color,
            .font: NSFont.systemFont(ofSize: NSFont.systemFontSize)
        ]
        button.attributedTitle = NSAttributedString(string: name, attributes: attrs)
        
        stackView.addArrangedSubview(button)
    }
    
    // MARK: - Actions
    
    @objc private func handleBreadcrumbClick(_ sender: BreadcrumbButton) {
        guard let url = sender.url else { return }
        onBreadcrumbClick?(url)
    }
    
    // MARK: - Layout
    
    override var intrinsicContentSize: NSSize {
        return NSSize(width: NSView.noIntrinsicMetric, height: 28)
    }
}