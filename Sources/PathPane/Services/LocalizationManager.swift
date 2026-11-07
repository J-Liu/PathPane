// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright © 2026 Jia Liu

import Foundation

// MARK: - App Language

enum AppLanguage: String, CaseIterable {
    case system = "system"
    case english = "en"
    case simplifiedChinese = "zh-Hans"
    case traditionalChinese = "zh-Hant"

    var displayName: String {
        switch self {
        case .system:
            return "System"
        case .english:
            return "English"
        case .simplifiedChinese:
            return "简体中文"
        case .traditionalChinese:
            return "繁體中文"
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
            // Default to system
            return .system
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "settings.language")
        }
    }

    // The actual language used for localization (resolves system to actual language)
    var effectiveLanguage: AppLanguage {
        if currentLanguage == .system {
            // Detect system language
            let preferredLanguage = Locale.preferredLanguages.first ?? "en"
            if preferredLanguage.hasPrefix("zh-Hans") {
                return .simplifiedChinese
            } else if preferredLanguage.hasPrefix("zh-Hant") || preferredLanguage.hasPrefix("zh-TW") || preferredLanguage.hasPrefix("zh-HK") {
                return .traditionalChinese
            } else if preferredLanguage.hasPrefix("zh") {
                return .simplifiedChinese  // Default to Simplified for generic zh
            } else {
                return .english
            }
        }
        return currentLanguage
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
                .simplifiedChinese: "设置",
                .traditionalChinese: "設定"
            ],
            "settings.tab.general": [
                .english: "General",
                .simplifiedChinese: "通用",
                .traditionalChinese: "一般"
            ],
            "settings.tab.about": [
                .english: "About",
                .simplifiedChinese: "关于",
                .traditionalChinese: "關於"
            ],
            "settings.theme": [
                .english: "Theme",
                .simplifiedChinese: "主题",
                .traditionalChinese: "主題"
            ],
            "settings.theme.system": [
                .english: "System",
                .simplifiedChinese: "跟随系统",
                .traditionalChinese: "跟隨系統"
            ],
            "settings.theme.light": [
                .english: "Light",
                .simplifiedChinese: "浅色",
                .traditionalChinese: "淺色"
            ],
            "settings.theme.dark": [
                .english: "Dark",
                .simplifiedChinese: "深色",
                .traditionalChinese: "深色"
            ],
            "settings.language": [
                .english: "Language",
                .simplifiedChinese: "语言",
                .traditionalChinese: "語言"
            ],
            "settings.about.version": [
                .english: "Version",
                .simplifiedChinese: "版本",
                .traditionalChinese: "版本"
            ],
            "settings.about.copyright": [
                .english: "Copyright © 2026 Jia Liu",
                .simplifiedChinese: "版权所有 © 2026 Jia Liu",
                .traditionalChinese: "版權所有 © 2026 Jia Liu"
            ],
            "settings.about.license": [
                .english: "License",
                .simplifiedChinese: "许可证",
                .traditionalChinese: "許可證"
            ],
            "settings.about.notice": [
                .english: "Notice",
                .simplifiedChinese: "声明",
                .traditionalChinese: "聲明"
            ],
            "OK": [
                .english: "OK",
                .simplifiedChinese: "确定",
                .traditionalChinese: "確定"
            ],
            "error.trash.title": [
                .english: "Move to Trash Failed",
                .simplifiedChinese: "移至废纸篓失败",
                .traditionalChinese: "移至垃圾桶失敗"
            ],
            "info.kind": [
                .english: "Kind:",
                .simplifiedChinese: "类型：",
                .traditionalChinese: "類型："
            ],
            "info.size": [
                .english: "Size:",
                .simplifiedChinese: "大小：",
                .traditionalChinese: "大小："
            ],
            "info.created": [
                .english: "Created:",
                .simplifiedChinese: "创建时间：",
                .traditionalChinese: "建立時間："
            ],
            "info.modified": [
                .english: "Modified:",
                .simplifiedChinese: "修改时间：",
                .traditionalChinese: "修改時間："
            ],
            "info.location": [
                .english: "Location:",
                .simplifiedChinese: "位置：",
                .traditionalChinese: "位置："
            ],
            "info.kind.folder": [
                .english: "Folder",
                .simplifiedChinese: "文件夹",
                .traditionalChinese: "檔案夾"
            ],
            "info.kind.file": [
                .english: "Document",
                .simplifiedChinese: "文件",
                .traditionalChinese: "文件"
            ],
            "info.kind.unknown": [
                .english: "Unknown",
                .simplifiedChinese: "未知",
                .traditionalChinese: "未知"
            ],
            "info.kind.calculating": [
                .english: "Calculating...",
                .simplifiedChinese: "计算中...",
                .traditionalChinese: "計算中..."
            ]
        ]

        let language = effectiveLanguage
        return strings[key]?[language] ?? key
    }
}