import Foundation

// MARK: - Local File System Provider

/// File system provider for local file system
final class LocalFileSystemProvider: FileSystemProvider, @unchecked Sendable {

    // MARK: - Properties

    let rootURL: URL
    let displayName: String
    private(set) var isConnected: Bool = true

    // MARK: - Initialization

    init(rootURL: URL = URL(fileURLWithPath: "/")) {
        self.rootURL = rootURL
        self.displayName = "Local"
    }

    // MARK: - Directory Operations

    func listContents(of url: URL, showHidden: Bool) async throws -> [FileItem] {
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
        let contents = try FileManager.default.contentsOfDirectory(
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

    func createDirectory(at url: URL) async throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false)
    }

    // MARK: - File Operations

    func copyItem(at source: URL, to destination: URL) async throws {
        try FileManager.default.copyItem(at: source, to: destination)
    }

    func moveItem(at source: URL, to destination: URL) async throws {
        try FileManager.default.moveItem(at: source, to: destination)
    }

    func deleteItem(at url: URL) async throws {
        try FileManager.default.removeItem(at: url)
    }

    func trashItem(at url: URL) async throws -> URL? {
        var resultURL: NSURL?
        try FileManager.default.trashItem(at: url, resultingItemURL: &resultURL)
        return resultURL as URL?
    }

    func renameItem(at url: URL, to newName: String) async throws {
        let newURL = url.deletingLastPathComponent().appendingPathComponent(newName)
        try FileManager.default.moveItem(at: url, to: newURL)
    }

    // MARK: - Connection

    func connect() async throws {
        // Local file system is always connected
        isConnected = true
    }

    func disconnect() async {
        // Local file system cannot be disconnected
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