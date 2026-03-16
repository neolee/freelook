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
        let contentType = UTType("net.daringfireball.markdown")
        #expect(UTIMapper.languageIdentifier(for: contentType) == "markdown")
    }

    @Test func mapsAlternateMarkdownUTIs() {
        #expect(UTIMapper.languageIdentifier(for: UTType("io.typora.markdown")) == "markdown")
        #expect(UTIMapper.languageIdentifier(for: UTType("net.ia.markdown")) == "markdown")
    }

    @Test func mapsJSON() {
        #expect(UTIMapper.languageIdentifier(for: .json) == "json")
    }

    @Test func mapsXML() {
        #expect(UTIMapper.languageIdentifier(for: .xml) == "xml")
    }

    @Test func mapsSwift() {
        let contentType = UTType("public.swift-source")
        #expect(UTIMapper.languageIdentifier(for: contentType) == "swift")
    }

    @Test func mapsPython() {
        let contentType = UTType("public.python-script")
        #expect(UTIMapper.languageIdentifier(for: contentType) == "python")
    }

    @Test func mapsJavaScript() {
        let contentType = UTType("com.netscape.javascript-source")
        #expect(UTIMapper.languageIdentifier(for: contentType) == "javascript")
        #expect(UTIMapper.languageIdentifier(for: UTType("net.paradigmx.commonjs-source")) == "javascript")
    }

    @Test func mapsTypeScript() {
        #expect(UTIMapper.languageIdentifier(for: UTType("public.typescript")) == "typescript")
        #expect(UTIMapper.languageIdentifier(for: UTType("com.microsoft.typescript")) == "typescript")
    }

    @Test func mapsShellScript() {
        let contentType = UTType("public.shell-script")
        #expect(UTIMapper.languageIdentifier(for: contentType) == "bash")
    }

    @Test func mapsShellSubtypes() {
        #expect(UTIMapper.languageIdentifier(for: UTType("public.zsh-script")) == "bash")
        #expect(UTIMapper.languageIdentifier(for: UTType("public.bash-script")) == "bash")
    }

    @Test func mapsAlternateCSSUTIs() {
        #expect(UTIMapper.languageIdentifier(for: UTType("org.w3.css")) == "css")
    }

    @Test func mapsGenericSourceCodeToText() {
        let contentType = UTType("public.source-code")
        #expect(UTIMapper.languageIdentifier(for: contentType) == "text")
        #expect(UTIMapper.languageIdentifier(for: UTType("public.c-source")) == "text")
    }

    @Test func mapsUnknownTypesToText() {
        let contentType = UTType.jpeg
        #expect(UTIMapper.languageIdentifier(for: contentType) == "text")
        #expect(UTIMapper.languageIdentifier(for: nil) == "text")
    }
}
