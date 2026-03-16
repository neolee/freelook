//
//  PreviewViewController.swift
//  QuickLookExtension
//
//  Created by Neo on 2026/3/16.
//

import AppKit
import Quartz
import WebKit

final class PreviewViewController: NSViewController, QLPreviewingController {
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
        loadStateHTML(title: "FreeLook", body: "Programmatic preview container is ready.")
    }

    func preparePreviewOfFile(at url: URL) async throws {
        let resourceValues = try url.resourceValues(forKeys: [.contentTypeKey])
        let contentType = resourceValues.contentType
        let languageIdentifier = UTIMapper.languageIdentifier(for: contentType)
        let typeIdentifier = contentType?.identifier ?? "unknown"

        await MainActor.run {
            loadPreviewHTML(
                fileName: url.lastPathComponent,
                typeIdentifier: typeIdentifier,
                languageIdentifier: languageIdentifier
            )
        }
    }

    private func loadStateHTML(title: String, body: String) {
        let html = """
        <!doctype html>
        <html lang="en">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <style>
            :root {
              color-scheme: light dark;
              font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif;
            }
            body {
              margin: 0;
              min-height: 100vh;
              display: grid;
              place-items: center;
              background:
                radial-gradient(circle at top left, rgba(76, 124, 255, 0.12), transparent 28%),
                linear-gradient(180deg, rgba(245, 247, 251, 1), rgba(235, 240, 246, 1));
              color: #1f2933;
            }
            @media (prefers-color-scheme: dark) {
              body {
                background:
                  radial-gradient(circle at top left, rgba(76, 124, 255, 0.18), transparent 30%),
                  linear-gradient(180deg, rgba(18, 24, 32, 1), rgba(12, 17, 24, 1));
                color: #e6edf5;
              }
              .card {
                background: rgba(22, 30, 39, 0.88);
                border-color: rgba(152, 166, 184, 0.18);
                box-shadow: 0 24px 60px rgba(0, 0, 0, 0.35);
              }
              .meta {
                color: #9fb0c3;
              }
              code {
                background: rgba(148, 163, 184, 0.14);
              }
            }
            .card {
              width: min(680px, calc(100vw - 48px));
              padding: 28px 30px;
              border-radius: 22px;
              background: rgba(255, 255, 255, 0.88);
              border: 1px solid rgba(31, 41, 51, 0.08);
              box-shadow: 0 20px 50px rgba(31, 41, 51, 0.12);
              backdrop-filter: blur(18px);
            }
            h1 {
              margin: 0 0 10px;
              font-size: 28px;
              line-height: 1.1;
            }
            p {
              margin: 0;
              font-size: 15px;
              line-height: 1.6;
            }
            .meta {
              margin-top: 18px;
              font-size: 13px;
              color: #52606d;
            }
            code {
              padding: 2px 8px;
              border-radius: 999px;
              background: rgba(15, 23, 42, 0.06);
              font-family: "SF Mono", "Menlo", monospace;
            }
          </style>
        </head>
        <body>
          <article class="card">
            <h1>\(escapeHTML(title))</h1>
            <p>\(escapeHTML(body))</p>
          </article>
        </body>
        </html>
        """

        webView.loadHTMLString(html, baseURL: nil)
    }

    private func loadPreviewHTML(fileName: String, typeIdentifier: String, languageIdentifier: String) {
        let html = """
        <!doctype html>
        <html lang="en">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <style>
            :root {
              color-scheme: light dark;
              font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif;
            }
            body {
              margin: 0;
              min-height: 100vh;
              display: grid;
              place-items: center;
              padding: 24px;
              background:
                radial-gradient(circle at top left, rgba(76, 124, 255, 0.14), transparent 24%),
                linear-gradient(180deg, rgba(244, 247, 251, 1), rgba(232, 238, 246, 1));
              color: #10212f;
            }
            @media (prefers-color-scheme: dark) {
              body {
                background:
                  radial-gradient(circle at top left, rgba(76, 124, 255, 0.2), transparent 26%),
                  linear-gradient(180deg, rgba(11, 16, 23, 1), rgba(15, 20, 28, 1));
                color: #edf2f7;
              }
              .card {
                background: rgba(19, 28, 36, 0.9);
                border-color: rgba(148, 163, 184, 0.18);
                box-shadow: 0 24px 64px rgba(0, 0, 0, 0.38);
              }
              .eyebrow {
                color: #8ab4ff;
              }
              .meta {
                color: #9db0c4;
              }
              code {
                background: rgba(148, 163, 184, 0.16);
              }
            }
            .card {
              width: min(760px, calc(100vw - 48px));
              padding: 30px 32px;
              border-radius: 24px;
              background: rgba(255, 255, 255, 0.9);
              border: 1px solid rgba(15, 23, 42, 0.08);
              box-shadow: 0 24px 60px rgba(15, 23, 42, 0.12);
              backdrop-filter: blur(18px);
            }
            .eyebrow {
              display: inline-block;
              margin-bottom: 14px;
              font-size: 12px;
              font-weight: 700;
              letter-spacing: 0.12em;
              text-transform: uppercase;
              color: #3662d8;
            }
            h1 {
              margin: 0 0 12px;
              font-size: 30px;
              line-height: 1.1;
            }
            p {
              margin: 0;
              font-size: 15px;
              line-height: 1.7;
            }
            .meta {
              margin-top: 20px;
              font-size: 13px;
              line-height: 1.7;
              color: #52606d;
            }
            code {
              padding: 2px 8px;
              border-radius: 999px;
              background: rgba(15, 23, 42, 0.06);
              font-family: "SF Mono", "Menlo", monospace;
            }
          </style>
        </head>
        <body>
          <article class="card">
            <div class="eyebrow">Phase 1.2 / 1.3</div>
            <h1>\(escapeHTML(fileName))</h1>
            <p>Phase 1 scaffold is active. <code>WKWebView</code> layout is live and the UTI mapping layer resolved this file to <code>\(escapeHTML(languageIdentifier))</code>.</p>
            <div class="meta">File: <code>\(escapeHTML(fileName))</code><br>UTType: <code>\(escapeHTML(typeIdentifier))</code></div>
          </article>
        </body>
        </html>
        """

        webView.loadHTMLString(html, baseURL: nil)
    }

    private func escapeHTML(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
