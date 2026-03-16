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

        let store = SettingsStore(userDefaults: defaults)
        store.lightTheme = lightTheme
        store.darkTheme = darkTheme
        store.quitAfterLastWindowClosed = true

        let reloadedStore = SettingsStore(userDefaults: defaults)

        #expect(reloadedStore.lightTheme == lightTheme)
        #expect(reloadedStore.darkTheme == darkTheme)
        #expect(reloadedStore.quitAfterLastWindowClosed == true)
    }

    @Test func normalizesInvalidPersistedValues() {
        let defaults = temporaryDefaults()
        defaults.set("Broken Light Theme", forKey: SettingsStore.lightThemeKey)
        defaults.set("Broken Dark Theme", forKey: SettingsStore.darkThemeKey)

        let store = SettingsStore(userDefaults: defaults)

        #expect(store.lightTheme == SettingsStore.defaultLightTheme)
        #expect(store.darkTheme == SettingsStore.defaultDarkTheme)
        #expect(store.quitAfterLastWindowClosed == SettingsStore.defaultQuitAfterLastWindowClosed)
    }

    private func temporaryDefaults() -> UserDefaults {
        let suiteName = "net.paradigmx.FreeLook.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
