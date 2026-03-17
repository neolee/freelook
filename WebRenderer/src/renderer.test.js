import { describe, expect, test } from "bun:test";

import { escapeHTML, installRenderer, renderPreview } from "./renderer.js";

describe("renderer bootstrap", () => {
  test("escapes HTML-sensitive characters", () => {
    expect(escapeHTML("<span>\"&\"</span>")).toBe("&lt;span&gt;&quot;&amp;&quot;&lt;/span&gt;");
  });

  test("renders placeholder preview markup", () => {
    const html = renderPreview({
      content: "const value = 1 < 2;",
      lang: "javascript",
    });

    expect(html).toContain("freelook-placeholder");
    expect(html).toContain("data-lang=\"javascript\"");
    expect(html).toContain("const value = 1 &lt; 2;");
  });

  test("installs the FreeLook global API", () => {
    const target = {};
    const api = installRenderer(target);

    expect(target.FreeLook).toBe(api);
    expect(target.FreeLook.render({ content: "hello" })).toContain("<code>hello</code>");
  });
});
