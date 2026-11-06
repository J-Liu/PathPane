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