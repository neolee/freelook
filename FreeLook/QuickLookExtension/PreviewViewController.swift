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
        let typeIdentifier = contentType?.identifier ?? "unknown"

        do {
            let preview = try PreviewFileLoader.loadPreview(for: url)
            let themeSnapshot = loadThemeSnapshot()

            await MainActor.run {
                loadPreviewHTML(
                    fileName: url.lastPathComponent,
                    typeIdentifier: typeIdentifier,
                    languageIdentifier: languageIdentifier,
                    preview: preview,
                    lightTheme: themeSnapshot.lightTheme,
                    darkTheme: themeSnapshot.darkTheme
                )
            }
        } catch {
            await MainActor.run {
                loadStateHTML(title: url.lastPathComponent, body: error.localizedDescription)
            }
        }
    }

    private func loadStateHTML(title: String, body: String) {
        let html = renderTemplate(
            pageTitle: title,
            bodyClass: .state,
            eyebrow: "",
            title: title,
            lead: "<p class=\"preview-lead\">\(escapeHTML(body))</p>",
            notice: "",
            content: "",
            meta: ""
        )

        loadRenderedHTML(html)
    }

    private func loadPreviewHTML(
        fileName: String,
        typeIdentifier: String,
        languageIdentifier: String,
        preview: PreviewFileLoadResult,
        lightTheme: String,
        darkTheme: String
    ) {
        let truncationNotice = preview.didTruncate
            ? "<div class=\"preview-notice\">Preview truncated to the first 500 KB.</div>"
            : ""
        let lead = """
        <p class="preview-lead">
          FreeLook decoded this preview as <span class="preview-inline-code">\(escapeHTML(preview.encodingName))</span>
          and resolved the file type to <span class="preview-inline-code">\(escapeHTML(languageIdentifier))</span>.
        </p>
        """

        let content = """
        <pre class="preview-codeblock"><code>\(escapeHTML(preview.content))</code></pre>
        """

        let meta = """
        <footer class="preview-meta">
          <div class="preview-meta-row"><span class="preview-meta-label">File</span><code>\(escapeHTML(fileName))</code></div>
          <div class="preview-meta-row"><span class="preview-meta-label">UTType</span><code>\(escapeHTML(typeIdentifier))</code></div>
          <div class="preview-meta-row"><span class="preview-meta-label">Light Theme</span><code>\(escapeHTML(lightTheme))</code></div>
          <div class="preview-meta-row"><span class="preview-meta-label">Dark Theme</span><code>\(escapeHTML(darkTheme))</code></div>
          <div class="preview-meta-row"><span class="preview-meta-label">Truncated</span><code>\(preview.didTruncate ? "yes (first 500 KB)" : "no")</code></div>
        </footer>
        """

        let html = renderTemplate(
            pageTitle: fileName,
            bodyClass: .preview,
            eyebrow: "<p class=\"preview-eyebrow\">FreeLook Preview</p>",
            title: fileName,
            lead: lead,
            notice: truncationNotice,
            content: content,
            meta: meta
        )

        loadRenderedHTML(html)
    }

    private func renderTemplate(
        pageTitle: String,
        bodyClass: BodyClass,
        eyebrow: String,
        title: String,
        lead: String,
        notice: String,
        content: String,
        meta: String
    ) -> String {
        guard var template = loadTemplate(named: "template", withExtension: "html") else {
            return """
            <!doctype html>
            <html lang="en">
            <body>
              <h1>\(escapeHTML(pageTitle))</h1>
              \(content)
            </body>
            </html>
            """
        }

        let replacements = [
            "{{PAGE_TITLE}}": escapeHTML(pageTitle),
            "{{BODY_CLASS}}": bodyClass.rawValue,
            "{{EYEBROW}}": eyebrow,
            "{{TITLE}}": escapeHTML(title),
            "{{LEAD}}": lead,
            "{{NOTICE}}": notice,
            "{{CONTENT}}": content,
            "{{META}}": meta,
        ]

        for (token, value) in replacements {
            template = template.replacingOccurrences(of: token, with: value)
        }

        return template
    }

    private func loadRenderedHTML(_ html: String) {
        webView.loadHTMLString(html, baseURL: resourcesBaseURL())
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

    private func loadThemeSnapshot() -> (lightTheme: String, darkTheme: String) {
        let defaults = SharedPreviewSettings.userDefaults()
        let lightTheme = defaults.string(forKey: SharedPreviewSettings.lightThemeKey) ?? SharedPreviewSettings.defaultLightTheme
        let darkTheme = defaults.string(forKey: SharedPreviewSettings.darkThemeKey) ?? SharedPreviewSettings.defaultDarkTheme
        return (lightTheme, darkTheme)
    }

    private func escapeHTML(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
