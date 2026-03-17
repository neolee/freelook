const HTML_ESCAPE_MAP = {
  "&": "&amp;",
  "<": "&lt;",
  ">": "&gt;",
  "\"": "&quot;",
  "'": "&#39;",
};

export function escapeHTML(value) {
  return String(value).replace(/[&<>"']/g, (character) => HTML_ESCAPE_MAP[character]);
}

export function renderPreview({ content = "", lang = "text" } = {}) {
  return [
    `<pre class="freelook-placeholder" data-lang="${escapeHTML(lang)}">`,
    `<code>${escapeHTML(content)}</code>`,
    "</pre>",
  ].join("");
}

export function installRenderer(target = globalThis) {
  const api = {
    render(input) {
      return renderPreview(input);
    },
  };

  target.FreeLook = api;
  return api;
}

if (typeof globalThis !== "undefined") {
  installRenderer(globalThis);
}
