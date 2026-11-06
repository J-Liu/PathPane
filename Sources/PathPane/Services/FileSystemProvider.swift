// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright © 2026 Jia Liu

import Foundation

// MARK: - File System Provider Protocol

/// Protocol that abstracts file system operations
/// Allows different implementations (local, SMB, SFTP, FTP)
protocol FileSystemProvider: AnyObject, Sendable {
    
    // MARK: - Properties
    
    /// Root URL for this provider
    var rootURL: URL { get }
    
    /// Display name for this provider
    var displayName: String { get }
    
    /// Whether this provider is connected
    var isConnected: Bool { get }
    
    // MARK: - Directory Operations
    
    /// List contents of a directory
    /// - Parameters:
    ///   - url: Directory URL to list
    ///   - showHidden: Whether to include hidden files
    /// - Returns: Array of FileItem objects
    func listContents(of url: URL, showHidden: Bool) async throws -> [FileItem]
    
    /// Create a directory
    /// - Parameter url: URL of directory to create
    func createDirectory(at url: URL) async throws
    
    // MARK: - File Operations
    
    /// Copy an item
    /// - Parameters:
    ///   - source: Source URL
    ///   - destination: Destination URL
    func copyItem(at source: URL, to destination: URL) async throws
    
    /// Move an item
    /// - Parameters:
    ///   - source: Source URL
    ///   - destination: Destination URL
    func moveItem(at source: URL, to destination: URL) async throws
    
    /// Delete an item
    /// - Parameter url: URL of item to delete
    func deleteItem(at url: URL) async throws
    
    /// Move an item to trash
    /// - Parameter url: URL of item to trash
    /// - Returns: URL where the item was moved in trash
    func trashItem(at url: URL) async throws -> URL?
    
    /// Rename an item
    /// - Parameters:
    ///   - url: URL of item to rename
    ///   - newName: New name for the item
    func renameItem(at url: URL, to newName: String) async throws
    
    // MARK: - Connection
    
    /// Connect to the file system
    func connect() async throws
    
    /// Disconnect from the file system
    func disconnect() async
}

// MARK: - File System Provider Error

enum FileSystemProviderError: Error, LocalizedError {
    case notConnected
    case invalidURL(String)
    case permissionDenied
    case itemNotFound
    case itemAlreadyExists
    case operationNotSupported
    
    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Not connected to file system"
        case .invalidURL(let message):
            return "Invalid URL: \(message)"
        case .permissionDenied:
            return "Permission denied"
        case .itemNotFound:
            return "Item not found"
        case .itemAlreadyExists:
            return "Item already exists"
        case .operationNotSupported:
            return "Operation not supported"
        }
    }
}

// MARK: - Connection Configuration

/// Configuration for connecting to a file system
struct FileSystemConnectionConfig: Sendable {
    let serverType: ServerType
    let host: String
    let port: Int?
    let username: String?
    let password: String?
    let path: String?

    enum ServerType: String, Sendable {
        case local = "local"
        case smb = "smb"
        case sftp = "sftp"
        case ftp = "ftp"
    }
    
    init(serverType: ServerType, host: String, port: Int? = nil, username: String? = nil, password: String? = nil, path: String? = nil) {
        self.serverType = serverType
        self.host = host
        self.port = port
        self.username = username
        self.password = password
        self.path = path
    }
    
    /// Create URL from configuration
    var url: URL? {
        var components = URLComponents()
        components.scheme = serverType.rawValue
        components.host = host
        if let port = port {
            components.port = port
        }
        if let username = username {
            components.user = username
        }
        if let password = password {
            components.password = password
        }
        if let path = path {
            components.path = path
        }
        return components.url
    }
    
    /// Display name for the connection
    var displayName: String {
        switch serverType {
        case .local:
            return "Local"
        case .smb:
            return "SMB: \(host)"
        case .sftp:
            return "SFTP: \(host)"
        case .ftp:
            return "FTP: \(host)"
        }
    }
}