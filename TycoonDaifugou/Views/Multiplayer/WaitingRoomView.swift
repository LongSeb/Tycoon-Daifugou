import Combine
import SwiftUI

struct WaitingRoomView: View {
    let lobbyVM: LobbyViewModel
    let lobbyId: String
    let inviteCode: String?
    let onLeave: () -> Void

    @State private var elapsedSeconds: Int = 0
    private let clock = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var elapsedString: String {
        String(format: "%d:%02d", elapsedSeconds / 60, elapsedSeconds % 60)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            topBar
            Spacer(minLength: 0)
            playersList
            Spacer()
            bottomActions
        }
        .padding(.bottom, 40)
        .preferredColorScheme(.dark)
        .onReceive(clock) { _ in elapsedSeconds += 1 }
    }

    // MARK: - Top bar

    private var topBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button(action: onLeave) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Leave")
                        .font(.tycoonCaption)
                }
                .foregroundStyle(Color.textSecondary)
            }
            .padding(.bottom, 12)

            Text("Waiting Room")
                .font(.brandTitle)
                .foregroundStyle(Color.textPrimary)
                .tracking(-0.4)

            if let code = inviteCode {
                HStack(spacing: 8) {
                    Text("Code:")
                        .font(.tycoonCaption)
                        .foregroundStyle(Color.textTertiary)
                    Text(code)
                        .font(.cardTitle)
                        .foregroundStyle(Color.cardBlush)
                        .tracking(4)
                }
            }

            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(.system(size: 11))
                Text(elapsedString)
                    .font(.tycoonCaption)
                    .monospacedDigit()
            }
            .foregroundStyle(Color.textTertiary)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 28)
    }

    // MARK: - Players list

    private var playersList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PLAYERS")
                .font(.tycoonCaption)
                .foregroundStyle(Color.textTertiary)
                .tracking(2.4)
                .padding(.horizontal, 24)

            let players = lobbyVM.currentLobby?.players ?? []
            let maxPlayers = lobbyVM.currentLobby?.maxPlayers ?? lobbyVM.playerCount

            VStack(spacing: 8) {
                ForEach(players, id: \.uid) { player in
                    playerRow(player: player)
                }

                // Empty slots
                ForEach(players.count..<maxPlayers, id: \.self) { _ in
                    emptySlotRow
                }
            }
            .padding(.horizontal, 24)
        }
    }

    private func playerRow(player: LobbyPlayer) -> some View {
        let isMe = player.uid == lobbyVM.myUID
        let avatarEmoji = player.emoji ?? "🎴"
        let borderColor = borderColor(for: player.borderID)
        return HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 44, height: 44)
                    .overlay(Text(avatarEmoji).font(.system(size: 22)))

                if let color = borderColor {
                    HoloBorderRing(diameter: 44, lineWidth: 3, color: color)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(player.displayName)
                    .font(.cardTitle)
                    .foregroundStyle(isMe ? Color.cardBlush : Color.textPrimary)
                if let title = player.title {
                    Text(title)
                        .font(.tycoonCaption)
                        .foregroundStyle(borderColor ?? Color.textTertiary)
                        .tracking(0.5)
                }
            }

            Spacer()

            if player.ready {
                Label("Ready", systemImage: "checkmark.circle.fill")
                    .font(.tycoonCaption)
                    .foregroundStyle(Color.cardMint)
                    .labelStyle(.iconOnly)
                    .font(.system(size: 20))
            } else {
                Text("Waiting…")
                    .font(.tycoonCaption)
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.white.opacity(0.07), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var emptySlotRow: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.04))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.textTertiary)
                )

            Text("Waiting for player…")
                .font(.tycoonCaption)
                .foregroundStyle(Color.textTertiary)

            Spacer()
        }
        .padding(16)
        .background(Color.white.opacity(0.02))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.white.opacity(0.04), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Helpers

    private func borderColor(for borderID: String?) -> Color? {
        guard let id = borderID else { return nil }
        for unlock in UnlockRegistry.all {
            if case .profileBorder(let b) = unlock.type, b.id == id { return b.color }
        }
        return nil
    }

    // MARK: - Bottom actions

    private var bottomActions: some View {
        VStack(spacing: 12) {
            if !lobbyVM.isReady {
                Button {
                    Task { await lobbyVM.setReady() }
                } label: {
                    Text("Ready")
                        .font(.cardTitle)
                        .foregroundStyle(Color.tycoonBlack)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.cardBlush)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
            } else {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.cardMint)
                    Text("You're ready — waiting for others")
                        .font(.tycoonCaption)
                        .foregroundStyle(Color.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding(.horizontal, 24)
    }
}
