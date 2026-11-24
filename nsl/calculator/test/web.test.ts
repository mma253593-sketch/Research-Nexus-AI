// Web build tests: the page must embed exactly the current engine, and that
// embedded engine must behave like the source engine.
import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { runInNewContext } from "node:vm";
import { fileURLToPath } from "node:url";
import { buildEngineScript, buildPage } from "../scripts/build-web.ts";
import { calculate } from "../src/evaluator.ts";
import { NslError } from "../src/errors.ts";

const pagePath = fileURLToPath(new URL("../web/index.html", import.meta.url));

test("web/index.html is up to date with src/ and web/template.html", () => {
  assert.equal(readFileSync(pagePath, "utf8"), buildPage(), "run `npm run build:web`");
});

test("embedded engine matches the source engine", () => {
  const sandbox: Record<string, unknown> = {};
  runInNewContext(`${buildEngineScript()}\n;this.calc = calculate; this.Err = NslError;`, sandbox);
  const webCalc = sandbox.calc as (s: string) => string;

  const cases = [
    "2*(3+4)", "1 + 2 * 3", "10 - 4 - 3", "0.1 + 0.2", "1 / 3", "-(5 - 8) / 2", "--5", "-0",
    "1000000 * 1000000 * 1000000 * 1000000",
    "1 / 0", "1 +", "(1 + 2", "2 ^ 3", ".5", "", "9".repeat(309), "(".repeat(101) + "1", "1".repeat(1001),
  ];
  for (const c of cases) {
    const run = (f: (s: string) => string): string => {
      try { return `ok ${f(c)}`; }
      catch (e) {
        const err = e as NslError;
        return `err ${err.code} ${err.column} ${err.message}`;
      }
    };
    assert.equal(run(webCalc), run(calculate), `case ${JSON.stringify(c).slice(0, 40)}`);
  }
});
