import AppKit

// MARK: - Drop Target View

@MainActor
protocol DropTargetViewDelegate: AnyObject {
    func dropTargetView(_ view: DropTargetView, performDragOperation sender: NSDraggingInfo) -> Bool
    func dropTargetView(_ view: DropTargetView, draggingEntered sender: NSDraggingInfo) -> NSDragOperation
    func dropTargetView(_ view: DropTargetView, draggingUpdated sender: NSDraggingInfo) -> NSDragOperation
}

class DropTargetView: NSView {

    weak var delegate: DropTargetViewDelegate?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard let delegate = delegate else { return [] }
        return delegate.dropTargetView(self, draggingEntered: sender)
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard let delegate = delegate else { return [] }
        return delegate.dropTargetView(self, draggingUpdated: sender)
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let delegate = delegate else { return false }
        return delegate.dropTargetView(self, performDragOperation: sender)
    }

    override func concludeDragOperation(_ sender: NSDraggingInfo?) {
        // Clean up after drag operation
    }
}