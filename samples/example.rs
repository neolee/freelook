use std::fmt::{self, Display, Formatter};

struct PreviewSummary<'a> {
    file_name: &'a str,
    language: &'a str,
    truncated: bool,
}

impl Display for PreviewSummary<'_> {
    fn fmt(&self, formatter: &mut Formatter<'_>) -> fmt::Result {
        let state = if self.truncated { "truncated" } else { "ready" };
        write!(formatter, "{} [{}] {}", self.file_name, self.language, state)
    }
}

fn build_summary() -> PreviewSummary<'static> {
    PreviewSummary {
        file_name: "Cargo.toml",
        language: "rust",
        truncated: false,
    }
}

fn main() {
    println!("{}", build_summary());
}
