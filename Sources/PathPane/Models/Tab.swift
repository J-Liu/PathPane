import Foundation

// MARK: - Tab Model

@MainActor
class Tab {
    
    // MARK: - Properties
    
    let id: UUID
    let directoryState: DirectoryState
    
    // MARK: - Initialization
    
    init(initialURL: URL = FileManager.default.homeDirectoryForCurrentUser) {
        self.id = UUID()
        self.directoryState = DirectoryState(initialURL: initialURL)
    }
}