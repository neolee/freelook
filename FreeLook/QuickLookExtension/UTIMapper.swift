//
//  UTIMapper.swift
//  QuickLookExtension
//
//  Created by Codex on 2026/3/16.
//

import UniformTypeIdentifiers

enum UTIMapper {
    private static let markdownType = UTType(importedAs: "net.daringfireball.markdown")
    private static let swiftType = UTType(importedAs: "public.swift-source")
    private static let pythonType = UTType(importedAs: "public.python-script")
    private static let javaScriptType = UTType(importedAs: "com.netscape.javascript-source")
    private static let typeScriptType = UTType(importedAs: "public.typescript-source")
    private static let shellScriptType = UTType(importedAs: "public.shell-script")
    private static let rubyScriptType = UTType(importedAs: "public.ruby-script")
    private static let cssType = UTType(importedAs: "public.css")
    private static let htmlType = UTType(importedAs: "public.html")
    private static let sourceCodeType = UTType(importedAs: "public.source-code")

    static func languageIdentifier(for contentType: UTType?) -> String {
        guard let contentType else {
            return "text"
        }

        if contentType.conforms(to: markdownType) {
            return "markdown"
        }

        if contentType.conforms(to: .json) {
            return "json"
        }

        if contentType.conforms(to: .xml) {
            return "xml"
        }

        if contentType.conforms(to: swiftType) {
            return "swift"
        }

        if contentType.conforms(to: pythonType) {
            return "python"
        }

        if contentType.conforms(to: javaScriptType) {
            return "javascript"
        }

        if contentType.conforms(to: typeScriptType) {
            return "typescript"
        }

        if contentType.conforms(to: shellScriptType) {
            return "bash"
        }

        if contentType.conforms(to: rubyScriptType) {
            return "ruby"
        }

        if contentType.conforms(to: cssType) {
            return "css"
        }

        if contentType.conforms(to: htmlType) {
            return "html"
        }

        if contentType.conforms(to: sourceCodeType) {
            return "text"
        }

        return "text"
    }
}
