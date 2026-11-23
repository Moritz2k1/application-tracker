//
//  build.mjs
//  application-tracker
//
//  Created by Moritz Gutschi on 23.11.26.
//

import { build } from "esbuild";
import { mkdir, readFile, rm, writeFile } from "node:fs/promises";

const outputDirectory = new URL("../application-tracker/Resources/Editor/", import.meta.url);

const result = await build({
  entryPoints: ["src/main.js"],
  bundle: true,
  minify: true,
  format: "iife",
  target: "safari16",
  write: false
});

const script = result.outputFiles[0].text.replaceAll("</script", "<\\/script");
const template = await readFile(new URL("./src/editor.html", import.meta.url), "utf8");
const html = template.replace("<editor-bundle></editor-bundle>", () => `<script>${script}</script>`);

await mkdir(outputDirectory, { recursive: true });
await rm(new URL("editor.js", outputDirectory), { force: true });
await writeFile(new URL("editor.html", outputDirectory), html);

console.log(`editor.html written (${(html.length / 1024 / 1024).toFixed(1)} MB)`);
