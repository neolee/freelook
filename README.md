# FreeLook

FreeLook is a macOS Quick Look extension for developer files.

It replaces the default preview for many code, markup, and structured-text formats with a cleaner reading surface, syntax highlighting, Markdown rendering, and format-aware fallback behavior.

## Highlights

- Syntax-highlighted previews powered by Shiki themes.
- Markdown rendering with GitHub-flavored Markdown support and a GitHub-style prose baseline.
- JSON and XML pretty-printing before rendering.
- Shared light and dark theme preferences between the host app and the Quick Look extension.
- Configurable code font and code font size.
- Graceful handling for large files, invalid JSON/XML, and binary files.
- Support for common developer file types, including language source files and build/config files.

## Supported Files

FreeLook focuses on developer-oriented files.

Core support includes:

- Markdown with GFM extensions
- JSON, XML (including property lists and entitlement files)
- Swift, JavaScript, TypeScript, Python, shell, Ruby, HTML, CSS
- Rust, Go, Java, Haskell, Clojure
- Kotlin, C#, PHP, Lua, Scala (and Scala script)
- YAML, TOML, SQL
- `Dockerfile`, `Makefile`

The exact support surface is documented in:

- [`docs/file-types.md`](docs/file-types.md)
- [`docs/uti.md`](docs/uti.md)

## Usage

1. Download the latest [release](https://github.com/neolee/freelook/releases).
2. Install and launch `FreeLook`.
3. Choose your preferred light theme, dark theme, code font, and code font size.
4. In Finder, select a supported file and press the Space bar to open Quick Look.

## Current Limitations

- Generic plain-text files such as `.txt` are not a guaranteed FreeLook surface on all systems because the system plain-text Quick Look path often wins.
- Some files may not route to FreeLook on machines where Launch Services still resolves it to other third-party metadata. It's beyond the scope of FreeLook. But you can [create an issue](https://github.com/neolee/freelook/issues) if you met this kind of issues.
- Some files may not route to FreeLook on machines where Launch Services still resolves them to third-party metadata. This is beyond the scope of FreeLook, but you can [create an issue](https://github.com/neolee/freelook/issues) if you encounter this kind of issue.
- FreeLook is intentionally conservative about file-type registration. It prefers a small, semantically correct registration surface over speculative claims.

## License

FreeLook is released under the [MIT License](LICENSE.md).

It also relies on third-party open-source components, including:

- [Sparkle](https://sparkle-project.org/)
- [Shiki](https://shiki.style/)
- [markdown-it](https://github.com/markdown-it/markdown-it)
- [xml-formatter](https://github.com/chrisbottin/xml-formatter)
- [github-markdown-css](https://github.com/sindresorhus/github-markdown-css)
