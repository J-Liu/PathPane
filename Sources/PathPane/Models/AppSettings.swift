// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright © 2026 Jia Liu

import Foundation

// MARK: - Selection Behavior

enum SelectionBehavior: String {
    case clickSelect = "clickSelect"
    case hoverSelect = "hoverSelect"
}

// MARK: - Default New Tab Location

enum DefaultNewTabLocation: String, CaseIterable {
    case desktop = "desktop"
    case downloads = "downloads"
    case documents = "documents"
    case home = "home"
    case custom = "custom"

    var displayName: String {
        switch self {
        case .desktop:
            return "Desktop"
        case .downloads:
            return "Downloads"
        case .documents:
            return "Documents"
        case .home:
            return "Home"
        case .custom:
            return "Other..."
        }
    }

    func resolvedURL(customPath: String? = nil) -> URL {
        switch self {
        case .desktop:
            return FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        case .downloads:
            return FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        case .documents:
            return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        case .home:
            return FileManager.default.homeDirectoryForCurrentUser
        case .custom:
            if let path = customPath, !path.isEmpty {
                return URL(fileURLWithPath: path)
            }
            return FileManager.default.homeDirectoryForCurrentUser
        }
    }
}

// MARK: - Settings Keys

enum SettingsKey {
    static let selectionBehavior = "selectionBehavior"
    static let viewMode = "viewMode"
    static let showHiddenFiles = "showHiddenFiles"
    static let dualPaneMode = "dualPaneMode"
    static let windowSize = "windowSize"
    static let lastVisitedDirectory = "lastVisitedDirectory"
    static let defaultNewTabLocation = "defaultNewTabLocation"
    static let customNewTabPath = "customNewTabPath"
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
    
    // MARK: - View Mode

    var viewMode: ViewMode {
        get {
            if let rawValue = defaults.string(forKey: SettingsKey.viewMode),
               let mode = ViewMode(rawValue: rawValue) {
                return mode
            }
            return .list
        }
        set {
            defaults.set(newValue.rawValue, forKey: SettingsKey.viewMode)
        }
    }

    // MARK: - Show Hidden Files

    var showHiddenFiles: Bool {
        get {
            defaults.bool(forKey: SettingsKey.showHiddenFiles)
        }
        set {
            defaults.set(newValue, forKey: SettingsKey.showHiddenFiles)
        }
    }

    // MARK: - Dual Pane Mode

    var dualPaneMode: Bool {
        get {
            defaults.bool(forKey: SettingsKey.dualPaneMode)
        }
        set {
            defaults.set(newValue, forKey: SettingsKey.dualPaneMode)
        }
    }

    // MARK: - Window Size

    var windowSize: NSSize? {
        get {
            guard let sizeString = defaults.string(forKey: SettingsKey.windowSize),
                  let width = Double(sizeString.split(separator: ",").first ?? ""),
                  let height = Double(sizeString.split(separator: ",").last ?? "") else {
                return nil
            }
            return NSSize(width: width, height: height)
        }
        set {
            if let size = newValue {
                let sizeString = "\(size.width),\(size.height)"
                defaults.set(sizeString, forKey: SettingsKey.windowSize)
            }
        }
    }

    // MARK: - Last Visited Directory

    var lastVisitedDirectory: URL? {
        get {
            guard let path = defaults.string(forKey: SettingsKey.lastVisitedDirectory) else {
                return nil
            }
            return URL(fileURLWithPath: path)
        }
        set {
            defaults.set(newValue?.path, forKey: SettingsKey.lastVisitedDirectory)
        }
    }

    // MARK: - Default New Tab Location

    var defaultNewTabLocation: DefaultNewTabLocation {
        get {
            if let rawValue = defaults.string(forKey: SettingsKey.defaultNewTabLocation),
               let location = DefaultNewTabLocation(rawValue: rawValue) {
                return location
            }
            return .desktop
        }
        set {
            defaults.set(newValue.rawValue, forKey: SettingsKey.defaultNewTabLocation)
        }
    }

    var customNewTabPath: String? {
        get {
            defaults.string(forKey: SettingsKey.customNewTabPath)
        }
        set {
            defaults.set(newValue, forKey: SettingsKey.customNewTabPath)
        }
    }

    var newTabURL: URL {
        let location = defaultNewTabLocation
        return location.resolvedURL(customPath: customNewTabPath)
    }
}