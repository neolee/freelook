import { createHighlighterCore } from "shiki/core";
import bashLanguage from "shiki/dist/langs/bash.mjs";
import cssLanguage from "shiki/dist/langs/css.mjs";
import htmlLanguage from "shiki/dist/langs/html.mjs";
import javascriptLanguage from "shiki/dist/langs/javascript.mjs";
import pythonLanguage from "shiki/dist/langs/python.mjs";
import rubyLanguage from "shiki/dist/langs/ruby.mjs";
import swiftLanguage from "shiki/dist/langs/swift.mjs";
import typescriptLanguage from "shiki/dist/langs/typescript.mjs";
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

const SUPPORTED_SOURCE_LANGUAGES = ["bash", "css", "html", "javascript", "python", "ruby", "swift", "typescript"];

const SOURCE_LANGUAGE_REGISTRATIONS = [
  bashLanguage,
  cssLanguage,
  htmlLanguage,
  javascriptLanguage,
  pythonLanguage,
  rubyLanguage,
  swiftLanguage,
  typescriptLanguage,
];

const THEME_REGISTRATIONS = themeManifest.themes.map((theme) => {
  const registration = THEME_MODULE_MAP[theme.id];

  if (!registration) {
    throw new Error(`Missing Shiki theme registration for ${theme.id}.`);
  }

  return registration;
});

let highlighterPromise;

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

function renderPlainText(content, lang = "text") {
  return [
    `<pre class="freelook-plain" data-lang="${escapeHTML(lang)}">`,
    `<code>${escapeHTML(content)}</code>`,
    "</pre>",
  ].join("");
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

export async function renderPreview({
  content = "",
  lang = "text",
  lightTheme = "GitHub Light",
  darkTheme = "GitHub Dark",
} = {}) {
  const normalizedLanguage = normalizeLanguageName(lang);

  if (!normalizedLanguage) {
    return makeRenderResult({
      html: renderPlainText(content, lang),
      lightTheme,
      darkTheme,
    });
  }

  const highlighter = await getHighlighter();

  try {
    const html = highlighter.codeToHtml(content, {
      lang: normalizedLanguage,
      themes: {
        light: normalizeThemeName(lightTheme, DEFAULT_LIGHT_THEME),
        dark: normalizeThemeName(darkTheme, DEFAULT_DARK_THEME),
      },
    });

    return makeRenderResult({
      html,
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
