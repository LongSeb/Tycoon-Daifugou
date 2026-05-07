/**
 * Layer 2: Phonetic matching via Double Metaphone.
 *
 * Catches evasions like "phuk" or "kunt" that survive normalization because
 * they use alternative spellings rather than character substitution.
 *
 * Length constraint: a phonetic match is only accepted when the normalized
 * input length equals the raw blocked term length exactly. This prevents
 * short innocent words ("bass", "ab") from spuriously matching blocked terms
 * with short phonetic codes ("pussy"→"PS", "wop"→"AP").
 *
 * The phonetic cache is built once at module initialization.
 */

import { DoubleMetaphone } from "natural";

/** Singleton encoder — DoubleMetaphone is a class; process() is an instance method. */
const dm = new DoubleMetaphone();

/** One entry in the phonetic cache. */
interface CacheEntry {
  /** Double Metaphone codes for the term (up to two non-empty strings). */
  codes: string[];
  /** Character count of the raw (un-normalized) blocked term. */
  rawLength: number;
}

/**
 * Encodes a word with Double Metaphone.
 * Returns up to two non-empty phonetic codes (primary + secondary).
 */
function encode(word: string): string[] {
  const [primary, secondary] = dm.process(word) as [string, string];
  return [primary, secondary].filter((c): c is string => c.length > 0);
}

let _cache: ReadonlyMap<string, CacheEntry> | null = null;

/**
 * Builds (or returns the existing) phonetic cache from raw blocked terms.
 *
 * Each raw blocked term is encoded with Double Metaphone; the raw term's
 * character length is stored alongside the codes so `checkPhonetic` can
 * apply the length constraint.
 *
 * @param rawTerms - Raw (un-normalized) blocked terms from the JSON blocklist.
 */
export function buildPhoneticCache(
  rawTerms: readonly string[]
): ReadonlyMap<string, CacheEntry> {
  if (_cache !== null) return _cache;
  const map = new Map<string, CacheEntry>();
  for (const term of rawTerms) {
    const codes = encode(term); // encode the raw term directly
    if (codes.length > 0) {
      map.set(term, { codes, rawLength: term.length });
    }
  }
  _cache = map;
  return _cache;
}

/** Resets the singleton cache — for use in tests only. */
export function resetPhoneticCache(): void {
  _cache = null;
}

/**
 * Checks whether the phonetic encoding of `normalizedInput` matches any
 * cached blocked term.
 *
 * A match requires **both**:
 *  - At least one phonetic code from the input overlaps with a code from the
 *    blocked term.
 *  - The normalized input length equals the raw blocked term's character count.
 *    This length constraint is critical: without it, innocent short words like
 *    "bass" (PS) spuriously match "pussy" (PS, 5 chars) because both produce
 *    the same 2-character Metaphone code.
 *
 * @param normalizedInput - Already-normalized username (output of `normalizeUsername`).
 * @param cache - Pre-built phonetic cache from `buildPhoneticCache`.
 */
export function checkPhonetic(
  normalizedInput: string,
  cache: ReadonlyMap<string, CacheEntry>
): { matched: true; term: string } | { matched: false } {
  if (normalizedInput.length === 0) return { matched: false };

  const inputCodes = encode(normalizedInput);
  if (inputCodes.length === 0) return { matched: false };

  const inputLen = normalizedInput.length;

  for (const [term, { codes, rawLength }] of cache) {
    if (inputLen !== rawLength) continue; // length constraint

    for (const ic of inputCodes) {
      if (codes.includes(ic)) {
        return { matched: true, term };
      }
    }
  }
  return { matched: false };
}
