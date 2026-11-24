// NSL Calculator — tests. Each block maps to a section of SPEC.md.
import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { calculate, MAX_INPUT_LENGTH } from "../src/evaluator.ts";
import { NslError, type ErrorCode } from "../src/errors.ts";
import { MAX_DEPTH } from "../src/parser.ts";

function expectError(source: string, code: ErrorCode, column?: number): void {
  assert.throws(
    () => calculate(source),
    (e: unknown) => {
      assert.ok(e instanceof NslError, `expected NslError, got ${e}`);
      assert.equal(e.code, code, `code for ${JSON.stringify(source)}`);
      if (column !== undefined) assert.equal(e.column, column, `column for ${JSON.stringify(source)}`);
      return true;
    },
  );
}

test("§2 literals", () => {
  assert.equal(calculate("0"), "0");
  assert.equal(calculate("42"), "42");
  assert.equal(calculate("3.25"), "3.25");
  assert.equal(calculate("007"), "7");
  assert.equal(calculate("  \t5  "), "5");
});

test("§3/§4 arithmetic and precedence", () => {
  assert.equal(calculate("1 + 2"), "3");
  assert.equal(calculate("7 - 10"), "-3");
  assert.equal(calculate("6 * 7"), "42");
  assert.equal(calculate("7 / 2"), "3.5");
  assert.equal(calculate("1 + 2 * 3"), "7");
  assert.equal(calculate("(1 + 2) * 3"), "9");
  assert.equal(calculate("2 * (3 + 4) - 5 / 5"), "13");
});

test("§4.1 left associativity", () => {
  assert.equal(calculate("10 - 4 - 3"), "3");
  assert.equal(calculate("100 / 10 / 2"), "5");
  assert.equal(calculate("8 / 2 * 4"), "16");
});

test("§3 unary operators", () => {
  assert.equal(calculate("-5"), "-5");
  assert.equal(calculate("+5"), "5");
  assert.equal(calculate("--5"), "5");
  assert.equal(calculate("-(2 + 3)"), "-5");
  assert.equal(calculate("2 * -3"), "-6");
  assert.equal(calculate("-2 * -3"), "6");
  assert.equal(calculate("3 - -2"), "5");
});

test("§5 display rule", () => {
  assert.equal(calculate("0.1 + 0.2"), "0.3");
  assert.equal(calculate("1 / 3"), "0.333333333333333");
  assert.equal(calculate("2 / 3"), "0.666666666666667");
  assert.equal(calculate("-0"), "0");
  assert.equal(calculate("0 * -1"), "0");
  assert.equal(calculate("1000000 * 1000000 * 1000000 * 1000000"), "1e+24");
});

test("§6 lexical errors", () => {
  expectError("2 ^ 3", "E100", 3);
  expectError("1 + x", "E100", 5);
  expectError("1,5", "E100", 2);
  expectError("1.", "E101", 3);
  expectError(".5", "E101", 1);
  expectError("1.2.3", "E101", 4);
});

test("§6 syntax errors", () => {
  expectError("", "E203", 1);
  expectError("   ", "E203", 4);
  expectError("1 +", "E200", 4);
  expectError("* 2", "E200", 1);
  expectError("1 2", "E200", 3);
  expectError("()", "E200", 2);
  expectError("(1 + 2", "E201", 7);
  expectError("1 + 2)", "E200", 6);
});

test("§6 runtime errors", () => {
  expectError("1 / 0", "E300", 3);
  expectError("1 / (2 - 2)", "E300", 3);
  expectError("0 / 0", "E300", 3);
  expectError("1 / -0", "E300", 3);
  const big = "9".repeat(309); // > Number.MAX_VALUE
  expectError(big, "E301", 1);
  expectError(`1${"0".repeat(200)} * 1${"0".repeat(200)}`, "E301");
});

test("§7 resource limits", () => {
  const ok = "(".repeat(MAX_DEPTH) + "1" + ")".repeat(MAX_DEPTH);
  assert.equal(calculate(ok), "1");
  expectError("(".repeat(MAX_DEPTH + 1) + "1" + ")".repeat(MAX_DEPTH + 1), "E202");
  expectError("-".repeat(MAX_DEPTH + 1) + "1", "E202");
  expectError("(".repeat(MAX_INPUT_LENGTH), "E202"); // deepest input the length limit allows
  expectError("(".repeat(100_000), "E001"); // rejected before parsing
  assert.equal(calculate("1+".repeat(400) + "1"), "401"); // long but flat input is fine
  expectError("1".repeat(MAX_INPUT_LENGTH + 1), "E001");
});

test("property: integer + and * agree with host arithmetic on small integers", () => {
  // Deterministic pseudo-random generator so failures are reproducible.
  let seed = 12345;
  const rand = (n: number): number => {
    seed = (seed * 1103515245 + 12345) % 2 ** 31;
    return seed % n;
  };
  for (let i = 0; i < 500; i++) {
    const a = rand(2001) - 1000;
    const b = rand(2001) - 1000;
    const c = rand(2001) - 1000;
    assert.equal(calculate(`${a} + ${b} * ${c}`), String(a + b * c), `${a} + ${b} * ${c}`);
    assert.equal(calculate(`(${a} - ${b}) * ${c}`), String((a - b) * c || 0));
  }
});

test("CLI: argument mode and exit codes", () => {
  const cli = fileURLToPath(new URL("../src/cli.ts", import.meta.url));
  const ok = spawnSync(process.execPath, [cli, "1 + 2 * 3"], { encoding: "utf8" });
  assert.equal(ok.status, 0);
  assert.equal(ok.stdout, "7\n");

  const bad = spawnSync(process.execPath, [cli, "1 / 0"], { encoding: "utf8" });
  assert.equal(bad.status, 1);
  assert.equal(bad.stderr, "error E300 at column 3: division by zero\n");
});

test("CLI: stdin mode", () => {
  const cli = fileURLToPath(new URL("../src/cli.ts", import.meta.url));
  const r = spawnSync(process.execPath, [cli], { input: "1 + 1\n\n2 * (3\n10 / 4\n", encoding: "utf8" });
  assert.equal(r.stdout, "2\n2.5\n");
  assert.equal(r.stderr, "error E201 at column 7: expected ')' to close '(' at column 5, found end of input\n");
  assert.equal(r.status, 1);
});
