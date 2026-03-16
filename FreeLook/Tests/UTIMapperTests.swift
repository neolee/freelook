//
//  UTIMapperTests.swift
//  Tests
//
//  Created by Codex on 2026/3/16.
//

import Testing
import UniformTypeIdentifiers

struct UTIMapperTests {
    @Test func mapsMarkdown() {
        let contentType = UTType(importedAs: "net.daringfireball.markdown")
        #expect(UTIMapper.languageIdentifier(for: contentType) == "markdown")
    }

    @Test func mapsJSON() {
        #expect(UTIMapper.languageIdentifier(for: .json) == "json")
    }

    @Test func mapsXML() {
        #expect(UTIMapper.languageIdentifier(for: .xml) == "xml")
    }

    @Test func mapsSwift() {
        let contentType = UTType(importedAs: "public.swift-source")
        #expect(UTIMapper.languageIdentifier(for: contentType) == "swift")
    }

    @Test func mapsPython() {
        let contentType = UTType(importedAs: "public.python-script")
        #expect(UTIMapper.languageIdentifier(for: contentType) == "python")
    }

    @Test func mapsJavaScript() {
        let contentType = UTType(importedAs: "com.netscape.javascript-source")
        #expect(UTIMapper.languageIdentifier(for: contentType) == "javascript")
    }

    @Test func mapsShellScript() {
        let contentType = UTType(importedAs: "public.shell-script")
        #expect(UTIMapper.languageIdentifier(for: contentType) == "bash")
    }

    @Test func mapsGenericSourceCodeToText() {
        let contentType = UTType(importedAs: "public.source-code")
        #expect(UTIMapper.languageIdentifier(for: contentType) == "text")
    }

    @Test func mapsUnknownTypesToText() {
        let contentType = UTType(importedAs: "com.example.random-data")
        #expect(UTIMapper.languageIdentifier(for: contentType) == "text")
        #expect(UTIMapper.languageIdentifier(for: nil) == "text")
    }
}
