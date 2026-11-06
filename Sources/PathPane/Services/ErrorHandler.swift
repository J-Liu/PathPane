import AppKit

// MARK: - Error Handler

@MainActor
class ErrorHandler {
    
    static let shared = ErrorHandler()
    
    private init() {}
    
    func showError(_ error: Error, title: String = "Error", in window: NSWindow? = nil) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        
        if let window = window {
            alert.beginSheetModal(for: window)
        } else {
            alert.runModal()
        }
    }

    func showError(title: String, message: String, in window: NSWindow? = nil) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")

        if let window = window {
            alert.beginSheetModal(for: window)
        } else {
            alert.runModal()
        }
    }
    
    func showPermissionError(for url: URL, in window: NSWindow? = nil) {
        let alert = NSAlert()
        alert.messageText = "Permission Denied"
        alert.informativeText = "Cannot access '\(url.lastPathComponent)'. You don't have permission to view this directory."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        
        if let window = window {
            alert.beginSheetModal(for: window)
        } else {
            alert.runModal()
        }
    }
    
    func showFileNotFoundError(for url: URL, in window: NSWindow? = nil) {
        let alert = NSAlert()
        alert.messageText = "File Not Found"
        alert.informativeText = "'\(url.lastPathComponent)' does not exist."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        
        if let window = window {
            alert.beginSheetModal(for: window)
        } else {
            alert.runModal()
        }
    }
}