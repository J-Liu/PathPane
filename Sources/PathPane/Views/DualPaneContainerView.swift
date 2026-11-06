import AppKit

// MARK: - Dual Pane Container View

@MainActor
class DualPaneContainerView: NSView {
    
    // MARK: - Properties
    
    private var leftPane: NSView?
    private var rightPane: NSView?
    private var splitView: NSSplitView?
    
    var isDualPaneMode: Bool = false {
        didSet {
            updateLayout()
        }
    }
    
    weak var leftContentView: NSView? {
        didSet {
            if let left = leftContentView {
                leftPane?.addSubview(left)
                setupConstraints(for: left, in: leftPane)
            }
        }
    }
    
    weak var rightContentView: NSView? {
        didSet {
            if let right = rightContentView, let rightPane = rightPane {
                rightPane.addSubview(right)
                setupConstraints(for: right, in: rightPane)
            }
        }
    }
    
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
        
        // Create split view
        let split = NSSplitView()
        split.dividerStyle = .thin
        split.isVertical = true
        split.translatesAutoresizingMaskIntoConstraints = false
        
        // Create left pane
        let left = NSView()
        left.wantsLayer = true
        left.translatesAutoresizingMaskIntoConstraints = false
        
        // Create right pane
        let right = NSView()
        right.wantsLayer = true
        right.translatesAutoresizingMaskIntoConstraints = false
        right.isHidden = true
        
        split.addArrangedSubview(left)
        split.addArrangedSubview(right)
        
        addSubview(split)
        
        NSLayoutConstraint.activate([
            split.topAnchor.constraint(equalTo: topAnchor),
            split.leadingAnchor.constraint(equalTo: leadingAnchor),
            split.trailingAnchor.constraint(equalTo: trailingAnchor),
            split.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        self.splitView = split
        self.leftPane = left
        self.rightPane = right
    }
    
    private func updateLayout() {
        guard let rightPane = rightPane else { return }
        
        rightPane.isHidden = !isDualPaneMode
        
        if isDualPaneMode {
            // Equal split
            splitView?.setPosition(bounds.width / 2, ofDividerAt: 0)
        }
    }
    
    private func setupConstraints(for view: NSView, in container: NSView?) {
        guard let container = container else { return }
        
        view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: container.topAnchor),
            view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
    }
}