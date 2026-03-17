from dataclasses import dataclass


@dataclass(frozen=True)
class PreviewSummary:
    file_name: str
    language: str
    truncated: bool = False

    def status_line(self) -> str:
        state = "truncated" if self.truncated else "ready"
        return f"{self.file_name} [{self.language}] {state}"


def make_summary() -> PreviewSummary:
    return PreviewSummary(file_name="README.md", language="markdown")
