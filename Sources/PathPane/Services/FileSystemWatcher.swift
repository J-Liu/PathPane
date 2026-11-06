// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright © 2026 Jia Liu

import Foundation

// MARK: - File System Watcher

@MainActor
class FileSystemWatcher {
    
    // MARK: - Types
    
    typealias EventHandler = @Sendable () -> Void
    
    // MARK: - Properties
    
    private(set) var isWatching: Bool = false
    
    // MARK: - Private Properties
    
    private nonisolated(unsafe) var eventStream: FSEventStreamRef?
    private var eventHandler: EventHandler?
    private var debounceWorkItem: DispatchWorkItem?
    private let debounceInterval: TimeInterval
    private let eventQueue = DispatchQueue(label: "com.pathpane.fsevents", qos: .utility)
    
    // MARK: - Initialization
    
    init(debounceInterval: TimeInterval = 0.3) {
        self.debounceInterval = debounceInterval
    }
    
    deinit {
        // Clean up stream in non-isolated context
        if let stream = eventStream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
        }
    }
    
    // MARK: - Public Methods
    
    /// Start watching a directory for changes
    /// - Parameters:
    ///   - url: Directory URL to watch
    ///   - handler: Handler called when changes detected
    func startWatching(url: URL, handler: @escaping EventHandler) {
        stop()
        
        self.eventHandler = handler
        
        // Create FSEventStream
        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )
        
        let flags: FSEventStreamEventFlags = FSEventStreamCreateFlags(
            kFSEventStreamEventFlagNone |
            kFSEventStreamEventFlagItemRenamed |
            kFSEventStreamEventFlagItemCreated |
            kFSEventStreamEventFlagItemRemoved |
            kFSEventStreamEventFlagItemModified
        )
        
        guard let stream = FSEventStreamCreate(
            kCFAllocatorDefault,
            { (_, streamCallBackInfo, _, _, eventFlags, _) in
                guard let info = streamCallBackInfo else { return }
                let watcher = Unmanaged<FileSystemWatcher>.fromOpaque(info).takeUnretainedValue()
                Task { @MainActor in
                    watcher.handleEvent()
                }
            },
            &context,
            [url.path] as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            debounceInterval,
            flags
        ) else {
            print("Failed to create FSEventStream")
            return
        }
        
        eventStream = stream
        
        // Use modern dispatch queue API
        FSEventStreamSetDispatchQueue(stream, eventQueue)
        
        // Start stream
        if FSEventStreamStart(stream) {
            isWatching = true
        }
    }
    
    /// Stop watching
    func stop() {
        guard let stream = eventStream else { return }
        
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
        
        eventStream = nil
        eventHandler = nil
        isWatching = false
        
        debounceWorkItem?.cancel()
        debounceWorkItem = nil
    }
    
    // MARK: - Private Methods
    
    private func handleEvent() {
        // Debounce: cancel existing work item and create new one
        debounceWorkItem?.cancel()
        
        let workItem = DispatchWorkItem { [weak self] in
            self?.eventHandler?()
        }
        
        debounceWorkItem = workItem
        
        DispatchQueue.main.asyncAfter(
            deadline: .now() + debounceInterval,
            execute: workItem
        )
    }
}