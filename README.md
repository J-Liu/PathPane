# PathPane

A native macOS file browser built with pure AppKit.

## Features

- **Three View Modes**: List, Icon, and Thumbnail views
- **Multi-tab Support**: Create and manage multiple tabs with Cmd+T/Cmd+W
- **Dual Pane Mode**: Split view for easy file management (Cmd+Shift+D)
- **Smart Navigation**: Back, Forward, Up, and path bar with auto-completion
- **Breadcrumb Navigation**: Click any path component to navigate
- **Context Menu**: Right-click for file operations
- **Drag & Drop**: Drag files between panes and to other applications
- **Hidden Files**: Toggle visibility with Cmd+Shift+.
- **File Operations**: Copy, Cut, Paste, Rename, Move to Trash
- **File System Monitoring**: Auto-refresh on directory changes

## Keyboard Shortcuts

### Navigation
- `Cmd+L` - Go to Folder (activate path bar)
- `Cmd+[` - Back
- `Cmd+]` - Forward
- `Cmd+Up` - Go to parent directory
- `Cmd+R` - Refresh

### View Modes
- `Cmd+1` - List View
- `Cmd+2` - Icon View
- `Cmd+3` - Thumbnail View

### Tabs
- `Cmd+T` - New Tab
- `Cmd+W` - Close Tab
- `Ctrl+Tab` - Next Tab
- `Ctrl+Shift+Tab` - Previous Tab

### Display
- `Cmd+Shift+.` - Show/Hide Hidden Files
- `Cmd+Shift+D` - Toggle Dual Pane Mode

### File Operations
- `Cmd+C` - Copy
- `Cmd+X` - Cut
- `Cmd+V` - Paste

## Building

```bash
swift build
swift run
```

## Requirements

- macOS 14.0 or later
- Xcode 15.0 or later
- Swift 6.0

## Technical Stack

- **Pure AppKit**: No SwiftUI dependencies
- **Swift Package Manager**: No Xcode project files
- **Swift 6 Concurrency**: Full @MainActor support
- **Modern APIs**: FSEventStream, QLThumbnailGenerator, UTType

## Architecture

- **Models**: FileItem, Tab, ViewMode, Settings
- **Views**: NSTableView, NSCollectionView-based view controllers
- **Services**: FileSystemService, FileSystemWatcher, ErrorHandler
- **State**: DirectoryState with navigation history
- **Controllers**: MainWindowController, ContentViewController

## Design Principles

- No `.DS_Store` creation - respects user's file system
- System icons only - uses `NSWorkspace.shared.icon(forFile:)`
- Persistent settings via UserDefaults
- Each tab maintains independent navigation history