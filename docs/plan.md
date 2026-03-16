# FreeLook — Design & Implementation Plan

## Overview

FreeLook is a macOS Quick Look Preview Extension that provides syntax-highlighted
previews for developer file types: Markdown, JSON, XML, and source code in common
programming languages. It is distributed via GitHub Releases (signed + notarized DMG)
with Sparkle-based auto-update, not through the App Store.

---

## Architecture

### Xcode Project

Two targets inside `FreeLook/FreeLook.xcodeproj`:

- `FreeLook` — host macOS app; provides the required container for the extension,
  a settings UI for theme selection, and the Sparkle update framework.
- `QuickLookExtension` — Quick Look Preview Extension; renders file content inside a
  `WKWebView`.

Both targets share an App Group (`group.net.paradigmx.FreeLook`) for `UserDefaults`
preference exchange.

### JS Rendering Pipeline

A standalone npm sub-project lives in `WebRenderer/` and is built separately with
esbuild. Its output, `bundle.js`, is committed/copied into
`QuickLookExtension/Resources/` and loaded by the extension's `WKWebView`.

The renderer exposes a single entry point:

```js
FreeLook.render({ content, lang, lightTheme, darkTheme })
```

File-type routing inside the renderer:

| `lang` value | Pipeline |
|---|---|
| `"markdown"` | markdown-it + @shikijs/markdown-it (code blocks highlighted inline) |
| `"json"` | `JSON.parse` → `JSON.stringify(_, null, 2)` → Shiki `json` |
| `"xml"` | xml-formatter → Shiki `xml` |
| anything else | Shiki with the provided lang string |

### Swift ↔ WKWebView Contract

1. `PreviewViewController` reads the file (`FileHandle`, UTF-8 then Latin-1 fallback,
   500 KB cap — larger files show a truncation notice).
2. `UTIMapper.swift` converts the file's `UTType` to a Shiki language identifier string.
3. `SettingsStore` reads `lightTheme` and `darkTheme` from the shared App Group
   `UserDefaults`.
4. A string-interpolated `template.html` is passed to `loadHTMLString(_:baseURL:)`;
   `baseURL` points to the extension's `Resources/` bundle directory so that relative
   paths to `bundle.js` and `styles.css` resolve correctly.

---

## Theme System

Users independently choose one light theme and one dark theme in the host app settings.
The selected theme names are stored in App Group `UserDefaults` under the keys
`lightTheme` and `darkTheme`.

Shiki's dual-theme CSS variable mechanism handles automatic `prefers-color-scheme`
switching at render time — no JavaScript theme-switching is performed after initial
render.

### Bundled Themes

Light: GitHub Light, One Light, Catppuccin Latte, Nord Light, Solarized Light
Dark: GitHub Dark, One Dark Pro, Catppuccin Mocha, Nord, Dracula

---

## UTI Coverage

The extension's `Info.plist` declares `QLSupportedContentTypes`:

- `public.source-code` — parent UTI; covers the majority of language subtypes
- Priority explicit declarations: `public.swift-source`, `public.python-script`,
  `com.netscape.javascript-source`, `public.typescript-source`, `public.css`,
  `public.html`, `public.shell-script`, `public.ruby-script`
- `net.daringfireball.markdown`
- `public.json`
- `public.xml`

---

## Auto-Update (Sparkle)

FreeLook uses the [Sparkle](https://sparkle-project.org) framework for automatic
updates. The CI release workflow runs `generate_appcast` to update `appcast.xml`
in the repository root after each release. The host app checks the appcast URL on
launch and notifies the user when an update is available.

Required setup:

1. Generate an EdDSA key pair with Sparkle's `generate_keys` tool; store the private
   key as the `SPARKLE_PRIVATE_KEY` GitHub Secret (base64-encoded).
2. Add the corresponding public key to `Info.plist` as `SUPublicEDKey`.
3. Set `SUFeedURL` in `Info.plist` to:
   `https://raw.githubusercontent.com/neolee/freelook/main/appcast.xml`

---

## File Structure

```
[repo root]/
├── FreeLook/                          Xcode project root
│   ├── FreeLook/                      host app source
│   │   ├── FreeLookApp.swift          app entry, Sparkle updater setup
│   │   ├── ContentView.swift          minimal main window
│   │   ├── SettingsView.swift         light/dark theme pickers + live preview (to be added)
│   │   ├── SettingsStore.swift        ObservableObject, App Group UserDefaults (to be added)
│   │   ├── Assets.xcassets/
│   │   └── FreeLook.entitlements
│   ├── QuickLookExtension/
│   │   ├── PreviewViewController.swift  (nib-based stub; WKWebView impl to come)
│   │   ├── UTIMapper.swift              (to be added)
│   │   ├── Info.plist
│   │   ├── QuickLookExtension.entitlements
│   │   └── Resources/
│   │       ├── template.html            (to be added)
│   │       ├── bundle.js                built artifact from WebRenderer/
│   │       └── styles.css               (to be added)
│   ├── Tests/
│   │   └── Tests.swift                  (to be renamed UTIMapperTests.swift)
│   └── FreeLook.xcodeproj
├── WebRenderer/                       JS sub-project (to be created)
│   ├── src/
│   │   └── renderer.js
│   ├── package.json
│   └── esbuild.config.mjs
├── exportOptions.plist                Developer ID export config for CI
├── appcast.xml                        Sparkle update feed (updated by CI)
├── docs/
│   └── PLAN.md
├── scripts/
│   └── build
└── .github/
    └── workflows/
        └── release.yml
```

---

## Implementation Phases

### Phase 1 — Project Skeleton

1. Xcode project skeleton is in place: `FreeLook` (host app) + `QuickLookExtension`
   (QL Preview Extension) + `Tests` unit test targets.
2. App Groups entitlement (`group.net.paradigmx.FreeLook`) is configured on both
   app and extension targets.
3. Delete `QuickLookExtension/PreviewProvider.swift` and
   `QuickLookExtension/Base.lproj/PreviewViewController.xib` — both are generated by
   Xcode for the data-based and nib-based preview alternatives respectively; our
   architecture uses `PreviewViewController` with a programmatic `WKWebView` layout.
4. Implement `PreviewViewController` with a full-safe-area `WKWebView`, replacing
   the default nib-based layout.
5. Implement `UTIMapper.swift` (in `QuickLookExtension/`) with UTType → Shiki lang
   mappings.
6. Rename `Tests/Tests.swift` to `Tests/UTIMapperTests.swift`; add representative
   test cases covering all supported categories.
7. Implement file reading with UTF-8/Latin-1 fallback and 500 KB cap.
8. Wire `SettingsStore` and App Group `UserDefaults` round-trip.

### Phase 2 — JS Rendering Pipeline

9. Bootstrap `WebRenderer/` npm project (at repo root level); install shiki,
   markdown-it, @shikijs/markdown-it, xml-formatter, esbuild.
10. Implement `renderer.js`: file-type routing, Shiki initialization with
    `createJavaScriptRegexEngine()`, dual-theme support for all bundled themes.
11. Build `bundle.js` and add it to `QuickLookExtension/Resources/`.
12. Connect Swift HTML template to the JS renderer; verify end-to-end rendering for
    each content type.

### Phase 3 — Theme Settings UI

13. Implement `SettingsView`: two pickers (light theme, dark theme) plus a live
    preview `WKWebView` showing a sample code snippet.
14. Verify `UserDefaults` changes propagate to the extension on next preview.

### Phase 4 — Polish

15. Declare full UTI list in `QuickLookExtension/Info.plist`; test with
    representative file types to confirm the extension is triggered.
16. Error states: unreadable encoding, file too large.
17. Typography refinement: font size, line height, padding, optional line numbers.
18. AppIcon, About window, bundled open-source license list.

### Phase 5 — Release

19. Add Sparkle via Swift Package Manager to the `FreeLook` target.
20. Create `exportOptions.plist` for Developer ID export.
21. Generate Sparkle EdDSA key pair; add public key to `Info.plist`; store private key
    in GitHub Secrets; set `SUFeedURL`.
22. Verify GitHub Actions release workflow: archive → export → notarize → staple →
    DMG → appcast → GitHub Release.
23. Write `README.md` with installation instructions (first-launch Gatekeeper bypass).

---

## Key Dependencies

| Dependency | Version constraint | Purpose |
|---|---|---|
| Sparkle | ^2.x | Auto-update framework (SPM) |
| shiki | ^1.x | Syntax highlighting (JS engine, no WASM) |
| markdown-it | ^14.x | Markdown parsing |
| @shikijs/markdown-it | ^1.x | Shiki integration for markdown-it |
| xml-formatter | ^3.x | XML pretty-printing |
| esbuild | ^0.24.x | JS bundle build tool |

---

## Constraints and Decisions

- **No WASM**: Shiki is initialized with `createJavaScriptRegexEngine()` to avoid
  WebAssembly binary loading inside the sandboxed App Extension.
- **No App Store**: distribution is Developer ID signed + notarized DMG via GitHub
  Releases only.
- **Sparkle auto-update**: `appcast.xml` lives in the repo root and is updated by CI
  on every tagged release.
- **min macOS 14 Sonoma**: enables modern SwiftUI APIs and CSS `light-dark()`.
- **500 KB file cap**: prevents the Quick Look extension from hitting sandbox memory
  limits on very large files.
- **Single extension, multiple UTIs**: one `FreeLookExtension` target covers all
  supported file types; no per-format split.
