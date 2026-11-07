// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright © 2026 Jia Liu

import AppKit

// MARK: - Content View Controller

class ContentViewController: NSViewController {
    
    // MARK: - Properties
    
    private let directoryState: DirectoryState
    private let settings = SettingsManager.shared
    
    var fileListViewController: FileListViewController?
    private var iconGridViewController: IconGridViewController?
    private var thumbnailGridViewController: ThumbnailGridViewController?
    
    private var currentViewMode: ViewMode = .list
    
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
    
    private var containerView: NSView = {
        let view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
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
        switchToViewMode(settings.viewMode)

        // Observe directory changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(directoryItemsDidChange),
            name: .directoryStateItemsDidChange,
            object: directoryState
        )
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
        
        // Add container for file views
        view.addSubview(containerView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            breadcrumbView.topAnchor.constraint(equalTo: view.topAnchor),
            breadcrumbView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            breadcrumbView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            pathBarView.topAnchor.constraint(equalTo: breadcrumbView.bottomAnchor),
            pathBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pathBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            containerView.topAnchor.constraint(equalTo: pathBarView.bottomAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - View Mode Switching
    
    func switchToViewMode(_ mode: ViewMode) {
        currentViewMode = mode
        settings.viewMode = mode
        
        // Remove current view
        containerView.subviews.forEach { $0.removeFromSuperview() }
        children.forEach { $0.removeFromParent() }
        
        // Create and add appropriate view controller
        switch mode {
        case .list:
            let listVC = FileListViewController(directoryState: directoryState)
            addChild(listVC)
            containerView.addSubview(listVC.view)
            listVC.view.frame = containerView.bounds
            listVC.view.autoresizingMask = [.width, .height]
            self.fileListViewController = listVC
            
        case .icon:
            let iconVC = IconGridViewController(directoryState: directoryState)
            addChild(iconVC)
            containerView.addSubview(iconVC.view)
            iconVC.view.frame = containerView.bounds
            iconVC.view.autoresizingMask = [.width, .height]
            self.iconGridViewController = iconVC
            
        case .thumbnail:
            let thumbnailVC = ThumbnailGridViewController(directoryState: directoryState)
            addChild(thumbnailVC)
            containerView.addSubview(thumbnailVC.view)
            thumbnailVC.view.frame = containerView.bounds
            thumbnailVC.view.autoresizingMask = [.width, .height]
            self.thumbnailGridViewController = thumbnailVC
        }
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
                self?.reloadCurrentView()
            }
        }
    }

    @objc private func directoryItemsDidChange() {
        updatePathBar()
        reloadCurrentView()
    }
    
    func reloadCurrentView() {
        switch currentViewMode {
        case .list:
            fileListViewController?.reloadData()
        case .icon:
            iconGridViewController?.reloadData()
        case .thumbnail:
            thumbnailGridViewController?.reloadData()
        }
    }
}