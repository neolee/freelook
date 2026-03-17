# FreeLook Markdown Showcase

FreeLook should render Markdown as a calm reading surface first, and only then as a technical feature checklist.

## Paragraphs and Inline Formatting

This paragraph includes **bold**, *italic*, ~~strikethrough~~, `inline code`, and an automatic link to <https://example.com>.

> A block quote should remain readable without overpowering the page.

## Task List

- [x] Syntax-highlight fenced code blocks
- [x] Tables when they fit
- [x] Long content that still feels balanced
- [ ] Final typography sign-off

## Table

| Format | Expected behavior | Notes |
|---|---|---|
| Markdown | Rendered prose | Includes GFM features where practical |
| JSON | Pretty-printed then highlighted | Falls back to raw source plus warning |
| XML | Pretty-printed then highlighted | Falls back to raw source plus warning |
| Code | Highlighted source | Reading comfort matters more than chrome |

## Swift Example

```swift
struct ThemeChoice: Identifiable {
    let id: String
    let title: String
    let isDark: Bool
}
```

## JavaScript Example

```javascript
export function renderNotice(message) {
  return `<aside class="notice">${message}</aside>`;
}
```

## Ordered List

1. Settle the HTML shell.
2. Validate real samples in Quick Look.
3. Add host-app preview later, after settings are stable.

## Long Paragraph

The preview should feel useful on the hundredth open, not just the first. That means spacing, font choice, code density, and warning tone all need to be tested on representative files instead of being left as a last-minute cleanup pass.
