import AppKit

// MARK: - Menu Builder

struct MenuBuilder {
    
    // MARK: - Build Main Menu
    
    static func buildMainMenu() -> NSMenu {
        let mainMenu = NSMenu()
        
        // App menu
        mainMenu.addItem(buildAppMenu())
        
        // File menu
        mainMenu.addItem(buildFileMenu())
        
        // Edit menu
        mainMenu.addItem(buildEditMenu())
        
        // View menu
        mainMenu.addItem(buildViewMenu())
        
        // Window menu
        mainMenu.addItem(buildWindowMenu())
        
        // Help menu
        mainMenu.addItem(buildHelpMenu())
        
        return mainMenu
    }
    
    // MARK: - App Menu
    
    private static func buildAppMenu() -> NSMenuItem {
        let appMenu = NSMenu()
        
        appMenu.addItem(
            NSMenuItem(
                title: "About PathPane",
                action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
                keyEquivalent: ""
            )
        )
        
        appMenu.addItem(NSMenuItem.separator())
        
        appMenu.addItem(
            NSMenuItem(
                title: "Hide PathPane",
                action: #selector(NSApplication.hide(_:)),
                keyEquivalent: "h"
            )
        )
        
        let hideOthersItem = NSMenuItem(
            title: "Hide Others",
            action: #selector(NSApplication.hideOtherApplications(_:)),
            keyEquivalent: "h"
        )
        hideOthersItem.keyEquivalentModifierMask = [.option, .command]
        appMenu.addItem(hideOthersItem)
        
        appMenu.addItem(
            NSMenuItem(
                title: "Show All",
                action: #selector(NSApplication.unhideAllApplications(_:)),
                keyEquivalent: ""
            )
        )
        
        appMenu.addItem(NSMenuItem.separator())
        
        appMenu.addItem(
            NSMenuItem(
                title: "Quit PathPane",
                action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: "q"
            )
        )
        
        let menuItem = NSMenuItem(title: "PathPane", action: nil, keyEquivalent: "")
        menuItem.submenu = appMenu
        return menuItem
    }
    
    // MARK: - File Menu
    
    private static func buildFileMenu() -> NSMenuItem {
        let fileMenu = NSMenu(title: "File")
        
        fileMenu.addItem(
            NSMenuItem(
                title: "New Window",
                action: nil,
                keyEquivalent: "n"
            )
        )
        
        fileMenu.addItem(
            NSMenuItem(
                title: "New Tab",
                action: nil,
                keyEquivalent: "t"
            )
        )
        
        fileMenu.addItem(NSMenuItem.separator())
        
        fileMenu.addItem(
            NSMenuItem(
                title: "Close Window",
                action: #selector(NSWindow.performClose(_:)),
                keyEquivalent: "w"
            )
        )
        
        let menuItem = NSMenuItem(title: "File", action: nil, keyEquivalent: "")
        menuItem.submenu = fileMenu
        return menuItem
    }
    
    // MARK: - Edit Menu
    
    private static func buildEditMenu() -> NSMenuItem {
        let editMenu = NSMenu(title: "Edit")
        
        // Undo
        editMenu.addItem(
            NSMenuItem(
                title: "Undo",
                action: Selector(("undo:")),
                keyEquivalent: "z"
            )
        )
        
        // Redo
        let redoItem = NSMenuItem(
            title: "Redo",
            action: Selector(("redo:")),
            keyEquivalent: "z"
        )
        redoItem.keyEquivalentModifierMask = [.shift, .command]
        editMenu.addItem(redoItem)
        
        editMenu.addItem(NSMenuItem.separator())
        
        // Cut
        editMenu.addItem(
            NSMenuItem(
                title: "Cut",
                action: #selector(NSText.cut(_:)),
                keyEquivalent: "x"
            )
        )
        
        // Copy
        editMenu.addItem(
            NSMenuItem(
                title: "Copy",
                action: #selector(NSText.copy(_:)),
                keyEquivalent: "c"
            )
        )
        
        // Paste
        editMenu.addItem(
            NSMenuItem(
                title: "Paste",
                action: #selector(NSText.paste(_:)),
                keyEquivalent: "v"
            )
        )
        
        // Select All
        editMenu.addItem(
            NSMenuItem(
                title: "Select All",
                action: #selector(NSResponder.selectAll(_:)),
                keyEquivalent: "a"
            )
        )
        
        let menuItem = NSMenuItem(title: "Edit", action: nil, keyEquivalent: "")
        menuItem.submenu = editMenu
        return menuItem
    }
    
    // MARK: - View Menu
    
    private static func buildViewMenu() -> NSMenuItem {
        let viewMenu = NSMenu(title: "View")

        let showHiddenItem = NSMenuItem(
            title: "Show Hidden Files",
            action: #selector(MainWindowController.toggleHiddenFiles),
            keyEquivalent: "."
        )
        showHiddenItem.keyEquivalentModifierMask = [.shift, .command]
        viewMenu.addItem(showHiddenItem)

        viewMenu.addItem(NSMenuItem.separator())

        viewMenu.addItem(
            NSMenuItem(
                title: "Go to Folder...",
                action: #selector(MainWindowController.goToFolder),
                keyEquivalent: "l"
            )
        )

        viewMenu.addItem(NSMenuItem.separator())

        viewMenu.addItem(
            NSMenuItem(
                title: "as List",
                action: #selector(MainWindowController.switchToListView),
                keyEquivalent: "1"
            )
        )

        viewMenu.addItem(
            NSMenuItem(
                title: "as Icons",
                action: #selector(MainWindowController.switchToIconView),
                keyEquivalent: "2"
            )
        )

        viewMenu.addItem(
            NSMenuItem(
                title: "as Thumbnails",
                action: #selector(MainWindowController.switchToThumbnailView),
                keyEquivalent: "3"
            )
        )

        let menuItem = NSMenuItem(title: "View", action: nil, keyEquivalent: "")
        menuItem.submenu = viewMenu
        return menuItem
    }
    
    // MARK: - Window Menu
    
    private static func buildWindowMenu() -> NSMenuItem {
        let windowMenu = NSMenu(title: "Window")
        
        windowMenu.addItem(
            NSMenuItem(
                title: "Minimize",
                action: #selector(NSWindow.performMiniaturize(_:)),
                keyEquivalent: "m"
            )
        )
        
        windowMenu.addItem(
            NSMenuItem(
                title: "Zoom",
                action: #selector(NSWindow.performZoom(_:)),
                keyEquivalent: ""
            )
        )
        
        let menuItem = NSMenuItem(title: "Window", action: nil, keyEquivalent: "")
        menuItem.submenu = windowMenu
        return menuItem
    }
    
    // MARK: - Help Menu
    
    private static func buildHelpMenu() -> NSMenuItem {
        let helpMenu = NSMenu(title: "Help")
        
        helpMenu.addItem(
            NSMenuItem(
                title: "PathPane Help",
                action: nil,
                keyEquivalent: ""
            )
        )
        
        let menuItem = NSMenuItem(title: "Help", action: nil, keyEquivalent: "")
        menuItem.submenu = helpMenu
        return menuItem
    }
}