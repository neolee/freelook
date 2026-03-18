//
//  UTIMapper.swift
//  QuickLookExtension
//
//  Created by Codex on 2026/3/16.
//

import UniformTypeIdentifiers

enum UTIMapper {
    private static let markdownTypes = supportedTypes(
        "net.daringfireball.markdown"
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
    private static let rustTypes = supportedTypes(
        "org.rust-lang.rust"
    )
    private static let goTypes = supportedTypes(
        "org.golang.golang"
    )
    private static let javaTypes = supportedTypes(
        "com.sun.java-source"
    )
    private static let haskellTypes = supportedTypes(
        "org.haskell.haskell"
    )
    private static let kotlinTypes = supportedTypes(
        "org.kotlinlang.source"
    )
    private static let csharpTypes = supportedTypes(
        "com.microsoft.c-sharp"
    )
    private static let phpTypes = supportedTypes(
        "public.php-script"
    )
    private static let luaTypes = supportedTypes(
        "public.lua-source",
        "org.lua.lua"
    )
    private static let scalaTypes = supportedTypes(
        "org.scala-lang.scala",
        "net.paradigmx.scala-script"
    )
    private static let clojureTypes = supportedTypes(
        "net.paradigmx.clojure-source",
        "org.cloture.cloture",
        "org.clojure.script"
    )
    private static let ednTypes = supportedTypes(
        "net.paradigmx.edn-document"
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
    private static let propertyListType = UTType("com.apple.property-list")
    private static let xmlPropertyListType = UTType("com.apple.xml-property-list")
    private static let entitlementsPropertyListType = UTType("com.apple.xcode.entitlements-property-list")
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

        if contentType.conforms(to: .xml)
            || matches(contentType, anyOf: [propertyListType, xmlPropertyListType, entitlementsPropertyListType]) {
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

        if matches(contentType, anyOf: rustTypes) {
            return "rust"
        }

        if matches(contentType, anyOf: goTypes) {
            return "go"
        }

        if matches(contentType, anyOf: javaTypes) {
            return "java"
        }

        if matches(contentType, anyOf: haskellTypes) {
            return "haskell"
        }

        if matches(contentType, anyOf: kotlinTypes) {
            return "kotlin"
        }

        if matches(contentType, anyOf: csharpTypes) {
            return "csharp"
        }

        if matches(contentType, anyOf: phpTypes) {
            return "php"
        }

        if matches(contentType, anyOf: luaTypes) {
            return "lua"
        }

        if matches(contentType, anyOf: scalaTypes) {
            return "scala"
        }

        if matches(contentType, anyOf: clojureTypes) {
            return "clojure"
        }

        if matches(contentType, anyOf: ednTypes) {
            return "clojure"
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
