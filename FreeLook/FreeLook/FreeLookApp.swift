//
//  FreeLookApp.swift
//  FreeLook
//
//  Created by Neo on 2026/3/16.
//

import SwiftUI

@main
struct FreeLookApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var settingsStore = SettingsStore.shared

    var body: some Scene {
        WindowGroup {
            ContentView(settingsStore: settingsStore)
        }
    }
}
