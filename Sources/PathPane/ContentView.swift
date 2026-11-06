import AppKit

// MARK: - Content View Controller

class ContentViewController: NSViewController {
    
    // MARK: - UI Elements
    
    private lazy var placeholderLabel: NSTextField = {
        let label = NSTextField(labelWithString: "PathPane")
        label.font = NSFont.systemFont(ofSize: 24, weight: .medium)
        label.textColor = NSColor.secondaryLabelColor
        label.alignment = .center
        return label
    }()
    
    // MARK: - Lifecycle
    
    override func loadView() {
        view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        
        setupSubviews()
        setupConstraints()
    }
    
    // MARK: - Setup
    
    private func setupSubviews() {
        view.addSubview(placeholderLabel)
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            placeholderLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            placeholderLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}