# FreeLook — File Type Support Matrix

This document defines the planned v1.0 file-type surface for FreeLook and the acceptance rules for adding each type.

Keep detailed `LaunchServices` and `UTType` investigation notes in [`docs/uti.md`](/Users/neo/Code/ML/freelook/docs/uti.md). This document is the product-facing support matrix and implementation checklist.

---

## Goals

FreeLook should provide a strong v1.0 preview surface for developer-oriented files:

- readable and visually consistent previews,
- correct syntax highlighting or format-specific rendering,
- minimal and semantically correct Quick Look registration,
- predictable maintenance cost after release.

The product does not need to claim every possible extension or every machine-specific identifier. It should claim the types that are semantically correct, materially useful, and realistically maintainable.

---

## Current Stable Baseline

These types are already part of the validated baseline:

- Markdown
- JSON
- XML
- Property List
- Entitlements
- Swift
- JavaScript
- Common-JS (`cjs`)
- TypeScript
- Python
- Shell script
- Ruby
- HTML
- CSS
- generic source code fallback as plain text

This document covers the next expansion step for v1.0.

---

## v1.0 Expansion Tiers

### Tier 1: Priority Languages

These should be implemented first.

| Type | Shiki lang | Common extensions | Notes |
|---|---|---|---|
| Rust | `rust` | `.rs` | Strong v1.0 target |
| Go | `go` | `.go` | Strong v1.0 target |
| Java | `java` | `.java` | Strong v1.0 target |
| Haskell | `haskell` | `.hs`, `.lhs` | Worth supporting even if `UTType` handling needs investigation |
| Clojure | `clojure` | `.clj`, `.cljs`, `.cljc`, `.edn` | FreeLook defines `net.paradigmx.clojure-source` for source files and `net.paradigmx.edn-document` for EDN; source files work on the current machine, while `.edn` remains blocked by the polluted third-party `com.adobe.edn` path |

### Tier 2: Secondary Mainstream Languages

These should follow after Tier 1.

| Type | Shiki lang | Common extensions | Notes |
|---|---|---|---|
| Kotlin | `kotlin` | `.kt`, `.kts` | Both currently resolve to `org.kotlinlang.source` on the current machine |
| C# | `csharp` | `.cs` | Mainstream and worth shipping in 1.0 |
| PHP | `php` | `.php`, `.phtml` | Start with `.php`; widen only if real routing data justifies more |
| Lua | `lua` | `.lua` | Current machine exposes both `public.lua-source` and `org.lua.lua`; support both |
| Scala | `scala` | `.scala`, `.sc` | Support `.scala` via `org.scala-lang.scala`; support `.sc` via product-defined `net.paradigmx.scala-script` |

### Tier 3: Developer Config and Build Files

These are not all “programming languages” in the narrow sense, but they fit FreeLook’s value proposition and are worth targeting for v1.0 if the implementation cost stays low.

| Type | Shiki lang | Common extensions / filenames | Notes |
|---|---|---|---|
| YAML | `yaml` | `.yml`, `.yaml` | Support `public.yaml` and `org.yaml.yaml` |
| TOML | `toml` | `.toml`, `.cfg`, `.config` | Current macOS resolves these to `public.toml`; keep compatibility with legacy `io.toml` |
| Emacs Lisp | `elisp` | `.el` | Support `org.gnu.emacs-lisp`; also claim `com.macromates.textmate.lisp` as the current-machine compatibility case, with filename-based disambiguation because that UTI also covers non-Emacs Lisp files |
| SQL | `sql` | `.sql` | Support `org.iso.sql`; also claim `com.sequel-ace.sequel-ace.sql` as a compatibility case on the current machine |
| Dockerfile | `dockerfile` | `Dockerfile` | Support via product-defined `net.paradigmx.dockerfile`, plus bounded fallback entry points for filename-only routing |
| Makefile | `makefile` | `Makefile` | Support `public.make-source` |
| CMake | `cmake` | `CMakeLists.txt`, `.cmake` | `.cmake` is supported; `CMakeLists.txt` still falls back to the system plain-text path on the current machine |

---

## Acceptance Rules

Every new type added to FreeLook should satisfy the same standards.

### 1. Renderer support must be real

- The type must map to a concrete Shiki language already present in the bundled renderer.
- If the file format needs non-highlight rendering behavior in the future, that behavior must be explicit and tested.
- Do not add a type to the product surface if the renderer can only handle it via generic `"text"` fallback unless that fallback is the intentional product behavior.

### 2. `UTType` routing must be investigated before registration changes

For each candidate extension or filename:

- inspect the preferred `UTType`,
- inspect the candidate type set when relevant,
- verify the actual `contentType` of a real sample file,
- prefer the system’s semantically correct type if it already exists.

Do not start by editing `Info.plist`. Start by understanding what the system is already doing.

### 3. Registration changes must be minimal and causal

- Prefer adding a type to `QLSupportedContentTypes` only when the semantic `UTType` is already good.
- Use `CFBundleDocumentTypes`, `UTImportedTypeDeclarations`, or `UTExportedTypeDeclarations` only when they create a concrete semantic entry point the system otherwise lacks.
- Prefer a product-owned exported UTI only when an important type otherwise resolves to a bad `dyn.*` path or similarly unusable route.
- Avoid speculative declarations that merely increase apparent coverage without clear causal value.

### 4. Polluted or low-quality identifiers must not be claimed

- Do not claim obviously wrong, machine-specific, or low-quality identifiers just because they appear in LaunchServices.
- If the system is polluted for a type on one machine, record the rejected identifier in [`docs/uti.md`](/Users/neo/Code/ML/freelook/docs/uti.md) rather than absorbing it into the product surface.

### 5. Every supported type must have a complete validation loop

Each new type requires all of the following:

- at least one committed sample file in [`samples/`](/Users/neo/Code/ML/freelook/samples),
- `UTIMapper` coverage in unit tests,
- renderer coverage where JS behavior changes,
- manual Quick Look verification on a real file,
- documentation update if the type required special routing decisions.

### 6. Filename-only special cases should be treated conservatively

Some useful developer files are routed more by filename than by extension, for example:

- `Dockerfile`
- `Makefile`
- `CMakeLists.txt`

These are worth supporting, but only if the actual system routing path is understood. They should not be forced into the product through broad or messy declarations without a validated route.

The current FreeLook fallback policy is:

- allow `public.content`, `public.unix-executable`, and `public.data` as bounded fallback entry points for developer-oriented text files,
- detect obvious binary content before rendering, and
- apply syntax highlighting for filename-driven special cases only through explicit filename fallback rules, not through speculative type claims.

Current consequences on the validated machine:

- `Dockerfile` now routes through the fallback path and renders correctly,
- `Makefile` already routes semantically through `public.make-source`,
- `CMakeLists.txt` still follows the system `public.plain-text` path and is not treated as a reliable FreeLook surface,
- generic `.txt` remains out of scope as a reliable product promise for the same reason.

---

## Implementation Checklist Per Type

Every type should go through this checklist.

1. Confirm that the Shiki language exists locally and can be bundled cleanly.
2. Probe the real `UTType` behavior for the target extension or filename on the current machine.
3. Decide whether existing system routing is sufficient or whether a minimal declaration change is required.
4. Add renderer language registration if needed.
5. Add or update `UTIMapper.swift`.
6. Update `QuickLookExtension/Info.plist` only if the routing investigation proved it necessary.
7. Add representative sample files to [`samples/`](/Users/neo/Code/ML/freelook/samples).
8. Add or update unit tests.
9. Run `./scripts/build`.
10. Run `./scripts/test`.
11. Manually verify the file in Quick Look.
12. Record any non-obvious routing rule or rejected identifier in [`docs/uti.md`](/Users/neo/Code/ML/freelook/docs/uti.md).

---

## Proposed Rollout Order

The v1.0 expansion should proceed in this order:

1. Tier 1
2. Tier 2
3. Tier 3

This order keeps the early work focused on high-value source languages before moving into filename-driven or config-oriented formats that are more likely to have routing quirks.

---

## Non-Goals for v1.0

These are explicitly out of scope unless later discussion changes the target:

- claiming generic plain text reliably across all systems,
- claiming every app-specific or polluted `UTType` observed on one machine,
- maximizing extension coverage at the expense of semantic correctness,
- adding snapshot tests or UI tests for each file type,
- supporting every language Shiki happens to ship.

FreeLook v1.0 should ship a curated, high-confidence developer-file surface, not an exhaustive catalog.
