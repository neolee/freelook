export function makeSummary(fileName, language, truncated = false) {
  const state = truncated ? "truncated" : "ready";
  return `${fileName} [${language}] ${state}`;
}

export function renderWarning(message) {
  return `<aside class="warning">${message}</aside>`;
}
