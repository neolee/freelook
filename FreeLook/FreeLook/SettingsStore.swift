//
//  SettingsStore.swift
//  FreeLook
//
//  Created by Codex on 2026/3/17.
//

import Combine
import Foundation

final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()
    static let appGroupSuiteName = "group.net.paradigmx.FreeLook"
    static let lightThemeKey = "lightTheme"
    static let darkThemeKey = "darkTheme"
    static let quitAfterLastWindowClosedKey = "quitAfterLastWindowClosed"

    static let lightThemeOptions = [
        "GitHub Light",
        "One Light",
        "Catppuccin Latte",
        "Nord Light",
    ]

    static let darkThemeOptions = [
        "GitHub Dark",
        "One Dark Pro",
        "Catppuccin Mocha",
        "Nord",
    ]

    static let defaultLightTheme = lightThemeOptions[0]
    static let defaultDarkTheme = darkThemeOptions[0]
    static let defaultQuitAfterLastWindowClosed = false

    @Published var lightTheme: String {
        didSet {
            persistLightTheme()
        }
    }

    @Published var darkTheme: String {
        didSet {
            persistDarkTheme()
        }
    }

    @Published var quitAfterLastWindowClosed: Bool {
        didSet {
            userDefaults.set(quitAfterLastWindowClosed, forKey: Self.quitAfterLastWindowClosedKey)
        }
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = SettingsStore.defaultUserDefaults()) {
        self.userDefaults = userDefaults
        self.lightTheme = Self.normalizedTheme(
            userDefaults.string(forKey: Self.lightThemeKey),
            allowedThemes: Self.lightThemeOptions,
            fallbackTheme: Self.defaultLightTheme
        )
        self.darkTheme = Self.normalizedTheme(
            userDefaults.string(forKey: Self.darkThemeKey),
            allowedThemes: Self.darkThemeOptions,
            fallbackTheme: Self.defaultDarkTheme
        )
        self.quitAfterLastWindowClosed = userDefaults.object(forKey: Self.quitAfterLastWindowClosedKey) as? Bool
            ?? Self.defaultQuitAfterLastWindowClosed

        persistCurrentValues()
    }

    func resetToDefaults() {
        lightTheme = Self.defaultLightTheme
        darkTheme = Self.defaultDarkTheme
        quitAfterLastWindowClosed = Self.defaultQuitAfterLastWindowClosed
    }

    private func persistCurrentValues() {
        userDefaults.set(lightTheme, forKey: Self.lightThemeKey)
        userDefaults.set(darkTheme, forKey: Self.darkThemeKey)
        userDefaults.set(quitAfterLastWindowClosed, forKey: Self.quitAfterLastWindowClosedKey)
    }

    private func persistLightTheme() {
        let normalized = Self.normalizedTheme(
            lightTheme,
            allowedThemes: Self.lightThemeOptions,
            fallbackTheme: Self.defaultLightTheme
        )

        if normalized != lightTheme {
            lightTheme = normalized
            return
        }

        userDefaults.set(normalized, forKey: Self.lightThemeKey)
    }

    private func persistDarkTheme() {
        let normalized = Self.normalizedTheme(
            darkTheme,
            allowedThemes: Self.darkThemeOptions,
            fallbackTheme: Self.defaultDarkTheme
        )

        if normalized != darkTheme {
            darkTheme = normalized
            return
        }

        userDefaults.set(normalized, forKey: Self.darkThemeKey)
    }

    private static func normalizedTheme(
        _ value: String?,
        allowedThemes: [String],
        fallbackTheme: String
    ) -> String {
        guard let value, allowedThemes.contains(value) else {
            return fallbackTheme
        }

        return value
    }

    private static func defaultUserDefaults() -> UserDefaults {
        UserDefaults(suiteName: appGroupSuiteName) ?? .standard
    }
}
