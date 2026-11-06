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

    var showHiddenFiles: Bool = SettingsManager.shared.showHiddenFiles {
        didSet {
            if oldValue != showHiddenFiles {
                SettingsManager.shared.showHiddenFiles = showHiddenFiles
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

    private var fileSystemProvider: FileSystemProvider
    private var loadCompletion: LoadCompletion?
    private let watcher = FileSystemWatcher()
    private var isNetworkProvider: Bool = false

    // MARK: - Initialization

    init(initialURL: URL = FileManager.default.homeDirectoryForCurrentUser, provider: FileSystemProvider? = nil) {
        self.currentURL = initialURL
        self.fileSystemProvider = provider ?? LocalFileSystemProvider()
        self.isNetworkProvider = !(self.fileSystemProvider is LocalFileSystemProvider)
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

        Task {
            do {
                let loadedItems = try await fileSystemProvider.listContents(of: url, showHidden: showHiddenFiles)
                await MainActor.run {
                    self.items = loadedItems
                    self.loadCompletion?(.success(loadedItems))
                }
            } catch {
                await MainActor.run {
                    self.items = []
                    self.loadCompletion?(.failure(error))
                }
            }
        }

        // Start watching for file system changes (only for local)
        if !isNetworkProvider {
            startWatching()
        }
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
        Task {
            do {
                let loadedItems = try await fileSystemProvider.listContents(of: currentURL, showHidden: showHiddenFiles)
                await MainActor.run {
                    self.items = loadedItems
                    self.loadCompletion?(.success(loadedItems))
                }
            } catch {
                await MainActor.run {
                    self.items = []
                    self.loadCompletion?(.failure(error))
                }
            }
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