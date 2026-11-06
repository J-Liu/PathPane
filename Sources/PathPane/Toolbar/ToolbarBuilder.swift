// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright © 2026 Jia Liu

import AppKit

// MARK: - Toolbar Item Identifiers

enum ToolbarItemIdentifier: String {
    case back = "back"
    case forward = "forward"
    case up = "up"
    case refresh = "refresh"
    case copy = "copy"
    case paste = "paste"
    case cut = "cut"
    
    var identifier: NSToolbarItem.Identifier {
        NSToolbarItem.Identifier(rawValue)
    }
}

// MARK: - Toolbar Builder

@MainActor
struct ToolbarBuilder {
    
    // MARK: - Build Toolbar
    
    static func buildToolbar(delegate: NSToolbarDelegate) -> NSToolbar {
        let toolbar = NSToolbar(identifier: "MainToolbar")
        toolbar.delegate = delegate
        toolbar.displayMode = .iconOnly
        toolbar.allowsUserCustomization = false
        
        return toolbar
    }
    
    // MARK: - Create Toolbar Item
    
    static func createToolbarItem(
        identifier: ToolbarItemIdentifier,
        label: String,
        symbol: String
    ) -> NSToolbarItem {
        let item = NSToolbarItem(itemIdentifier: identifier.identifier)
        item.label = label
        item.paletteLabel = label
        item.toolTip = label
        
        // Create button with SF Symbol
        if let image = NSImage(systemSymbolName: symbol, accessibilityDescription: label) {
            image.isTemplate = true
            item.image = image
        }
        
        return item
    }
    
    // MARK: - Create Space Items
    
    static func createSpaceItem() -> NSToolbarItem {
        NSToolbarItem(itemIdentifier: .space)
    }
    
    static func createFlexibleSpaceItem() -> NSToolbarItem {
        NSToolbarItem(itemIdentifier: .flexibleSpace)
    }
}