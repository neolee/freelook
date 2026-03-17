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
        let resourceValues = try url.resourceValues(forKeys: [.contentTypeKey])
        let contentType = resourceValues.contentType
        let languageIdentifier = UTIMapper.languageIdentifier(for: contentType)

        do {
            let preview = try FileLoader.loadPreview(for: url)
            let appearanceSnapshot = loadAppearanceSnapshot()

            await MainActor.run {
                loadPreviewHTML(
                    fileName: url.lastPathComponent,
                    languageIdentifier: languageIdentifier,
                    preview: preview,
                    previewAppearanceMode: appearanceSnapshot.previewAppearanceMode,
                    lightTheme: appearanceSnapshot.lightTheme,
                    darkTheme: appearanceSnapshot.darkTheme,
                    codeFont: appearanceSnapshot.codeFont,
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
        let content = """
        <section class="state-panel" role="status" aria-live="polite">
          <p class="state-title">\(escapeHTML(title))</p>
          <p class="state-copy">\(escapeHTML(body))</p>
        </section>
        """

        let html = renderTemplate(
            pageTitle: title,
            bodyClass: .state,
            bodyAppearance: "system",
            bodyStyle: "",
            notice: "",
            content: content
        )

        loadRenderedHTML(html)
    }

    private func loadPreviewHTML(
        fileName: String,
        languageIdentifier: String,
        preview: FileLoadResult,
        previewAppearanceMode: String,
        lightTheme: String,
        darkTheme: String,
        codeFont: String,
        codeFontSize: Int
    ) {
        let truncationNotice = preview.didTruncate
            ? "<div class=\"preview-notice\">Preview truncated to the first 500 KB.</div>"
            : ""

        let renderPayload = makeRenderPayloadJSON(
            content: preview.content,
            languageIdentifier: languageIdentifier,
            lightTheme: lightTheme,
            darkTheme: darkTheme
        )

        let content = """
        <div id="preview-root" class="preview-render-root" aria-live="polite"></div>
        <div id="preview-renderer-notice" class="preview-notice" hidden></div>
        <div id="preview-runtime-notice" class="preview-notice" hidden></div>
        <script id="preview-payload" type="application/json">\(renderPayload)</script>
        <script>
        (async () => {
          const root = document.getElementById("preview-root");
          const payloadElement = document.getElementById("preview-payload");
          const rendererNotice = document.getElementById("preview-renderer-notice");
          const runtimeNotice = document.getElementById("preview-runtime-notice");

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
          }
        })();
        </script>
        """

        let html = renderTemplate(
            pageTitle: fileName,
            bodyClass: .preview,
            bodyAppearance: previewAppearanceToken(for: previewAppearanceMode),
            bodyStyle: makeBodyStyle(codeFont: codeFont, codeFontSize: codeFontSize),
            notice: truncationNotice,
            content: content
        )

        loadRenderedHTML(html)
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
            "{{NOTICE}}": notice,
            "{{CONTENT}}": content,
        ]

        for (token, value) in replacements {
            template = template.replacingOccurrences(of: token, with: value)
        }

        return template
    }

    private func loadRenderedHTML(_ html: String) {
        webView.loadHTMLString(html, baseURL: resourcesBaseURL())
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

    private func loadAppearanceSnapshot() -> (previewAppearanceMode: String, lightTheme: String, darkTheme: String, codeFont: String, codeFontSize: Int) {
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
        let codeFont = Settings.normalizedCodeFont(
            defaults.string(forKey: Settings.codeFontKey)
        )
        let codeFontSize = Settings.normalizedCodeFontSize(
            defaults.object(forKey: Settings.codeFontSizeKey)
        )

        return (previewAppearanceMode, lightTheme, darkTheme, codeFont, codeFontSize)
    }

    private func makeBodyStyle(codeFont: String, codeFontSize: Int) -> String {
        let codeFontStack = Settings.codeFontStack(for: codeFont)
        return "--preview-code-font: \(codeFontStack); --preview-code-font-size: \(codeFontSize)px;"
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
}
