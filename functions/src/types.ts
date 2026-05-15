// Shared TypeScript types for Tycoon multiplayer.
//
// Card encoding: rank initial + suit initial, e.g. "3C", "10H", "KS", "2D".
// Jokers: "JKR0", "JKR1".
// Rank strength (ascending): 3 < 4 < 5 < 6 < 7 < 8 < 9 < 10 < J < Q < K < A < 2 < JKR
// This mirrors the Rank enum raw values in TycoonDaifugouKit/Models/Card.swift.

export type CardString = string;

// ---------------------------------------------------------------------------
// Lobby (Firestore /lobbies/{lobbyId})
// ---------------------------------------------------------------------------

export interface LobbyPlayer {
  uid: string;
  displayName: string;
  ready: boolean;
  emoji?: string;
  title?: string;
  borderID?: string;
}

/** Mirrors the RuleSet struct in TycoonDaifugouKit. */
export interface LobbySettings {
  jokerCount: 0 | 1 | 2;
  revolutionEnabled: boolean;
  eightStopEnabled: boolean;
  threeSpadeReversalEnabled: boolean;
  bankruptcyEnabled: boolean;
  roundsPerGame: number;
}

export interface Lobby {
  status: "waiting" | "full" | "in_progress" | "finished" | "cancelled";
  matchType: "random" | "private" | "ranked";
  inviteCode: string | null;
  hostUid: string;
  players: LobbyPlayer[];
  maxPlayers: 2 | 3 | 4;
  createdAt: FirebaseFirestore.Timestamp;
  settings: Partial<LobbySettings>;
}

// ---------------------------------------------------------------------------
// Realtime Database (/games/{lobbyId})
// ---------------------------------------------------------------------------

export interface RTDBPlayer {
  displayName: string;
  hand: CardString[];
  /** 1-indexed finishing position this round (1 = Tycoon). null = still playing. */
  finishRank: number | null;
  connected: boolean;
}

export interface RTDBGameState {
  phase: "playing" | "trading" | "scoring" | "roundEnded" | "finished" | "abandoned";
  round: number;
  currentPlayerIndex: number;
  currentPlayerUid: string;
  /** UIDs in seat order — determines turn rotation. */
  playerOrder: string[];
  players: Record<string, RTDBPlayer>;
  /** Array of played hands since the last trick clear. Each hand is an array of card strings. */
  currentTrick: CardString[][];
  passCountSinceLastPlay: number;
  isRevolutionActive: boolean;
  /** Index into playerOrder of the player who made the last play (null if trick is empty). */
  lastPlayedByIndex: number | null;
  matchType: "random" | "private" | "ranked";
  settings: Partial<LobbySettings>;
  status: "in_progress" | "finished" | "abandoned";
  /** Completed round finish ranks keyed by round number (string). uid → 1-indexed finishRank. */
  roundResults?: Record<string, Record<string, number>>;
  /** Display name of the player who abandoned the game, if applicable. */
  abandonedBy?: string;
  /** Monotonically incrementing counters — clients watch these to trigger animations. */
  eightStopEventCount?: number;
  revolutionEventCount?: number;
  threeSpadeEventCount?: number;
  updatedAt: number;
}

// ---------------------------------------------------------------------------
// Actions (submitAction payload)
// ---------------------------------------------------------------------------

export interface PlayAction {
  type: "play";
  cards: CardString[];
}

export interface PassAction {
  type: "pass";
}

export type GameAction = PlayAction | PassAction;
