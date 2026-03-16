# FreeLook — UTI and LaunchServices Notes

This document records the detailed findings behind FreeLook's file-type registration work. Keep `AGENTS.md` and `plan.md` high-level; put investigative detail here instead.

## Scope

FreeLook can only receive a file in Quick Look after the system has already resolved that file to a `UTType` that matches one of the extension's `QLSupportedContentTypes`.

In practice, the difficult part is often not the Quick Look extension itself but the system's LaunchServices and `UTType` environment for a given filename extension.

## Current validated findings

### `WKWebView` baseline

- `QuickLookExtension` must keep `com.apple.security.network.client = true`.
- Without that entitlement, the extension's `WKWebView` repeatedly crashed its `WebContent` process before the first committed load.
- With that entitlement enabled, the same minimal local HTML page completed `didCommitLoadForFrame` and `didFinishLoadForFrame`.

### Markdown routing baseline

- FreeLook currently declares `net.daringfireball.markdown` in `QLSupportedContentTypes`.
- FreeLook currently keeps the Markdown imported declaration in `QuickLookExtension/Info.plist`.
- The current extension-level imported declaration gives `md`, `markdown`, and `text/markdown` an explicit local path to `net.daringfireball.markdown`.
- On a clean-enough system state, both `.md` and `.markdown` can resolve to `net.daringfireball.markdown`, and default Quick Look will route Markdown files to `net.paradigmx.FreeLook.QuickLookExtension`.

### Post-reboot cleanup status

After the LaunchServices reset and OS reboot, the local machine returned to a clean Markdown baseline:

- `UTType(filenameExtension: "md") == net.daringfireball.markdown`
- `UTType(filenameExtension: "markdown") == net.daringfireball.markdown`
- the candidate set for `md` no longer includes `com.unknown.md`
- actual `.md` files resolve to `net.daringfireball.markdown`
- default Quick Look for Markdown launches `net.paradigmx.FreeLook.QuickLookExtension`

### Observed pollution case: `com.unknown.md`

During diagnosis on the current machine, `.md` files initially resolved to `com.unknown.md` instead of `net.daringfireball.markdown`.

That was not an abstract system fallback. A concrete app, `TeXShop`, declared:

- `CFBundleDocumentTypes` with `md` mapped to `LSItemContentTypes = com.unknown.md`
- `UTImportedTypeDeclarations` importing `com.unknown.md` for the `md` extension

Once `TeXShop.app` was removed and stale LaunchServices preferences were cleaned, the preferred type for `.md` changed back to `net.daringfireball.markdown`.

Important implication:

- multiple apps may legitimately claim the same extension,
- the preferred `UTType` is not guaranteed to be the obvious or semantically best one, and
- Quick Look provider selection depends on the resolved type, not on the user's default editor alone.

## Working model

The local experiments support the following model:

1. Bundles register document types and UTIs through `CFBundleDocumentTypes`, `UTExportedTypeDeclarations`, and `UTImportedTypeDeclarations`.
2. LaunchServices builds a candidate set of `UTType`s for a tag such as the filename extension `md`.
3. The system picks a preferred type for that tag.
4. Finder kind strings and `URLResourceValues.contentTypeKey` follow that preferred type.
5. Quick Look routing then uses that resolved content type to choose a preview provider.

Apple documents the existence of the candidate set and the preferred type, but the exact tie-breaking algorithm for competing `UTType` claims is not publicly specified in enough detail to treat it as deterministic.

## Practical rules for FreeLook

- Treat `QLSupportedContentTypes` as the final "can this extension preview this resolved type?" gate.
- Keep all file-type registration declarations in `QuickLookExtension/Info.plist`, including `CFBundleDocumentTypes`, `UTImportedTypeDeclarations`, `UTExportedTypeDeclarations`, and `QLSupportedContentTypes`.
- The current validated baseline is that the tested Markdown and CommonJS declarations work from `QuickLookExtension/Info.plist` alone and do not require matching file-type declarations in the host app `Info.plist`.
- Treat `UTImportedTypeDeclarations` and `UTExportedTypeDeclarations` as inputs into system type resolution, not as direct Quick Look routing controls.
- Validate both the preferred type and the provider actually selected by Quick Look.
- When a routing failure appears, do not assume the extension declaration is wrong before checking for third-party LaunchServices pollution.
- Prefer exact, well-known `UTType` identifiers over broad parent types.
- For an important filename extension, inspect the real candidate `UTType` set on the target system and try to claim the semantically valid candidates that FreeLook should own.
- Do not claim every identifier in the candidate set. Reject polluted or low-quality identifiers such as `com.unknown.md` even if claiming them might increase routing coverage on one machine.
- In practical terms: maximize coverage across reasonable `UTType`s, not across arbitrary strings that happen to appear in LaunchServices.

## Working registration strategy

The current best strategy for FreeLook is:

1. Start from the current `QLSupportedContentTypes` whitelist in `QuickLookExtension/Info.plist`.
2. Keep file-type registration declarations in `QuickLookExtension/Info.plist`. The present local baseline shows that the tested Markdown/CommonJS cases do not require host-app placement.
3. For each important file extension, inspect the preferred `UTType` and the candidate set observed on a real machine.
4. If the system resolves that extension to one of FreeLook's claimed, semantically valid `UTType`s, FreeLook will usually be launched as long as no stronger competing Quick Look provider takes precedence.
5. If coverage is missing and the extension falls back to an opaque `dyn.*` identifier, prefer exporting a product-owned UTI and claiming that exact type instead of trying to absorb the extension into an unrelated global type.
6. If coverage is missing for other reasons, add more semantically valid `UTType`s, not polluted fallback identifiers.
7. If a candidate type is low-quality, machine-specific, or obviously wrong for the file format, document it as rejected instead of claiming it.

This is intentionally a probability-maximizing strategy, not a guarantee. Apple does not document the full provider tie-break algorithm, and other installed Quick Look extensions may still win for some types.

## First whitelist audit

The first audit of the v1.0 whitelist on the current machine led to three kinds of changes:

- replace invalid identifiers,
- add semantically valid vendor-specific candidates that real extensions can resolve to, and
- add product-owned type declarations where a useful developer-file extension lacks a stable semantic mapping.

### Accepted additions

- TypeScript: `public.typescript`, `com.microsoft.typescript`, `org.typescriptlang.typescript`
- Shell subtypes: `public.zsh-script`, `public.bash-script`
- CSS: `org.w3.css`
- Markdown: `io.typora.markdown`, `net.ia.markdown`
- Common C-family source types: `public.c-source`, `public.c-header`, `public.objective-c-source`, `public.objective-c-plus-plus-source`, `public.c-plus-plus-source`
- Product-owned CommonJS type: `net.paradigmx.commonjs-source`

### Explicitly rejected candidates

- Markdown pollution example: `com.unknown.md`
- JSON app-specific type: `com.omnigroup.statusboard`
- XML document-specific types such as `com.microsoft.excel.xml` and `com.microsoft.word.wordml`
- Media types that collide with TypeScript extensions, such as `public.mpeg-2-transport-stream` and `public.avchd-mpeg-2-transport-stream`
- Dynamic or opaque identifiers such as the current `cjs` fallback `dyn.*`

### Why TypeScript is still only partially solvable

On the current machine:

- `tsx` and `cts` already resolve to semantically valid TypeScript identifiers
- `ts` prefers `public.mpeg-2-transport-stream`
- `mts` prefers `public.avchd-mpeg-2-transport-stream`

FreeLook now claims the semantically valid TypeScript identifiers, but it does not try to override ambiguous media extensions globally. That is a deliberate product decision: the app should not steal real transport-stream files just to improve TypeScript routing on one machine.

### `cjs` custom-type experiment

The first two `cjs` experiments showed that binding `cjs` directly onto `com.netscape.javascript-source` was not enough to replace the system's `dyn.*` fallback on the current machine.

FreeLook then tested a stronger configuration:

- export `net.paradigmx.commonjs-source`,
- bind `cjs` directly to that exported identifier,
- declare that the new type conforms to `com.netscape.javascript-source`, `public.script`, and `public.source-code`, and
- claim `net.paradigmx.commonjs-source` directly in `QLSupportedContentTypes`.

This is a more complete experiment than the earlier imported-only approach because it gives LaunchServices a stable product-owned identifier instead of asking the OS to merge `cjs` into an existing global JavaScript type.

This experiment succeeded on the current machine:

- `UTType(filenameExtension: "cjs") == net.paradigmx.commonjs-source`
- the candidate set for `cjs` is now `["net.paradigmx.commonjs-source"]`
- a real `.cjs` file resolves to `net.paradigmx.commonjs-source`
- Finder reports the kind string `CommonJS Source`
- `qlmanage -p` for a `.cjs` file launches `net.paradigmx.FreeLook.QuickLookExtension`

The practical conclusion is that a product-owned exported UTI is a viable fix when a developer-oriented extension otherwise falls back to a useless `dyn.*` type.

### Bundle placement follow-up

The next control experiment moved the CommonJS and Markdown type declarations back from the host app bundle into `QuickLookExtension/Info.plist`.

That experiment also succeeded on the current machine:

- `UTType(filenameExtension: "cjs")` remained `net.paradigmx.commonjs-source`
- the candidate set for `cjs` remained `["net.paradigmx.commonjs-source"]`
- a real `.cjs` file still resolved to `net.paradigmx.commonjs-source`
- Finder still reported `CommonJS Source`
- `qlmanage -p` still launched `net.paradigmx.FreeLook.QuickLookExtension`

So the earlier "host app only" inference was too strong. At least for this project and this OS state, the extension bundle itself is sufficient for the tested file-type registration surface, including the product-owned CommonJS type and the Markdown declarations.

### Negative control: cache-versus-causality check

Because the bundle-placement follow-up reused the same product-owned CommonJS identifier, cache persistence was a reasonable concern. A negative-control experiment therefore removed the CommonJS declarations from both the app and the extension and rebuilt the project before re-probing the system state.

That negative control reverted the machine to the broken behavior:

- `UTType(filenameExtension: "cjs")` fell back to `dyn.ah62d4rv4ge80g4xx`
- the candidate set for `cjs` collapsed back to a dynamic identifier
- a real `.cjs` file resolved to the same `dyn.*` type
- Finder reported the generic kind string `Document`

After restoring the product-owned CommonJS declaration in `QuickLookExtension/Info.plist`, the machine returned to:

- `UTType(filenameExtension: "cjs") == net.paradigmx.commonjs-source`
- a real `.cjs` file resolving to `net.paradigmx.commonjs-source`
- Finder reporting `CommonJS Source`
- `qlmanage -p /tmp/freelook_probe.cjs` launching `net.paradigmx.FreeLook.QuickLookExtension`

This rules out the simplest "the result only survived because of stale LaunchServices cache" explanation. On the current machine, the CommonJS declaration is causally responsible for the observed routing change.

## FreeLook v1.0 baseline whitelist

The current v1.0 `QLSupportedContentTypes` baseline is:

- `public.source-code`
- `public.c-source`
- `public.c-header`
- `public.objective-c-source`
- `public.objective-c-plus-plus-source`
- `public.c-plus-plus-source`
- `public.swift-source`
- `public.python-script`
- `net.paradigmx.commonjs-source`
- `com.netscape.javascript-source`
- `public.typescript`
- `com.microsoft.typescript`
- `org.typescriptlang.typescript`
- `public.css`
- `org.w3.css`
- `public.html`
- `public.shell-script`
- `public.zsh-script`
- `public.bash-script`
- `public.ruby-script`
- `net.daringfireball.markdown`
- `io.typora.markdown`
- `net.ia.markdown`
- `public.json`
- `public.xml`

This list should be treated as the baseline validation surface for FreeLook v1.0. Future registration work should begin by validating this whitelist against real files and real system `UTType` resolution behavior before expanding it.

## Useful probes

No dedicated repo-owned diagnostic script exists yet. The following commands were used during the investigation and are worth keeping around.

### 1. Preferred type for an extension

```shell
swift -e 'import UniformTypeIdentifiers; print(UTType(filenameExtension: "md")?.identifier ?? "nil")'
```

### 2. All candidate types for an extension

```shell
swift -e 'import UniformTypeIdentifiers; print(UTType.types(tag: "md", tagClass: .filenameExtension, conformingTo: nil).map{$0.identifier}.sorted())'
```

### 3. Resolved type for a specific file URL

```shell
swift -e 'import Foundation; import UniformTypeIdentifiers; let url = URL(fileURLWithPath: "/path/to/file.md"); let values = try url.resourceValues(forKeys: [.contentTypeKey, .localizedTypeDescriptionKey]); print(values.contentType?.identifier ?? "nil"); print(values.localizedTypeDescription ?? "nil")'
```

### 4. Inspect extension or app bundle declarations

```shell
plutil -p /Applications/Typora.app/Contents/Info.plist
plutil -p /Applications/TeX/TeXShop.app/Contents/Info.plist
plutil -p /Users/neo/Library/Developer/Xcode/DerivedData/.../QuickLookExtension.appex/Contents/Info.plist
```

### 5. Search installed bundles for a suspicious type identifier

```shell
rg -n --glob 'Info.plist' 'com\.unknown\.md' /Applications /System/Applications /Library /Users/neo/Applications 2>/dev/null
```

### 6. Inspect LaunchServices handler preferences

```shell
defaults read ~/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers
```

A more readable form:

```shell
defaults export ~/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure - 2>/dev/null | plutil -convert json -o - - | ruby -rjson -e 'data=JSON.parse(STDIN.read); (data["LSHandlers"]||[]).each_with_index{|h,i| puts "#{i}\t#{h}" if h["LSHandlerContentType"]=="net.daringfireball.markdown" || h["LSHandlerContentType"]=="com.unknown.md" }'
```

### 7. Inspect the LaunchServices registration database

```shell
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -dump | rg -n -C8 'net\.daringfireball\.markdown|com\.unknown\.md|Typora|TeXShop'
```

### 8. Force Quick Look to use a specific type

```shell
qlmanage -c net.daringfireball.markdown -p /path/to/file.md
```

This is useful for separating:

- "the file was resolved to the wrong type" from
- "the file resolved to the right type but Quick Look still chose another provider"

### 9. Observe the actual preview provider chosen

```shell
/usr/bin/log show --last 1m --style compact --predicate '(process == "QuickLookExtension" OR process == "qlmanage" OR process == "QLPreviewGenerationExtension" OR eventMessage CONTAINS[c] "QuickLookExtension" OR eventMessage CONTAINS[c] "QLPreviewGenerationExtension")'
```

### 10. Reset Quick Look caches

```shell
qlmanage -r
qlmanage -r cache
```

## Cleanup actions used locally

### Garbage-collect LaunchServices

```shell
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -gc
```

### Remove a stale user-level handler preference

Example from the Markdown investigation:

```shell
plutil -remove LSHandlers.281 ~/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist
```

Do not reuse an index blindly. Recompute it from the readable JSON export first.

### Full LaunchServices reset

```shell
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -delete
```

Apple's own help text warns that a reboot is required after deleting the database. Use this only when incremental cleanup is not enough.

### Local cleanup status

On 2026-03-16, after incremental cleanup was not enough to fully remove stale candidate identifiers from observation commands, the following reset was executed on the current development machine:

```shell
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -delete
qlmanage -r
qlmanage -r cache
```

After `lsregister -delete`, LaunchServices is in a "reboot required" state. Any observations collected before the reboot should not be treated as the final post-cleanup baseline.

## Open questions

- Apple documents preferred type lookup but not a sufficiently precise tie-breaking algorithm for competing `UTType` claims.
- The presence of a candidate in `UTType.types(tag:)` does not guarantee that it is still sourced from a live bundle; stale candidates may survive longer than the currently effective preferred type.
- Some identifiers in the current `QLSupportedContentTypes` list, such as `public.typescript-source`, should be revalidated against the current OS before they are treated as stable.
