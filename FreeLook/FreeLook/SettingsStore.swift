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
    static let appGroupSuiteName = SharedPreviewSettings.appGroupSuiteName
    static let previewAppearanceModeKey = SharedPreviewSettings.previewAppearanceModeKey
    static let lightThemeKey = SharedPreviewSettings.lightThemeKey
    static let darkThemeKey = SharedPreviewSettings.darkThemeKey
    static let codeFontKey = SharedPreviewSettings.codeFontKey
    static let codeFontSizeKey = SharedPreviewSettings.codeFontSizeKey

    static let previewAppearanceModeOptions = SharedPreviewSettings.previewAppearanceModeOptions
    static let lightThemeOptions = SharedPreviewSettings.lightThemeOptions
    static let darkThemeOptions = SharedPreviewSettings.darkThemeOptions
    static let defaultPreviewAppearanceMode = SharedPreviewSettings.defaultPreviewAppearanceMode
    static let codeFontOptions = SharedPreviewSettings.codeFontOptions
    static let defaultLightTheme = SharedPreviewSettings.defaultLightTheme
    static let defaultDarkTheme = SharedPreviewSettings.defaultDarkTheme
    static let defaultCodeFont = SharedPreviewSettings.defaultCodeFont
    static let minimumCodeFontSize = SharedPreviewSettings.minimumCodeFontSize
    static let maximumCodeFontSize = SharedPreviewSettings.maximumCodeFontSize
    static let defaultCodeFontSize = SharedPreviewSettings.defaultCodeFontSize

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

    @Published var codeFont: String {
        didSet {
            persistCodeFont()
        }
    }

    @Published var codeFontSize: Int {
        didSet {
            persistCodeFontSize()
        }
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = SettingsStore.defaultUserDefaults()) {
        self.userDefaults = userDefaults
        self.previewAppearanceMode = SharedPreviewSettings.normalizedPreviewAppearanceMode(
            userDefaults.string(forKey: Self.previewAppearanceModeKey)
        )
        self.lightTheme = SharedPreviewSettings.normalizedLightTheme(
            userDefaults.string(forKey: Self.lightThemeKey)
        )
        self.darkTheme = SharedPreviewSettings.normalizedDarkTheme(
            userDefaults.string(forKey: Self.darkThemeKey)
        )
        self.codeFont = SharedPreviewSettings.normalizedCodeFont(
            userDefaults.string(forKey: Self.codeFontKey)
        )
        self.codeFontSize = SharedPreviewSettings.normalizedCodeFontSize(
            userDefaults.object(forKey: Self.codeFontSizeKey)
        )

        persistCurrentValues()
    }

    func resetToDefaults() {
        previewAppearanceMode = Self.defaultPreviewAppearanceMode
        lightTheme = Self.defaultLightTheme
        darkTheme = Self.defaultDarkTheme
        codeFont = Self.defaultCodeFont
        codeFontSize = Self.defaultCodeFontSize
    }

    private func persistCurrentValues() {
        userDefaults.set(previewAppearanceMode, forKey: Self.previewAppearanceModeKey)
        userDefaults.set(lightTheme, forKey: Self.lightThemeKey)
        userDefaults.set(darkTheme, forKey: Self.darkThemeKey)
        userDefaults.set(codeFont, forKey: Self.codeFontKey)
        userDefaults.set(codeFontSize, forKey: Self.codeFontSizeKey)
    }

    private func persistPreviewAppearanceMode() {
        let normalized = SharedPreviewSettings.normalizedPreviewAppearanceMode(previewAppearanceMode)

        if normalized != previewAppearanceMode {
            previewAppearanceMode = normalized
            return
        }

        userDefaults.set(normalized, forKey: Self.previewAppearanceModeKey)
    }

    private func persistLightTheme() {
        let normalized = SharedPreviewSettings.normalizedLightTheme(lightTheme)

        if normalized != lightTheme {
            lightTheme = normalized
            return
        }

        userDefaults.set(normalized, forKey: Self.lightThemeKey)
    }

    private func persistDarkTheme() {
        let normalized = SharedPreviewSettings.normalizedDarkTheme(darkTheme)

        if normalized != darkTheme {
            darkTheme = normalized
            return
        }

        userDefaults.set(normalized, forKey: Self.darkThemeKey)
    }

    private func persistCodeFont() {
        let normalized = SharedPreviewSettings.normalizedCodeFont(codeFont)

        if normalized != codeFont {
            codeFont = normalized
            return
        }

        userDefaults.set(normalized, forKey: Self.codeFontKey)
    }

    private func persistCodeFontSize() {
        let normalized = SharedPreviewSettings.normalizedCodeFontSize(codeFontSize)

        if normalized != codeFontSize {
            codeFontSize = normalized
            return
        }

        userDefaults.set(normalized, forKey: Self.codeFontSizeKey)
    }

    private static func defaultUserDefaults() -> UserDefaults {
        SharedPreviewSettings.userDefaults()
    }
}
