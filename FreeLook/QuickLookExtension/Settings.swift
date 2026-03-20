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
    struct ThemeSurface: Equatable {
        let background: String?
        let foreground: String?
    }

    private struct ThemeManifest: Decodable {
        struct Defaults: Decodable {
            let light: String
            let dark: String
        }

        struct Theme: Decodable {
            struct Surface: Decodable {
                let background: String?
                let foreground: String?
            }

            let id: String
            let displayName: String
            let appearance: String
            let surface: Surface?
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
    static let fallbackLightSurface = ThemeSurface(background: "#fcfbf7", foreground: "#17212c")
    static let fallbackDarkSurface = ThemeSurface(background: "#14181f", foreground: "#e7ebef")

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

    static func themeSurface(forDisplayName displayName: String) -> ThemeSurface? {
        let normalizedDisplayName: String

        if lightThemeOptions.contains(displayName) {
            normalizedDisplayName = normalizedLightTheme(displayName)
        } else if darkThemeOptions.contains(displayName) {
            normalizedDisplayName = normalizedDarkTheme(displayName)
        } else {
            normalizedDisplayName = displayName
        }

        guard let theme = themeManifest.themes.first(where: { $0.displayName == normalizedDisplayName }) else {
            return nil
        }

        return themeSurface(for: theme)
    }

    static func previewSurface(
        previewAppearanceMode: String,
        lightTheme: String,
        darkTheme: String,
        effectiveAppearance: NSAppearance
    ) -> ThemeSurface {
        if usesDarkPreviewSurface(previewAppearanceMode: previewAppearanceMode, effectiveAppearance: effectiveAppearance) {
            return themeSurface(forDisplayName: normalizedDarkTheme(darkTheme))
                ?? defaultThemeSurface(forAppearance: "dark")
        }

        return themeSurface(forDisplayName: normalizedLightTheme(lightTheme))
            ?? defaultThemeSurface(forAppearance: "light")
    }

    static func lightThemeSurface(forDisplayName displayName: String) -> ThemeSurface {
        themeSurface(forDisplayName: normalizedLightTheme(displayName))
            ?? defaultThemeSurface(forAppearance: "light")
    }

    static func darkThemeSurface(forDisplayName displayName: String) -> ThemeSurface {
        themeSurface(forDisplayName: normalizedDarkTheme(displayName))
            ?? defaultThemeSurface(forAppearance: "dark")
    }

    static func usesDarkPreviewSurface(
        previewAppearanceMode: String,
        effectiveAppearance: NSAppearance
    ) -> Bool {
        switch normalizedPreviewAppearanceMode(previewAppearanceMode) {
        case "Always Light":
            return false
        case "Always Dark":
            return true
        default:
            return effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
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
                .init(
                    id: "github-light",
                    displayName: "GitHub Light",
                    appearance: "light",
                    surface: .init(background: "#fff", foreground: "#24292e")
                ),
                .init(
                    id: "github-dark",
                    displayName: "GitHub Dark",
                    appearance: "dark",
                    surface: .init(background: "#24292e", foreground: "#e1e4e8")
                ),
            ]
        )
    }

    private static func themeSurface(for theme: ThemeManifest.Theme) -> ThemeSurface? {
        guard let surface = theme.surface else {
            return nil
        }

        return ThemeSurface(
            background: surface.background,
            foreground: surface.foreground
        )
    }

    private static func defaultThemeSurface(forAppearance appearance: String) -> ThemeSurface {
        let defaultThemeName = appearance == "dark" ? themeManifest.defaults.dark : themeManifest.defaults.light
        let fallbackSurface = appearance == "dark" ? fallbackDarkSurface : fallbackLightSurface

        guard let theme = themeManifest.themes.first(where: { $0.displayName == defaultThemeName }) else {
            return fallbackSurface
        }

        return themeSurface(for: theme) ?? fallbackSurface
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
