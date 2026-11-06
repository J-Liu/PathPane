import Foundation

// MARK: - File Item Model

struct FileItem {
    let url: URL
    let name: String
    let isDirectory: Bool
    let isHidden: Bool
    let fileSize: UInt64
    let modificationDate: Date?
    let isSymlink: Bool
    
    // MARK: - Convenience Properties
    
    /// File extension (without dot)
    var fileExtension: String {
        url.pathExtension
    }
    
    /// Whether the item is a package (directory that appears as a file)
    var isPackage: Bool {
        isDirectory && !url.pathExtension.isEmpty
    }
}