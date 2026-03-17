import Foundation

struct PreviewSummary {
    let fileName: String
    let language: String
    let isTruncated: Bool

    var statusLine: String {
        if isTruncated {
            return "\(fileName) [\(language)] truncated"
        }

        return "\(fileName) [\(language)] ready"
    }
}

func makeSummary() -> PreviewSummary {
    PreviewSummary(fileName: "README.md", language: "markdown", isTruncated: false)
}
