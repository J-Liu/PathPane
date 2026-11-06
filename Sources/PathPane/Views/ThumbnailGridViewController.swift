import AppKit
@preconcurrency import QuickLookThumbnailing

// MARK: - Thumbnail Grid View Controller

@MainActor
class ThumbnailGridViewController: NSViewController {
    
    // MARK: - Properties
    
    let directoryState: DirectoryState
    private var thumbnailRequests: [URL: QLThumbnailGenerator.Request] = [:]
    
    // MARK: - UI Elements
    
    private lazy var scrollView: NSScrollView = {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        return scrollView
    }()
    
    private lazy var collectionView: NSCollectionView = {
        let layout = NSCollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.itemSize = NSSize(width: 120, height: 120)
        layout.minimumInteritemSpacing = 16
        layout.minimumLineSpacing = 16
        layout.sectionInset = NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        
        let collectionView = NSCollectionView()
        collectionView.collectionViewLayout = layout
        collectionView.isSelectable = true
        collectionView.allowsMultipleSelection = true
        collectionView.backgroundColors = [NSColor.clear]
        return collectionView
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
        
        setupSubviews()
        setupConstraints()
        loadInitialData()
    }
    
    deinit {
        // Cancel all thumbnail requests on main actor
        Task { @MainActor [thumbnailRequests] in
            thumbnailRequests.values.forEach { request in
                QLThumbnailGenerator.shared.cancel(request)
            }
        }
    }
    
    // MARK: - Setup
    
    private func setupSubviews() {
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(ThumbnailGridItem.self, forItemWithIdentifier: NSUserInterfaceItemIdentifier("ThumbnailGridItem"))

        // Setup context menu
        collectionView.menu = buildContextMenu()

        scrollView.documentView = collectionView
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
        collectionView.reloadData()
    }
    
    // MARK: - Public Methods
    
    func reloadData() {
        cancelAllThumbnailRequests()
        collectionView.reloadData()
    }

    // MARK: - Context Menu

    private func buildContextMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self

        menu.addItem(
            NSMenuItem(
                title: "Open",
                action: #selector(openSelectedItems),
                keyEquivalent: ""
            )
        )

        let openWithItem = NSMenuItem(
            title: "Open With",
            action: nil,
            keyEquivalent: ""
        )
        openWithItem.submenu = NSMenu()
        menu.addItem(openWithItem)

        menu.addItem(NSMenuItem.separator())

        menu.addItem(
            NSMenuItem(
                title: "Cut",
                action: #selector(cutSelectedItems),
                keyEquivalent: ""
            )
        )

        menu.addItem(
            NSMenuItem(
                title: "Copy",
                action: #selector(copySelectedItems),
                keyEquivalent: ""
            )
        )

        menu.addItem(
            NSMenuItem(
                title: "Paste",
                action: #selector(pasteItems),
                keyEquivalent: ""
            )
        )

        menu.addItem(NSMenuItem.separator())

        menu.addItem(
            NSMenuItem(
                title: "Rename",
                action: #selector(renameSelectedItem),
                keyEquivalent: ""
            )
        )

        menu.addItem(
            NSMenuItem(
                title: "Move to Trash",
                action: #selector(moveToTrash),
                keyEquivalent: ""
            )
        )

        menu.addItem(NSMenuItem.separator())

        menu.addItem(
            NSMenuItem(
                title: "Get Info",
                action: #selector(getInfoForSelectedItem),
                keyEquivalent: ""
            )
        )

        return menu
    }

    @objc private func openSelectedItems() {
        let selectedIndexPaths = collectionView.selectionIndexPaths
        guard !selectedIndexPaths.isEmpty else { return }

        for indexPath in selectedIndexPaths {
            guard indexPath.item < directoryState.items.count else { continue }
            let item = directoryState.items[indexPath.item]

            if item.isDirectory {
                directoryState.load(url: item.url) { [weak self] result in
                    Task { @MainActor in
                        self?.collectionView.reloadData()
                    }
                }
                break
            } else {
                NSWorkspace.shared.open(item.url)
            }
        }
    }

    @objc private func cutSelectedItems() {
        copySelectedItems()
        UserDefaults.standard.set(true, forKey: "PathPane_IsCutOperation")
    }

    @objc private func copySelectedItems() {
        let selectedIndexPaths = collectionView.selectionIndexPaths
        guard !selectedIndexPaths.isEmpty else { return }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        var urls: [URL] = []
        for indexPath in selectedIndexPaths {
            guard indexPath.item < directoryState.items.count else { continue }
            urls.append(directoryState.items[indexPath.item].url)
        }

        pasteboard.writeObjects(urls as [NSURL])
        UserDefaults.standard.set(false, forKey: "PathPane_IsCutOperation")
    }

    @objc private func pasteItems() {
        let pasteboard = NSPasteboard.general
        guard let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] else {
            return
        }

        let isCut = UserDefaults.standard.bool(forKey: "PathPane_IsCutOperation")
        let destinationDir = directoryState.currentURL

        for sourceURL in urls {
            let destinationURL = destinationDir.appendingPathComponent(sourceURL.lastPathComponent)

            do {
                if isCut {
                    try FileManager.default.moveItem(at: sourceURL, to: destinationURL)
                } else {
                    try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
                }
            } catch {
                print("Error pasting \(sourceURL): \(error)")
            }
        }

        if isCut {
            pasteboard.clearContents()
            UserDefaults.standard.set(false, forKey: "PathPane_IsCutOperation")
        }

        directoryState.reload()
        collectionView.reloadData()
    }

    @objc private func renameSelectedItem() {
        let selectedIndexPaths = collectionView.selectionIndexPaths
        guard let indexPath = selectedIndexPaths.first, indexPath.item < directoryState.items.count else { return }

        print("Rename: \(directoryState.items[indexPath.item].name)")
    }

    @objc private func moveToTrash() {
        let selectedIndexPaths = collectionView.selectionIndexPaths
        guard !selectedIndexPaths.isEmpty else { return }

        for indexPath in selectedIndexPaths {
            guard indexPath.item < directoryState.items.count else { continue }
            let item = directoryState.items[indexPath.item]

            do {
                var resultURL: NSURL?
                try FileManager.default.trashItem(at: item.url, resultingItemURL: &resultURL)
            } catch {
                print("Error moving to trash \(item.url): \(error)")
            }
        }

        directoryState.reload()
        collectionView.reloadData()
    }

    @objc private func getInfoForSelectedItem() {
        let selectedIndexPaths = collectionView.selectionIndexPaths
        guard let indexPath = selectedIndexPaths.first, indexPath.item < directoryState.items.count else { return }

        let item = directoryState.items[indexPath.item]
        NSWorkspace.shared.activateFileViewerSelecting([item.url])
    }

    // MARK: - Thumbnail Generation
    
    func generateThumbnail(for item: FileItem, completion: @escaping (NSImage?) -> Void) {
        let request = QLThumbnailGenerator.Request(
            fileAt: item.url,
            size: NSSize(width: 96, height: 96),
            scale: 2.0,
            representationTypes: .thumbnail
        )
        
        thumbnailRequests[item.url] = request
        
        QLThumbnailGenerator.shared.generateRepresentations(for: request) { [weak self] thumbnail, type, error in
            DispatchQueue.main.async {
                self?.thumbnailRequests.removeValue(forKey: item.url)

                if let thumbnail = thumbnail {
                    completion(thumbnail.nsImage)
                } else {
                    completion(nil)
                }
            }
        }
    }
    
    private func cancelAllThumbnailRequests() {
        thumbnailRequests.values.forEach { request in
            QLThumbnailGenerator.shared.cancel(request)
        }
        thumbnailRequests.removeAll()
    }
}

// MARK: - NSCollectionViewDataSource

extension ThumbnailGridViewController: NSCollectionViewDataSource {
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        directoryState.items.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        guard let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier("ThumbnailGridItem"), for: indexPath) as? ThumbnailGridItem else {
            return NSCollectionViewItem()
        }
        
        if indexPath.item < directoryState.items.count {
            let fileItem = directoryState.items[indexPath.item]
            item.configure(with: fileItem, thumbnailProvider: self)
        }
        
        return item
    }
}

// MARK: - NSCollectionViewDelegate

extension ThumbnailGridViewController: NSCollectionViewDelegate {
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        // Selection handling
    }
}

// MARK: - Thumbnail Provider

@MainActor
protocol ThumbnailProvider {
    func generateThumbnail(for item: FileItem, completion: @escaping (NSImage?) -> Void)
}

extension ThumbnailGridViewController: ThumbnailProvider {}

// MARK: - Thumbnail Grid Item

class ThumbnailGridItem: NSCollectionViewItem {
    
    // MARK: - UI Elements
    
    private lazy var thumbnailView: NSImageView = {
        let imageView = NSImageView()
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.wantsLayer = true
        imageView.layer?.cornerRadius = 8
        imageView.layer?.borderWidth = 0.5
        imageView.layer?.borderColor = NSColor.separatorColor.cgColor
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var nameLabel: NSTextField = {
        let label = NSTextField()
        label.isEditable = false
        label.isBordered = false
        label.backgroundColor = .clear
        label.alignment = .center
        label.lineBreakMode = .byTruncatingMiddle
        label.maximumNumberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Lifecycle
    
    override func loadView() {
        let containerView = NSView()
        containerView.wantsLayer = true
        
        containerView.addSubview(thumbnailView)
        containerView.addSubview(nameLabel)
        
        NSLayoutConstraint.activate([
            thumbnailView.topAnchor.constraint(equalTo: containerView.topAnchor),
            thumbnailView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            thumbnailView.widthAnchor.constraint(equalToConstant: 96),
            thumbnailView.heightAnchor.constraint(equalToConstant: 96),
            
            nameLabel.topAnchor.constraint(equalTo: thumbnailView.bottomAnchor, constant: 4),
            nameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 4),
            nameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -4),
            nameLabel.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor)
        ])
        
        view = containerView
    }
    
    // MARK: - Configuration
    
    func configure(with item: FileItem, thumbnailProvider: ThumbnailProvider?) {
        nameLabel.stringValue = item.name
        
        // Start with placeholder icon
        let placeholderIcon = NSWorkspace.shared.icon(forFile: item.url.path)
        placeholderIcon.size = NSSize(width: 64, height: 64)
        thumbnailView.image = placeholderIcon
        
        // Generate thumbnail for images, videos, PDFs
        if isThumbnailable(item) {
            thumbnailProvider?.generateThumbnail(for: item) { [weak self] image in
                if let image = image {
                    self?.thumbnailView.image = image
                }
            }
        }
    }
    
    private func isThumbnailable(_ item: FileItem) -> Bool {
        let thumbnailExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic", "pdf", "mp4", "mov", "avi", "mkv"]
        return thumbnailExtensions.contains(item.fileExtension.lowercased())
    }
}

// MARK: - NSMenuDelegate

extension ThumbnailGridViewController: NSMenuDelegate {

    func menuNeedsUpdate(_ menu: NSMenu) {
        let selectedIndexPaths = collectionView.selectionIndexPaths
        let hasSelection = !selectedIndexPaths.isEmpty
        let hasSingleSelection = selectedIndexPaths.count == 1

        for item in menu.items {
            switch item.title {
            case "Open":
                item.isEnabled = hasSelection
            case "Open With":
                item.isEnabled = hasSingleSelection && !selectedIndexPaths.contains(where: { $0.item < directoryState.items.count && directoryState.items[$0.item].isDirectory })
                if item.isEnabled, let submenu = item.submenu {
                    submenu.removeAllItems()
                    if let indexPath = selectedIndexPaths.first, indexPath.item < directoryState.items.count {
                        let fileItem = directoryState.items[indexPath.item]
                        buildOpenWithMenu(for: fileItem, in: submenu)
                    }
                }
            case "Cut", "Copy":
                item.isEnabled = hasSelection
            case "Paste":
                let pasteboard = NSPasteboard.general
                item.isEnabled = pasteboard.canReadItem(withDataConformingToTypes: [NSPasteboard.PasteboardType.fileURL.rawValue])
            case "Rename":
                item.isEnabled = hasSingleSelection
            case "Move to Trash":
                item.isEnabled = hasSelection
            case "Get Info":
                item.isEnabled = hasSingleSelection
            default:
                break
            }
        }
    }

    private func buildOpenWithMenu(for item: FileItem, in menu: NSMenu) {
        guard !item.isDirectory else { return }

        let urls = NSWorkspace.shared.urlsForApplications(toOpen: item.url)

        if urls.isEmpty {
            let item = NSMenuItem(title: "No Applications Available", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
        } else {
            for appURL in urls {
                let appName = appURL.deletingLastPathComponent().lastPathComponent
                let menuItem = NSMenuItem(
                    title: appName,
                    action: #selector(openWithApplication(_:)),
                    keyEquivalent: ""
                )
                menuItem.representedObject = appURL
                menu.addItem(menuItem)
            }
        }
    }

    @objc private func openWithApplication(_ sender: NSMenuItem) {
        guard let appURL = sender.representedObject as? URL else { return }

        let selectedIndexPaths = collectionView.selectionIndexPaths
        for indexPath in selectedIndexPaths {
            guard indexPath.item < directoryState.items.count else { continue }
            let item = directoryState.items[indexPath.item]
            NSWorkspace.shared.open([item.url], withApplicationAt: appURL, configuration: NSWorkspace.OpenConfiguration())
        }
    }
}