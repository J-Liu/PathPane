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
    }
    
    /// Reload current directory
    func reload() {
        load(url: currentURL, completion: loadCompletion)
    }
}