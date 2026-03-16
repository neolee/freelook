//
//  PreviewFileLoader.swift
//  QuickLookExtension
//
//  Created by Codex on 2026/3/17.
//

import Foundation

struct PreviewFileLoadResult {
    let content: String
    let didTruncate: Bool
    let encodingName: String
}

enum PreviewFileLoaderError: LocalizedError {
    case couldNotReadFile
    case unsupportedEncoding

    var errorDescription: String? {
        switch self {
        case .couldNotReadFile:
            return "FreeLook could not read this file."
        case .unsupportedEncoding:
            return "FreeLook could not decode this file as UTF-8 or ISO Latin 1."
        }
    }
}

enum PreviewFileLoader {
    static let maximumPreviewBytes = 500 * 1024

    static func loadPreview(for url: URL) throws -> PreviewFileLoadResult {
        let handle: FileHandle

        do {
            handle = try FileHandle(forReadingFrom: url)
        } catch {
            throw PreviewFileLoaderError.couldNotReadFile
        }

        defer {
            try? handle.close()
        }

        guard let rawData = try handle.read(upToCount: maximumPreviewBytes + 1) else {
            throw PreviewFileLoaderError.couldNotReadFile
        }

        let didTruncate = rawData.count > maximumPreviewBytes
        let previewData = Data(didTruncate ? rawData.prefix(maximumPreviewBytes) : rawData)

        if let content = String(data: previewData, encoding: .utf8) {
            return PreviewFileLoadResult(content: content, didTruncate: didTruncate, encodingName: "UTF-8")
        }

        if didTruncate, let content = utf8ContentDroppingIncompleteTail(from: previewData) {
            return PreviewFileLoadResult(content: content, didTruncate: didTruncate, encodingName: "UTF-8")
        }

        if let content = String(data: previewData, encoding: .isoLatin1) {
            return PreviewFileLoadResult(content: content, didTruncate: didTruncate, encodingName: "ISO Latin 1")
        }

        throw PreviewFileLoaderError.unsupportedEncoding
    }

    private static func utf8ContentDroppingIncompleteTail(from data: Data) -> String? {
        guard data.count > 1 else {
            return nil
        }

        let tailLimit = min(3, data.count - 1)

        for droppedByteCount in 1...tailLimit {
            let candidate = data.dropLast(droppedByteCount)

            if let content = String(data: candidate, encoding: .utf8) {
                return content
            }
        }

        return nil
    }
}
