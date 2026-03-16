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
    static let quitAfterLastWindowClosedKey = "quitAfterLastWindowClosed"

    static let defaultLightTheme = "GitHub Light"
    static let defaultDarkTheme = "GitHub Dark"
    static let defaultQuitAfterLastWindowClosed = false

    static func userDefaults() -> UserDefaults {
        UserDefaults(suiteName: appGroupSuiteName) ?? .standard
    }
}
