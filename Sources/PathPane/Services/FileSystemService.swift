import Foundation

// MARK: - File System Service

class FileSystemService {
    
    // MARK: - Shared Instance
    
    @MainActor static let shared = FileSystemService()
    
    // MARK: - Private Properties
    
    private let fileManager = FileManager.default
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// List contents of a directory
    /// - Parameters:
    ///   - url: Directory URL to list
    ///   - showHidden: Whether to include hidden files
    /// - Returns: Array of FileItem objects
    func listContents(of url: URL, showHidden: Bool = false) throws -> [FileItem] {
        // Prefetch attributes to avoid multiple stat calls
        let resourceKeys: [URLResourceKey] = [
            .nameKey,
            .isDirectoryKey,
            .isHiddenKey,
            .fileSizeKey,
            .contentModificationDateKey,
            .isSymbolicLinkKey
        ]
        
        let options: FileManager.DirectoryEnumerationOptions = showHidden
            ? [.skipsSubdirectoryDescendants]
            : [.skipsSubdirectoryDescendants, .skipsHiddenFiles]
        
        // Get directory contents
        let contents = try fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: resourceKeys,
            options: options
        )
        
        // Convert to FileItem objects
        let items = try contents.map { url in
            try createFileItem(from: url)
        }
        
        // Sort: directories first, then by name
        return items.sorted { lhs, rhs in
            if lhs.isDirectory != rhs.isDirectory {
                return lhs.isDirectory
            }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }
    
    // MARK: - Private Methods
    
    private func createFileItem(from url: URL) throws -> FileItem {
        // Get resource values
        let resourceValues = try url.resourceValues(forKeys: [
            .nameKey,
            .isDirectoryKey,
            .isHiddenKey,
            .fileSizeKey,
            .contentModificationDateKey,
            .isSymbolicLinkKey
        ])
        
        let name = resourceValues.name ?? url.lastPathComponent
        let isDirectory = resourceValues.isDirectory ?? false
        let isHidden = resourceValues.isHidden ?? false
        let fileSize = UInt64(resourceValues.fileSize ?? 0)
        let modificationDate = resourceValues.contentModificationDate
        let isSymlink = resourceValues.isSymbolicLink ?? false
        
        return FileItem(
            url: url,
            name: name,
            isDirectory: isDirectory,
            isHidden: isHidden,
            fileSize: fileSize,
            modificationDate: modificationDate,
            isSymlink: isSymlink
        )
    }
}