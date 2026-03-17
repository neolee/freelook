# FreeLook — Design & Implementation Plan

## Overview

FreeLook is a macOS Quick Look Preview Extension that provides syntax-highlighted previews for developer file types: Markdown, JSON, XML, and source code in common programming languages. It is distributed via GitHub Releases (signed + notarized DMG) with Sparkle-based auto-update, not through the App Store.

Phase 1 is complete. The remaining work should preserve the same gated workflow: every implementation step must be small enough to verify independently, `./scripts/build` must pass without warnings, all existing unit tests must pass without warnings, the user must confirm the result manually when applicable, and a version-control baseline must be created before the next step starts.

---

## Architecture

### Xcode Project

Two targets inside `FreeLook/FreeLook.xcodeproj`:

- `FreeLook` — host macOS app; provides the required container for the extension, a settings UI for user preferences, and the Sparkle update framework.
- `QuickLookExtension` — Quick Look Preview Extension; renders file content inside a `WKWebView`.

Both targets share an App Group (`group.net.paradigmx.FreeLook`) for `UserDefaults` preference exchange.

### Validated `WKWebView` Requirement

`QuickLookExtension` keeps `com.apple.security.network.client = true` in `QuickLookExtension.entitlements`.

This is not speculative: a local capability test on the current project showed that `WKWebView` inside the Quick Look extension repeatedly crashed its `WebContent` process before the first committed load when the entitlement was absent. The same minimal HTML preview completed `didCommitLoadForFrame` and `didFinishLoadForFrame` after enabling `network.client`.

Treat this entitlement as part of the baseline for any future WebKit-based preview work unless a later validated experiment proves a narrower setup.

### JS Rendering Pipeline

A standalone Bun-managed sub-project lives in `WebRenderer/` and is built separately with `esbuild`. Its output, `bundle.js`, is committed/copied into `QuickLookExtension/Resources/` and loaded by the extension's `WKWebView`.

The renderer exposes a single entry point:

```js
FreeLook.render({ content, lang, lightTheme, darkTheme })
```

File-type routing inside the renderer:

| `lang` value | Pipeline |
|---|---|
| `"markdown"` | `markdown-it` with practical GFM support enabled, plus `@shikijs/markdown-it` for code blocks |
| `"json"` | `JSON.parse` → `JSON.stringify(_, null, 2)` → Shiki `json`; on parse failure, show original source with a warning |
| `"xml"` | `xml-formatter` → Shiki `xml`; on parse failure, show original source with a warning |
| anything else | Shiki with the provided lang string |

Markdown support should aim at the full practical GFM surface that is reasonable with the chosen libraries, including fenced code blocks, tables, task lists, autolinks, and strikethrough. If a specific GFM feature must be omitted because of library or safety constraints, that exception should be documented before implementation is considered complete.

### JS Toolchain Selection

Phase 2 should keep the JS side intentionally small and infrastructure-light.

- package manager and script runner: `bun`
- language: plain JavaScript with ESM modules
- bundler: `esbuild`
- unit test runner: `bun test`
- runtime target: browser code running inside the extension's `WKWebView`
- UI approach: framework-free rendering; no React, Vue, or other client framework

Recommended dependency set:

- `shiki` v1.x with Oniguruma/WASM via the inline `shiki/wasm` module
- `markdown-it`
- `@shikijs/markdown-it`
- a small Markdown task-list plugin if needed to complete the practical GFM surface
- `xml-formatter`
- `esbuild`
- `bun`

Recommended non-goals for the first renderer phase:

- no TypeScript unless the JS layer grows enough to justify extra tooling,
- no DOM-heavy client framework,
- no SSR or Node-specific rendering assumptions,
- no separate runtime state-management layer.

This is a deliberate trade-off. The job of renderer is narrow: transform file content into static HTML with syntax highlighting and a few warning states, then hand that result to the existing HTML shell. A framework would add more structure than value at this stage.

Bun should be used for dependency installation, script execution, and JS tests. The final renderer code still runs inside `WKWebView`, so production code must not rely on Bun-specific runtime APIs or Node-only environment assumptions.

For syntax highlighting, the validated baseline is `Shiki + Oniguruma/WASM`, packaged through the inline `shiki/wasm` module. This keeps the Quick Look extension on a single `bundle.js` runtime artifact and avoids a separate `onig.wasm` fetch path, which proved brittle in the `loadHTMLString(_:baseURL:)` preview environment.

For Markdown safety, keep raw HTML disabled in the initial renderer unless a later requirement explicitly justifies sanitization and support. Practical GFM support does not require enabling arbitrary embedded HTML.

### Swift ↔ WKWebView Contract

1. `PreviewViewController` reads the file (`FileHandle`, UTF-8 then Latin-1 fallback, 500 KB cap — larger files show a truncation notice).
2. `UTIMapper.swift` converts the file's `UTType` to a Shiki language identifier string.
3. `SettingsStore` reads preview preferences from the shared App Group `UserDefaults`.
4. A string-interpolated `template.html` is passed to `loadHTMLString(_:baseURL:)`; `baseURL` points to the extension's `Resources/` bundle directory so that relative paths to `bundle.js` and `styles.css` resolve correctly.

---

## Preview Design Baseline

The HTML shell is a product surface, not a throwaway integration detail. Visual decisions that affect reading comfort should be established before full renderer rollout, not postponed to the final polish pass.

### Design goals

- The preview should feel calm, compact, and durable for daily use.
- The content should remain visually subordinate to the file itself; decorative chrome should be restrained.
- The default Quick Look surface should be content-first: the file body is the product, and surrounding UI should stay as close to invisible as possible.
- Light and dark mode should share one spacing and typography system even though syntax colors come from different Shiki themes.

### Content-first rules

- Do not repeat the file name inside the preview body. Quick Look window chrome already provides that context.
- Do not keep persistent header, footer, theme labels, `UTType`, encoding, or similar diagnostic metadata in the product surface.
- Non-content UI should appear only when it serves a real reading or error-handling need.
- Warning and fallback states should stay visible enough to explain what happened, but they should never compete with the main content once the file is readable.
- Decorative containers should be weak. The preview should feel like viewing the file itself, not like viewing a document inside an app page.

### Optional utility affordances

- A very small top bar that shows the full file path and offers one-click copy may be worth exploring later.
- This is explicitly a secondary utility feature, not part of the default preview structure.
- If implemented, it should be lightweight enough that the preview still reads as content-first.

### Baseline design tokens to settle early

- typography:
  - body text font stack,
  - code font stack,
  - base font size,
  - line height,
  - heading scale,
  - inline code treatment
- layout:
  - maximum readable width,
  - outer padding,
  - vertical rhythm,
  - code block padding,
  - table overflow behavior
- states:
  - loading,
  - truncation notice,
  - parse warning,
  - unreadable-encoding fallback,
  - generic error state

The first renderer-facing HTML/CSS milestone should produce a stable visual baseline for:

- plain code files,
- Markdown prose with code blocks,
- prettified JSON,
- prettified XML,
- parse-failure warning states.

### Settings scope discipline

The host app settings UI should not drive early visual decisions. The preview surface comes first; the host settings panel can land later once the supported preference set is stable and the reusable assets already exist.

For v1, user-facing settings should be grouped conceptually as:

- `Appearance` — theme choices and any later visual density controls
- `Reading` — typography-related controls that are explicitly approved
- `Behavior` — non-visual preferences such as quitting after the last window closes

Do not expose arbitrary font-family selection early. That setting has disproportionate visual impact and should only be added once the default typography system is already approved.

---

## Theme System

Users independently choose one light theme and one dark theme in the host app settings. The selected theme names are stored in App Group `UserDefaults` under the keys `lightTheme` and `darkTheme`.

Shiki's dual-theme CSS variable mechanism handles automatic `prefers-color-scheme` switching at render time. FreeLook should not add a second theme-switching layer in JavaScript after initial render unless a later validated requirement makes it necessary.

### Bundled Themes

Light: GitHub Light, One Light, Catppuccin Latte, Nord Light
Dark: GitHub Dark, One Dark Pro, Catppuccin Mocha, Nord

The current theme list is sufficient for the initial renderer rollout. Expanding the theme catalog should only happen after the baseline HTML shell and representative sample files are visually approved.

---

## Sample Corpus

FreeLook should keep a committed sample corpus in the repository so the same files can be reused for:

- visual design review,
- manual Quick Look verification,
- host-app preview verification once that UI exists,
- future renderer smoke checks,
- selected unit-test fixtures where file-backed inputs are appropriate.

The committed sample corpus should prioritize representative, human-reviewable files:

- a Markdown showcase document,
- valid and invalid JSON,
- valid and invalid XML,
- representative source files for Swift, Python, JavaScript, and shell script,
- at least one long-line file for overflow review.

Some edge cases are better generated by tests instead of committed as static files:

- oversized files around the 500 KB cap,
- non-UTF-8 encoding fixtures such as Latin-1,
- pathological whitespace or deeply nested stress cases that are useful for parser or loader testing but not for normal design review.

The initial committed corpus should live in `samples/` at the repository root so it remains easy to reference from docs, tests, and manual validation steps.

---

## UTI Coverage

The extension's current `QLSupportedContentTypes` list is the FreeLook v1.0 baseline whitelist and should be treated as the starting point for validation, not as a random placeholder.

Do not assume that a parent type such as `public.source-code` is sufficient to reliably claim all descendant source-file types. The registration strategy is to cover the semantically valid `UTType` candidates that important extensions resolve to on real systems, while avoiding polluted or low-quality identifiers that happen to appear in LaunchServices. This must still be established by explicit Quick Look experiments and should be documented with representative findings for Swift, Markdown, JSON, XML, and at least one additional source-code subtype.

Keep all file-type registration declarations in `QuickLookExtension/Info.plist`, including `CFBundleDocumentTypes`, `UTImportedTypeDeclarations`, `UTExportedTypeDeclarations`, and `QLSupportedContentTypes`. The current validated baseline does not require matching file-type declarations in the host app `Info.plist`.

When an important developer-facing extension falls back to an opaque `dyn.*` identifier, prefer testing a product-owned exported UTI that conforms to the relevant semantic parent type and is claimed directly in `QLSupportedContentTypes`.

The detailed LaunchServices and `UTType` findings live in `docs/uti.md`. That document is the source of truth for:

- how file extensions are resolved to preferred `UTType`s on the current system,
- how third-party apps can pollute the candidate set for a tag such as `md`,
- why FreeLook should try to claim the reasonable candidate `UTType`s for an extension rather than every identifier that appears in the candidate set,
- which local cleanup steps were validated during diagnosis, and
- which command-line probes are useful when preview routing behaves unexpectedly.

---

## Verification Strategy

FreeLook needs both unit-test confidence and early visible results. The plan should therefore distinguish clearly between behavior that is primarily programmatic and behavior that is primarily visual.

### Unit-test-first surfaces

- `UTType` to renderer-language mapping
- bounded file loading, truncation, and decoding fallbacks
- settings normalization and persistence rules
- renderer input shaping on the Swift side
- warning/fallback branching where the logic is deterministic and easy to isolate

### Manual-review-first surfaces

- typography and spacing quality
- code block readability
- table overflow behavior
- contrast and emphasis in light and dark appearances
- warning and error state tone
- how Markdown, JSON, XML, and code feel as reading surfaces rather than just parsed outputs

### Review artifacts to keep stable during development

- the committed sample corpus in `samples/`
- a short manual review checklist for representative file types and states
- the current theme list and preview sample choices

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
│   │   ├── FreeLookApp.swift          app entry
│   │   ├── AppDelegate.swift          close-last-window termination hook
│   │   ├── ContentView.swift          settings window UI
│   │   ├── SettingsStore.swift        ObservableObject, App Group UserDefaults
│   │   ├── Assets.xcassets/
│   │   └── FreeLook.entitlements
│   ├── QuickLookExtension/
│   │   ├── PreviewViewController.swift  WKWebView preview shell
│   │   ├── PreviewFileLoader.swift      bounded file loading + decoding
│   │   ├── SharedPreviewSettings.swift  shared App Group keys/defaults
│   │   ├── UTIMapper.swift              UTType -> renderer language mapping
│   │   ├── Info.plist
│   │   ├── QuickLookExtension.entitlements
│   │   └── Resources/
│   │       ├── template.html            local HTML shell
│   │       ├── bundle.js                built artifact from WebRenderer/
│   │       └── styles.css               shared preview styles
│   ├── Tests/
│   │   ├── UTIMapperTests.swift
│   │   ├── PreviewFileLoaderTests.swift
│   │   └── SettingsStoreTests.swift
│   └── FreeLook.xcodeproj
├── samples/                           committed review and test corpus
├── WebRenderer/                       JS sub-project
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
│   ├── build
│   └── test
└── .github/
    └── workflows/
        └── release.yml
```

---

## Implementation Phases

The remaining work should optimize for early visual validation without sacrificing small, gated steps.

### Phase 2 — Preview Surface Baseline

2.1 Committed sample corpus
- Add `samples/` with the initial committed review corpus: Markdown showcase, valid/invalid JSON, valid/invalid XML, representative source files, and a long-line sample.
- Keep oversized and non-UTF-8 fixtures out of the committed corpus for now; generate those in tests when needed.
- Verification gate: clean build; full unit test suite; user confirms the sample set is representative enough for ongoing design review.

2.2 Renderer project bootstrap
- Create `WebRenderer/` with `package.json`, `esbuild.config.mjs`, and the initial `src/renderer.js` entry point.
- Use Bun for dependency installation and scripts, and install/pin `shiki`, `markdown-it`, `@shikijs/markdown-it`, `xml-formatter`, and `esbuild`.
- Verification gate: clean native build; full unit test suite; user reviews the JS project scaffold before renderer logic is added.

2.3 HTML shell and design tokens
- Add `template.html` and `styles.css` as first-class product assets rather than last-minute polish files.
- Establish the baseline typography, spacing, width, and state styling using the committed sample corpus as the review surface.
- Keep this step focused on the HTML/CSS shell and static sample rendering shape; do not mix in all format-specific parsing behavior yet.
- Verification gate: clean build; full unit test suite; user manually reviews the visual baseline before format pipelines are added.

### Phase 3 — Renderer Rollout by Content Type

3.1 Core source-code rendering
- Implement the base `Shiki` pipeline in `renderer.js` with Oniguruma/WASM and the bundled theme set.
- At this stage, remove the temporary development chrome so the Quick Look body converges toward the approved content-first presentation.
- Verify representative source files from the sample corpus first.
- Verification gate: clean native build; full unit test suite; user confirms the baseline code-reading surface.

3.2 Markdown rendering
- Implement Markdown rendering with practical GFM support using `markdown-it` and `@shikijs/markdown-it`.
- Validate headings, paragraphs, fenced code blocks, tables, task lists, strikethrough, blockquotes, and links using the Markdown showcase sample.
- Verification gate: clean native build; full unit test suite; user manually reviews Markdown rendering quality.

3.3 JSON rendering
- Implement `JSON.parse` → `JSON.stringify(_, null, 2)` → `Shiki` `json`.
- On parse failure, display the original source instead of an empty or broken preview, and add a clear but restrained warning.
- Verification gate: clean native build; full unit test suite; user manually reviews both valid and invalid JSON behavior.

3.4 XML rendering
- Implement `xml-formatter` → `Shiki` `xml`.
- On parse failure, display the original source instead of an empty or broken preview, and add a clear but restrained warning.
- Verification gate: clean native build; full unit test suite; user manually reviews both valid and invalid XML behavior.

3.5 Swift-to-renderer integration
- Pass file contents, language identifier, and selected themes from Swift into the HTML template and renderer bundle.
- Verify end-to-end rendering for the committed sample corpus inside Quick Look.
- Verification gate: clean build; full unit test suite; user manually validates end-to-end preview output before host-app UI work starts.

### Phase 4 — Host App Preferences

4.1 Settings surface definition
- Finalize which settings are in scope for v1 and group them under `Appearance`, `Reading`, and `Behavior`.
- Keep theme selection as the only guaranteed visual preference unless later controls are explicitly approved.
- Verification gate: clean build; full unit test suite; user confirms the v1 settings surface before UI design starts.

4.2 Settings UI
- Implement the host app settings UI around the finalized settings surface.
- Reuse the already approved preview visual language and assets where appropriate.
- Verification gate: clean build; full unit test suite; user confirms the settings layout and interaction model.

4.3 Preview panel and propagation
- Add the host-app preview panel only after the settings set is stable.
- Verify that changing preferences updates the host preview and propagates to the Quick Look extension on the next preview.
- Verification gate: clean build; full unit test suite; user manually checks preference propagation in both places.

### Phase 5 — Product Hardening and Polish

5.1 UTI registration
- Finalize the supported UTI list in `QuickLookExtension/Info.plist` using explicit Quick Look experiments instead of assumptions about parent-type coverage.
- Test representative file types to confirm the extension is triggered reliably and record any system-owned fallbacks or tie-break behaviors.
- Verification gate: clean build; full unit test suite; user manually confirms file association behavior.

5.2 Error and fallback states
- Refine explicit UI states for unreadable encoding, oversized files, and renderer parse warnings.
- Ensure these states match the approved visual system rather than looking like ad hoc debug output.
- Keep them as transient content-adjacent notices rather than turning them into permanent structural chrome.
- Verification gate: clean build; full unit test suite; user manually validates the fallback states.

5.3 Reading comfort refinements
- Revisit font size, line height, padding, code-block density, and any approved reading controls after the main format pipelines are already stable.
- Optional line numbers, if explored, should be treated as a product decision rather than an automatic addition.
- Any future full-path bar or copy-path affordance should be evaluated here as an optional utility layer, not as required default UI.
- Verification gate: clean build; full unit test suite; user reviews readability before additional polish is added.

5.4 Product polish assets
- Deliver the remaining product-facing assets such as the About window and bundled open-source license list.
- `AppIcon` can be completed independently once the asset catalog is stable; it does not need to block the runtime implementation path.
- Verification gate: clean build; full unit test suite; user signs off on the product polish set.

### Phase 6 — Release

6.1 Sparkle target integration
- Add Sparkle to the `FreeLook` target and wire the host app updater setup.
- Verification gate: clean build; full unit test suite; user confirms updater integration scope before release configuration.

6.2 Export configuration
- Create `exportOptions.plist` for Developer ID export.
- Verification gate: clean build; full unit test suite; user reviews export settings.

6.3 Signing metadata
- Generate the Sparkle EdDSA key pair, add the public key to `Info.plist`, store the private key in GitHub Secrets, and set `SUFeedURL`.
- Verification gate: clean build; full unit test suite; user confirms release metadata values before CI changes are relied on.

6.4 CI release validation
- Verify the GitHub Actions workflow end to end: archive, export, notarize, staple, DMG, appcast update, and GitHub Release creation.
- Verification gate: clean build; full unit test suite; user confirms the release pipeline behavior.

6.5 End-user installation docs
- Write `README.md` installation instructions, including the first-launch Gatekeeper bypass flow.
- Verification gate: clean build; full unit test suite; user reviews the release documentation before the first public release.

---
