import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getDatabase, ServerValue } from "firebase-admin/database";
import type { Reference } from "firebase-admin/database";
import type {
  CardString,
  GameAction,
  Lobby,
  LobbySettings,
  RTDBGameState,
  RTDBPlayer,
} from "./types";

// ---------------------------------------------------------------------------
// Deck constants — mirror TycoonDaifugouKit/Models/Card.swift
//
// Rank strength ascending: 3 < 4 < 5 < 6 < 7 < 8 < 9 < 10 < J < Q < K < A < 2 < JKR
// ---------------------------------------------------------------------------
const RANKS = ["3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A", "2"] as const;
const SUITS = ["C", "D", "H", "S"] as const;
const RANK_STRENGTH: Record<string, number> = Object.fromEntries(
  RANKS.map((r, i) => [r, i])
);
RANK_STRENGTH["JKR"] = RANKS.length; // Joker beats everything

// ---------------------------------------------------------------------------
// Deck helpers
// ---------------------------------------------------------------------------

function buildDeck(jokerCount: 0 | 1 | 2 = 0): CardString[] {
  const deck: CardString[] = [];
  for (const suit of SUITS) {
    for (const rank of RANKS) {
      deck.push(`${rank}${suit}`);
    }
  }
  for (let i = 0; i < jokerCount; i++) {
    deck.push(`JKR${i}`);
  }
  return deck;
}

function shuffleDeck(deck: CardString[]): CardString[] {
  const d = [...deck];
  for (let i = d.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [d[i], d[j]] = [d[j], d[i]];
  }
  return d;
}

/** Deal the shuffled deck evenly — leftover cards go to earlier seats, matching the Swift engine. */
function dealCards(deck: CardString[], playerCount: number): CardString[][] {
  const base = Math.floor(deck.length / playerCount);
  const leftover = deck.length % playerCount;
  const hands: CardString[][] = [];
  let offset = 0;
  for (let i = 0; i < playerCount; i++) {
    const size = base + (i < leftover ? 1 : 0);
    hands.push(deck.slice(offset, offset + size));
    offset += size;
  }
  return hands;
}

function cardRankStr(card: CardString): string {
  if (card.startsWith("JKR")) return "JKR";
  return card.slice(0, -1); // strip the suit initial
}

function cardStrength(card: CardString): number {
  return RANK_STRENGTH[cardRankStr(card)] ?? -1;
}

// ---------------------------------------------------------------------------
// initializeGame — called directly from setReady when all players are ready
// ---------------------------------------------------------------------------
export async function initializeGame(lobbyId: string, lobby: Lobby): Promise<void> {
  // Idempotency guard: don't re-initialise a game that already exists
  const existing = await getDatabase().ref(`/games/${lobbyId}`).once("value");
  if (existing.exists()) return;

  // Merge caller settings on top of sane defaults so rules are always on
  // unless the host explicitly disabled them.
  const settings: Partial<LobbySettings> = {
    eightStopEnabled: true,
    revolutionEnabled: true,
    bankruptcyEnabled: true,
    threeSpadeReversalEnabled: false,
    roundsPerGame: 3,
    jokerCount: 2,
    ...lobby.settings,
  };
  const jokerCount = (settings.jokerCount ?? 0) as 0 | 1 | 2;

  const shuffled = shuffleDeck(buildDeck(jokerCount));
  const hands = dealCards(shuffled, lobby.players.length);

  // Starting player: whoever holds the 3 of Diamonds — mirrors newGame() in Swift
  const starterIndex = hands.findIndex((h) => h.includes("3D")) ?? 0;
  const playerOrder = lobby.players.map((p) => p.uid);

  const players: Record<string, RTDBPlayer> = {};
  lobby.players.forEach((p, i) => {
    players[p.uid] = {
      displayName: p.displayName,
      hand: hands[i],
      finishRank: null,
      connected: true,
    };
  });

  const gameState: RTDBGameState = {
    phase: "playing",
    round: 1,
    currentPlayerIndex: starterIndex,
    currentPlayerUid: playerOrder[starterIndex],
    playerOrder,
    players,
    currentTrick: [],
    passCountSinceLastPlay: 0,
    isRevolutionActive: false,
    lastPlayedByIndex: null,
    matchType: lobby.matchType,
    settings,
    status: "in_progress",
    eightStopEventCount: 0,
    revolutionEventCount: 0,
    threeSpadeEventCount: 0,
    updatedAt: ServerValue.TIMESTAMP as number,
  };

  await getDatabase().ref(`/games/${lobbyId}`).set(gameState);
}

// ---------------------------------------------------------------------------
// submitAction — current player plays cards or passes
// ---------------------------------------------------------------------------
export const submitAction = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in");
  }

  const uid = request.auth.uid;
  const { lobbyId, action } = request.data as { lobbyId: string; action: GameAction };

  if (!lobbyId || !action) {
    throw new HttpsError("invalid-argument", "lobbyId and action are required");
  }

  const gameRef = getDatabase().ref(`/games/${lobbyId}`);
  const snapshot = await gameRef.once("value");
  const state = snapshot.val() as RTDBGameState | null;

  if (!state || state.status !== "in_progress") {
    throw new HttpsError("failed-precondition", "Game is not in progress");
  }
  if (state.currentPlayerUid !== uid) {
    throw new HttpsError("failed-precondition", "Not your turn");
  }

  if (action.type === "pass") {
    await applyPass(gameRef, state);
    return;
  }
  if (action.type === "play") {
    await applyPlay(gameRef, state, uid, action.cards);
    return;
  }

  throw new HttpsError("invalid-argument", "Unknown action type");
});

// ---------------------------------------------------------------------------
// applyPass
// ---------------------------------------------------------------------------
async function applyPass(
  gameRef: Reference,
  state: RTDBGameState
): Promise<void> {
  const activePlayers = state.playerOrder.filter(
    (u) => state.players[u].finishRank == null
  );
  const newPassCount = state.passCountSinceLastPlay + 1;

  // Trick clears when all other active players have passed
  const trickClears =
    state.lastPlayedByIndex != null && newPassCount >= activePlayers.length - 1;

  let update: Record<string, unknown>;

  if (trickClears) {
    // Give the lead back to whoever made the last play
    const leadIndex = state.lastPlayedByIndex!;
    update = {
      currentPlayerIndex: leadIndex,
      currentPlayerUid: state.playerOrder[leadIndex],
      currentTrick: [],
      passCountSinceLastPlay: 0,
      lastPlayedByIndex: null,
      updatedAt: ServerValue.TIMESTAMP,
    };
  } else {
    const nextIndex = nextActivePlayerIndex(
      state.currentPlayerIndex,
      state.playerOrder,
      state.players
    );
    update = {
      currentPlayerIndex: nextIndex,
      currentPlayerUid: state.playerOrder[nextIndex],
      passCountSinceLastPlay: newPassCount,
      updatedAt: ServerValue.TIMESTAMP,
    };
  }

  await gameRef.update(update);
}

// ---------------------------------------------------------------------------
// applyPlay
// ---------------------------------------------------------------------------
async function applyPlay(
  gameRef: Reference,
  state: RTDBGameState,
  uid: string,
  cards: CardString[]
): Promise<void> {
  // RTDB drops both empty arrays and empty objects — normalise on read
  const currentTrick: CardString[][] = state.currentTrick ?? [];
  const settings = state.settings ?? {};

  const player = state.players[uid];

  // Verify card ownership
  for (const card of cards) {
    if (!player.hand.includes(card)) {
      throw new HttpsError("failed-precondition", `Card ${card} not in hand`);
    }
  }

  // Validate hand type (1–4 of same rank, or Joker plays)
  validateHandType(cards);

  // Validate the play beats the current trick top
  if (currentTrick.length > 0) {
    const topPlay = currentTrick[currentTrick.length - 1];
    validateBeats(cards, topPlay, state.isRevolutionActive, settings.threeSpadeReversalEnabled ?? false);
  }

  const currentIndex = state.playerOrder.indexOf(uid);
  const newHand = player.hand.filter((c) => !cards.includes(c));
  const newTrick = [...currentTrick, cards];

  const playerFinished = newHand.length === 0;
  const alreadyFinished = countFinished(state);
  const playerFinishRank = playerFinished ? alreadyFinished + 1 : null;

  // Revolution: 4-of-a-kind flips the rank order if the rule is enabled
  const nonJokers = cards.filter((c) => !c.startsWith("JKR"));
  const isQuad = nonJokers.length === 4 && cards.length === 4;
  const newRevolution =
    isQuad && (settings.revolutionEnabled ?? false)
      ? !state.isRevolutionActive
      : state.isRevolutionActive;

  // 8-Stop: all played cards are 8s → clear the trick, same player leads again
  const is8Stop =
    (settings.eightStopEnabled ?? false) &&
    nonJokers.length > 0 &&
    nonJokers.every((c) => cardRankStr(c) === "8");

  // 3-Spade Reversal: solo 3♠ beating a solo Joker
  const topPlay = currentTrick.length > 0 ? currentTrick[currentTrick.length - 1] : null;
  const isThreeSpadeReversal =
    (settings.threeSpadeReversalEnabled ?? false) &&
    cards.length === 1 &&
    cards[0] === "3S" &&
    topPlay !== null &&
    topPlay.length === 1 &&
    topPlay[0].startsWith("JKR");

  // Players still active after this move
  const remainingActive = state.playerOrder.filter((u) => {
    if (u === uid) return !playerFinished;
    return state.players[u].finishRank == null;
  });

  // Round ends when only 0 or 1 players remain without a finish rank
  const roundOver = remainingActive.length <= 1;

  let update: Record<string, unknown> = {
    [`players/${uid}/hand`]: newHand,
    isRevolutionActive: newRevolution,
    updatedAt: ServerValue.TIMESTAMP,
  };

  // Increment event counters so clients can trigger animations reliably
  if (isQuad && (settings.revolutionEnabled ?? false)) {
    update["revolutionEventCount"] = (state.revolutionEventCount ?? 0) + 1;
  }
  if (isThreeSpadeReversal) {
    update["threeSpadeEventCount"] = (state.threeSpadeEventCount ?? 0) + 1;
  }

  if (playerFinished) {
    update[`players/${uid}/finishRank`] = playerFinishRank;
  }

  if (roundOver) {
    // Auto-assign last place to the one remaining active player (the Beggar)
    if (remainingActive.length === 1) {
      const beggar = remainingActive[0];
      update[`players/${beggar}/finishRank`] = alreadyFinished + (playerFinished ? 2 : 1);
    }

    // Build effective finish ranks for this completed round.
    // Some players finished in earlier turns (already in DB state); the current player
    // and any final beggar were just computed above but not yet written to DB.
    const effectiveRanks: Record<string, number> = {};
    state.playerOrder.forEach((pUid) => {
      if (state.players[pUid].finishRank != null) effectiveRanks[pUid] = state.players[pUid].finishRank!;
    });
    if (playerFinished && playerFinishRank != null) effectiveRanks[uid] = playerFinishRank;
    if (remainingActive.length === 1) {
      const beggar = remainingActive[0];
      effectiveRanks[beggar] = alreadyFinished + (playerFinished ? 2 : 1);
    }

    // Persist this round's results so they survive the per-round finishRank reset
    update[`roundResults/${state.round}`] = effectiveRanks;

    const maxRounds = settings.roundsPerGame ?? 3;

    if (state.round >= maxRounds) {
      update["status"] = "finished";
      update["phase"] = "roundEnded";
    } else {
      // Start next round: reshuffle, redeal, optional bankruptcy trade, reset per-round state
      const jokerCount = (settings.jokerCount ?? 2) as 0 | 1 | 2;
      const newDeck = shuffleDeck(buildDeck(jokerCount));
      const newHands = dealCards(newDeck, state.playerOrder.length);

      const handsByUid: Record<string, CardString[]> = {};
      state.playerOrder.forEach((pUid, i) => { handsByUid[pUid] = [...newHands[i]]; });

      if (settings.bankruptcyEnabled) {
        executeTrade(handsByUid, effectiveRanks, state.playerOrder.length);
      }

      const rawStarterIndex = state.playerOrder.findIndex((pUid) => handsByUid[pUid]?.includes("3D"));
      const newStarterIndex = rawStarterIndex >= 0 ? rawStarterIndex : 0;

      state.playerOrder.forEach((pUid) => {
        update[`players/${pUid}/hand`] = handsByUid[pUid];
        update[`players/${pUid}/finishRank`] = null;
      });

      update["round"] = state.round + 1;
      update["phase"] = "playing";
      update["currentPlayerIndex"] = newStarterIndex;
      update["currentPlayerUid"] = state.playerOrder[newStarterIndex];
      update["currentTrick"] = [];
      update["passCountSinceLastPlay"] = 0;
      update["isRevolutionActive"] = false;
      update["lastPlayedByIndex"] = null;
    }
  } else if (is8Stop) {
    // Trick clears but the same player leads again
    update = {
      ...update,
      currentPlayerIndex: currentIndex,
      currentPlayerUid: uid,
      currentTrick: [],
      passCountSinceLastPlay: 0,
      lastPlayedByIndex: null,
      eightStopEventCount: (state.eightStopEventCount ?? 0) + 1,
    };
  } else {
    // Normal play: advance to the next active player
    const updatedPlayers = playerFinished
      ? { ...state.players, [uid]: { ...player, hand: newHand, finishRank: playerFinishRank } }
      : state.players;
    const nextIndex = nextActivePlayerIndex(
      currentIndex,
      state.playerOrder,
      updatedPlayers
    );
    update = {
      ...update,
      currentPlayerIndex: nextIndex,
      currentPlayerUid: state.playerOrder[nextIndex],
      currentTrick: newTrick,
      passCountSinceLastPlay: 0,
      lastPlayedByIndex: currentIndex,
    };
  }

  await gameRef.update(update);
}

// ---------------------------------------------------------------------------
// Hand validation
// ---------------------------------------------------------------------------

function validateHandType(cards: CardString[]): void {
  if (cards.length < 1 || cards.length > 4) {
    throw new HttpsError("invalid-argument", `Invalid hand size: ${cards.length}`);
  }
  const nonJokers = cards.filter((c) => !c.startsWith("JKR"));
  // Pure Joker plays (solo or pair) are always legal as trump
  if (nonJokers.length === 0) return;

  const ranks = new Set(nonJokers.map(cardRankStr));
  if (ranks.size !== 1) {
    throw new HttpsError(
      "invalid-argument",
      "All non-Joker cards must share the same rank"
    );
  }
}

function validateBeats(
  played: CardString[],
  topPlay: CardString[],
  revolutionActive: boolean,
  threeSpadeReversalEnabled: boolean
): void {
  if (played.length !== topPlay.length) {
    throw new HttpsError(
      "invalid-argument",
      `Must play ${topPlay.length} card(s) to match the trick`
    );
  }

  const playedAllJokers = played.every((c) => c.startsWith("JKR"));
  const topAllJokers = topPlay.every((c) => c.startsWith("JKR"));

  // Double Joker can only be beaten by nothing — it always wins
  if (topAllJokers && topPlay.length === 2) {
    throw new HttpsError("failed-precondition", "Cannot beat a double Joker play");
  }

  // 3-Spade Reversal: solo 3♠ beats a solo Joker
  if (
    threeSpadeReversalEnabled &&
    played.length === 1 &&
    played[0] === "3S" &&
    topAllJokers &&
    topPlay.length === 1
  ) {
    return;
  }

  // Solo Joker is beaten only by double Joker or 3♠ reversal (handled above)
  if (topAllJokers && !playedAllJokers) {
    throw new HttpsError("failed-precondition", "Cannot beat a Joker play with regular cards");
  }

  // Joker always beats any regular hand
  if (playedAllJokers) return;

  const playedStrength = cardStrength(played[0]);
  const topStrength = cardStrength(topPlay[0]);

  const beats = revolutionActive
    ? playedStrength < topStrength
    : playedStrength > topStrength;

  if (!beats) {
    throw new HttpsError("failed-precondition", "Played hand does not beat the top of the trick");
  }
}

// ---------------------------------------------------------------------------
// abandonGame — current player forfeits, ends the game for everyone
// ---------------------------------------------------------------------------
export const abandonGame = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in");
  }

  const uid = request.auth.uid;
  const { lobbyId } = request.data as { lobbyId: string };

  if (!lobbyId) {
    throw new HttpsError("invalid-argument", "lobbyId is required");
  }

  const gameRef = getDatabase().ref(`/games/${lobbyId}`);
  const snapshot = await gameRef.once("value");
  const state = snapshot.val() as RTDBGameState | null;

  if (!state || state.status !== "in_progress") {
    throw new HttpsError("failed-precondition", "Game is not in progress");
  }

  const player = state.players[uid];
  if (!player) {
    throw new HttpsError("permission-denied", "You are not in this game");
  }

  await gameRef.update({
    status: "abandoned",
    phase: "abandoned",
    abandonedBy: player.displayName,
    updatedAt: ServerValue.TIMESTAMP,
  });

  return { ok: true };
});

// ---------------------------------------------------------------------------
// Bankruptcy — card exchange between ranks at the start of each new round
// ---------------------------------------------------------------------------

function executeTrade(
  handsByUid: Record<string, CardString[]>,
  finishRanks: Record<string, number>,
  playerCount: number
): void {
  const byRank = Object.entries(finishRanks).sort(([, a], [, b]) => a - b);
  if (byRank.length < 2) return;

  const trades: Array<{ topUid: string; bottomUid: string; count: number }> = [];

  // Tycoon (rank 1) ↔ Beggar (rank last): 1 card for 2-player, 2 cards otherwise
  trades.push({
    topUid: byRank[0][0],
    bottomUid: byRank[byRank.length - 1][0],
    count: playerCount === 2 ? 1 : 2,
  });

  // Millionaire (rank 2) ↔ Poor (rank 3) in 4-player only: 1 card
  if (playerCount === 4 && byRank.length === 4) {
    trades.push({ topUid: byRank[1][0], bottomUid: byRank[2][0], count: 1 });
  }

  for (const { topUid, bottomUid, count } of trades) {
    const topHand = [...handsByUid[topUid]];
    const bottomHand = [...handsByUid[bottomUid]];

    // Beggar gives their strongest `count` cards to Tycoon
    const bottomSorted = [...bottomHand].sort((a, b) => cardStrength(b) - cardStrength(a));
    const bottomGives = bottomSorted.slice(0, count);

    // Tycoon gives their weakest `count` cards to Beggar
    const topSorted = [...topHand].sort((a, b) => cardStrength(a) - cardStrength(b));
    const topGives = topSorted.slice(0, count);

    handsByUid[topUid] = topHand.filter((c) => !topGives.includes(c)).concat(bottomGives);
    handsByUid[bottomUid] = bottomHand.filter((c) => !bottomGives.includes(c)).concat(topGives);
  }
}

// ---------------------------------------------------------------------------
// Turn helpers
// ---------------------------------------------------------------------------

function nextActivePlayerIndex(
  currentIndex: number,
  playerOrder: string[],
  players: Record<string, RTDBPlayer | { finishRank: number | null }>
): number {
  const count = playerOrder.length;
  let next = (currentIndex + 1) % count;
  // Skip players who have already finished; guard prevents infinite loop
  for (let guard = 0; guard < count; guard++) {
    if (players[playerOrder[next]]?.finishRank == null) break;
    next = (next + 1) % count;
  }
  return next;
}

function countFinished(state: RTDBGameState): number {
  return state.playerOrder.filter((u) => state.players[u].finishRank != null).length;
}
