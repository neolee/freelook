import { createHighlighterCore } from "shiki/core";
import MarkdownIt from "markdown-it";
import { fromHighlighter } from "@shikijs/markdown-it";
import bashLanguage from "shiki/dist/langs/bash.mjs";
import clojureLanguage from "shiki/dist/langs/clojure.mjs";
import cssLanguage from "shiki/dist/langs/css.mjs";
import goLanguage from "shiki/dist/langs/go.mjs";
import haskellLanguage from "shiki/dist/langs/haskell.mjs";
import htmlLanguage from "shiki/dist/langs/html.mjs";
import javaLanguage from "shiki/dist/langs/java.mjs";
import javascriptLanguage from "shiki/dist/langs/javascript.mjs";
import jsonLanguage from "shiki/dist/langs/json.mjs";
import pythonLanguage from "shiki/dist/langs/python.mjs";
import rustLanguage from "shiki/dist/langs/rust.mjs";
import rubyLanguage from "shiki/dist/langs/ruby.mjs";
import swiftLanguage from "shiki/dist/langs/swift.mjs";
import typescriptLanguage from "shiki/dist/langs/typescript.mjs";
import xmlLanguage from "shiki/dist/langs/xml.mjs";
import ayuDarkTheme from "shiki/dist/themes/ayu-dark.mjs";
import ayuLightTheme from "shiki/dist/themes/ayu-light.mjs";
import catppuccinLatteTheme from "shiki/dist/themes/catppuccin-latte.mjs";
import catppuccinMochaTheme from "shiki/dist/themes/catppuccin-mocha.mjs";
import everforestDarkTheme from "shiki/dist/themes/everforest-dark.mjs";
import everforestLightTheme from "shiki/dist/themes/everforest-light.mjs";
import githubDarkTheme from "shiki/dist/themes/github-dark.mjs";
import githubLightTheme from "shiki/dist/themes/github-light.mjs";
import nordTheme from "shiki/dist/themes/nord.mjs";
import oneDarkProTheme from "shiki/dist/themes/one-dark-pro.mjs";
import oneLightTheme from "shiki/dist/themes/one-light.mjs";
import { createOnigurumaEngine } from "shiki/engine/oniguruma";
import onigWasm from "shiki/wasm";
import xmlFormat from "xml-formatter";
import themeManifest from "../../FreeLook/QuickLookExtension/Resources/Themes.json";

const HTML_ESCAPE_MAP = {
  "&": "&amp;",
  "<": "&lt;",
  ">": "&gt;",
  "\"": "&quot;",
  "'": "&#39;",
};

const DEFAULT_LIGHT_THEME = "github-light";
const DEFAULT_DARK_THEME = "github-dark";

const THEME_MODULE_MAP = {
  "ayu-light": ayuLightTheme,
  "ayu-dark": ayuDarkTheme,
  "github-light": githubLightTheme,
  "github-dark": githubDarkTheme,
  "one-light": oneLightTheme,
  "one-dark-pro": oneDarkProTheme,
  "catppuccin-latte": catppuccinLatteTheme,
  "catppuccin-mocha": catppuccinMochaTheme,
  "everforest-light": everforestLightTheme,
  "everforest-dark": everforestDarkTheme,
  nord: nordTheme,
};

const THEME_NAME_MAP = Object.fromEntries(themeManifest.themes.map((theme) => [theme.displayName, theme.id]));

const SUPPORTED_SOURCE_LANGUAGES = [
  "bash",
  "clojure",
  "css",
  "go",
  "haskell",
  "html",
  "java",
  "javascript",
  "json",
  "python",
  "ruby",
  "rust",
  "swift",
  "typescript",
  "xml",
];

const SOURCE_LANGUAGE_REGISTRATIONS = [
  bashLanguage,
  clojureLanguage,
  cssLanguage,
  goLanguage,
  haskellLanguage,
  htmlLanguage,
  javaLanguage,
  javascriptLanguage,
  jsonLanguage,
  pythonLanguage,
  rustLanguage,
  rubyLanguage,
  swiftLanguage,
  typescriptLanguage,
  xmlLanguage,
];

const THEME_REGISTRATIONS = themeManifest.themes.map((theme) => {
  const registration = THEME_MODULE_MAP[theme.id];

  if (!registration) {
    throw new Error(`Missing Shiki theme registration for ${theme.id}.`);
  }

  return registration;
});

let highlighterPromise;
let markdownParserPromise;

export function escapeHTML(value) {
  return String(value).replace(/[&<>"']/g, (character) => HTML_ESCAPE_MAP[character]);
}

export function normalizeThemeName(themeName, fallbackTheme) {
  return THEME_NAME_MAP[themeName] ?? fallbackTheme;
}

export function normalizeLanguageName(languageName) {
  if (!languageName || languageName === "text") {
    return null;
  }

  return SUPPORTED_SOURCE_LANGUAGES.includes(languageName) ? languageName : null;
}

function isMarkdownLanguage(languageName) {
  return languageName === "markdown";
}

function isJSONLanguage(languageName) {
  return languageName === "json";
}

function isXMLLanguage(languageName) {
  return languageName === "xml";
}

function getHighlighter() {
  if (!highlighterPromise) {
    highlighterPromise = (async () => {
      const engine = await createOnigurumaEngine(onigWasm);

      return createHighlighterCore({
        engine,
        langs: SOURCE_LANGUAGE_REGISTRATIONS,
        themes: THEME_REGISTRATIONS,
      });
    })();
  }

  return highlighterPromise;
}

function taskListPlugin(markdownIt) {
  markdownIt.core.ruler.after("inline", "freelook-task-list", (state) => {
    for (let index = 2; index < state.tokens.length; index += 1) {
      const inlineToken = state.tokens[index];

      if (inlineToken.type !== "inline" || !inlineToken.children?.length) {
        continue;
      }

      const paragraphToken = state.tokens[index - 1];
      const listItemToken = state.tokens[index - 2];

      if (paragraphToken?.type !== "paragraph_open" || listItemToken?.type !== "list_item_open") {
        continue;
      }

      const firstChild = inlineToken.children[0];

      if (!firstChild || firstChild.type !== "text") {
        continue;
      }

      const match = firstChild.content.match(/^\[([ xX])\]\s+/);

      if (!match) {
        continue;
      }

      const isChecked = match[1].toLowerCase() === "x";
      firstChild.content = firstChild.content.slice(match[0].length);

      if (firstChild.content.length === 0) {
        inlineToken.children.shift();
      }

      listItemToken.attrJoin("class", "task-list-item");
      const checkboxToken = new state.Token("html_inline", "", 0);
      checkboxToken.content = `<input class="task-list-item-checkbox" type="checkbox"${isChecked ? " checked" : ""} disabled>`;
      inlineToken.children.unshift(checkboxToken);
    }
  });
}

async function getMarkdownParser() {
  if (!markdownParserPromise) {
    markdownParserPromise = (async () => {
      const highlighter = await getHighlighter();
      const markdownIt = new MarkdownIt({
        html: false,
        linkify: true,
      });

      markdownIt.use(
        fromHighlighter(highlighter, {
          themes: {
            light: DEFAULT_LIGHT_THEME,
            dark: DEFAULT_DARK_THEME,
          },
        })
      );
      markdownIt.use(taskListPlugin);

      const defaultFenceRenderer = markdownIt.renderer.rules.fence
        ?? ((tokens, idx, options, _env, self) => self.renderToken(tokens, idx, options));

      markdownIt.renderer.rules.fence = (tokens, index, options, environment, self) => {
        const token = tokens[index];
        const language = token.info.trim().split(/\s+/)[0] ?? "";

        if (!language || normalizeLanguageName(language)) {
          return defaultFenceRenderer(tokens, index, options, environment, self);
        }

        return renderPlainText(token.content, language);
      };

      return markdownIt;
    })();
  }

  return markdownParserPromise;
}

function renderPlainText(content, lang = "text") {
  return [
    `<pre class="freelook-plain" data-lang="${escapeHTML(lang)}">`,
    `<code>${escapeHTML(content)}</code>`,
    "</pre>",
  ].join("");
}

async function renderMarkdownDocument(content) {
  const markdownParser = await getMarkdownParser();
  return `<article class="markdown-body">${markdownParser.render(content)}</article>`;
}

function formatJSONDocument(content) {
  return `${JSON.stringify(JSON.parse(content), null, 2)}\n`;
}

function formatXMLDocument(content) {
  return `${xmlFormat(content, {
    indentation: "  ",
    lineSeparator: "\n",
    collapseContent: true,
    throwOnFailure: true,
  })}\n`;
}

function resolveThemeSurface(themeId) {
  const theme = THEME_MODULE_MAP[themeId];
  const colors = theme?.colors ?? {};

  return {
    background: colors["editor.background"] ?? null,
    foreground: colors["editor.foreground"] ?? null,
  };
}

function makeSurface(lightTheme, darkTheme) {
  const normalizedLightTheme = normalizeThemeName(lightTheme, DEFAULT_LIGHT_THEME);
  const normalizedDarkTheme = normalizeThemeName(darkTheme, DEFAULT_DARK_THEME);
  const lightSurface = resolveThemeSurface(normalizedLightTheme);
  const darkSurface = resolveThemeSurface(normalizedDarkTheme);

  return {
    lightBackground: lightSurface.background,
    lightForeground: lightSurface.foreground,
    darkBackground: darkSurface.background,
    darkForeground: darkSurface.foreground,
  };
}

function makeRenderResult({
  html,
  lightTheme,
  darkTheme,
  notice = null,
}) {
  return {
    html,
    notice,
    surface: makeSurface(lightTheme, darkTheme),
  };
}

async function renderHighlightedSource(content, lang, lightTheme, darkTheme) {
  const highlighter = await getHighlighter();

  return highlighter.codeToHtml(content, {
    lang,
    themes: {
      light: normalizeThemeName(lightTheme, DEFAULT_LIGHT_THEME),
      dark: normalizeThemeName(darkTheme, DEFAULT_DARK_THEME),
    },
  });
}

export async function renderPreview({
  content = "",
  lang = "text",
  lightTheme = "GitHub Light",
  darkTheme = "GitHub Dark",
} = {}) {
  if (isMarkdownLanguage(lang)) {
    return makeRenderResult({
      html: await renderMarkdownDocument(content),
      lightTheme,
      darkTheme,
    });
  }

  if (isJSONLanguage(lang)) {
    try {
      return makeRenderResult({
        html: await renderHighlightedSource(formatJSONDocument(content), "json", lightTheme, darkTheme),
        lightTheme,
        darkTheme,
      });
    } catch {
      return makeRenderResult({
        html: renderPlainText(content, lang),
        lightTheme,
        darkTheme,
        notice: "Invalid JSON. Showing the original source.",
      });
    }
  }

  if (isXMLLanguage(lang)) {
    try {
      return makeRenderResult({
        html: await renderHighlightedSource(formatXMLDocument(content), "xml", lightTheme, darkTheme),
        lightTheme,
        darkTheme,
      });
    } catch {
      return makeRenderResult({
        html: renderPlainText(content, lang),
        lightTheme,
        darkTheme,
        notice: "Invalid XML. Showing the original source.",
      });
    }
  }

  const normalizedLanguage = normalizeLanguageName(lang);

  if (!normalizedLanguage) {
    return makeRenderResult({
      html: renderPlainText(content, lang),
      lightTheme,
      darkTheme,
    });
  }

  try {
    return makeRenderResult({
      html: await renderHighlightedSource(content, normalizedLanguage, lightTheme, darkTheme),
      lightTheme,
      darkTheme,
    });
  } catch {
    return makeRenderResult({
      html: renderPlainText(content, lang),
      lightTheme,
      darkTheme,
    });
  }
}

export function installRenderer(target = globalThis) {
  const api = {
    async render(input) {
      return renderPreview(input);
    },
  };

  target.FreeLook = api;
  return api;
}

if (typeof globalThis !== "undefined") {
  installRenderer(globalThis);
}
