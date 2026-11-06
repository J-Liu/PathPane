import Foundation

// MARK: - Selection Behavior

enum SelectionBehavior: String {
    case clickSelect = "clickSelect"
    case hoverSelect = "hoverSelect"
}

// MARK: - Settings Keys

enum SettingsKey {
    static let selectionBehavior = "selectionBehavior"
}

// MARK: - Settings Manager

@MainActor
class SettingsManager {
    
    // MARK: - Shared Instance
    
    static let shared = SettingsManager()
    
    // MARK: - Properties
    
    private let defaults = UserDefaults.standard
    
    // MARK: - Selection Behavior
    
    var selectionBehavior: SelectionBehavior {
        get {
            if let rawValue = defaults.string(forKey: SettingsKey.selectionBehavior),
               let behavior = SelectionBehavior(rawValue: rawValue) {
                return behavior
            }
            return .clickSelect
        }
        set {
            defaults.set(newValue.rawValue, forKey: SettingsKey.selectionBehavior)
        }
    }
}