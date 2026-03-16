//
//  PreviewFileLoaderTests.swift
//  Tests
//
//  Created by Codex on 2026/3/17.
//

import Foundation
import Testing

struct PreviewFileLoaderTests {
    @Test func loadsUTF8Content() throws {
        let url = try temporaryFile(named: "utf8.swift", data: Data("print(\"FreeLook\")".utf8))

        let result = try PreviewFileLoader.loadPreview(for: url)

        #expect(result.content == "print(\"FreeLook\")")
        #expect(result.encodingName == "UTF-8")
        #expect(result.didTruncate == false)
    }

    @Test func fallsBackToLatin1() throws {
        let data = try #require("café".data(using: .isoLatin1))
        let url = try temporaryFile(named: "latin1.txt", data: data)

        let result = try PreviewFileLoader.loadPreview(for: url)

        #expect(result.content == "café")
        #expect(result.encodingName == "ISO Latin 1")
        #expect(result.didTruncate == false)
    }

    @Test func truncatesOversizedFiles() throws {
        let data = Data(repeating: 0x61, count: PreviewFileLoader.maximumPreviewBytes + 128)
        let url = try temporaryFile(named: "oversized.txt", data: data)

        let result = try PreviewFileLoader.loadPreview(for: url)

        #expect(result.didTruncate == true)
        #expect(result.encodingName == "UTF-8")
        #expect(result.content.count == PreviewFileLoader.maximumPreviewBytes)
        #expect(result.content.hasPrefix("aaaa"))
    }

    @Test func preservesUTF8WhenTruncationSplitsAMultibyteCharacter() throws {
        let source = String(repeating: "€", count: (PreviewFileLoader.maximumPreviewBytes / 3) + 1)
        let data = try #require(source.data(using: .utf8))
        let url = try temporaryFile(named: "oversized-utf8.txt", data: data)

        let result = try PreviewFileLoader.loadPreview(for: url)

        #expect(result.didTruncate == true)
        #expect(result.encodingName == "UTF-8")
        #expect(result.content.utf8.count <= PreviewFileLoader.maximumPreviewBytes)
        #expect(result.content == String(repeating: "€", count: PreviewFileLoader.maximumPreviewBytes / 3))
    }

    @Test func throwsForMissingFiles() {
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)

        #expect(throws: PreviewFileLoaderError.couldNotReadFile) {
            try PreviewFileLoader.loadPreview(for: url)
        }
    }

    private func temporaryFile(named fileName: String, data: Data) throws -> URL {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let fileURL = directory.appendingPathComponent(fileName)
        try data.write(to: fileURL)
        return fileURL
    }
}
