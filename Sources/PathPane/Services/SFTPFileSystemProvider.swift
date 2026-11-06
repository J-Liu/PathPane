import Foundation

// MARK: - SFTP File System Provider

/// File system provider for SFTP servers
final class SFTPFileSystemProvider: FileSystemProvider, @unchecked Sendable {

    // MARK: - Properties

    let rootURL: URL
    let displayName: String
    private(set) var isConnected: Bool = false

    private let config: FileSystemConnectionConfig
    private var currentPath: String = "/"
    
    // MARK: - Initialization
    
    init(config: FileSystemConnectionConfig) {
        self.config = config
        self.rootURL = config.url ?? URL(fileURLWithPath: "/")
        self.displayName = config.displayName
    }
    
    // MARK: - Directory Operations
    
    func listContents(of url: URL, showHidden: Bool) async throws -> [FileItem] {
        guard isConnected else {
            throw FileSystemProviderError.notConnected
        }
        
        let path = url.path
        let output = try await executeSFTPCommand("ls -l\(showHidden ? "a" : "") \"\(path)\"")
        
        return parseListOutput(output, baseURL: url)
    }
    
    func createDirectory(at url: URL) async throws {
        guard isConnected else {
            throw FileSystemProviderError.notConnected
        }
        
        let path = url.path
        _ = try await executeSFTPCommand("mkdir \"\(path)\"")
    }
    
    // MARK: - File Operations
    
    func copyItem(at source: URL, to destination: URL) async throws {
        // SFTP doesn't have native copy command
        // Need to download and re-upload
        throw FileSystemProviderError.operationNotSupported
    }
    
    func moveItem(at source: URL, to destination: URL) async throws {
        guard isConnected else {
            throw FileSystemProviderError.notConnected
        }
        
        let sourcePath = source.path
        let destPath = destination.path
        _ = try await executeSFTPCommand("rename \"\(sourcePath)\" \"\(destPath)\"")
    }
    
    func deleteItem(at url: URL) async throws {
        guard isConnected else {
            throw FileSystemProviderError.notConnected
        }
        
        let path = url.path
        _ = try await executeSFTPCommand("rm \"\(path)\"")
    }
    
    func trashItem(at url: URL) async throws -> URL? {
        // SFTP doesn't have trash
        throw FileSystemProviderError.operationNotSupported
    }
    
    func renameItem(at url: URL, to newName: String) async throws {
        guard isConnected else {
            throw FileSystemProviderError.notConnected
        }
        
        let sourcePath = url.path
        let destPath = url.deletingLastPathComponent().appendingPathComponent(newName).path
        _ = try await executeSFTPCommand("rename \"\(sourcePath)\" \"\(destPath)\"")
    }
    
    // MARK: - Connection
    
    func connect() async throws {
        guard !isConnected else { return }
        
        // Test connection with a simple command
        do {
            _ = try await executeSFTPCommand("pwd")
            isConnected = true
        } catch {
            throw FileSystemProviderError.notConnected
        }
    }
    
    func disconnect() async {
        isConnected = false
    }
    
    // MARK: - Private Methods
    
    private func executeSFTPCommand(_ command: String) async throws -> String {
        // Build SFTP command
        var arguments = ["-b", "-", "-o", "BatchMode=yes"]
        
        // Add port if specified
        if let port = config.port {
            arguments.append(contentsOf: ["-o", "Port=\(port)"])
        }
        
        // Build host string
        var hostString = ""
        if let username = config.username {
            hostString = "\(username)@\(config.host)"
        } else {
            hostString = config.host
        }
        
        arguments.append(hostString)
        
        // Create process
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sftp")
        process.arguments = arguments
        
        let inputPipe = Pipe()
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        
        process.standardInput = inputPipe
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        // Write command to stdin
        let commandData = (command + "\n").data(using: .utf8)!
        inputPipe.fileHandleForWriting.write(commandData)
        inputPipe.fileHandleForWriting.closeFile()
        
        // Run process
        try process.run()
        process.waitUntilExit()
        
        // Read output
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: outputData, encoding: .utf8) ?? ""
        
        if process.terminationStatus != 0 {
            _ = errorPipe.fileHandleForReading.readDataToEndOfFile()
            throw FileSystemProviderError.itemNotFound
        }
        
        return output
    }
    
    private func parseListOutput(_ output: String, baseURL: URL) -> [FileItem] {
        var items: [FileItem] = []
        
        let lines = output.components(separatedBy: "\n")
        for line in lines {
            guard !line.isEmpty else { continue }
            
            // Parse ls -l output
            // Format: permissions links owner group size month day time/year name
            let components = line.split(separator: " ", omittingEmptySubsequences: true)
            guard components.count >= 9 else { continue }
            
            let permissions = String(components[0])
            let isDirectory = permissions.hasPrefix("d")
            let isSymlink = permissions.hasPrefix("l")
            
            // Size is at index 4
            guard let fileSize = UInt64(String(components[4])) else { continue }
            
            // Name is the last component
            let name = components.suffix(1).first.map(String.init) ?? ""
            guard !name.isEmpty, name != ".", name != ".." else { continue }
            
            // Check if hidden
            let isHidden = name.hasPrefix(".")
            
            // Try to parse date
            var modificationDate: Date? = nil
            if let monthIdx = components.indices.first(where: { $0 >= 5 }),
               monthIdx + 2 < components.count {
                let month = String(components[monthIdx])
                let day = String(components[monthIdx + 1])
                let timeOrYear = String(components[monthIdx + 2])
                
                // Try to parse date string
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MMM d yyyy"
                if let date = dateFormatter.date(from: "\(month) \(day) \(timeOrYear)") {
                    modificationDate = date
                } else {
                    dateFormatter.dateFormat = "MMM d HH:mm"
                    if let date = dateFormatter.date(from: "\(month) \(day) \(timeOrYear)") {
                        modificationDate = date
                    }
                }
            }
            
            let url = baseURL.appendingPathComponent(name)
            
            let item = FileItem(
                url: url,
                name: name,
                isDirectory: isDirectory,
                isHidden: isHidden,
                fileSize: fileSize,
                modificationDate: modificationDate,
                isSymlink: isSymlink
            )
            
            items.append(item)
        }
        
        // Sort: directories first, then by name
        return items.sorted { lhs, rhs in
            if lhs.isDirectory != rhs.isDirectory {
                return lhs.isDirectory
            }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }
}