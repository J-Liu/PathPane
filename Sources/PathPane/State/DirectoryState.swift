import Foundation

// MARK: - Directory State

@MainActor
class DirectoryState {
    
    // MARK: - Types
    
    typealias LoadCompletion = (Result<[FileItem], Error>) -> Void
    
    // MARK: - Properties
    
    private(set) var currentURL: URL
    private(set) var items: [FileItem] = []
    
    // Navigation history
    private(set) var history: [URL] = []
    private(set) var historyIndex: Int = -1
    
    var showHiddenFiles: Bool = false {
        didSet {
            if oldValue != showHiddenFiles {
                reload()
            }
        }
    }
    
    // Navigation state
    var canGoBack: Bool {
        historyIndex > 0
    }
    
    var canGoForward: Bool {
        historyIndex < history.count - 1
    }
    
    var canGoUp: Bool {
        currentURL.path != "/"
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
    ///   - addToHistory: Whether to add to navigation history (default: true)
    func load(url: URL, completion: LoadCompletion? = nil, addToHistory: Bool = true) {
        self.loadCompletion = completion
        self.currentURL = url
        
        // Add to history if requested
        if addToHistory {
            // Remove forward history if navigating to new location
            if historyIndex < history.count - 1 {
                history.removeLast(history.count - historyIndex - 1)
            }
            history.append(url)
            historyIndex = history.count - 1
        }
        
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
    
    // MARK: - Navigation
    
    /// Go back in history
    func goBack() {
        guard canGoBack else { return }
        historyIndex -= 1
        let url = history[historyIndex]
        load(url: url, addToHistory: false)
    }
    
    /// Go forward in history
    func goForward() {
        guard canGoForward else { return }
        historyIndex += 1
        let url = history[historyIndex]
        load(url: url, addToHistory: false)
    }
    
    /// Go to parent directory
    func goUp() {
        guard canGoUp else { return }
        let parentURL = currentURL.deletingLastPathComponent()
        load(url: parentURL)
    }
}