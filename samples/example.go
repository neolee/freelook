package main

import "fmt"

type PreviewSummary struct {
	FileName  string
	Language  string
	Truncated bool
}

func (summary PreviewSummary) StatusLine() string {
	state := "ready"
	if summary.Truncated {
		state = "truncated"
	}

	return fmt.Sprintf("%s [%s] %s", summary.FileName, summary.Language, state)
}

func buildSummary() PreviewSummary {
	return PreviewSummary{
		FileName:  "go.mod",
		Language:  "go",
		Truncated: false,
	}
}

func main() {
	fmt.Println(buildSummary().StatusLine())
}
