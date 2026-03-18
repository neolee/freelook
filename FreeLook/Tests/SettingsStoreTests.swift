//
//  SettingsStoreTests.swift
//  Tests
//
//  Created by Codex on 2026/3/17.
//

import Foundation
import Testing
@testable import FreeLook

struct SettingsStoreTests {
    @Test func exposesThemeOptionsFromManifest() {
        #expect(SettingsStore.lightThemeOptions.contains("Ayu Light"))
        #expect(SettingsStore.lightThemeOptions.contains("Everforest Light"))
        #expect(SettingsStore.darkThemeOptions.contains("Ayu Dark"))
        #expect(SettingsStore.darkThemeOptions.contains("Everforest Dark"))
        #expect(SettingsStore.defaultLightTheme == "GitHub Light")
        #expect(SettingsStore.defaultDarkTheme == "GitHub Dark")
    }

    @Test func persistsThemeSelectionsAcrossInstances() {
        let defaults = temporaryDefaults()
        let previewAppearanceMode = SettingsStore.previewAppearanceModeOptions[2]
        let lightTheme = SettingsStore.lightThemeOptions[1]
        let darkTheme = SettingsStore.darkThemeOptions[2]
        let selectedCodeFont = SettingsStore.codeFontOptions.dropFirst().first ?? SettingsStore.defaultCodeFont
        let selectedCodeFontSize = 17

        let store = SettingsStore(userDefaults: defaults)
        store.previewAppearanceMode = previewAppearanceMode
        store.lightTheme = lightTheme
        store.darkTheme = darkTheme
        store.selectedCodeFont = selectedCodeFont
        store.selectedCodeFontSize = selectedCodeFontSize

        let reloadedStore = SettingsStore(userDefaults: defaults)

        #expect(reloadedStore.previewAppearanceMode == previewAppearanceMode)
        #expect(reloadedStore.lightTheme == lightTheme)
        #expect(reloadedStore.darkTheme == darkTheme)
        #expect(reloadedStore.selectedCodeFont == selectedCodeFont)
        #expect(reloadedStore.selectedCodeFontSize == selectedCodeFontSize)
    }

    @Test func normalizesInvalidPersistedValues() {
        let defaults = temporaryDefaults()
        defaults.set("Broken Theme Mode", forKey: SettingsStore.previewAppearanceModeKey)
        defaults.set("Broken Light Theme", forKey: SettingsStore.lightThemeKey)
        defaults.set("Broken Dark Theme", forKey: SettingsStore.darkThemeKey)
        defaults.set("Broken Code Font", forKey: SettingsStore.codeFontKey)
        defaults.set(999, forKey: SettingsStore.codeFontSizeKey)

        let store = SettingsStore(userDefaults: defaults)

        #expect(store.previewAppearanceMode == SettingsStore.defaultPreviewAppearanceMode)
        #expect(store.lightTheme == SettingsStore.defaultLightTheme)
        #expect(store.darkTheme == SettingsStore.defaultDarkTheme)
        #expect(store.selectedCodeFont == SettingsStore.defaultCodeFont)
        #expect(store.selectedCodeFontSize == SettingsStore.defaultCodeFontSize)
    }

    @Test func resetToDefaultsPersistsNormalizedValues() {
        let defaults = temporaryDefaults()
        let store = SettingsStore(userDefaults: defaults)

        if let customFont = SettingsStore.codeFontOptions.dropFirst().first {
            store.selectedCodeFont = customFont
        }
        store.previewAppearanceMode = SettingsStore.previewAppearanceModeOptions[1]
        store.lightTheme = SettingsStore.lightThemeOptions[1]
        store.darkTheme = SettingsStore.darkThemeOptions[1]
        store.selectedCodeFontSize = SettingsStore.maximumCodeFontSize

        store.resetToDefaults()

        let reloadedStore = SettingsStore(userDefaults: defaults)
        #expect(reloadedStore.previewAppearanceMode == SettingsStore.defaultPreviewAppearanceMode)
        #expect(reloadedStore.lightTheme == SettingsStore.defaultLightTheme)
        #expect(reloadedStore.darkTheme == SettingsStore.defaultDarkTheme)
        #expect(reloadedStore.selectedCodeFont == SettingsStore.defaultCodeFont)
        #expect(reloadedStore.selectedCodeFontSize == SettingsStore.defaultCodeFontSize)
    }

    @Test func buildsExpectedCodeFontStacks() {
        #expect(Settings.codeFontStack(for: Settings.systemDefaultCodeFont) == "monospace")

        if let customFont = Settings.codeFontOptions.dropFirst().first {
            #expect(Settings.codeFontStack(for: customFont) == "\"\(customFont)\", monospace")
        }

        #expect(Settings.codeFontStack(for: "Not A Valid Font") == "monospace")
    }

    private func temporaryDefaults() -> UserDefaults {
        let suiteName = "net.paradigmx.FreeLook.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
