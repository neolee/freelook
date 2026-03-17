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
        let lightTheme = SettingsStore.lightThemeOptions[1]
        let darkTheme = SettingsStore.darkThemeOptions[2]
        let codeFont = SettingsStore.codeFontOptions[1]
        let codeFontSize = 17

        let store = SettingsStore(userDefaults: defaults)
        store.lightTheme = lightTheme
        store.darkTheme = darkTheme
        store.codeFont = codeFont
        store.codeFontSize = codeFontSize
        store.quitAfterLastWindowClosed = true

        let reloadedStore = SettingsStore(userDefaults: defaults)

        #expect(reloadedStore.lightTheme == lightTheme)
        #expect(reloadedStore.darkTheme == darkTheme)
        #expect(reloadedStore.codeFont == codeFont)
        #expect(reloadedStore.codeFontSize == codeFontSize)
        #expect(reloadedStore.quitAfterLastWindowClosed == true)
    }

    @Test func normalizesInvalidPersistedValues() {
        let defaults = temporaryDefaults()
        defaults.set("Broken Light Theme", forKey: SettingsStore.lightThemeKey)
        defaults.set("Broken Dark Theme", forKey: SettingsStore.darkThemeKey)
        defaults.set("Broken Code Font", forKey: SettingsStore.codeFontKey)
        defaults.set(999, forKey: SettingsStore.codeFontSizeKey)

        let store = SettingsStore(userDefaults: defaults)

        #expect(store.lightTheme == SettingsStore.defaultLightTheme)
        #expect(store.darkTheme == SettingsStore.defaultDarkTheme)
        #expect(store.codeFont == SettingsStore.defaultCodeFont)
        #expect(store.codeFontSize == SettingsStore.defaultCodeFontSize)
        #expect(store.quitAfterLastWindowClosed == SettingsStore.defaultQuitAfterLastWindowClosed)
    }

    private func temporaryDefaults() -> UserDefaults {
        let suiteName = "net.paradigmx.FreeLook.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
