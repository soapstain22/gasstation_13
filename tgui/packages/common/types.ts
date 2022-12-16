/**
 * Returns the arguments of a function F as an array.
 */
// prettier-ignore
export type ArgumentsOf<F extends Function>
  = F extends (...args: infer A) => unknown ? A : never;

/** Returns an array of values of an object. */
export type ObjectValues<T> = T extends Record<string, unknown>
  ? T[keyof T]
  : never;
