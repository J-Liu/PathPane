import AppKit

// MARK: - View Menu Delegate

@MainActor
class ViewMenuDelegate: NSObject, NSMenuDelegate {

    func menuNeedsUpdate(_ menu: NSMenu) {
        for item in menu.items {
            if item.action == #selector(MainWindowController.toggleHiddenFiles) {
                item.state = SettingsManager.shared.showHiddenFiles ? .on : .off
            }
        }
    }
}