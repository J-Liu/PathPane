import Foundation

// MARK: - App Language

enum AppLanguage: String, CaseIterable {
    case english = "en"
    case chinese = "zh"

    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .chinese:
            return "中文"
        }
    }
}

// MARK: - Localization Manager

@MainActor
class LocalizationManager {

    // MARK: - Singleton

    static let shared = LocalizationManager()

    // MARK: - Properties

    private(set) var currentLanguage: AppLanguage {
        get {
            if let rawValue = UserDefaults.standard.string(forKey: "settings.language"),
               let language = AppLanguage(rawValue: rawValue) {
                return language
            }
            // Default to system language
            let preferredLanguage = Locale.preferredLanguages.first ?? "en"
            return preferredLanguage.hasPrefix("zh") ? .chinese : .english
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "settings.language")
        }
    }

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    func setLanguage(_ language: AppLanguage) {
        currentLanguage = language

        // Post notification for language change
        NotificationCenter.default.post(name: .languageChanged, object: nil)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let languageChanged = Notification.Name("languageChanged")
}

// MARK: - Localization Helper

@MainActor
func L(_ key: String) -> String {
    return LocalizationManager.shared.localizedString(for: key)
}

extension LocalizationManager {
    func localizedString(for key: String) -> String {
        // Simple localization mapping
        let strings: [String: [AppLanguage: String]] = [
            "settings.title": [
                .english: "Settings",
                .chinese: "设置"
            ],
            "settings.tab.general": [
                .english: "General",
                .chinese: "通用"
            ],
            "settings.tab.about": [
                .english: "About",
                .chinese: "关于"
            ],
            "settings.theme": [
                .english: "Theme",
                .chinese: "主题"
            ],
            "settings.theme.system": [
                .english: "System",
                .chinese: "跟随系统"
            ],
            "settings.theme.light": [
                .english: "Light",
                .chinese: "浅色"
            ],
            "settings.theme.dark": [
                .english: "Dark",
                .chinese: "深色"
            ],
            "settings.language": [
                .english: "Language",
                .chinese: "语言"
            ],
            "settings.about.version": [
                .english: "Version",
                .chinese: "版本"
            ],
            "settings.about.copyright": [
                .english: "Copyright © 2026 Jia Liu",
                .chinese: "版权所有 © 2026 Jia Liu"
            ],
            "settings.about.license": [
                .english: "License",
                .chinese: "许可证"
            ],
            "settings.about.notice": [
                .english: "Notice",
                .chinese: "声明"
            ],
            "OK": [
                .english: "OK",
                .chinese: "确定"
            ]
        ]

        return strings[key]?[currentLanguage] ?? key
    }
}