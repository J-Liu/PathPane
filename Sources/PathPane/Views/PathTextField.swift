import AppKit

// MARK: - Path TextField

class PathTextField: NSTextField {
    
    // MARK: - Properties
    
    var onKeyDown: ((NSEvent) -> Bool)?
    
    // MARK: - Keyboard Handling
    
    override func keyDown(with event: NSEvent) {
        // Check if handler wants to process this key
        if onKeyDown?(event) == true {
            return
        }
        super.keyDown(with: event)
    }
}