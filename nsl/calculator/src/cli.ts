// NSL Calculator — command-line front end (Stage A, EXPERIMENTAL)
//
// Usage:
//   node src/cli.ts "1 + 2 * 3"     evaluate one expression, exit 0 / 1
//   node src/cli.ts                 read expressions line by line from stdin

import { createInterface } from "node:readline";
import { NslError } from "./errors.ts";
import { calculate } from "./evaluator.ts";

function run(line: string): boolean {
  try {
    console.log(calculate(line));
    return true;
  } catch (e) {
    if (e instanceof NslError) {
      console.error(e.format());
      return false;
    }
    throw e; // internal bug: do not hide it
  }
}

const args = process.argv.slice(2);

if (args.length > 0) {
  process.exitCode = run(args.join(" ")) ? 0 : 1;
} else {
  const interactive = process.stdin.isTTY === true;
  const rl = createInterface({ input: process.stdin, output: process.stdout, prompt: "nsl> ", terminal: interactive });
  let failed = false;
  if (interactive) rl.prompt();
  rl.on("line", (line) => {
    if (line.trim() !== "") failed = !run(line) || failed;
    if (interactive) rl.prompt();
  });
  rl.on("close", () => {
    if (interactive) process.stdout.write("\n");
    process.exitCode = failed ? 1 : 0;
  });
}
