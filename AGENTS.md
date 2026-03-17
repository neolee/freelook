# FreeLook — Agent Engineering Notes

Reference for AI coding agents working on this codebase. Keep this file concise, prescriptive, and focused on repository-wide rules.

---

## 1. Communication and Documentation

- Communicate with the user in Chinese.
- Write code comments and repository documentation in English unless explicitly requested otherwise.
- Do not use emojis in code comments or documentation.
- Use backticks for code references in Markdown.

---

## 2. Core Stack and Naming

- Language: Swift + SwiftUI; minimum deployment target macOS 14.6 Sonoma.
- Xcode project: `FreeLook/FreeLook.xcodeproj`.
- Two targets: `FreeLook` (host app) and `QuickLookExtension` (QL Preview Extension).
- App Groups identifier shared by both targets: `group.net.paradigmx.FreeLook`.
- `QuickLookExtension` must keep the entitlement `com.apple.security.network.client = true`. A validated local experiment showed that `WKWebView` inside the Quick Look extension crashes before the first page commit without this entitlement, while the same minimal HTML preview loads successfully once it is enabled.
- Keep detailed `UTType` / LaunchServices / Quick Look registration findings in `docs/uti.md`. `AGENTS.md` and `docs/plan.md` should only keep the high-level constraints that remain true after the detailed investigation changes.
- For file-type coverage, reason in terms of resolved `UTType`s, not filename extensions alone. The practical goal is to claim the semantically valid `UTType` candidates that a target extension may resolve to, while explicitly avoiding polluted or low-quality identifiers that are not acceptable product surface.
- Keep all file-type registration declarations in `QuickLookExtension/Info.plist`, including `CFBundleDocumentTypes`, `UTImportedTypeDeclarations`, `UTExportedTypeDeclarations`, and `QLSupportedContentTypes`. The current validated baseline is that the tested registration surface works from the Quick Look extension bundle itself and does not require matching declarations in the host app `Info.plist`.
- When LaunchServices behavior is ambiguous, prefer negative-control experiments that remove a declaration and verify the fallback path before attributing the result to cache or stale registration state.
- JS renderer sub-project: `WebRenderer/` (Bun for package management, script execution, and JS tests; `esbuild` for browser bundling). It is **not** part of the Xcode build; run it separately when changing `renderer.js`. The built artifact `bundle.js` lives at `QuickLookExtension/Resources/bundle.js`.
- Syntax highlighting: Shiki v4.x with Oniguruma/WASM.
- Renderer packaging baseline: use the inline wasm module path (`shiki/wasm`) so the extension only needs to load `bundle.js`; do not depend on a standalone `onig.wasm` resource unless a later validated experiment proves it is stable in the Quick Look `WKWebView` environment.
- Markdown: markdown-it + @shikijs/markdown-it plugin.
- JSON pretty-printing: native `JSON.stringify(JSON.parse(src), null, 2)` piped into Shiki with `lang: 'json'`.
- XML pretty-printing: xml-formatter piped into Shiki with `lang: 'xml'`.
- The renderer bundle runs in `WKWebView`, so production renderer code must stay browser-compatible and must not depend on Bun-specific runtime APIs.
- User theme preferences stored in App Group `UserDefaults` under keys `lightTheme` and `darkTheme`; supported theme metadata lives in `QuickLookExtension/Resources/Themes.json`.
- Do not add new Xcode targets without discussing with the user first.

---

## 3. Build and Verification

Run from repo root:

```shell
./scripts/build
```

- Do not pipe or post-process build output.
- Keep the build free of compiler errors and warnings.
- Treat each implementation step as a gated checkpoint that must be independently verifiable.
- Before moving to the next implementation step, run `./scripts/build` and all existing unit tests locally; both must finish with no errors and no warnings.
- After completing a step, stop and wait for the user to verify the result and create a version-control baseline before continuing to the next step.
- If a step cannot satisfy the build/test/user-baseline gate, do not continue to the next planned step.
- If tooling returns empty or missing output, stop and ask the user to verify manually.
- To rebuild `bundle.js` after changing `WebRenderer/src/renderer.js`:
  ```shell
  cd WebRenderer && bun run build
  ```
  Then copy the output into `QuickLookExtension/Resources/bundle.js`.

---

## 4. Localization Rules

- The app UI is English-only; no formal localization (`Localizable.strings`) is needed.
- Do not wrap strings in `NSLocalizedString` speculatively.
- Theme names are display strings defined in `QuickLookExtension/Resources/Themes.json`; they are not localized.

---

## 5. Testing Rules

- Unit tests live in the `Tests` target.
- Run the full unit test suite after every implementation step, even if the step does not introduce new tests.
- `UTIMapperTests.swift` must cover at least one representative `UTType` for each category: Markdown, JSON, XML, Swift, Python, JavaScript, shell script, and generic source code (should map to a valid Shiki lang string or `"text"`).
- After any change to `UTIMapper.swift`, run the unit tests locally.
- Rendering pipeline correctness is verified manually: open a representative file of each supported type via Quick Look and confirm the output looks correct.
- Do not add snapshot tests or UI tests without discussing with the user first.
