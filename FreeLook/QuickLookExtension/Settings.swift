//
//  Settings.swift
//  QuickLookExtension
//
//  Created by Codex on 2026/3/17.
//

import AppKit
import CoreText
import Foundation

enum Settings {
    private struct ThemeManifest: Decodable {
        struct Defaults: Decodable {
            let light: String
            let dark: String
        }

        struct Theme: Decodable {
            let id: String
            let displayName: String
            let appearance: String
        }

        let defaults: Defaults
        let themes: [Theme]
    }

    private static let themeManifest = loadThemeManifest()

    static let appGroupSuiteName = "group.net.paradigmx.FreeLook"
    static let previewAppearanceModeKey = "previewAppearanceMode"
    static let lightThemeKey = "lightTheme"
    static let darkThemeKey = "darkTheme"
    static let codeFontKey = "codeFont"
    static let codeFontSizeKey = "codeFontSize"

    static let previewAppearanceModeOptions = [
        "Follow System",
        "Always Light",
        "Always Dark",
    ]
    static let lightThemeOptions = themeManifest.themes
        .filter { $0.appearance == "light" }
        .map(\.displayName)
    static let darkThemeOptions = themeManifest.themes
        .filter { $0.appearance == "dark" }
        .map(\.displayName)
    static let defaultPreviewAppearanceMode = "Follow System"
    static let defaultLightTheme = themeManifest.defaults.light
    static let defaultDarkTheme = themeManifest.defaults.dark
    static let systemDefaultCodeFont = "System Default"
    static let codeFontOptions = [systemDefaultCodeFont] + availableMonospacedFonts()
    static let defaultCodeFont = systemDefaultCodeFont
    static let minimumCodeFontSize = 12
    static let maximumCodeFontSize = 20
    static let defaultCodeFontSize = 14

    static func userDefaults() -> UserDefaults {
        UserDefaults(suiteName: appGroupSuiteName) ?? .standard
    }

    static func normalizedPreviewAppearanceMode(_ value: String?) -> String {
        guard let value, previewAppearanceModeOptions.contains(value) else {
            return defaultPreviewAppearanceMode
        }

        return value
    }

    static func normalizedLightTheme(_ value: String?) -> String {
        guard let value, lightThemeOptions.contains(value) else {
            return defaultLightTheme
        }

        return value
    }

    static func normalizedDarkTheme(_ value: String?) -> String {
        guard let value, darkThemeOptions.contains(value) else {
            return defaultDarkTheme
        }

        return value
    }

    static func normalizedCodeFont(_ value: String?) -> String {
        guard let value, codeFontOptions.contains(value) else {
            return defaultCodeFont
        }

        return value
    }

    static func normalizedCodeFontSize(_ value: Any?) -> Int {
        let size: Int

        switch value {
        case let intValue as Int:
            size = intValue
        case let doubleValue as Double:
            size = Int(doubleValue.rounded())
        default:
            return defaultCodeFontSize
        }

        guard (minimumCodeFontSize...maximumCodeFontSize).contains(size) else {
            return defaultCodeFontSize
        }

        return size
    }

    static func codeFontStack(for value: String) -> String {
        switch normalizedCodeFont(value) {
        case systemDefaultCodeFont:
            return "monospace"
        default:
            return "\"\(escapedCSSFontFamily(value))\", monospace"
        }
    }

    private static func availableMonospacedFonts() -> [String] {
        let families = NSFontManager.shared.availableFontFamilies
        var results = Set<String>()

        for family in families {
            guard let members = NSFontManager.shared.availableMembers(ofFontFamily: family) else {
                continue
            }

            let isMonospaced = members.contains { member in
                guard let postScriptName = member.first as? String else {
                    return false
                }

                let font = CTFontCreateWithName(postScriptName as CFString, 12, nil)
                return CTFontGetSymbolicTraits(font).contains(.traitMonoSpace)
            }

            if isMonospaced {
                results.insert(family)
            }
        }

        return results.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private static func escapedCSSFontFamily(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }

    private static func loadThemeManifest() -> ThemeManifest {
        let decoder = JSONDecoder()

        for url in candidateThemeManifestURLs() {
            guard let data = try? Data(contentsOf: url),
                  let manifest = try? decoder.decode(ThemeManifest.self, from: data) else {
                continue
            }

            return manifest
        }

        assertionFailure("Themes.json could not be loaded from the app bundle or source checkout.")
        return ThemeManifest(
            defaults: .init(light: "GitHub Light", dark: "GitHub Dark"),
            themes: [
                .init(id: "github-light", displayName: "GitHub Light", appearance: "light"),
                .init(id: "github-dark", displayName: "GitHub Dark", appearance: "dark"),
            ]
        )
    }

    private static func candidateThemeManifestURLs() -> [URL] {
        var urls: [URL] = []

        if let bundledURL = Bundle.main.url(forResource: "Themes", withExtension: "json") {
            urls.append(bundledURL)
        }

        let sourceCheckoutURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Resources", isDirectory: true)
            .appendingPathComponent("Themes.json", isDirectory: false)
        urls.append(sourceCheckoutURL)

        return urls
    }
}
