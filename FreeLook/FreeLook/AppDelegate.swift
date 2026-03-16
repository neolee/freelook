//
//  AppDelegate.swift
//  FreeLook
//
//  Created by Codex on 2026/3/17.
//

import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        SettingsStore.shared.quitAfterLastWindowClosed
    }
}
