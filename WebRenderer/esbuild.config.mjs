import { build, context } from "esbuild";

const devMode = process.argv.includes("--dev");
const watchMode = process.argv.includes("--watch");

const config = {
  entryPoints: ["src/renderer.js"],
  outfile: "dist/bundle.js",
  bundle: true,
  format: "iife",
  platform: "browser",
  target: ["safari17"],
  sourcemap: devMode,
  minify: !devMode,
  legalComments: devMode ? "inline" : "none",
  logLevel: "info",
};

if (watchMode) {
  const ctx = await context(config);
  await ctx.watch();
  console.log("Watching WebRenderer...");
} else {
  await build(config);
}
