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
    static let appGroupSuiteName = Settings.appGroupSuiteName
    static let previewAppearanceModeKey = Settings.previewAppearanceModeKey
    static let lightThemeKey = Settings.lightThemeKey
    static let darkThemeKey = Settings.darkThemeKey
    static let codeFontKey = Settings.codeFontKey
    static let codeFontSizeKey = Settings.codeFontSizeKey

    static let previewAppearanceModeOptions = Settings.previewAppearanceModeOptions
    static let lightThemeOptions = Settings.lightThemeOptions
    static let darkThemeOptions = Settings.darkThemeOptions
    static let defaultPreviewAppearanceMode = Settings.defaultPreviewAppearanceMode
    static let codeFontOptions = Settings.codeFontOptions
    static let defaultLightTheme = Settings.defaultLightTheme
    static let defaultDarkTheme = Settings.defaultDarkTheme
    static let defaultCodeFont = Settings.defaultCodeFont
    static let minimumCodeFontSize = Settings.minimumCodeFontSize
    static let maximumCodeFontSize = Settings.maximumCodeFontSize
    static let defaultCodeFontSize = Settings.defaultCodeFontSize

    @Published var lightTheme: String {
        didSet {
            persistLightTheme()
        }
    }

    @Published var previewAppearanceMode: String {
        didSet {
            persistPreviewAppearanceMode()
        }
    }

    @Published var darkTheme: String {
        didSet {
            persistDarkTheme()
        }
    }

    @Published var selectedCodeFont: String {
        didSet {
            persistCodeFont()
        }
    }

    @Published var selectedCodeFontSize: Int {
        didSet {
            persistCodeFontSize()
        }
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = SettingsStore.defaultUserDefaults()) {
        self.userDefaults = userDefaults
        self.previewAppearanceMode = Settings.normalizedPreviewAppearanceMode(
            userDefaults.string(forKey: Self.previewAppearanceModeKey)
        )
        self.lightTheme = Settings.normalizedLightTheme(
            userDefaults.string(forKey: Self.lightThemeKey)
        )
        self.darkTheme = Settings.normalizedDarkTheme(
            userDefaults.string(forKey: Self.darkThemeKey)
        )
        self.selectedCodeFont = Settings.normalizedCodeFont(
            userDefaults.string(forKey: Self.codeFontKey)
        )
        self.selectedCodeFontSize = Settings.normalizedCodeFontSize(
            userDefaults.object(forKey: Self.codeFontSizeKey)
        )

        persistCurrentValues()
    }

    func resetToDefaults() {
        previewAppearanceMode = Self.defaultPreviewAppearanceMode
        lightTheme = Self.defaultLightTheme
        darkTheme = Self.defaultDarkTheme
        selectedCodeFont = Self.defaultCodeFont
        selectedCodeFontSize = Self.defaultCodeFontSize
    }

    private func persistCurrentValues() {
        userDefaults.set(previewAppearanceMode, forKey: Self.previewAppearanceModeKey)
        userDefaults.set(lightTheme, forKey: Self.lightThemeKey)
        userDefaults.set(darkTheme, forKey: Self.darkThemeKey)
        userDefaults.set(selectedCodeFont, forKey: Self.codeFontKey)
        userDefaults.set(selectedCodeFontSize, forKey: Self.codeFontSizeKey)
    }

    private func persistPreviewAppearanceMode() {
        let normalized = Settings.normalizedPreviewAppearanceMode(previewAppearanceMode)

        if normalized != previewAppearanceMode {
            previewAppearanceMode = normalized
            return
        }

        userDefaults.set(normalized, forKey: Self.previewAppearanceModeKey)
    }

    private func persistLightTheme() {
        let normalized = Settings.normalizedLightTheme(lightTheme)

        if normalized != lightTheme {
            lightTheme = normalized
            return
        }

        userDefaults.set(normalized, forKey: Self.lightThemeKey)
    }

    private func persistDarkTheme() {
        let normalized = Settings.normalizedDarkTheme(darkTheme)

        if normalized != darkTheme {
            darkTheme = normalized
            return
        }

        userDefaults.set(normalized, forKey: Self.darkThemeKey)
    }

    private func persistCodeFont() {
        let normalized = Settings.normalizedCodeFont(selectedCodeFont)

        if normalized != selectedCodeFont {
            selectedCodeFont = normalized
            return
        }

        userDefaults.set(normalized, forKey: Self.codeFontKey)
    }

    private func persistCodeFontSize() {
        let normalized = Settings.normalizedCodeFontSize(selectedCodeFontSize)

        if normalized != selectedCodeFontSize {
            selectedCodeFontSize = normalized
            return
        }

        userDefaults.set(normalized, forKey: Self.codeFontSizeKey)
    }

    private static func defaultUserDefaults() -> UserDefaults {
        Settings.userDefaults()
    }
}
