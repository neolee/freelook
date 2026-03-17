//
//  SharedPreviewSettings.swift
//  QuickLookExtension
//
//  Created by Codex on 2026/3/17.
//

import Foundation

enum SharedPreviewSettings {
    static let appGroupSuiteName = "group.net.paradigmx.FreeLook"
    static let lightThemeKey = "lightTheme"
    static let darkThemeKey = "darkTheme"
    static let codeFontKey = "codeFont"
    static let codeFontSizeKey = "codeFontSize"
    static let quitAfterLastWindowClosedKey = "quitAfterLastWindowClosed"

    static let defaultLightTheme = "GitHub Light"
    static let defaultDarkTheme = "GitHub Dark"
    static let codeFontOptions = [
        "SF Mono",
        "Menlo",
        "Monaco",
        "Courier",
    ]
    static let defaultCodeFont = "SF Mono"
    static let minimumCodeFontSize = 12
    static let maximumCodeFontSize = 20
    static let defaultCodeFontSize = 14
    static let defaultQuitAfterLastWindowClosed = false

    static func userDefaults() -> UserDefaults {
        UserDefaults(suiteName: appGroupSuiteName) ?? .standard
    }

    static func normalizedCodeFont(_ value: String?) -> String {
        guard let value, codeFontOptions.contains(value) else {
            return defaultCodeFont
        }

        return value
    }

    static func normalizedCodeFontSize(_ value: Any?) -> Int {
        let size: Int

        switch value {
        case let intValue as Int:
            size = intValue
        case let doubleValue as Double:
            size = Int(doubleValue.rounded())
        default:
            return defaultCodeFontSize
        }

        guard (minimumCodeFontSize...maximumCodeFontSize).contains(size) else {
            return defaultCodeFontSize
        }

        return size
    }

    static func codeFontStack(for value: String) -> String {
        switch normalizedCodeFont(value) {
        case "Menlo":
            return "'Menlo', monospace"
        case "Monaco":
            return "'Monaco', monospace"
        case "Courier":
            return "'Courier', monospace"
        default:
            return "'SF Mono', SFMono-Regular, monospace"
        }
    }
}
