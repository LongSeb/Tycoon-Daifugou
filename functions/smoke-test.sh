#!/usr/bin/env bash
# Smoke test — runs against the local Firebase emulator suite.
# Start emulators first: firebase emulators:start

BASE="http://127.0.0.1:5001/tycooniosgame/us-central1"
AUTH="http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1"
RTDB="http://127.0.0.1:9000/games"
RTDB_NS="?ns=tycooniosgame"
TMP=$(mktemp -d)

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'
pass() { echo -e "${GREEN}✔  $1${NC}"; }
fail() { echo -e "${RED}✗  $1${NC}"; exit 1; }
info() { echo -e "${YELLOW}▶  $1${NC}"; }

# POST to a callable function; body written to a temp file to avoid shell quoting issues
fn_call() {
  local token="$1" fn="$2" body_file="$3"
  curl -s -X POST "${BASE}/${fn}" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${token}" \
    -d "@${body_file}"
}

# ---------------------------------------------------------------------------
info "Creating Player A in Auth emulator..."
curl -s -X POST "${AUTH}/accounts:signUp?key=test-key" \
  -H "Content-Type: application/json" \
  -d '{"displayName":"Player A","returnSecureToken":true}' \
  -o "$TMP/player_a.json"
TOKEN_A=$(jq -r '.idToken' "$TMP/player_a.json")
UID_A=$(jq -r '.localId' "$TMP/player_a.json")
[ "$TOKEN_A" != "null" ] && pass "Player A created (uid: $UID_A)" || fail "Could not create Player A — is the Auth emulator running?"

info "Creating Player B in Auth emulator..."
curl -s -X POST "${AUTH}/accounts:signUp?key=test-key" \
  -H "Content-Type: application/json" \
  -d '{"displayName":"Player B","returnSecureToken":true}' \
  -o "$TMP/player_b.json"
TOKEN_B=$(jq -r '.idToken' "$TMP/player_b.json")
UID_B=$(jq -r '.localId' "$TMP/player_b.json")
[ "$TOKEN_B" != "null" ] && pass "Player B created (uid: $UID_B)" || fail "Could not create Player B"

# ---------------------------------------------------------------------------
info "createLobby — Player A hosts a private 2-player lobby..."
echo '{"data":{"maxPlayers":2}}' > "$TMP/create_lobby.json"
fn_call "$TOKEN_A" "createLobby" "$TMP/create_lobby.json" -o "$TMP/lobby_resp.json" 2>/dev/null
fn_call "$TOKEN_A" "createLobby" "$TMP/create_lobby.json" > "$TMP/lobby_resp.json"
echo "  Response: $(cat "$TMP/lobby_resp.json")"
LOBBY_ID=$(jq -r '.result.lobbyId // empty' "$TMP/lobby_resp.json")
INVITE_CODE=$(jq -r '.result.inviteCode // empty' "$TMP/lobby_resp.json")
[ -n "$LOBBY_ID" ] && pass "Lobby created — id: $LOBBY_ID  code: $INVITE_CODE" || fail "createLobby failed"

# ---------------------------------------------------------------------------
info "joinWithCode — bad code should be rejected..."
echo '{"data":{"inviteCode":"XXXXXX"}}' > "$TMP/bad_code.json"
fn_call "$TOKEN_B" "joinWithCode" "$TMP/bad_code.json" > "$TMP/bad_code_resp.json"
echo "  Response: $(cat "$TMP/bad_code_resp.json")"
BAD_STATUS=$(jq -r '.error.status // empty' "$TMP/bad_code_resp.json")
[ "$BAD_STATUS" = "NOT_FOUND" ] && pass "Bad invite code correctly rejected" || fail "Expected NOT_FOUND, got: $(cat "$TMP/bad_code_resp.json")"

# ---------------------------------------------------------------------------
info "joinWithCode — Player B joins with the correct code..."
jq -n --arg code "$INVITE_CODE" '{"data":{"inviteCode":$code}}' > "$TMP/join.json"
fn_call "$TOKEN_B" "joinWithCode" "$TMP/join.json" > "$TMP/join_resp.json"
echo "  Response: $(cat "$TMP/join_resp.json")"
JOINED_ID=$(jq -r '.result.lobbyId // empty' "$TMP/join_resp.json")
[ "$JOINED_ID" = "$LOBBY_ID" ] && pass "Player B joined lobby $LOBBY_ID" || fail "joinWithCode failed: $(cat "$TMP/join_resp.json")"

# ---------------------------------------------------------------------------
info "setReady — game should NOT start until both players are ready..."
jq -n --arg lid "$LOBBY_ID" '{"data":{"lobbyId":$lid}}' > "$TMP/ready.json"
fn_call "$TOKEN_A" "setReady" "$TMP/ready.json" > "$TMP/ready_a_resp.json"
echo "  Player A ready response: $(cat "$TMP/ready_a_resp.json")"
READY_A=$(jq -r '.result.ok // empty' "$TMP/ready_a_resp.json")
[ "$READY_A" = "true" ] && pass "Player A marked ready" || fail "setReady failed for Player A: $(cat "$TMP/ready_a_resp.json")"

sleep 2
GAME_EARLY=$(curl -s "${RTDB}/${LOBBY_ID}.json${RTDB_NS}")
EARLY_PHASE=$(echo "$GAME_EARLY" | jq -r '.phase // "null"')
[ "$EARLY_PHASE" = "null" ] && pass "Game not started yet (only 1 of 2 players ready)" || fail "Game started too early — phase: $EARLY_PHASE"

fn_call "$TOKEN_B" "setReady" "$TMP/ready.json" > "$TMP/ready_b_resp.json"
echo "  Player B ready response: $(cat "$TMP/ready_b_resp.json")"
READY_B=$(jq -r '.result.ok // empty' "$TMP/ready_b_resp.json")
[ "$READY_B" = "true" ] && pass "Player B marked ready" || fail "setReady failed for Player B: $(cat "$TMP/ready_b_resp.json")"

info "Waiting 4s for startGame Firestore trigger..."
sleep 4

info "Verifying RTDB game state..."
curl -s "${RTDB}/${LOBBY_ID}.json${RTDB_NS}" > "$TMP/game.json"
echo "  Phase:          $(jq -r '.phase' "$TMP/game.json")"
echo "  Status:         $(jq -r '.status' "$TMP/game.json")"
echo "  Player order:   $(jq -c '.playerOrder' "$TMP/game.json")"
echo "  Current player: $(jq -r '.currentPlayerUid' "$TMP/game.json")"
HAND_A=$(jq -r --arg uid "$UID_A" '.players[$uid].hand | length' "$TMP/game.json")
HAND_B=$(jq -r --arg uid "$UID_B" '.players[$uid].hand | length' "$TMP/game.json")
echo "  Hand sizes:     A=$HAND_A  B=$HAND_B"
PHASE=$(jq -r '.phase' "$TMP/game.json")
[ "$PHASE" = "playing" ] && pass "Game state initialised in RTDB (phase=$PHASE)" || fail "Game not initialised — phase=$PHASE"

# ---------------------------------------------------------------------------
info "submitAction — out-of-turn player should be rejected..."
CURRENT_UID=$(jq -r '.currentPlayerUid' "$TMP/game.json")
if [ "$CURRENT_UID" = "$UID_A" ]; then
  WRONG_TOKEN="$TOKEN_B"; WRONG_LABEL="Player B"
else
  WRONG_TOKEN="$TOKEN_A"; WRONG_LABEL="Player A"
fi
jq -n --arg lid "$LOBBY_ID" '{"data":{"lobbyId":$lid,"action":{"type":"pass"}}}' > "$TMP/wrong_turn.json"
fn_call "$WRONG_TOKEN" "submitAction" "$TMP/wrong_turn.json" > "$TMP/wrong_turn_resp.json"
echo "  Response: $(cat "$TMP/wrong_turn_resp.json")"
WRONG_STATUS=$(jq -r '.error.status // empty' "$TMP/wrong_turn_resp.json")
[ "$WRONG_STATUS" = "FAILED_PRECONDITION" ] && pass "Out-of-turn action rejected ($WRONG_LABEL)" || fail "Expected FAILED_PRECONDITION, got: $(cat "$TMP/wrong_turn_resp.json")"

# ---------------------------------------------------------------------------
info "submitAction — current player plays the 3 of Diamonds to open..."
if [ "$CURRENT_UID" = "$UID_A" ]; then
  CURRENT_TOKEN="$TOKEN_A"; CURRENT_LABEL="Player A"
else
  CURRENT_TOKEN="$TOKEN_B"; CURRENT_LABEL="Player B"
fi
THREE_D=$(jq -r --arg uid "$CURRENT_UID" '.players[$uid].hand[] | select(. == "3D")' "$TMP/game.json")
[ -n "$THREE_D" ] || fail "3D not found in current player's hand — unexpected"

jq -n --arg lid "$LOBBY_ID" '{"data":{"lobbyId":$lid,"action":{"type":"play","cards":["3D"]}}}' > "$TMP/play_3d.json"
fn_call "$CURRENT_TOKEN" "submitAction" "$TMP/play_3d.json" > "$TMP/play_resp.json"
echo "  Response: $(cat "$TMP/play_resp.json")"
PLAY_ERR=$(jq -r '.error.message // empty' "$TMP/play_resp.json")
[ -z "$PLAY_ERR" ] && pass "$CURRENT_LABEL played 3D successfully" || fail "Play 3D failed: $(cat "$TMP/play_resp.json")"

# ---------------------------------------------------------------------------
info "Verifying turn advanced after play..."
curl -s "${RTDB}/${LOBBY_ID}.json${RTDB_NS}" > "$TMP/game2.json"
NEW_CURRENT=$(jq -r '.currentPlayerUid' "$TMP/game2.json")
TRICK_LEN=$(jq -r '.currentTrick | length' "$TMP/game2.json")
echo "  New current player: $NEW_CURRENT"
echo "  Trick length:       $TRICK_LEN"
[ "$NEW_CURRENT" != "$CURRENT_UID" ] && pass "Turn advanced to next player" || fail "Turn did not advance"
[ "$TRICK_LEN" = "1" ] && pass "currentTrick has 1 play" || fail "currentTrick length unexpected: $TRICK_LEN"

# ---------------------------------------------------------------------------
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  All smoke tests passed.${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

rm -rf "$TMP"
