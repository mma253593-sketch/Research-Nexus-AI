// Builds web/index.html: the browser calculator with the Stage A engine inlined.
//
// The engine is NOT rewritten for the web. Its TypeScript sources in src/ are
// type-stripped with Node's built-in stripTypeScriptTypes (no dependencies),
// concatenated in dependency order, and inlined into web/template.html.
//
//   node scripts/build-web.ts           write web/index.html
//   node scripts/build-web.ts --check   exit 1 if web/index.html is stale

import { readFileSync, writeFileSync } from "node:fs";
import { stripTypeScriptTypes } from "node:module";
import { fileURLToPath } from "node:url";

const root = fileURLToPath(new URL("..", import.meta.url));
const ENGINE_FILES = ["src/errors.ts", "src/lexer.ts", "src/parser.ts", "src/evaluator.ts"];
const MARKER = "/*__NSL_ENGINE__*/";

export function buildEngineScript(): string {
  const parts = ENGINE_FILES.map((file) => {
    const js = stripTypeScriptTypes(readFileSync(root + file, "utf8"), { mode: "strip" });
    const body = js
      .split("\n")
      .filter((line) => !/^import\s/.test(line)) // modules are concatenated, so imports go
      .map((line) => line.replace(/^export\s+/, ""))
      .filter((line) => line.trim() !== "")
      .join("\n");
    return `// ---- ${file} ----\n${body}`;
  });
  return parts.join("\n");
}

export function buildPage(): string {
  const template = readFileSync(root + "web/template.html", "utf8");
  if (template.split(MARKER).length !== 2) throw new Error(`template must contain ${MARKER} exactly once`);
  return template.replace(MARKER, () => buildEngineScript());
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const page = buildPage();
  const out = root + "web/index.html";
  if (process.argv.includes("--check")) {
    let current = "";
    try { current = readFileSync(out, "utf8"); } catch { /* missing counts as stale */ }
    if (current !== page) {
      console.error("web/index.html is out of date: run `npm run build:web`");
      process.exitCode = 1;
    } else {
      console.log("web/index.html is up to date");
    }
  } else {
    writeFileSync(out, page);
    console.log(`wrote web/index.html (${page.length} bytes)`);
  }
}
