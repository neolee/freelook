import { build, context } from "esbuild";

const watchMode = process.argv.includes("--watch");

const config = {
  entryPoints: ["src/renderer.js"],
  outfile: "dist/bundle.js",
  bundle: true,
  format: "iife",
  platform: "browser",
  target: ["safari17"],
  sourcemap: true,
  logLevel: "info",
};

if (watchMode) {
  const ctx = await context(config);
  await ctx.watch();
  console.log("Watching WebRenderer...");
} else {
  await build(config);
}
