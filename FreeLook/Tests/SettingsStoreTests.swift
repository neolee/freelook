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
    @Test func persistsThemeSelectionsAcrossInstances() {
        let defaults = temporaryDefaults()
        let previewAppearanceMode = SettingsStore.previewAppearanceModeOptions[2]
        let lightTheme = SettingsStore.lightThemeOptions[1]
        let darkTheme = SettingsStore.darkThemeOptions[2]
        let codeFont = SettingsStore.codeFontOptions.dropFirst().first ?? SettingsStore.defaultCodeFont
        let codeFontSize = 17

        let store = SettingsStore(userDefaults: defaults)
        store.previewAppearanceMode = previewAppearanceMode
        store.lightTheme = lightTheme
        store.darkTheme = darkTheme
        store.codeFont = codeFont
        store.codeFontSize = codeFontSize

        let reloadedStore = SettingsStore(userDefaults: defaults)

        #expect(reloadedStore.previewAppearanceMode == previewAppearanceMode)
        #expect(reloadedStore.lightTheme == lightTheme)
        #expect(reloadedStore.darkTheme == darkTheme)
        #expect(reloadedStore.codeFont == codeFont)
        #expect(reloadedStore.codeFontSize == codeFontSize)
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
        #expect(store.codeFont == SettingsStore.defaultCodeFont)
        #expect(store.codeFontSize == SettingsStore.defaultCodeFontSize)
    }

    private func temporaryDefaults() -> UserDefaults {
        let suiteName = "net.paradigmx.FreeLook.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
