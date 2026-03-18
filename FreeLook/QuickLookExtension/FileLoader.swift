//
//  FileLoader.swift
//  QuickLookExtension
//
//  Created by Codex on 2026/3/17.
//

import Foundation

struct FileLoadResult {
    let content: String
    let didTruncate: Bool
}

enum FileLoaderError: LocalizedError {
    case couldNotReadFile
    case binaryContent
    case unsupportedEncoding

    var errorDescription: String? {
        switch self {
        case .couldNotReadFile:
            return "FreeLook could not read this file."
        case .binaryContent:
            return "FreeLook cannot preview binary content."
        case .unsupportedEncoding:
            return "FreeLook could not decode this file as UTF-8 or ISO Latin 1."
        }
    }
}

enum FileLoader {
    static let maximumPreviewBytes = 500 * 1024

    static func loadPreview(for url: URL) throws -> FileLoadResult {
        let handle: FileHandle

        do {
            handle = try FileHandle(forReadingFrom: url)
        } catch {
            throw FileLoaderError.couldNotReadFile
        }

        defer {
            try? handle.close()
        }

        guard let rawData = try handle.read(upToCount: maximumPreviewBytes + 1) else {
            throw FileLoaderError.couldNotReadFile
        }

        let didTruncate = rawData.count > maximumPreviewBytes
        let previewData = Data(didTruncate ? rawData.prefix(maximumPreviewBytes) : rawData)

        if looksBinary(previewData) {
            throw FileLoaderError.binaryContent
        }

        if let content = String(data: previewData, encoding: .utf8) {
            return FileLoadResult(content: content, didTruncate: didTruncate)
        }

        if didTruncate, let content = utf8ContentDroppingIncompleteTail(from: previewData) {
            return FileLoadResult(content: content, didTruncate: didTruncate)
        }

        if let content = String(data: previewData, encoding: .isoLatin1) {
            return FileLoadResult(content: content, didTruncate: didTruncate)
        }

        throw FileLoaderError.unsupportedEncoding
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

    private static func looksBinary(_ data: Data) -> Bool {
        guard !data.isEmpty else {
            return false
        }

        if data.contains(0) {
            return true
        }

        let sampleCount = min(data.count, 4096)
        let sample = data.prefix(sampleCount)
        let suspiciousByteCount = sample.reduce(into: 0) { count, byte in
            switch byte {
            case 0x09, 0x0A, 0x0C, 0x0D:
                break
            case 0x20...0x7E, 0x80...0xFF:
                break
            default:
                count += 1
            }
        }

        return Double(suspiciousByteCount) / Double(sampleCount) > 0.30
    }
}
