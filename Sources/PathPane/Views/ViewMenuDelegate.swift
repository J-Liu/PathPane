import AppKit

// MARK: - View Menu Delegate

@MainActor
class ViewMenuDelegate: NSObject, NSMenuDelegate {

    weak var mainWindowController: MainWindowController?

    init(mainWindowController: MainWindowController? = nil) {
        self.mainWindowController = mainWindowController
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        for item in menu.items {
            if item.action == #selector(MainWindowController.toggleHiddenFiles) {
                item.state = SettingsManager.shared.showHiddenFiles ? .on : .off
            }
            
            if item.action == #selector(MainWindowController.toggleDualPaneMode) {
                item.state = mainWindowController?.isDualPaneMode == true ? .on : .off
            }
        }
    }
}