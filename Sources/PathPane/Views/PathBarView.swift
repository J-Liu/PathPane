import AppKit

// MARK: - Path Bar View

class PathBarView: NSView {
    
    // MARK: - Properties
    
    var currentURL: URL? {
        didSet {
            updatePathDisplay()
        }
    }
    
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
    
    private lazy var pathTextField: NSTextField = {
        let textField = NSTextField()
        textField.isEditable = false
        textField.isBordered = false
        textField.backgroundColor = .clear
        textField.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        textField.textColor = .labelColor
        textField.lineBreakMode = .byTruncatingHead
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
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
        window?.makeFirstResponder(nil)
    }
    
    func textField() -> NSTextField {
        return pathTextField
    }
    
    // MARK: - Layout
    
    override var intrinsicContentSize: NSSize {
        return NSSize(width: NSView.noIntrinsicMetric, height: 36)
    }
}