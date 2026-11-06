import Foundation

// MARK: - Network Manager

@MainActor
class NetworkManager {
    
    // MARK: - Singleton
    
    static let shared = NetworkManager()
    
    // MARK: - Properties
    
    private(set) var connections: [UUID: NetworkConnection] = [:]
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Connection Management
    
    /// Create a new network connection
    /// - Parameter config: Connection configuration
    /// - Returns: The created connection
    func createConnection(config: FileSystemConnectionConfig) async throws -> NetworkConnection {
        // Create provider based on server type
        let provider: FileSystemProvider
        
        switch config.serverType {
        case .smb:
            provider = SMBFileSystemProvider(config: config)
        case .sftp:
            provider = SFTPFileSystemProvider(config: config)
        case .ftp:
            provider = FTPFileSystemProvider(config: config)
        case .local:
            provider = LocalFileSystemProvider()
        }
        
        // Connect to server
        try await provider.connect()
        
        // Create connection object
        let connection = NetworkConnection(
            id: UUID(),
            config: config,
            provider: provider
        )
        
        connections[connection.id] = connection
        
        return connection
    }
    
    /// Remove a network connection
    /// - Parameter id: Connection ID
    func removeConnection(id: UUID) async {
        guard let connection = connections[id] else { return }
        
        await connection.provider.disconnect()
        connections.removeValue(forKey: id)
    }
    
    /// Get a connection by ID
    /// - Parameter id: Connection ID
    /// - Returns: The connection if found
    func getConnection(id: UUID) -> NetworkConnection? {
        return connections[id]
    }
    
    /// Get all active connections
    /// - Returns: Array of active connections
    func getActiveConnections() -> [NetworkConnection] {
        return connections.values.filter { $0.provider.isConnected }
    }
}

// MARK: - Network Connection

/// Represents an active network connection
struct NetworkConnection {
    let id: UUID
    let config: FileSystemConnectionConfig
    let provider: FileSystemProvider
    
    var displayName: String {
        return config.displayName
    }
    
    var rootURL: URL {
        return provider.rootURL
    }
    
    var isConnected: Bool {
        return provider.isConnected
    }
}