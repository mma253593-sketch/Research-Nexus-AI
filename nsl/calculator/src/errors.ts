// NSL Calculator — Diagnostics (Stage A, EXPERIMENTAL)
// Error codes are defined in nsl/calculator/SPEC.md §6

export type ErrorCode =
  | "E001" // input too long
  | "E100" // unexpected character
  | "E101" // malformed number
  | "E200" // unexpected token
  | "E201" // missing ')'
  | "E202" // nesting too deep
  | "E203" // empty input
  | "E300" // division by zero
  | "E301"; // result not finite (overflow)

export class NslError extends Error {
  readonly code: ErrorCode;
  /** 1-based column in the source line. */
  readonly column: number;

  constructor(code: ErrorCode, message: string, column: number) {
    super(message);
    this.name = "NslError";
    this.code = code;
    this.column = column;
  }

  format(): string {
    return `error ${this.code} at column ${this.column}: ${this.message}`;
  }
}
