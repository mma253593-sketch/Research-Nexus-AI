// NSL Calculator — Parser (Stage A, EXPERIMENTAL)
// Recursive descent over the EBNF in nsl/calculator/SPEC.md §3

import { NslError } from "./errors.ts";
import type { Token, TokenKind } from "./lexer.ts";

export type BinaryOp = "+" | "-" | "*" | "/";

export type Expr =
  | { type: "Number"; value: number; column: number }
  | { type: "Unary"; op: "-" | "+"; operand: Expr; column: number }
  | { type: "Binary"; op: BinaryOp; left: Expr; right: Expr; column: number };

/** Guards against stack exhaustion from deeply nested input (SPEC §7). */
export const MAX_DEPTH = 100;

const DESCRIBE: Record<TokenKind, string> = {
  NUMBER: "number",
  PLUS: "'+'",
  MINUS: "'-'",
  STAR: "'*'",
  SLASH: "'/'",
  LPAREN: "'('",
  RPAREN: "')'",
  EOF: "end of input",
};

export function parse(tokens: Token[]): Expr {
  let pos = 0;
  let depth = 0;

  const peek = (): Token => tokens[pos];
  const next = (): Token => tokens[pos++];

  const enter = (column: number): void => {
    if (++depth > MAX_DEPTH) {
      throw new NslError("E202", `nesting deeper than ${MAX_DEPTH} levels`, column);
    }
  };

  // expression = term , { ( "+" | "-" ) , term } ;
  function expression(): Expr {
    let left = term();
    while (peek().kind === "PLUS" || peek().kind === "MINUS") {
      const op = next();
      const right = term();
      left = { type: "Binary", op: op.text as BinaryOp, left, right, column: op.column };
    }
    return left;
  }

  // term = unary , { ( "*" | "/" ) , unary } ;
  function term(): Expr {
    let left = unary();
    while (peek().kind === "STAR" || peek().kind === "SLASH") {
      const op = next();
      const right = unary();
      left = { type: "Binary", op: op.text as BinaryOp, left, right, column: op.column };
    }
    return left;
  }

  // unary = ( "-" | "+" ) , unary | primary ;
  function unary(): Expr {
    const t = peek();
    if (t.kind === "MINUS" || t.kind === "PLUS") {
      next();
      enter(t.column);
      const operand = unary();
      depth--;
      return { type: "Unary", op: t.text as "-" | "+", operand, column: t.column };
    }
    return primary();
  }

  // primary = number | "(" , expression , ")" ;
  function primary(): Expr {
    const t = next();
    if (t.kind === "NUMBER") {
      return { type: "Number", value: Number(t.text), column: t.column };
    }
    if (t.kind === "LPAREN") {
      enter(t.column);
      const inner = expression();
      depth--;
      const close = next();
      if (close.kind !== "RPAREN") {
        throw new NslError("E201", `expected ')' to close '(' at column ${t.column}, found ${DESCRIBE[close.kind]}`, close.column);
      }
      return inner;
    }
    throw new NslError("E200", `expected number or '(', found ${DESCRIBE[t.kind]}`, t.column);
  }

  if (peek().kind === "EOF") {
    throw new NslError("E203", "empty expression", peek().column);
  }
  const result = expression();
  const rest = peek();
  if (rest.kind !== "EOF") {
    throw new NslError("E200", `unexpected ${DESCRIBE[rest.kind]} after complete expression`, rest.column);
  }
  return result;
}
