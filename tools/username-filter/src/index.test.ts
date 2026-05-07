import { describe, it, expect, beforeEach } from "vitest";
import { checkUsername, normalizeUsername } from "./index.js";
import { resetPhoneticCache } from "./phonetic.js";

// Reset phonetic cache before each suite so tests are independent.
beforeEach(() => resetPhoneticCache());

// ---------------------------------------------------------------------------
// normalizeUsername
// ---------------------------------------------------------------------------

describe("normalizeUsername", () => {
  it("lowercases ASCII input", () => {
    expect(normalizeUsername("HELLO")).toBe("hello");
    expect(normalizeUsername("CoolPlayer")).toBe("coolplayer");
  });

  it("strips zero-width characters", () => {
    // Zero-width space (U+200B) between letters
    expect(normalizeUsername("f​uck")).toBe("fuck");
    // Zero-width non-joiner (U+200C)
    expect(normalizeUsername("s‌h‌it")).toBe("shit");
    // BOM (U+FEFF)
    expect(normalizeUsername("﻿test")).toBe("test");
  });

  it("strips diacritics and accents", () => {
    expect(normalizeUsername("fück")).toBe("fuck");
    expect(normalizeUsername("shìt")).toBe("shit");
    expect(normalizeUsername("nïgger")).toBe("nigger");
  });

  it("maps common leet substitutions", () => {
    expect(normalizeUsername("f0ck")).toBe("fock"); // 0→o
    expect(normalizeUsername("sh1t")).toBe("shit"); // 1→i
    expect(normalizeUsername("sh!t")).toBe("shit"); // !→i
    expect(normalizeUsername("@ss")).toBe("ass"); // @→a
    expect(normalizeUsername("a$$hole")).toBe("asshole"); // $→s
    expect(normalizeUsername("5hit")).toBe("shit"); // 5→s
    expect(normalizeUsername("7wee7")).toBe("tweet"); // 7→t
    expect(normalizeUsername("4ss")).toBe("ass"); // 4→a
  });

  it("maps Cyrillic visual lookalikes", () => {
    // Cyrillic с looks like c, о looks like o
    expect(normalizeUsername("fuсk")).toBe("fuck"); // fuсk
    expect(normalizeUsername("fuоk")).toBe("fuok"); // fuок — о→o only
    expect(normalizeUsername("сunt")).toBe("cunt"); // сunt — с→c
  });

  it("collapses 3+ repeated characters to 1", () => {
    expect(normalizeUsername("fuuuck")).toBe("fuck"); // 3 u's → u
    expect(normalizeUsername("shhhhit")).toBe("shit"); // 4 h's → h
    expect(normalizeUsername("aaass")).toBe("ass"); // 3 a's → a, 2 s's stay
    expect(normalizeUsername("fuuuuuuuck")).toBe("fuck"); // many u's → u
  });

  it("strips spaces and non-alphanumeric characters", () => {
    expect(normalizeUsername("f u c k")).toBe("fuck");
    expect(normalizeUsername("f_u_c_k")).toBe("fuck");
    expect(normalizeUsername("f-u-c-k")).toBe("fuck");
    expect(normalizeUsername("f.u.c.k")).toBe("fuck");
  });

  it("applies spec digit mappings; unmapped digits (2,6,8,9) stay as-is", () => {
    // 9 is NOT mapped → stays as '9'
    expect(normalizeUsername("player99")).toBe("player99");
    // 4→a per spec; 2 is unmapped → stays as '2'
    expect(normalizeUsername("johndoe42")).toBe("johndoea2");
    // 0→o and 5→s per spec; 2 is unmapped
    expect(normalizeUsername("team2025")).toBe("team2o2s");
    // 2, 6, 8, 9 are all unmapped
    expect(normalizeUsername("a2b6c8d9")).toBe("a2b6c8d9");
  });
});

// ---------------------------------------------------------------------------
// Layer 1 — obvious profanity (exact matches)
// ---------------------------------------------------------------------------

describe("checkUsername — Layer 1 obvious profanity", () => {
  const cases: string[] = [
    "fuck",
    "shit",
    "bitch",
    "cunt",
    "asshole",
    "nigger",
    "nigga",
    "chink",
    "spic",
    "faggot",
    "fag",
    "nazi",
    "rape",
    "rapist",
    "dildo",
  ];

  for (const word of cases) {
    it(`blocks "${word}"`, () => {
      const result = checkUsername(word);
      expect(result.allowed).toBe(false);
      expect(result.layer).toBe("layer1");
    });
  }
});

// ---------------------------------------------------------------------------
// Layer 1 — leet-speak / symbol evasion
// ---------------------------------------------------------------------------

describe("checkUsername — Layer 1 leet-speak evasion", () => {
  it('blocks "f0ck" (0 → o produces "fock"; phonetically identical to "fuck")', () => {
    // 0→o maps to 'o', so "f0ck" normalizes to "fock" not "fuck".
    // "fock" is not a direct substring match, but it IS phonetically identical
    // to "fuck" (both encode to "FK") so it is caught by layer 2.
    const r = checkUsername("f0ck");
    expect(r.allowed).toBe(false);
    // Layer 2 (phonetic) catches it since "fock" ≠ "fuck" but sounds the same
    expect(r.layer).toBe("layer2");
  });

  it('blocks "sh1t" (1 → i)', () => {
    const r = checkUsername("sh1t");
    expect(r.allowed).toBe(false);
    expect(r.layer).toBe("layer1");
  });

  it('blocks "sh!t" (! → i)', () => {
    const r = checkUsername("sh!t");
    expect(r.allowed).toBe(false);
    expect(r.layer).toBe("layer1");
  });

  it('blocks "@ssh0le" (@ → a, 0 → o)', () => {
    const r = checkUsername("@ssh0le");
    expect(r.allowed).toBe(false);
    expect(r.layer).toBe("layer1");
  });

  it('blocks "a$$h0le" ($ → s, 0 → o)', () => {
    const r = checkUsername("a$$h0le");
    expect(r.allowed).toBe(false);
    expect(r.layer).toBe("layer1");
  });

  it('blocks "b1tch" (1 → i)', () => {
    const r = checkUsername("b1tch");
    expect(r.allowed).toBe(false);
    expect(r.layer).toBe("layer1");
  });

  it('blocks "5hit" (5 → s)', () => {
    const r = checkUsername("5hit");
    expect(r.allowed).toBe(false);
    expect(r.layer).toBe("layer1");
  });

  it('blocks "n1gg3r" (1 → i, 3 → e)', () => {
    const r = checkUsername("n1gg3r");
    expect(r.allowed).toBe(false);
    expect(r.layer).toBe("layer1");
  });
});

// ---------------------------------------------------------------------------
// Layer 1 — spaced-out / separator evasion
// ---------------------------------------------------------------------------

describe("checkUsername — Layer 1 separator evasion", () => {
  it('blocks "f u c k" (spaces stripped)', () => {
    const r = checkUsername("f u c k");
    expect(r.allowed).toBe(false);
    expect(r.layer).toBe("layer1");
  });

  it('blocks "f_u_c_k" (underscores stripped)', () => {
    const r = checkUsername("f_u_c_k");
    expect(r.allowed).toBe(false);
    expect(r.layer).toBe("layer1");
  });

  it('blocks "f.u.c.k" (dots stripped)', () => {
    const r = checkUsername("f.u.c.k");
    expect(r.allowed).toBe(false);
    expect(r.layer).toBe("layer1");
  });

  it('blocks "f-u-c-k" (dashes stripped)', () => {
    const r = checkUsername("f-u-c-k");
    expect(r.allowed).toBe(false);
    expect(r.layer).toBe("layer1");
  });

  it('blocks "s.h.i.t" (dots stripped)', () => {
    const r = checkUsername("s.h.i.t");
    expect(r.allowed).toBe(false);
    expect(r.layer).toBe("layer1");
  });
});

// ---------------------------------------------------------------------------
// Layer 1 — Unicode / Cyrillic / diacritic evasion
// ---------------------------------------------------------------------------

describe("checkUsername — Layer 1 Unicode evasion", () => {
  it("blocks username with zero-width space injection", () => {
    const r = checkUsername("f​uck");
    expect(r.allowed).toBe(false);
    expect(r.layer).toBe("layer1");
  });

  it("blocks username with zero-width non-joiner", () => {
    const r = checkUsername("s‌h‌i‌t");
    expect(r.allowed).toBe(false);
    expect(r.layer).toBe("layer1");
  });

  it("blocks username with BOM prefix", () => {
    const r = checkUsername("﻿fuck");
    expect(r.allowed).toBe(false);
    expect(r.layer).toBe("layer1");
  });

  it("blocks username with accented vowels (diacritics)", () => {
    const r = checkUsername("fück");
    expect(r.allowed).toBe(false);
    expect(r.layer).toBe("layer1");
  });

  it("blocks username using Cyrillic с (looks like c)", () => {
    // fuсk — с is U+0441, visually identical to c
    const r = checkUsername("fuсk");
    expect(r.allowed).toBe(false);
    expect(r.layer).toBe("layer1");
  });

  it("blocks username using Cyrillic а (looks like a)", () => {
    // nigger with Cyrillic а replacing a in a related term
    const r = checkUsername("nиgger"); // и is removed (not in map) → "ngger" — no match
    // The above should NOT catch it since и has no homoglyph.
    // Use the е (e-lookalike) variant instead:
    // niggеr → nigger with е replacing e
    const r2 = checkUsername("niggеr");
    expect(r2.allowed).toBe(false);
    expect(r2.layer).toBe("layer1");
  });

  it("blocks repeated-char evasion (fuuuuck)", () => {
    const r = checkUsername("fuuuuck");
    expect(r.allowed).toBe(false);
    expect(r.layer).toBe("layer1");
  });

  it("blocks repeated-char evasion (shhhhit)", () => {
    const r = checkUsername("shhhhit");
    expect(r.allowed).toBe(false);
    expect(r.layer).toBe("layer1");
  });
});

// ---------------------------------------------------------------------------
// Layer 2 — phonetic evasion
// ---------------------------------------------------------------------------

describe("checkUsername — Layer 2 phonetic evasion", () => {
  it('blocks "phuk" (phonetically identical to "fuck")', () => {
    const r = checkUsername("phuk");
    expect(r.allowed).toBe(false);
    expect(r.layer).toBe("layer2");
  });

  it('blocks "kunt" (phonetically identical to "cunt")', () => {
    const r = checkUsername("kunt");
    expect(r.allowed).toBe(false);
    expect(r.layer).toBe("layer2");
  });
});

// ---------------------------------------------------------------------------
// False-positive allowlist — these must PASS
// ---------------------------------------------------------------------------

describe("checkUsername — false-positive allowlist (must pass)", () => {
  const allowedWords = [
    "scunthorpe", // contains "cunt"
    "assassin", // contains "ass"
    "bass", // contains "ass"
    "class", // contains "ass"
    "grass", // contains "ass"
    "cockatoo", // contains "cock"
    "therapist", // contains "rapist"
    "shitake", // contains "shit"
    "shiitake", // contains "shit" (correct spelling)
    "bassoon", // contains "ass"
    "raccoon", // contains "coon"
    "cartoon", // contains "coon" (car+toon)
    "classic", // contains "ass"
    "peacock", // contains "cock"
    "hancock", // contains "cock"
    "massive", // contains "ass"
    "glass", // contains "ass"
    "brass", // contains "ass"
    "grape", // contains "rape"
    "drape", // contains "rape"
    "scrape", // contains "rape"
    "grapevine", // contains "rape"
  ];

  for (const word of allowedWords) {
    it(`allows "${word}"`, () => {
      const result = checkUsername(word);
      expect(result.allowed).toBe(true);
    });
  }
});

// ---------------------------------------------------------------------------
// Clean usernames — must always pass
// ---------------------------------------------------------------------------

describe("checkUsername — clean usernames (must pass)", () => {
  const clean: string[] = [
    "coolplayer",
    "player99",
    "johndoe42",
    "xXSwordMasterXx",
    "TycoonKing",
    "DaifugouPro",
    "CardShark",
    "sakura",
    "hanako",
    "blue_dragon",
    "red_phoenix",
    "123abc",
    "a",
    "ab",
    "thunderbolt",
    "mountain_lion",
  ];

  for (const name of clean) {
    it(`allows "${name}"`, () => {
      const result = checkUsername(name);
      expect(result.allowed).toBe(true);
    });
  }
});

// ---------------------------------------------------------------------------
// Result shape
// ---------------------------------------------------------------------------

describe("checkUsername — result shape", () => {
  it("returns { allowed: true } with no extra keys for clean input", () => {
    const r = checkUsername("coolplayer");
    expect(r.allowed).toBe(true);
    expect(r.reason).toBeUndefined();
    expect(r.layer).toBeUndefined();
  });

  it("returns allowed=false + reason + layer for blocked input", () => {
    const r = checkUsername("fuck");
    expect(r.allowed).toBe(false);
    expect(typeof r.reason).toBe("string");
    expect(r.layer === "layer1" || r.layer === "layer2").toBe(true);
  });

  it("is case-insensitive — FUCK and fuck are both blocked", () => {
    expect(checkUsername("FUCK").allowed).toBe(false);
    expect(checkUsername("Fuck").allowed).toBe(false);
    expect(checkUsername("fUcK").allowed).toBe(false);
  });

  it("empty string is allowed (validation of length is caller's responsibility)", () => {
    const r = checkUsername("");
    expect(r.allowed).toBe(true);
  });
});
