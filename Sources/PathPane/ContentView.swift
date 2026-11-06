import AppKit

// MARK: - Content View Controller

class ContentViewController: NSViewController {
    
    // MARK: - Properties
    
    private let directoryState: DirectoryState
    var fileListViewController: FileListViewController?
    
    // MARK: - UI Elements
    
    private lazy var pathBarView: PathBarView = {
        let view = PathBarView()
        view.currentURL = directoryState.currentURL
        return view
    }()
    
    private lazy var breadcrumbView: BreadcrumbView = {
        let view = BreadcrumbView()
        view.currentURL = directoryState.currentURL
        return view
    }()
    
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
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        
        setupSubviews()
        setupConstraints()
    }
    
    // MARK: - Setup
    
    private func setupSubviews() {
        // Add breadcrumb view
        view.addSubview(breadcrumbView)
        breadcrumbView.translatesAutoresizingMaskIntoConstraints = false
        breadcrumbView.onBreadcrumbClick = { [weak self] url in
            self?.navigateToURL(url)
        }
        
        // Add path bar
        view.addSubview(pathBarView)
        pathBarView.translatesAutoresizingMaskIntoConstraints = false
        pathBarView.onPathSubmit = { [weak self] url in
            self?.navigateToURL(url)
        }
        
        // Add file list
        let fileVC = FileListViewController(directoryState: directoryState)
        addChild(fileVC)
        view.addSubview(fileVC.view)
        fileVC.view.translatesAutoresizingMaskIntoConstraints = false
        self.fileListViewController = fileVC
    }
    
    private func setupConstraints() {
        guard let fileVC = fileListViewController else { return }
        
        NSLayoutConstraint.activate([
            breadcrumbView.topAnchor.constraint(equalTo: view.topAnchor),
            breadcrumbView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            breadcrumbView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            pathBarView.topAnchor.constraint(equalTo: breadcrumbView.bottomAnchor),
            pathBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pathBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            fileVC.view.topAnchor.constraint(equalTo: pathBarView.bottomAnchor),
            fileVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            fileVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            fileVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - Public Methods
    
    func updatePathBar() {
        pathBarView.currentURL = directoryState.currentURL
        breadcrumbView.currentURL = directoryState.currentURL
    }
    
    func activatePathBarForEditing() {
        pathBarView.activateForEditing()
    }
    
    // MARK: - Navigation
    
    private func navigateToURL(_ url: URL) {
        directoryState.load(url: url) { [weak self] result in
            DispatchQueue.main.async {
                self?.updatePathBar()
                self?.fileListViewController?.reloadData()
            }
        }
    }
}