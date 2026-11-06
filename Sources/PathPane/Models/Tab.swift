// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright © 2026 Jia Liu

import Foundation

// MARK: - Tab Model

@MainActor
class Tab {

    // MARK: - Properties

    let id: UUID
    let directoryState: DirectoryState

    // MARK: - Initialization

    init(initialURL: URL = FileManager.default.homeDirectoryForCurrentUser, provider: FileSystemProvider? = nil) {
        self.id = UUID()
        self.directoryState = DirectoryState(initialURL: initialURL, provider: provider)
    }
}