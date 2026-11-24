// NSL Calculator — Lexer (Stage A, EXPERIMENTAL)
// Spec: nsl/calculator/SPEC.md §2

import { NslError } from "./errors.ts";

export type TokenKind = "NUMBER" | "PLUS" | "MINUS" | "STAR" | "SLASH" | "LPAREN" | "RPAREN" | "EOF";

export interface Token {
  kind: TokenKind;
  text: string;
  /** 1-based column of the first character. */
  column: number;
}

const SINGLE: Record<string, TokenKind> = {
  "+": "PLUS",
  "-": "MINUS",
  "*": "STAR",
  "/": "SLASH",
  "(": "LPAREN",
  ")": "RPAREN",
};

const isDigit = (c: string): boolean => c >= "0" && c <= "9";

export function tokenize(source: string): Token[] {
  const tokens: Token[] = [];
  let i = 0;

  while (i < source.length) {
    const c = source[i];
    const column = i + 1;

    if (c === " " || c === "\t") {
      i++;
      continue;
    }

    const kind = SINGLE[c];
    if (kind !== undefined) {
      tokens.push({ kind, text: c, column });
      i++;
      continue;
    }

    if (isDigit(c)) {
      let j = i;
      while (j < source.length && isDigit(source[j])) j++;
      if (source[j] === ".") {
        j++;
        if (!(j < source.length && isDigit(source[j]))) {
          throw new NslError("E101", "decimal point must be followed by a digit", j + 1);
        }
        while (j < source.length && isDigit(source[j])) j++;
      }
      tokens.push({ kind: "NUMBER", text: source.slice(i, j), column });
      i = j;
      continue;
    }

    if (c === ".") {
      throw new NslError("E101", "number must start with a digit", column);
    }

    throw new NslError("E100", `unexpected character '${c}'`, column);
  }

  tokens.push({ kind: "EOF", text: "", column: source.length + 1 });
  return tokens;
}
