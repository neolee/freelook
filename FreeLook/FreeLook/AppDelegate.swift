//
//  AppDelegate.swift
//  FreeLook
//
//  Created by Codex on 2026/3/17.
//

import AppKit
import Sparkle

final class AppDelegate: NSObject, NSApplicationDelegate {
    private lazy var updaterController: SPUStandardUpdaterController? = {
        guard Self.hasSparkleConfiguration else {
            return nil
        }

        return SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    }()

    var canCheckForUpdates: Bool {
        updaterController != nil
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func checkForUpdates() {
        updaterController?.checkForUpdates(nil)
    }

    private static var hasSparkleConfiguration: Bool {
        guard
            let feedURL = Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") as? String,
            let publicKey = Bundle.main.object(forInfoDictionaryKey: "SUPublicEDKey") as? String
        else {
            return false
        }

        return !feedURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !publicKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
