//
//  PreviewViewController.swift
//  QuickLookExtension
//
//  Created by Neo on 2026/3/16.
//

import AppKit
import Foundation
import Quartz
import WebKit

final class PreviewViewController: NSViewController, QLPreviewingController {
    private enum BodyClass: String {
        case preview = "preview-screen"
        case state = "state-screen"
    }

    private lazy var webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.setValue(false, forKey: "drawsBackground")
        return webView
    }()

    override func loadView() {
        view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadStateHTML(title: "FreeLook", body: "Loading preview...")
    }

    func preparePreviewOfFile(at url: URL) async throws {
        let appearanceSnapshot = loadAppearanceSnapshot()

        await MainActor.run {
            applyPreviewSurface(
                previewAppearanceMode: appearanceSnapshot.previewAppearanceMode,
                lightTheme: appearanceSnapshot.lightTheme,
                darkTheme: appearanceSnapshot.darkTheme
            )
        }

        let resourceValues = try url.resourceValues(forKeys: [.contentTypeKey])
        let contentType = resourceValues.contentType
        let languageIdentifier = UTIMapper.languageIdentifier(for: contentType, fileName: url.lastPathComponent)

        do {
            let preview = try FileLoader.loadPreview(for: url)

            await MainActor.run {
                loadPreviewHTML(
                    fileURL: url,
                    fileName: url.lastPathComponent,
                    languageIdentifier: languageIdentifier,
                    preview: preview,
                    previewAppearanceMode: appearanceSnapshot.previewAppearanceMode,
                    lightTheme: appearanceSnapshot.lightTheme,
                    darkTheme: appearanceSnapshot.darkTheme,
                    codeFontName: appearanceSnapshot.codeFontName,
                    codeFontSize: appearanceSnapshot.codeFontSize
                )
            }
        } catch FileLoaderError.binaryContent {
            await MainActor.run {
                loadPreviewNoticeHTML(
                    fileURL: url,
                    fileName: url.lastPathComponent,
                    notice: "Binary file. Text preview is unavailable.",
                    previewAppearanceMode: appearanceSnapshot.previewAppearanceMode,
                    lightTheme: appearanceSnapshot.lightTheme,
                    darkTheme: appearanceSnapshot.darkTheme,
                    codeFontName: appearanceSnapshot.codeFontName,
                    codeFontSize: appearanceSnapshot.codeFontSize
                )
            }
        } catch {
            await MainActor.run {
                loadStateHTML(title: url.lastPathComponent, body: error.localizedDescription)
            }
        }
    }

    private func loadStateHTML(title: String, body: String) {
        let appearanceSnapshot = loadAppearanceSnapshot()
        let content = """
        <section class="state-panel" role="status" aria-live="polite">
          <p class="state-title">\(escapeHTML(title))</p>
          <p class="state-copy">\(escapeHTML(body))</p>
        </section>
        """

        let html = renderTemplate(
            pageTitle: title,
            bodyClass: .state,
            bodyAppearance: previewAppearanceToken(for: appearanceSnapshot.previewAppearanceMode),
            bodyStyle: makeBodyStyle(
                codeFontName: appearanceSnapshot.codeFontName,
                codeFontSize: appearanceSnapshot.codeFontSize,
                previewAppearanceMode: appearanceSnapshot.previewAppearanceMode,
                lightTheme: appearanceSnapshot.lightTheme,
                darkTheme: appearanceSnapshot.darkTheme
            ),
            notice: "",
            content: content
        )

        applyPreviewSurface(
            previewAppearanceMode: appearanceSnapshot.previewAppearanceMode,
            lightTheme: appearanceSnapshot.lightTheme,
            darkTheme: appearanceSnapshot.darkTheme
        )
        loadRenderedHTML(html, baseURL: resourcesBaseURL())
    }

    private func loadPreviewHTML(
        fileURL: URL,
        fileName: String,
        languageIdentifier: String,
        preview: FileLoadResult,
        previewAppearanceMode: String,
        lightTheme: String,
        darkTheme: String,
        codeFontName: String,
        codeFontSize: Int
    ) {
        let truncationNotice = preview.didTruncate
            ? "<div class=\"preview-notice\">Large file. Previewing only the first 500 KB.</div>"
            : ""
        let hasInitialNotice = preview.didTruncate ? "" : " hidden"
        let renderPayload = makeRenderPayloadJSON(
            content: preview.content,
            languageIdentifier: languageIdentifier,
            lightTheme: lightTheme,
            darkTheme: darkTheme
        )

        let content = """
        <div id="preview-notice-stack" class="preview-notice-stack" aria-live="polite"\(hasInitialNotice)>
          \(truncationNotice)
          <div id="preview-renderer-notice" class="preview-notice" hidden></div>
          <div id="preview-runtime-notice" class="preview-notice" hidden></div>
        </div>
        <div id="preview-root" class="preview-render-root" aria-live="polite"></div>
        <script id="preview-payload" type="application/json">\(renderPayload)</script>
        <script>
        (async () => {
          const root = document.getElementById("preview-root");
          const noticeStack = document.getElementById("preview-notice-stack");
          const payloadElement = document.getElementById("preview-payload");
          const rendererNotice = document.getElementById("preview-renderer-notice");
          const runtimeNotice = document.getElementById("preview-runtime-notice");

          const syncNoticeStack = () => {
            if (!noticeStack) {
              return;
            }

            const hasVisibleNotice = Array.from(noticeStack.querySelectorAll(".preview-notice"))
              .some((element) => !element.hidden);
            noticeStack.hidden = !hasVisibleNotice;
          };

          if (!root || !payloadElement) {
            return;
          }

          try {
            const payload = JSON.parse(payloadElement.textContent || "{}");
            const result = await window.FreeLook.render(payload);
            root.innerHTML = result?.html ?? "";

            if (rendererNotice) {
              const notice = result?.notice?.trim();
              rendererNotice.hidden = !notice;
              rendererNotice.textContent = notice ?? "";
            }

            syncNoticeStack();

            const surface = result?.surface;
            if (surface?.lightBackground) {
              document.body.style.setProperty("--preview-light-surface-bg", surface.lightBackground);
            }

            if (surface?.lightForeground) {
              document.body.style.setProperty("--preview-light-surface-fg", surface.lightForeground);
            }

            if (surface?.darkBackground) {
              document.body.style.setProperty("--preview-dark-surface-bg", surface.darkBackground);
            }

            if (surface?.darkForeground) {
              document.body.style.setProperty("--preview-dark-surface-fg", surface.darkForeground);
            }
          } catch (error) {
            if (runtimeNotice) {
              runtimeNotice.hidden = false;
              runtimeNotice.textContent = error?.message ?? String(error);
            }

            syncNoticeStack();
          }
        })();
        </script>
        """

        let html = renderTemplate(
            pageTitle: fileName,
            bodyClass: .preview,
            bodyAppearance: previewAppearanceToken(for: previewAppearanceMode),
            bodyStyle: makeBodyStyle(
                codeFontName: codeFontName,
                codeFontSize: codeFontSize,
                previewAppearanceMode: previewAppearanceMode,
                lightTheme: lightTheme,
                darkTheme: darkTheme
            ),
            notice: "",
            content: content
        )

        applyPreviewSurface(
            previewAppearanceMode: previewAppearanceMode,
            lightTheme: lightTheme,
            darkTheme: darkTheme
        )
        loadRenderedHTML(html, baseURL: previewBaseURL(for: fileURL))
    }

    private func loadPreviewNoticeHTML(
        fileURL: URL,
        fileName: String,
        notice: String,
        previewAppearanceMode: String,
        lightTheme: String,
        darkTheme: String,
        codeFontName: String,
        codeFontSize: Int
    ) {
        let content = """
        <div id="preview-notice-stack" class="preview-notice-stack" aria-live="polite">
          <div class="preview-notice">\(escapeHTML(notice))</div>
        </div>
        <div id="preview-root" class="preview-render-root" aria-live="polite"></div>
        """

        let html = renderTemplate(
            pageTitle: fileName,
            bodyClass: .preview,
            bodyAppearance: previewAppearanceToken(for: previewAppearanceMode),
            bodyStyle: makeBodyStyle(
                codeFontName: codeFontName,
                codeFontSize: codeFontSize,
                previewAppearanceMode: previewAppearanceMode,
                lightTheme: lightTheme,
                darkTheme: darkTheme
            ),
            notice: "",
            content: content
        )

        applyPreviewSurface(
            previewAppearanceMode: previewAppearanceMode,
            lightTheme: lightTheme,
            darkTheme: darkTheme
        )
        loadRenderedHTML(html, baseURL: previewBaseURL(for: fileURL))
    }

    private func renderTemplate(
        pageTitle: String,
        bodyClass: BodyClass,
        bodyAppearance: String,
        bodyStyle: String,
        notice: String,
        content: String
    ) -> String {
        guard var template = loadTemplate(named: "template", withExtension: "html") else {
            return """
            <!doctype html>
            <html lang="en">
            <body>
              \(content)
            </body>
            </html>
            """
        }

        let replacements = [
            "{{PAGE_TITLE}}": escapeHTML(pageTitle),
            "{{BODY_CLASS}}": bodyClass.rawValue,
            "{{BODY_APPEARANCE}}": escapeHTML(bodyAppearance),
            "{{BODY_STYLE}}": escapeHTML(bodyStyle),
            "{{MARKDOWN_STYLESHEET_URL}}": escapeHTML(resourceURLString(named: "github-markdown", withExtension: "css")),
            "{{STYLESHEET_URL}}": escapeHTML(resourceURLString(named: "styles", withExtension: "css")),
            "{{BUNDLE_SCRIPT_URL}}": escapeHTML(resourceURLString(named: "bundle", withExtension: "js")),
            "{{NOTICE}}": notice,
            "{{CONTENT}}": content,
        ]

        for (token, value) in replacements {
            template = template.replacingOccurrences(of: token, with: value)
        }

        return template
    }

    private func loadRenderedHTML(_ html: String, baseURL: URL?) {
        webView.loadHTMLString(html, baseURL: baseURL)
    }

    private func makeRenderPayloadJSON(
        content: String,
        languageIdentifier: String,
        lightTheme: String,
        darkTheme: String
    ) -> String {
        let payload: [String: String] = [
            "content": content,
            "lang": languageIdentifier,
            "lightTheme": lightTheme,
            "darkTheme": darkTheme,
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: payload, options: []),
              let json = String(data: data, encoding: .utf8) else {
            return "{}"
        }

        return json.replacingOccurrences(of: "</script", with: "<\\/script")
    }

    private func loadTemplate(named name: String, withExtension fileExtension: String) -> String? {
        guard let url = Bundle.main.url(forResource: name, withExtension: fileExtension),
              let template = try? String(contentsOf: url, encoding: .utf8) else {
            return nil
        }

        return template
    }

    private func resourcesBaseURL() -> URL? {
        Bundle.main.resourceURL
    }

    private func previewBaseURL(for fileURL: URL) -> URL {
        fileURL.deletingLastPathComponent()
    }

    private func resourceURLString(named name: String, withExtension fileExtension: String) -> String {
        Bundle.main.url(forResource: name, withExtension: fileExtension)?.absoluteString ?? ""
    }

    private func loadAppearanceSnapshot() -> (previewAppearanceMode: String, lightTheme: String, darkTheme: String, codeFontName: String, codeFontSize: Int) {
        let defaults = Settings.userDefaults()
        let previewAppearanceMode = Settings.normalizedPreviewAppearanceMode(
            defaults.string(forKey: Settings.previewAppearanceModeKey)
        )
        let lightTheme = Settings.normalizedLightTheme(
            defaults.string(forKey: Settings.lightThemeKey)
        )
        let darkTheme = Settings.normalizedDarkTheme(
            defaults.string(forKey: Settings.darkThemeKey)
        )
        let codeFontName = Settings.normalizedCodeFont(
            defaults.string(forKey: Settings.codeFontKey)
        )
        let codeFontSize = Settings.normalizedCodeFontSize(
            defaults.object(forKey: Settings.codeFontSizeKey)
        )

        return (previewAppearanceMode, lightTheme, darkTheme, codeFontName, codeFontSize)
    }

    private func makeBodyStyle(
        codeFontName: String,
        codeFontSize: Int,
        previewAppearanceMode: String,
        lightTheme: String,
        darkTheme: String
    ) -> String {
        let codeFontStack = Settings.codeFontStack(for: codeFontName)
        let lightSurface = Settings.lightThemeSurface(forDisplayName: lightTheme)
        let darkSurface = Settings.darkThemeSurface(forDisplayName: darkTheme)
        let activeSurface = Settings.previewSurface(
            previewAppearanceMode: previewAppearanceMode,
            lightTheme: lightTheme,
            darkTheme: darkTheme,
            effectiveAppearance: view.effectiveAppearance
        )

        var declarations = [
            "--preview-code-font: \(codeFontStack)",
            "--preview-code-font-size: \(codeFontSize)px",
        ]

        if let background = lightSurface.background {
            declarations.append("--preview-light-surface-bg: \(background)")
        }

        if let foreground = lightSurface.foreground {
            declarations.append("--preview-light-surface-fg: \(foreground)")
        }

        if let background = darkSurface.background {
            declarations.append("--preview-dark-surface-bg: \(background)")
        }

        if let foreground = darkSurface.foreground {
            declarations.append("--preview-dark-surface-fg: \(foreground)")
        }

        if let background = activeSurface.background {
            declarations.append("background: \(background)")
        }

        if let foreground = activeSurface.foreground {
            declarations.append("color: \(foreground)")
        }

        return declarations.joined(separator: "; ") + ";"
    }

    private func previewAppearanceToken(for mode: String) -> String {
        switch Settings.normalizedPreviewAppearanceMode(mode) {
        case "Always Light":
            return "light"
        case "Always Dark":
            return "dark"
        default:
            return "system"
        }
    }

    private func escapeHTML(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    private func applyPreviewSurface(
        previewAppearanceMode: String,
        lightTheme: String,
        darkTheme: String
    ) {
        let surface = Settings.previewSurface(
            previewAppearanceMode: previewAppearanceMode,
            lightTheme: lightTheme,
            darkTheme: darkTheme,
            effectiveAppearance: view.effectiveAppearance
        )

        guard let background = surface.background,
              let backgroundColor = NSColor(cssHexString: background) else {
            return
        }

        view.layer?.backgroundColor = backgroundColor.cgColor
        webView.underPageBackgroundColor = backgroundColor
    }
}

private extension NSColor {
    convenience init?(cssHexString: String) {
        let hex = cssHexString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard hex.first == "#" else {
            return nil
        }

        let normalized = String(hex.dropFirst())
        let expandedHex: String

        switch normalized.count {
        case 3:
            expandedHex = normalized.reduce(into: "") { partialResult, character in
                partialResult.append(character)
                partialResult.append(character)
            }
        case 6, 8:
            expandedHex = normalized
        default:
            return nil
        }

        guard let value = UInt64(expandedHex, radix: 16) else {
            return nil
        }

        let red: Double
        let green: Double
        let blue: Double
        let alpha: Double

        if expandedHex.count == 8 {
            red = Double((value & 0xFF00_0000) >> 24) / 255
            green = Double((value & 0x00FF_0000) >> 16) / 255
            blue = Double((value & 0x0000_FF00) >> 8) / 255
            alpha = Double(value & 0x0000_00FF) / 255
        } else {
            red = Double((value & 0xFF00_00) >> 16) / 255
            green = Double((value & 0x00FF_00) >> 8) / 255
            blue = Double(value & 0x0000_FF) / 255
            alpha = 1
        }

        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
