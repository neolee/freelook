//
//  UTIMapper.swift
//  QuickLookExtension
//
//  Created by Codex on 2026/3/16.
//

import UniformTypeIdentifiers

enum UTIMapper {
    private static let markdownTypes = supportedTypes(
        "net.daringfireball.markdown",
        "io.typora.markdown",
        "net.ia.markdown"
    )
    private static let javaScriptTypes = supportedTypes(
        "net.paradigmx.commonjs-source",
        "com.netscape.javascript-source"
    )
    private static let typeScriptTypes = supportedTypes(
        "public.typescript",
        "com.microsoft.typescript",
        "org.typescriptlang.typescript"
    )
    private static let cssTypes = supportedTypes(
        "public.css",
        "org.w3.css"
    )
    private static let swiftType = UTType("public.swift-source")
    private static let pythonType = UTType("public.python-script")
    private static let shellScriptType = UTType("public.shell-script")
    private static let rubyScriptType = UTType("public.ruby-script")
    private static let htmlType = UTType("public.html")
    private static let sourceCodeType = UTType("public.source-code")

    static func languageIdentifier(for contentType: UTType?) -> String {
        guard let contentType else {
            return "text"
        }

        if matches(contentType, anyOf: markdownTypes) {
            return "markdown"
        }

        if contentType.conforms(to: .json) {
            return "json"
        }

        if contentType.conforms(to: .xml) {
            return "xml"
        }

        if matches(contentType, anyOf: [swiftType]) {
            return "swift"
        }

        if matches(contentType, anyOf: [pythonType]) {
            return "python"
        }

        if matches(contentType, anyOf: javaScriptTypes) {
            return "javascript"
        }

        if matches(contentType, anyOf: typeScriptTypes) {
            return "typescript"
        }

        if matches(contentType, anyOf: [shellScriptType]) {
            return "bash"
        }

        if matches(contentType, anyOf: [rubyScriptType]) {
            return "ruby"
        }

        if matches(contentType, anyOf: cssTypes) {
            return "css"
        }

        if matches(contentType, anyOf: [htmlType]) {
            return "html"
        }

        if matches(contentType, anyOf: [sourceCodeType]) {
            return "text"
        }

        return "text"
    }

    private static func supportedTypes(_ identifiers: String...) -> [UTType] {
        identifiers.compactMap(UTType.init)
    }

    private static func matches(_ contentType: UTType, anyOf types: [UTType?]) -> Bool {
        types.compactMap { $0 }.contains(where: { candidate in
            contentType == candidate || contentType.conforms(to: candidate)
        })
    }
}
