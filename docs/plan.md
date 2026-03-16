# FreeLook — Design & Implementation Plan

## Overview

FreeLook is a macOS Quick Look Preview Extension that provides syntax-highlighted previews for developer file types: Markdown, JSON, XML, and source code in common programming languages. It is distributed via GitHub Releases (signed + notarized DMG) with Sparkle-based auto-update, not through the App Store.

Every implementation step should be small enough to verify independently. The required gate after each step is: `./scripts/build` passes without warnings, all existing unit tests pass without warnings, the user confirms the result manually when applicable, and a version-control baseline is created before the next step starts.

---

## Architecture

### Xcode Project

Two targets inside `FreeLook/FreeLook.xcodeproj`:

- `FreeLook` — host macOS app; provides the required container for the extension, a settings UI for theme selection, and the Sparkle update framework.
- `QuickLookExtension` — Quick Look Preview Extension; renders file content inside a `WKWebView`.

Both targets share an App Group (`group.net.paradigmx.FreeLook`) for `UserDefaults` preference exchange.

### Validated `WKWebView` Requirement

`QuickLookExtension` keeps `com.apple.security.network.client = true` in `QuickLookExtension.entitlements`.

This is not speculative: a local capability test on the current project showed that `WKWebView` inside the Quick Look extension repeatedly crashed its `WebContent` process before the first committed load when the entitlement was absent. The same minimal HTML preview completed `didCommitLoadForFrame` and `didFinishLoadForFrame` after enabling `network.client`.

Treat this entitlement as part of the baseline for any future WebKit-based preview work unless a later validated experiment proves a narrower setup.

### JS Rendering Pipeline

A standalone npm sub-project lives in `WebRenderer/` and is built separately with esbuild. Its output, `bundle.js`, is committed/copied into `QuickLookExtension/Resources/` and loaded by the extension's `WKWebView`.

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

1. `PreviewViewController` reads the file (`FileHandle`, UTF-8 then Latin-1 fallback, 500 KB cap — larger files show a truncation notice).
2. `UTIMapper.swift` converts the file's `UTType` to a Shiki language identifier string.
3. `SettingsStore` reads `lightTheme` and `darkTheme` from the shared App Group `UserDefaults`.
4. A string-interpolated `template.html` is passed to `loadHTMLString(_:baseURL:)`; `baseURL` points to the extension's `Resources/` bundle directory so that relative paths to `bundle.js` and `styles.css` resolve correctly.

---

## Theme System

Users independently choose one light theme and one dark theme in the host app settings. The selected theme names are stored in App Group `UserDefaults` under the keys `lightTheme` and `darkTheme`.

Shiki's dual-theme CSS variable mechanism handles automatic `prefers-color-scheme` switching at render time — no JavaScript theme-switching is performed after initial render.

### Bundled Themes

Light: GitHub Light, One Light, Catppuccin Latte, Nord Light, Solarized Light
Dark: GitHub Dark, One Dark Pro, Catppuccin Mocha, Nord, Dracula

---

## UTI Coverage

The extension's current `QLSupportedContentTypes` list is the FreeLook v1.0 baseline whitelist and should be treated as the starting point for validation, not as a random placeholder.

Do not assume that a parent type such as `public.source-code` is sufficient to reliably claim all descendant source-file types. The registration strategy is to cover the semantically valid `UTType` candidates that important extensions resolve to on real systems, while avoiding polluted or low-quality identifiers that happen to appear in LaunchServices. This must still be established by explicit Quick Look experiments during Phase 4 and should be documented with representative findings for Swift, Markdown, JSON, XML, and at least one additional source-code subtype.

The detailed LaunchServices and `UTType` findings now live in `docs/uti.md`. That document is the source of truth for:

- how file extensions are resolved to preferred `UTType`s on the current system,
- how third-party apps can pollute the candidate set for a tag such as `md`,
- why FreeLook should try to claim the reasonable candidate `UTType`s for an extension rather than every identifier that appears in the candidate set,
- which local cleanup steps were validated during diagnosis, and
- which command-line probes are useful when preview routing behaves unexpectedly.

---

## Auto-Update (Sparkle)

FreeLook uses the [Sparkle](https://sparkle-project.org) framework for automatic updates. The CI release workflow runs `generate_appcast` to update `appcast.xml` in the repository root after each release. The host app checks the appcast URL on launch and notifies the user when an update is available.

Required setup:

1. Generate an EdDSA key pair with Sparkle's `generate_keys` tool; store the private key as the `SPARKLE_PRIVATE_KEY` GitHub Secret (base64-encoded).
2. Add the corresponding public key to `Info.plist` as `SUPublicEDKey`.
3. Set `SUFeedURL` in `Info.plist` to `https://raw.githubusercontent.com/neolee/freelook/main/appcast.xml`

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
│   ├── plan.md
│   └── uti.md
├── scripts/
│   └── build
└── .github/
    └── workflows/
        └── release.yml
```

---

## Implementation Phases

The original phase boundaries are still correct, but several items were too large for the required build-test-review-baseline workflow. The phase breakdown below splits each phase into smaller implementation steps that should each fit in one checkpoint.

### Phase 1 — Project Skeleton

1.1 Baseline skeleton
- Confirm the Xcode project skeleton, both targets, the `Tests` target, App Group entitlement, and deletion of the unused template preview files.
- Verification gate: clean `./scripts/build`; unit tests; user confirms the repository baseline.

1.2 Programmatic preview container
- Replace the nib-based extension view with a full-safe-area programmatic `WKWebView` shell in `PreviewViewController`.
- Keep the first pass focused on layout and loading-state plumbing only; do not mix in file parsing or JS rendering yet.
- Verification gate: clean build; unit tests; user manually confirms the extension loads the new container without layout regressions.

1.3 `UTI` mapping and tests
- Implement `UTIMapper.swift` with `UTType` → `Shiki` language mappings.
- Rename `Tests/Tests.swift` to `Tests/UTIMapperTests.swift` and add representative coverage for Markdown, JSON, XML, Swift, Python, JavaScript, shell script, and generic source code.
- Verification gate: clean build; full unit test suite; user confirms the tested mapping surface is sufficient before moving on.

1.4 Bounded file loading
- Implement file reading with UTF-8 first, Latin-1 fallback, and a 500 KB cap.
- If useful, extract decoding/size-limit helpers so they can be tested directly.
- Verification gate: clean build; full unit test suite; user manually checks at least one small file and one oversized file path.

1.5 Shared settings persistence
- Add `SettingsStore.swift` and wire App Group `UserDefaults` round-trip for `lightTheme` and `darkTheme`.
- Keep this step limited to persistence and model code; defer the full UI to Phase 3.
- Verification gate: clean build; full unit test suite; user confirms settings persist across relaunches or extension reloads.

### Phase 2 — JS Rendering Pipeline

2.1 Renderer project bootstrap
- Create `WebRenderer/` with `package.json`, `esbuild.config.mjs`, and the initial `src/renderer.js` entry point.
- Install and pin `shiki`, `markdown-it`, `@shikijs/markdown-it`, `xml-formatter`, and `esbuild`.
- Verification gate: clean native build; full unit test suite; user reviews the JS project scaffold before renderer logic is added.

2.2 Core renderer implementation
- Implement file-type routing in `renderer.js`.
- Initialize `Shiki` with `createJavaScriptRegexEngine()` and configure the bundled light/dark theme set.
- Verification gate: clean native build; full unit test suite; user reviews the JS implementation before asset bundling.

2.3 Bundled extension resources
- Build `bundle.js` and add it to `QuickLookExtension/Resources/`.
- Add `template.html` and `styles.css` so the extension has a stable local HTML shell for the renderer.
- Verification gate: clean build; full unit test suite; user confirms the bundled resources are present and versioned correctly.

2.4 Swift-to-renderer integration
- Pass file contents, lang, and selected themes from Swift into the HTML template.
- Verify end-to-end rendering for Markdown, JSON, XML, and representative source files.
- Verification gate: clean build; full unit test suite; user manually validates rendering output in Quick Look before Phase 3 starts.

### Phase 3 — Theme Settings UI

3.1 Theme catalog and preview sample
- Finalize the theme list exposed by `SettingsStore` and the sample content used for previews.
- Verification gate: clean build; full unit test suite; user confirms the theme catalog and sample snippet.

3.2 Settings UI
- Implement `SettingsView` with independent light/dark theme pickers.
- Keep this step focused on UI structure and persistence bindings.
- Verification gate: clean build; full unit test suite; user confirms the settings UI layout and interaction model.

3.3 Live preview and propagation
- Add the live preview `WKWebView` in the host app and verify changes propagate to the extension on the next preview.
- Verification gate: clean build; full unit test suite; user manually checks theme changes in both the host app preview and Quick Look.

### Phase 4 — Polish

4.1 UTI registration
- Finalize the supported UTI list in `QuickLookExtension/Info.plist` using explicit Quick Look experiments instead of assumptions about parent-type coverage.
- Test representative file types to confirm the extension is triggered reliably and record any system-owned fallbacks or tie-break behaviors.
- Verification gate: clean build; full unit test suite; user manually confirms file association behavior.

4.2 Error and fallback states
- Add explicit UI states for unreadable encoding and oversized files.
- Verification gate: clean build; full unit test suite; user manually validates the error states.

4.3 Typography and reading comfort
- Refine font size, line height, padding, and optional line numbers.
- Verification gate: clean build; full unit test suite; user reviews readability before additional polish.

4.4 Product polish assets
- Deliver the remaining product-facing assets such as the About window and bundled open-source license list.
- `AppIcon` can be completed independently once the asset catalog is stable; it does not need to block the runtime implementation path.
- Verification gate: clean build; full unit test suite; user signs off on the product polish set.

### Phase 5 — Release

5.1 Sparkle target integration
- Add Sparkle to the `FreeLook` target and wire the host app updater setup.
- Verification gate: clean build; full unit test suite; user confirms updater integration scope before release configuration.

5.2 Export configuration
- Create `exportOptions.plist` for Developer ID export.
- Verification gate: clean build; full unit test suite; user reviews export settings.

5.3 Signing metadata
- Generate the Sparkle EdDSA key pair, add the public key to `Info.plist`, store the private key in GitHub Secrets, and set `SUFeedURL`.
- Verification gate: clean build; full unit test suite; user confirms release metadata values before CI changes are relied on.

5.4 CI release validation
- Verify the GitHub Actions workflow end to end: archive, export, notarize, staple, DMG, appcast update, and GitHub Release creation.
- Verification gate: clean build; full unit test suite; user confirms the release pipeline behavior.

5.5 End-user installation docs
- Write `README.md` installation instructions, including the first-launch Gatekeeper bypass flow.
- Verification gate: clean build; full unit test suite; user reviews the release documentation before the first public release.

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

- **No WASM**: Shiki is initialized with `createJavaScriptRegexEngine()` to avoid WebAssembly binary loading inside the sandboxed App Extension.
- **No App Store**: distribution is Developer ID signed + notarized DMG via GitHub Releases only.
- **Sparkle auto-update**: `appcast.xml` lives in the repo root and is updated by CI on every tagged release.
- **min macOS 14.6 Sonoma**: enables modern SwiftUI APIs and CSS `light-dark()`.
- **500 KB file cap**: prevents the Quick Look extension from hitting sandbox memory limits on very large files.
- **Single extension, multiple UTIs**: one `FreeLookExtension` target covers all supported file types; no per-format split.
