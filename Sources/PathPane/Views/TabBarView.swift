import AppKit

// MARK: - Tab Bar View

@MainActor
class TabBarView: NSView {
    
    // MARK: - Properties
    
    weak var delegate: TabBarViewDelegate?
    private var tabButtons: [NSButton] = []
    
    // MARK: - UI Elements
    
    private lazy var stackView: NSStackView = {
        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.spacing = 0
        stack.alignment = .centerY
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private lazy var newTabButton: NSButton = {
        let button = NSButton()
        button.title = "+"
        button.bezelStyle = .inline
        button.target = self
        button.action = #selector(createNewTab)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Initialization
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Setup
    
    private func setupView() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        
        addSubview(stackView)
        addSubview(newTabButton)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            newTabButton.leadingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: 8),
            newTabButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            newTabButton.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -8)
        ])
    }
    
    // MARK: - Tab Management
    
    func updateTabs(_ tabs: [Tab], activeIndex: Int) {
        // Remove existing buttons
        tabButtons.forEach { $0.removeFromSuperview() }
        tabButtons.removeAll()
        
        // Create new buttons
        for (index, tab) in tabs.enumerated() {
            let button = createTabButton(for: tab, at: index, isActive: index == activeIndex)
            tabButtons.append(button)
            stackView.addArrangedSubview(button)
        }
    }
    
    private func createTabButton(for tab: Tab, at index: Int, isActive: Bool) -> NSButton {
        let button = NSButton()
        button.title = tab.directoryState.currentURL.lastPathComponent
        button.bezelStyle = .texturedRounded
        button.target = self
        button.action = #selector(switchToTab(_:))
        button.tag = index
        button.translatesAutoresizingMaskIntoConstraints = false
        
        if isActive {
            button.state = .on
        }
        
        return button
    }
    
    // MARK: - Actions
    
    @objc private func createNewTab() {
        delegate?.tabBarViewDidRequestNewTab()
    }
    
    @objc private func switchToTab(_ sender: NSButton) {
        let index = sender.tag
        delegate?.tabBarView(self, didSelectTabAt: index)
    }
    
    @objc private func closeTab(_ sender: NSButton) {
        let index = sender.tag
        delegate?.tabBarView(self, didRequestCloseTabAt: index)
    }
}

// MARK: - Tab Bar View Delegate

@MainActor
protocol TabBarViewDelegate: AnyObject {
    func tabBarViewDidRequestNewTab()
    func tabBarView(_ view: TabBarView, didSelectTabAt index: Int)
    func tabBarView(_ view: TabBarView, didRequestCloseTabAt index: Int)
}