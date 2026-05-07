/**
 * Username normalization for content filtering.
 * The normalized form is used for matching only — never display it to the user.
 */

/**
 * Zero-width and invisible Unicode code points, expressed as explicit hex escapes
 * so the regex is unambiguous regardless of editor or tool rendering.
 * Covers: soft hyphen (AD), zero-width space (200B), zero-width non-joiner (200C),
 * zero-width joiner (200D), left-to-right mark (200E), right-to-left mark (200F),
 * directional formatting chars (202A-202E), word joiner (2060), invisible operators
 * (2061-2064), BOM (FEFF), Mongolian vowel separator (180E).
 */
const ZERO_WIDTH_RE =
  /[­​‌‍‎‏‪-‮⁠⁡⁢⁣⁤﻿᠎]/g;

/** Unicode non-spacing marks (diacritics) left behind after NFD decomposition. */
const COMBINING_MARKS_RE = /\p{M}/gu;

/**
 * Maps a single character to its closest ASCII equivalent for filter purposes.
 * Priority: visual similarity for Cyrillic/Greek; phonetic convention for ASCII leet.
 * Digits included: only the unambiguous, high-frequency leet substitutions from the spec
 * (0→o, 1→i, 3→e, 4→a, 5→s, 7→t). Digits 2/6/8/9 are NOT mapped because they appear
 * commonly in clean usernames ("player99", "team86") and rarely serve as slur evasion.
 */
const HOMOGLYPH_MAP: Readonly<Record<string, string>> = {
  // ASCII leet / symbol substitutions
  "@": "a",
  "4": "a",
  "3": "e",
  "€": "e", // €
  "1": "i",
  "!": "i",
  "|": "i",
  "0": "o",
  $: "s",
  "5": "s",
  "7": "t",
  "+": "t",

  // Cyrillic → Latin VISUAL lookalikes (not phonetic — с looks like c, not s)
  "а": "a", // а
  "А": "a", // А
  "В": "b", // В → B
  "в": "b", // в
  "с": "c", // с → c  (NOT 's' — visual match)
  "С": "c", // С → C
  "е": "e", // е
  "Е": "e", // Е
  "к": "k", // к
  "К": "k", // К
  "м": "m", // м
  "М": "m", // М
  "н": "h", // н → h (uppercase Н looks like H)
  "Н": "h", // Н → H
  "о": "o", // о
  "О": "o", // О
  "р": "p", // р → p  (looks like p, NOT r)
  "Р": "p", // Р → P
  "т": "t", // т
  "Т": "t", // Т → T
  "х": "x", // х
  "Х": "x", // Х → X
  "у": "y", // у
  "У": "y", // У → Y
  "І": "i", // І (Ukrainian I)
  "і": "i", // і (Ukrainian i)

  // Greek visual lookalikes
  "α": "a", // α
  "ε": "e", // ε
  "ο": "o", // ο
  "ρ": "p", // ρ (looks like p)
  "υ": "y", // υ
  "κ": "k", // κ
  "τ": "t", // τ
};

/** Strip zero-width / invisible characters. */
function stripZeroWidth(s: string): string {
  return s.replace(ZERO_WIDTH_RE, "");
}

/** Remove diacritics: NFD-decompose then drop Unicode combining marks. */
function stripDiacritics(s: string): string {
  return s.normalize("NFD").replace(COMBINING_MARKS_RE, "");
}

/** Replace each character with its ASCII homoglyph equivalent, if known. */
function applyHomoglyphs(s: string): string {
  let out = "";
  for (const ch of s) {
    out += HOMOGLYPH_MAP[ch] ?? ch;
  }
  return out;
}

/**
 * Collapse 3 or more consecutive identical characters to 1.
 * "fuuuck" → "fuck", "shhhhit" → "shit".
 * Two repetitions are kept (many legitimate words double letters: "class", "grass").
 */
function collapseRepeats(s: string): string {
  return s.replace(/(.)\1{2,}/g, "$1");
}

/** Drop everything that is not ASCII a-z or 0-9. */
function stripNonAlphanumeric(s: string): string {
  return s.replace(/[^a-z0-9]/g, "");
}

/** Shared prefix pipeline: lowercase → zero-width strip → diacritics → homoglyphs → lowercase. */
function sharedPrefix(input: string): string {
  let s = input.toLowerCase();
  s = stripZeroWidth(s);
  s = stripDiacritics(s);
  s = applyHomoglyphs(s);
  return s.toLowerCase(); // re-lowercase in case any substitution left uppercase ASCII
}

/**
 * Normalizes a username for content-filter matching (full pipeline).
 *
 * Pipeline (applied in order):
 *  1. Lowercase
 *  2. Strip zero-width / invisible Unicode
 *  3. Strip diacritics (NFD + remove combining marks)
 *  4. Map homoglyphs and leet substitutions to ASCII
 *  5. Lowercase (re-apply after homoglyph step)
 *  6. Collapse 3+ consecutive identical characters to 1
 *  7. Strip remaining non-alphanumeric characters
 *
 * Result is ASCII-only, lowercase. Used for matching — never display it.
 *
 * @param input - Raw username as entered by the user.
 * @returns Normalized ASCII string for blocklist comparison.
 */
export function normalizeUsername(input: string): string {
  let s = sharedPrefix(input);
  s = collapseRepeats(s);
  s = stripNonAlphanumeric(s);
  return s;
}

/**
 * Like {@link normalizeUsername} but **skips the repeat-collapse step**.
 *
 * Used alongside `normalizeUsername` in the dictionary check so that terms
 * consisting of a repeated character (e.g. "kkk") are not collapsed to a
 * single character that would match any word containing that letter.
 *
 * @param input - Raw username as entered by the user.
 * @returns Normalized ASCII string without repeat collapse.
 */
export function normalizeWithoutCollapse(input: string): string {
  let s = sharedPrefix(input);
  s = stripNonAlphanumeric(s);
  return s;
}
