// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright © 2026 Jia Liu

import Foundation

// MARK: - SMB File System Provider

/// File system provider for SMB/CIFS shares
final class SMBFileSystemProvider: FileSystemProvider, @unchecked Sendable {

    // MARK: - Properties

    let rootURL: URL
    let displayName: String
    private(set) var isConnected: Bool = false

    private let config: FileSystemConnectionConfig
    private var mountPoint: URL?
    private var localProvider: LocalFileSystemProvider?
    
    // MARK: - Initialization
    
    init(config: FileSystemConnectionConfig) {
        self.config = config
        self.rootURL = config.url ?? URL(fileURLWithPath: "/")
        self.displayName = config.displayName
    }
    
    // MARK: - Directory Operations
    
    func listContents(of url: URL, showHidden: Bool) async throws -> [FileItem] {
        guard isConnected, let localProvider = localProvider else {
            throw FileSystemProviderError.notConnected
        }
        return try await localProvider.listContents(of: url, showHidden: showHidden)
    }
    
    func createDirectory(at url: URL) async throws {
        guard isConnected, let localProvider = localProvider else {
            throw FileSystemProviderError.notConnected
        }
        try await localProvider.createDirectory(at: url)
    }
    
    // MARK: - File Operations
    
    func copyItem(at source: URL, to destination: URL) async throws {
        guard isConnected, let localProvider = localProvider else {
            throw FileSystemProviderError.notConnected
        }
        try await localProvider.copyItem(at: source, to: destination)
    }
    
    func moveItem(at source: URL, to destination: URL) async throws {
        guard isConnected, let localProvider = localProvider else {
            throw FileSystemProviderError.notConnected
        }
        try await localProvider.moveItem(at: source, to: destination)
    }
    
    func deleteItem(at url: URL) async throws {
        guard isConnected, let localProvider = localProvider else {
            throw FileSystemProviderError.notConnected
        }
        try await localProvider.deleteItem(at: url)
    }
    
    func trashItem(at url: URL) async throws -> URL? {
        guard isConnected, let localProvider = localProvider else {
            throw FileSystemProviderError.notConnected
        }
        return try await localProvider.trashItem(at: url)
    }
    
    func renameItem(at url: URL, to newName: String) async throws {
        guard isConnected, let localProvider = localProvider else {
            throw FileSystemProviderError.notConnected
        }
        try await localProvider.renameItem(at: url, to: newName)
    }
    
    // MARK: - Connection
    
    func connect() async throws {
        guard !isConnected else { return }
        
        // Create mount point in /Volumes
        let mountName = "\(config.host)_\(config.path?.replacingOccurrences(of: "/", with: "_") ?? "root")"
        let mountPoint = URL(fileURLWithPath: "/Volumes/\(mountName)")
        
        // Create mount point directory
        try? FileManager.default.createDirectory(at: mountPoint, withIntermediateDirectories: true)
        
        // Build mount_smbfs command
        var arguments = ["mount_smbfs"]
        
        // Add credentials if provided
        if let username = config.username {
            var credential = username
            if let password = config.password {
                credential = "\(username):\(password)"
            }
            arguments.append("//\(credential)@\(config.host)\(config.path ?? "/")")
        } else {
            arguments.append("//\(config.host)\(config.path ?? "/")")
        }
        
        arguments.append(mountPoint.path)
        
        // Execute mount command
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
        process.arguments = arguments
        
        // Alternative: use open command to let system handle authentication
        let openProcess = Process()
        openProcess.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        openProcess.arguments = [rootURL.absoluteString]
        
        do {
            try openProcess.run()
            openProcess.waitUntilExit()
            
            // Wait a moment for mount to complete
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            // Find the actual mount point
            if let mountedURL = findMountPoint(for: config.host) {
                self.mountPoint = mountedURL
                self.localProvider = LocalFileSystemProvider(rootURL: mountedURL)
                self.isConnected = true
            } else {
                throw FileSystemProviderError.notConnected
            }
        } catch {
            throw FileSystemProviderError.notConnected
        }
    }
    
    func disconnect() async {
        guard isConnected, let mountPoint = mountPoint else { return }
        
        // Unmount using diskutil
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/diskutil")
        process.arguments = ["unmount", mountPoint.path]
        
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            // Ignore errors during disconnect
        }
        
        self.isConnected = false
        self.mountPoint = nil
        self.localProvider = nil
    }
    
    // MARK: - Private Methods
    
    private func findMountPoint(for host: String) -> URL? {
        // Check /Volumes for mounted shares
        let volumesURL = URL(fileURLWithPath: "/Volumes")
        guard let contents = try? FileManager.default.contentsOfDirectory(at: volumesURL, includingPropertiesForKeys: nil) else {
            return nil
        }
        
        // Find the most recently mounted volume matching the host
        for volume in contents {
            // Check if this volume is our SMB mount
            if let mountInfo = getMountInfo(for: volume.path), mountInfo.contains(host) {
                return volume
            }
        }
        
        return nil
    }
    
    private func getMountInfo(for path: String) -> String? {
        // Use mount command to get mount info
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/sbin/mount")
        process.arguments = ["-t", "smbfs"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            // Look for our path in the output
            if output.contains(path) {
                return output
            }
        } catch {
            // Ignore errors
        }
        
        return nil
    }
}