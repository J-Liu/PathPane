import Foundation

// MARK: - Directory State

@MainActor
class DirectoryState {
    
    // MARK: - Types
    
    typealias LoadCompletion = (Result<[FileItem], Error>) -> Void
    
    // MARK: - Properties
    
    private(set) var currentURL: URL
    private(set) var items: [FileItem] = []
    var showHiddenFiles: Bool = false {
        didSet {
            if oldValue != showHiddenFiles {
                reload()
            }
        }
    }
    
    // MARK: - Private Properties
    
    private let fileSystemService = FileSystemService.shared
    private var loadCompletion: LoadCompletion?
    private let watcher = FileSystemWatcher()
    
    // MARK: - Initialization
    
    init(initialURL: URL = FileManager.default.homeDirectoryForCurrentUser) {
        self.currentURL = initialURL
    }
    
    // MARK: - Public Methods
    
    /// Load contents of a directory
    /// - Parameters:
    ///   - url: Directory URL to load
    ///   - completion: Completion handler called after loading
    func load(url: URL, completion: LoadCompletion? = nil) {
        self.loadCompletion = completion
        self.currentURL = url
        
        do {
            items = try fileSystemService.listContents(of: url, showHidden: showHiddenFiles)
            loadCompletion?(.success(items))
        } catch {
            items = []
            loadCompletion?(.failure(error))
        }
        
        // Start watching for file system changes
        startWatching()
    }
    
    /// Start watching current directory for changes
    private func startWatching() {
        watcher.startWatching(url: currentURL) { [weak self] in
            Task { @MainActor in
                self?.reload()
            }
        }
    }
    
    /// Reload current directory
    func reload() {
        do {
            items = try fileSystemService.listContents(of: currentURL, showHidden: showHiddenFiles)
            loadCompletion?(.success(items))
        } catch {
            items = []
            loadCompletion?(.failure(error))
        }
    }
}