import { describe, expect, test } from "bun:test";

import {
  escapeHTML,
  installRenderer,
  normalizeLanguageName,
  normalizeThemeName,
  renderPreview,
} from "./renderer.js";

describe("renderer bootstrap", () => {
  test("escapes HTML-sensitive characters", () => {
    expect(escapeHTML("<span>\"&\"</span>")).toBe("&lt;span&gt;&quot;&amp;&quot;&lt;/span&gt;");
  });

  test("normalizes supported source languages", () => {
    expect(normalizeLanguageName("javascript")).toBe("javascript");
    expect(normalizeLanguageName("rust")).toBe("rust");
    expect(normalizeLanguageName("go")).toBe("go");
    expect(normalizeLanguageName("java")).toBe("java");
    expect(normalizeLanguageName("haskell")).toBe("haskell");
    expect(normalizeLanguageName("clojure")).toBe("clojure");
    expect(normalizeLanguageName("kotlin")).toBe("kotlin");
    expect(normalizeLanguageName("csharp")).toBe("csharp");
    expect(normalizeLanguageName("php")).toBe("php");
    expect(normalizeLanguageName("lua")).toBe("lua");
    expect(normalizeLanguageName("scala")).toBe("scala");
    expect(normalizeLanguageName("text")).toBeNull();
    expect(normalizeLanguageName("unknown")).toBeNull();
  });

  test("normalizes configured theme names", () => {
    expect(normalizeThemeName("Ayu Light", "github-light")).toBe("ayu-light");
    expect(normalizeThemeName("Ayu Dark", "github-dark")).toBe("ayu-dark");
    expect(normalizeThemeName("Everforest Light", "github-light")).toBe("everforest-light");
    expect(normalizeThemeName("Everforest Dark", "github-dark")).toBe("everforest-dark");
    expect(normalizeThemeName("GitHub Light", "github-light")).toBe("github-light");
    expect(normalizeThemeName("Missing Theme", "github-dark")).toBe("github-dark");
  });

  test("renders source code with shiki", async () => {
    const result = await renderPreview({
      content: "const value = 1 < 2;\n",
      lang: "javascript",
      lightTheme: "GitHub Light",
      darkTheme: "GitHub Dark",
    });
    const { html, surface } = result;

    expect(html).toContain("class=\"shiki");
    expect(html).toContain("shiki-themes");
    expect(html).toContain("--shiki-dark");
    expect(html).toContain("const");
    expect(typeof surface.lightBackground).toBe("string");
    expect(typeof surface.darkBackground).toBe("string");
  });

  test("falls back to escaped plain text for unsupported languages", async () => {
    const result = await renderPreview({
      content: "plain <text>",
      lang: "text",
    });
    const { html, notice, surface } = result;

    expect(html).toContain("freelook-plain");
    expect(html).toContain("plain &lt;text&gt;");
    expect(notice).toBeNull();
    expect(typeof surface.lightForeground).toBe("string");
  });

  test("renders Swift source code with Oniguruma wasm", async () => {
    const result = await renderPreview({
      content: "let value = 1\n",
      lang: "swift",
    });
    const { html } = result;

    expect(html).toContain("class=\"shiki");
    expect(html).toContain("--shiki-dark");
    expect(html).toContain("span class=\"line\"");
  });

  test("renders Markdown with GFM-style prose and highlighted fences", async () => {
    const result = await renderPreview({
      content: [
        "# Hello",
        "",
        "Visit <https://example.com> and ~~cross this out~~.",
        "",
        "- [x] Done",
        "- [ ] Pending",
        "",
        "| A | B |",
        "| --- | --- |",
        "| 1 | 2 |",
        "",
        "```swift",
        "let value = 1",
        "```",
      ].join("\n"),
      lang: "markdown",
      lightTheme: "GitHub Light",
      darkTheme: "GitHub Dark",
    });
    const { html, notice, surface } = result;

    expect(html).toContain("<h1>Hello</h1>");
    expect(html).toContain("<a href=\"https://example.com\">https://example.com</a>");
    expect(html).toContain("<s>cross this out</s>");
    expect(html).toContain("task-list-item-checkbox");
    expect(html).toContain("<table>");
    expect(html).toContain("class=\"shiki");
    expect(notice).toBeNull();
    expect(typeof surface.lightBackground).toBe("string");
  });

  test("renders prettified JSON with Shiki highlighting", async () => {
    const result = await renderPreview({
      content: "{\"name\":\"FreeLook\",\"enabled\":true,\"items\":[1,2]}",
      lang: "json",
      lightTheme: "GitHub Light",
      darkTheme: "GitHub Dark",
    });
    const { html, notice } = result;

    expect(html).toContain("class=\"shiki");
    expect(html).toContain("\"name\"");
    expect(html).toContain(">  \"enabled\"");
    expect(html).toContain(">    1<");
    expect(notice).toBeNull();
  });

  test("falls back to raw source with a warning for invalid JSON", async () => {
    const result = await renderPreview({
      content: "{\"name\": }",
      lang: "json",
      lightTheme: "GitHub Light",
      darkTheme: "GitHub Dark",
    });
    const { html, notice } = result;

    expect(html).toContain("freelook-plain");
    expect(html).toContain("{&quot;name&quot;: }");
    expect(notice).toBe("Invalid JSON. Showing the original source.");
  });

  test("renders prettified XML with Shiki highlighting", async () => {
    const result = await renderPreview({
      content: "<root><item key=\"value\">text</item><empty /></root>",
      lang: "xml",
      lightTheme: "GitHub Light",
      darkTheme: "GitHub Dark",
    });
    const { html, notice } = result;

    expect(html).toContain("class=\"shiki");
    expect(html).toContain("&#x3C;");
    expect(html).toContain(">root<");
    expect(html).toContain(">item<");
    expect(html).toContain(">empty<");
    expect(notice).toBeNull();
  });

  test("falls back to raw source with a warning for invalid XML", async () => {
    const result = await renderPreview({
      content: "<root><item></root",
      lang: "xml",
      lightTheme: "GitHub Light",
      darkTheme: "GitHub Dark",
    });
    const { html, notice } = result;

    expect(html).toContain("freelook-plain");
    expect(html).toContain("&lt;root&gt;&lt;item&gt;&lt;/root");
    expect(notice).toBe("Invalid XML. Showing the original source.");
  });

  test("installs the FreeLook global API", async () => {
    const target = {};
    const api = installRenderer(target);

    expect(target.FreeLook).toBe(api);

    const result = await target.FreeLook.render({
      content: "print('hello')\n",
      lang: "python",
    });
    const { html, surface } = result;

    expect(html).toContain("class=\"shiki");
    expect(typeof surface.darkForeground).toBe("string");
  });
});
