// NSL Calculator — Evaluator (Stage A, EXPERIMENTAL)
// Semantics: nsl/calculator/SPEC.md §4

import { NslError } from "./errors.ts";
import { tokenize } from "./lexer.ts";
import { parse, type Expr } from "./parser.ts";

/** Maximum accepted source length in characters (SPEC §7). */
export const MAX_INPUT_LENGTH = 1000;

export function evaluate(expr: Expr): number {
  switch (expr.type) {
    case "Number":
      return checkFinite(expr.value, expr.column);
    case "Unary": {
      const v = evaluate(expr.operand);
      // Normalise -0 to 0 so results never display as "-0".
      return expr.op === "-" ? (v === 0 ? 0 : -v) : v;
    }
    case "Binary": {
      // Left operand is evaluated before the right (SPEC §4.2).
      const l = evaluate(expr.left);
      const r = evaluate(expr.right);
      let result: number;
      switch (expr.op) {
        case "+": result = l + r; break;
        case "-": result = l - r; break;
        case "*": result = l * r; break;
        case "/":
          if (r === 0) throw new NslError("E300", "division by zero", expr.column);
          result = l / r;
          break;
      }
      return checkFinite(result === 0 ? 0 : result, expr.column);
    }
  }
}

function checkFinite(v: number, column: number): number {
  if (!Number.isFinite(v)) {
    throw new NslError("E301", "result is outside the representable range", column);
  }
  return v;
}

/** Display rule (SPEC §5): round to 15 significant digits, drop trailing zeros. */
export function formatNumber(v: number): string {
  const s = Number(v.toPrecision(15)).toString();
  return s === "-0" ? "0" : s;
}

/** Full pipeline: source line → displayed result. Throws NslError on failure. */
export function calculate(source: string): string {
  if (source.length > MAX_INPUT_LENGTH) {
    throw new NslError("E001", `input longer than ${MAX_INPUT_LENGTH} characters`, MAX_INPUT_LENGTH + 1);
  }
  return formatNumber(evaluate(parse(tokenize(source))));
}
