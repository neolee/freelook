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
    expect(normalizeLanguageName("text")).toBeNull();
    expect(normalizeLanguageName("unknown")).toBeNull();
  });

  test("normalizes configured theme names", () => {
    expect(normalizeThemeName("Ayu Light", "github-light")).toBe("ayu-light");
    expect(normalizeThemeName("Ayu Dark", "github-dark")).toBe("ayu-dark");
    expect(normalizeThemeName("Everforest Light", "github-light")).toBe("everforest-light");
    expect(normalizeThemeName("Everforest Dark", "github-dark")).toBe("everforest-dark");
    expect(normalizeThemeName("GitHub Light", "github-light")).toBe("github-light");
    expect(normalizeThemeName("Solarized Light", "github-light")).toBe("solarized-light");
    expect(normalizeThemeName("Missing Theme", "github-dark")).toBe("github-dark");
  });

  test("renders source code with shiki", async () => {
    const html = await renderPreview({
      content: "const value = 1 < 2;\n",
      lang: "javascript",
      lightTheme: "GitHub Light",
      darkTheme: "GitHub Dark",
    });

    expect(html).toContain("class=\"shiki");
    expect(html).toContain("shiki-themes");
    expect(html).toContain("--shiki-dark");
    expect(html).toContain("const");
  });

  test("falls back to escaped plain text for unsupported languages", async () => {
    const html = await renderPreview({
      content: "plain <text>",
      lang: "text",
    });

    expect(html).toContain("freelook-plain");
    expect(html).toContain("plain &lt;text&gt;");
  });

  test("renders Swift source code with Oniguruma wasm", async () => {
    const html = await renderPreview({
      content: "let value = 1\n",
      lang: "swift",
    });

    expect(html).toContain("class=\"shiki");
    expect(html).toContain("--shiki-dark");
    expect(html).toContain("span class=\"line\"");
  });

  test("installs the FreeLook global API", async () => {
    const target = {};
    const api = installRenderer(target);

    expect(target.FreeLook).toBe(api);

    const html = await target.FreeLook.render({
      content: "print('hello')\n",
      lang: "python",
    });

    expect(html).toContain("class=\"shiki");
  });
});
