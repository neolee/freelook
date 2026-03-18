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

    @Test func mapsJSON() {
        #expect(UTIMapper.languageIdentifier(for: .json) == "json")
    }

    @Test func mapsXML() {
        #expect(UTIMapper.languageIdentifier(for: .xml) == "xml")
    }

    @Test func mapsPropertyListsAndEntitlementsToXML() {
        #expect(UTIMapper.languageIdentifier(for: UTType("com.apple.property-list")) == "xml")
        #expect(UTIMapper.languageIdentifier(for: UTType("com.apple.xml-property-list")) == "xml")
        #expect(UTIMapper.languageIdentifier(for: UTType("com.apple.xcode.entitlements-property-list")) == "xml")
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
        #expect(UTIMapper.languageIdentifier(for: UTType("com.netscape.javascript-source")) == "javascript")
        #expect(UTIMapper.languageIdentifier(for: UTType("net.paradigmx.commonjs-source")) == "javascript")
    }

    @Test func mapsTypeScript() {
        #expect(UTIMapper.languageIdentifier(for: UTType("public.typescript")) == "typescript")
        #expect(UTIMapper.languageIdentifier(for: UTType("com.microsoft.typescript")) == "typescript")
    }

    @Test func mapsRust() {
        #expect(UTIMapper.languageIdentifier(for: UTType("org.rust-lang.rust")) == "rust")
    }

    @Test func mapsGo() {
        #expect(UTIMapper.languageIdentifier(for: UTType("org.golang.golang")) == "go")
    }

    @Test func mapsJava() {
        #expect(UTIMapper.languageIdentifier(for: UTType("com.sun.java-source")) == "java")
    }

    @Test func mapsHaskell() {
        #expect(UTIMapper.languageIdentifier(for: UTType("org.haskell.haskell")) == "haskell")
    }

    @Test func mapsKotlin() {
        #expect(UTIMapper.languageIdentifier(for: UTType("org.kotlinlang.source")) == "kotlin")
    }

    @Test func mapsCSharp() {
        #expect(UTIMapper.languageIdentifier(for: UTType("com.microsoft.c-sharp")) == "csharp")
    }

    @Test func mapsPHP() {
        #expect(UTIMapper.languageIdentifier(for: UTType("public.php-script")) == "php")
    }

    @Test func mapsLua() {
        #expect(UTIMapper.languageIdentifier(for: UTType("public.lua-source")) == "lua")
        #expect(UTIMapper.languageIdentifier(for: UTType("org.lua.lua")) == "lua")
    }

    @Test func mapsScala() {
        #expect(UTIMapper.languageIdentifier(for: UTType("org.scala-lang.scala")) == "scala")
        #expect(UTIMapper.languageIdentifier(for: UTType("net.paradigmx.scala-script")) == "scala")
        #expect(UTIMapper.languageIdentifier(for: UTType("dyn.age81g22")) == "text")
    }

    @Test func mapsClojure() {
        #expect(UTIMapper.languageIdentifier(for: UTType("net.paradigmx.clojure-source")) == "clojure")
        #expect(UTIMapper.languageIdentifier(for: UTType("org.cloture.cloture")) == "clojure")
        if let clojureScriptType = UTType("org.clojure.script") {
            #expect(UTIMapper.languageIdentifier(for: clojureScriptType) == "clojure")
        }
        #expect(UTIMapper.languageIdentifier(for: UTType("net.paradigmx.edn-document")) == "clojure")
        #expect(UTIMapper.languageIdentifier(for: UTType("com.adobe.edn")) == "text")
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
        #expect(UTIMapper.languageIdentifier(for: .plainText) == "text")
        #expect(UTIMapper.languageIdentifier(for: nil) == "text")
    }
}
