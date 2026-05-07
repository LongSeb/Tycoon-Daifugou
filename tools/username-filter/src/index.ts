/**
 * Username content-filter module.
 *
 * Two-layer check:
 *
 *   Layer 1 — Normalization + dictionary:
 *     Collapses common evasion tricks (leet-speak, homoglyphs, zero-width chars,
 *     diacritics, separator characters, repeated-character stretching) then checks
 *     the result against a blocklist.
 *
 *     The dictionary check runs against TWO normalizations of the username:
 *       • Full  — with repeat-collapse (catches "fuuuck" → "fuck").
 *       • Partial — without repeat-collapse (catches "kkk" typed directly, which
 *                   would otherwise collapse to "k" and match any word with 'k').
 *
 *     Blocked terms are compared in their raw, un-normalized form. Allowlist words
 *     override false positives by positional coverage (e.g. "cunt" inside the
 *     username "scunthorpe" is excused because "scunthorpe" is in the allowlist).
 *
 *   Layer 2 — Phonetic (Double Metaphone):
 *     Catches alternative spellings that survive normalization (e.g. "phuk", "kunt").
 *     A length constraint (normalized input length must equal raw blocked-term length)
 *     prevents short innocent words from spuriously matching due to short phonetic codes.
 *
 * Both layers are fully synchronous; no I/O occurs after module load.
 */

import wordlists from "./blocklist.json" assert { type: "json" };
import { normalizeUsername, normalizeWithoutCollapse } from "./normalize.js";
import { buildPhoneticCache, checkPhonetic } from "./phonetic.js";

// ---------------------------------------------------------------------------
// Module-load initialization
// ---------------------------------------------------------------------------

/** Blocked terms exactly as stored in the JSON (raw, lowercase). */
const RAW_BLOCKED: readonly string[] = wordlists.blocked;

/** Allowlist words exactly as stored in the JSON (raw, lowercase). */
const RAW_ALLOWLIST: readonly string[] = wordlists.allowlist;

/**
 * Phonetic cache: raw blocked term → { Double Metaphone codes, rawLength }.
 * Built once at module load from the raw (un-normalized) blocked terms so that
 * the original term length is preserved for the length constraint in Layer 2.
 */
const PHONETIC_CACHE = buildPhoneticCache(RAW_BLOCKED);

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

/** Returns all [start, end) index ranges where `needle` appears in `haystack`. */
function findAllRanges(
  haystack: string,
  needle: string
): Array<[number, number]> {
  const ranges: Array<[number, number]> = [];
  let pos = 0;
  while ((pos = haystack.indexOf(needle, pos)) !== -1) {
    ranges.push([pos, pos + needle.length]);
    pos++;
  }
  return ranges;
}

/**
 * Returns true when `[bStart, bEnd)` is fully contained within at least one
 * `[aStart, aEnd)` range in `coveredBy`.
 */
function isCoveredBy(
  bStart: number,
  bEnd: number,
  coveredBy: Array<[number, number]>
): boolean {
  return coveredBy.some(([aStart, aEnd]) => aStart <= bStart && aEnd >= bEnd);
}

/**
 * Finds all positions where any allowlist word appears in `normalizedStr`.
 * These ranges are used to excuse blocked-term hits that fall inside a known
 * false-positive word (e.g. "cunt" inside "scunthorpe").
 */
function buildAllowlistRanges(
  normalizedStr: string
): Array<[number, number]> {
  const ranges: Array<[number, number]> = [];
  for (const allowed of RAW_ALLOWLIST) {
    for (const range of findAllRanges(normalizedStr, allowed)) {
      ranges.push(range);
    }
  }
  return ranges;
}

/**
 * Checks one normalized form of the username against all raw blocked terms.
 *
 * @returns The first raw blocked term found that is not covered by an allowlist
 *          word, or `null` if the string is clean.
 */
function checkNormalizedForm(normalized: string): string | null {
  const allowlistRanges = buildAllowlistRanges(normalized);
  for (const term of RAW_BLOCKED) {
    for (const [start, end] of findAllRanges(normalized, term)) {
      if (!isCoveredBy(start, end, allowlistRanges)) {
        return term;
      }
    }
  }
  return null;
}

/**
 * Layer 1: dictionary check.
 *
 * Runs against BOTH the full-normalized form (repeat-collapse applied) and the
 * partial-normalized form (no collapse) to catch both stretched spellings
 * ("fuuuck" → "fuck") and direct repeated-character terms ("kkk" typed straight).
 */
function dictionaryCheck(
  username: string
): { blocked: false } | { blocked: true; term: string } {
  // Full normalization — collapses "fuuuck" → "fuck", strips separators
  const normFull = normalizeUsername(username);
  const hitFull = checkNormalizedForm(normFull);
  if (hitFull !== null) return { blocked: true, term: hitFull };

  // Partial normalization — no collapse, so "kkk" stays "kkk" and isn't
  // reduced to "k" which would match any word containing that letter.
  const normPartial = normalizeWithoutCollapse(username);
  // Only run the partial check if it differs from the full (saves work)
  if (normPartial !== normFull) {
    const hitPartial = checkNormalizedForm(normPartial);
    if (hitPartial !== null) return { blocked: true, term: hitPartial };
  }

  return { blocked: false };
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/**
 * Result returned by {@link checkUsername}.
 */
export interface UsernameCheckResult {
  /** `true` if the username passes both filter layers. */
  allowed: boolean;
  /** Human-readable rejection reason (undefined when allowed). */
  reason?: string;
  /** Which layer caught the violation: `"layer1"` or `"layer2"`. */
  layer?: "layer1" | "layer2";
}

/**
 * Checks whether a username is acceptable for display.
 *
 * Runs Layer 1 (normalization + dictionary) first; if that passes, runs
 * Layer 2 (phonetic Double Metaphone). Short-circuits on the first failure.
 *
 * @param username - Raw username string as entered by the user.
 * @returns `{ allowed: true }` for a clean username, or
 *          `{ allowed: false, reason, layer }` for a violation.
 *
 * @example
 * checkUsername("coolplayer99")  // → { allowed: true }
 * checkUsername("f0ck")          // → { allowed: false, reason: "...", layer: "layer1" }
 * checkUsername("phuk")          // → { allowed: false, reason: "...", layer: "layer2" }
 */
export function checkUsername(username: string): UsernameCheckResult {
  // Layer 1 — normalization + dictionary
  const l1 = dictionaryCheck(username);
  if (l1.blocked) {
    return {
      allowed: false,
      reason: "Contains prohibited content (layer 1)",
      layer: "layer1",
    };
  }

  // Layer 2 — phonetic (check against the full-normalized form)
  const normalized = normalizeUsername(username);
  const l2 = checkPhonetic(normalized, PHONETIC_CACHE);
  if (l2.matched) {
    return {
      allowed: false,
      reason: "Phonetically similar to prohibited content (layer 2)",
      layer: "layer2",
    };
  }

  return { allowed: true };
}

export { normalizeUsername } from "./normalize.js";
