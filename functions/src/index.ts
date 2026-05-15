import * as admin from "firebase-admin";
admin.initializeApp({
  databaseURL: "https://tycooniosgame-default-rtdb.firebaseio.com",
});

export { createLobby, joinWithCode, joinQueue, setReady, leaveLobby } from "./lobbies";
export { submitAction, abandonGame } from "./game";
