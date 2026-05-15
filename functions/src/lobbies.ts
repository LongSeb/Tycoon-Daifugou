import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import type { DocumentReference } from "firebase-admin/firestore";
import type { Lobby, LobbyPlayer } from "./types";
import { initializeGame } from "./game";

// ---------------------------------------------------------------------------
// createLobby — host a private match and receive an invite code
// ---------------------------------------------------------------------------
export const createLobby = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in");
  }

  const uid = request.auth.uid;
  const playerDoc = await getFirestore().collection("players").doc(uid).get();
  const pd = playerDoc.data();
  const displayName = (request.data.displayName as string | undefined) ?? (pd?.username as string | undefined) ?? "Player";
  const emoji = (request.data.emoji as string | undefined) ?? (pd?.emoji as string | undefined) ?? "😎";
  const title = (request.data.title as string | undefined) ?? (pd?.equippedTitleID as string | undefined) ?? "Commoner";
  const borderID = (request.data.borderID as string | undefined) ?? (pd?.equippedBorderID as string | undefined);
  const inviteCode = generateCode();

  const lobby: Lobby = {
    status: "waiting",
    matchType: "private",
    inviteCode,
    hostUid: uid,
    players: [{ uid, displayName, ready: false, emoji, title, ...(borderID && { borderID }) }],
    maxPlayers: request.data.maxPlayers ?? 2,
    createdAt: FieldValue.serverTimestamp() as FirebaseFirestore.Timestamp,
    settings: request.data.settings ?? {},
  };

  const ref = getFirestore().collection("lobbies").doc();
  await ref.set(lobby);
  return { lobbyId: ref.id, inviteCode };
});

// ---------------------------------------------------------------------------
// joinWithCode — join a private lobby using its invite code
// ---------------------------------------------------------------------------
export const joinWithCode = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in");
  }

  const uid = request.auth.uid;
  const playerDoc = await getFirestore().collection("players").doc(uid).get();
  const pd = playerDoc.data();
  const displayName = (request.data.displayName as string | undefined) ?? (pd?.username as string | undefined) ?? "Player";
  const emoji = (request.data.emoji as string | undefined) ?? (pd?.emoji as string | undefined) ?? "😎";
  const title = (request.data.title as string | undefined) ?? (pd?.equippedTitleID as string | undefined) ?? "Commoner";
  const borderID = (request.data.borderID as string | undefined) ?? (pd?.equippedBorderID as string | undefined);
  const { inviteCode } = request.data as { inviteCode: string };

  if (!inviteCode || typeof inviteCode !== "string") {
    throw new HttpsError("invalid-argument", "inviteCode is required");
  }

  const snap = await getFirestore()
    .collection("lobbies")
    .where("inviteCode", "==", inviteCode.toUpperCase())
    .where("status", "==", "waiting")
    .limit(1)
    .get();

  if (snap.empty) {
    throw new HttpsError("not-found", "Lobby not found or no longer open");
  }

  const lobbyRef = snap.docs[0].ref;
  const lobby = snap.docs[0].data() as Lobby;

  // Already in the lobby — idempotent
  if (lobby.players.find((p) => p.uid === uid)) {
    return { lobbyId: lobbyRef.id };
  }

  const updated: LobbyPlayer[] = [...lobby.players, { uid, displayName, ready: false, emoji, title, ...(borderID && { borderID }) }];
  const isFull = updated.length >= lobby.maxPlayers;

  await lobbyRef.update({ players: updated, status: isFull ? "full" : "waiting" });
  return { lobbyId: lobbyRef.id };
});

// ---------------------------------------------------------------------------
// joinQueue — random matchmaking (joins an open lobby or creates a new one)
// ---------------------------------------------------------------------------
export const joinQueue = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in");
  }

  const uid = request.auth.uid;
  const playerDoc = await getFirestore().collection("players").doc(uid).get();
  const pd = playerDoc.data();
  const displayName = (request.data.displayName as string | undefined) ?? (pd?.username as string | undefined) ?? "Player";
  const emoji = (request.data.emoji as string | undefined) ?? (pd?.emoji as string | undefined) ?? "😎";
  const title = (request.data.title as string | undefined) ?? (pd?.equippedTitleID as string | undefined) ?? "Commoner";
  const borderID = (request.data.borderID as string | undefined) ?? (pd?.equippedBorderID as string | undefined);
  const maxPlayers: 2 | 3 | 4 = request.data.maxPlayers ?? 2;

  const snap = await getFirestore()
    .collection("lobbies")
    .where("matchType", "==", "random")
    .where("status", "==", "waiting")
    .where("maxPlayers", "==", maxPlayers)
    .limit(1)
    .get();

  let lobbyRef: DocumentReference;

  if (!snap.empty) {
    lobbyRef = snap.docs[0].ref;
    const lobby = snap.docs[0].data() as Lobby;

    // Already queued — idempotent
    if (lobby.players.find((p) => p.uid === uid)) {
      return { lobbyId: lobbyRef.id };
    }

    const updated: LobbyPlayer[] = [...lobby.players, { uid, displayName, ready: false, emoji, title, ...(borderID && { borderID }) }];
    const isFull = updated.length >= lobby.maxPlayers;
    await lobbyRef.update({ players: updated, status: isFull ? "full" : "waiting" });
  } else {
    const lobby: Lobby = {
      status: "waiting",
      matchType: "random",
      inviteCode: null,
      hostUid: uid,
      players: [{ uid, displayName, ready: false, emoji, title, ...(borderID && { borderID }) }],
      maxPlayers,
      createdAt: FieldValue.serverTimestamp() as FirebaseFirestore.Timestamp,
      settings: {},
    };
    lobbyRef = getFirestore().collection("lobbies").doc();
    await lobbyRef.set(lobby);
  }

  return { lobbyId: lobbyRef.id };
});

// ---------------------------------------------------------------------------
// setReady — player confirms they're ready; game starts when all players ready
// ---------------------------------------------------------------------------
export const setReady = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in");
  }

  const uid = request.auth.uid;
  const { lobbyId } = request.data as { lobbyId: string };

  if (!lobbyId) {
    throw new HttpsError("invalid-argument", "lobbyId is required");
  }

  const lobbyRef = getFirestore().collection("lobbies").doc(lobbyId);
  const doc = await lobbyRef.get();

  if (!doc.exists) {
    throw new HttpsError("not-found", "Lobby not found");
  }

  const lobby = doc.data() as Lobby;

  if (!lobby.players.find((p) => p.uid === uid)) {
    throw new HttpsError("permission-denied", "You are not in this lobby");
  }

  if (lobby.status !== "waiting" && lobby.status !== "full") {
    throw new HttpsError(
      "failed-precondition",
      "Lobby is not accepting ready confirmations"
    );
  }

  const updatedPlayers = lobby.players.map((p) =>
    p.uid === uid ? { ...p, ready: true } : p
  );

  const lobbyFull = updatedPlayers.length >= lobby.maxPlayers;
  const allReady = lobbyFull && updatedPlayers.every((p) => p.ready);

  if (allReady) {
    const updatedLobby: Lobby = { ...lobby, players: updatedPlayers };
    await lobbyRef.update({ players: updatedPlayers, status: "in_progress" });
    await initializeGame(lobbyId, updatedLobby);
  } else {
    await lobbyRef.update({ players: updatedPlayers });
  }

  return { ok: true };
});

// ---------------------------------------------------------------------------
// leaveLobby — any player cancels the lobby for everyone
// ---------------------------------------------------------------------------
export const leaveLobby = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in");
  }

  const uid = request.auth.uid;
  const { lobbyId } = request.data as { lobbyId: string };

  if (!lobbyId) {
    throw new HttpsError("invalid-argument", "lobbyId is required");
  }

  const lobbyRef = getFirestore().collection("lobbies").doc(lobbyId);
  const doc = await lobbyRef.get();

  if (!doc.exists) {
    throw new HttpsError("not-found", "Lobby not found");
  }

  const lobby = doc.data() as Lobby;

  if (!lobby.players.find((p) => p.uid === uid)) {
    throw new HttpsError("permission-denied", "You are not in this lobby");
  }

  const updatedPlayers = lobby.players.filter((p) => p.uid !== uid);

  if (updatedPlayers.length === 0) {
    // Last player left — cancel the lobby
    await lobbyRef.update({ players: [], status: "cancelled" });
  } else {
    // Transfer host if the host is the one leaving
    const newHostUid =
      lobby.hostUid === uid ? updatedPlayers[0].uid : lobby.hostUid;
    await lobbyRef.update({
      players: updatedPlayers,
      status: "waiting",
      hostUid: newHostUid,
    });
  }

  return { ok: true };
});

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
// Excludes homoglyphs: 0/O, 1/I/L
const CODE_ALPHABET = "23456789ABCDEFGHJKMNPQRSTUVWXYZ";

function generateCode(): string {
  let code = "";
  for (let i = 0; i < 6; i++) {
    code += CODE_ALPHABET[Math.floor(Math.random() * CODE_ALPHABET.length)];
  }
  return code;
}
