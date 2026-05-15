import SwiftUI

struct OnlineLobbyView: View {
    let lobbyVM: LobbyViewModel
    let onGameStarted: (String) -> Void
    let onDismiss: () -> Void

    @State private var showCodeEntry = false
    @State private var gameStarted = false

    var body: some View {
        @Bindable var vm = lobbyVM

        ZStack {
            Color.tycoonBlack.ignoresSafeArea()

            switch vm.phase {
            case .idle:
                modeSelectionContent(vm: vm)
            case .searching:
                loadingContent
            case .inLobby(let lobbyId, let code):
                WaitingRoomView(
                    lobbyVM: vm,
                    lobbyId: lobbyId,
                    inviteCode: code,
                    onLeave: { vm.leave() }
                )
            case .error(let msg):
                errorContent(message: msg, vm: vm)
            }
        }
        .onChange(of: lobbyVM.currentLobby?.status) { _, newStatus in
            if !gameStarted, newStatus == "in_progress", let id = lobbyVM.lobbyId {
                gameStarted = true
                onGameStarted(id)
            } else if newStatus == "cancelled" {
                // Another player left — reset to mode selection without tearing down the flow
                lobbyVM.cleanupLocally()
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Mode selection

    private func modeSelectionContent(vm: LobbyViewModel) -> some View {
        @Bindable var vm = vm
        return ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                playerCountPicker(vm: vm)
                actionButtons(vm: vm)
                    .padding(.top, 8)
            }
            .padding(.bottom, 40)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button(action: onDismiss) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Back")
                        .font(.tycoonCaption)
                }
                .foregroundStyle(Color.textSecondary)
            }
            .padding(.bottom, 12)

            Text("Play Online")
                .font(.brandTitle)
                .foregroundStyle(Color.textPrimary)
                .tracking(-0.4)

            Text("Match with players worldwide")
                .font(.tycoonCaption)
                .foregroundStyle(Color.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 32)
    }

    private func playerCountPicker(vm: LobbyViewModel) -> some View {
        @Bindable var vm = vm
        return VStack(alignment: .leading, spacing: 12) {
            Text("PLAYERS")
                .font(.tycoonCaption)
                .foregroundStyle(Color.textTertiary)
                .tracking(2.4)
                .padding(.horizontal, 24)

            HStack(spacing: 12) {
                ForEach([2, 3, 4], id: \.self) { count in
                    Button {
                        vm.playerCount = count
                    } label: {
                        Text("\(count)")
                            .font(.cardTitle)
                            .foregroundStyle(vm.playerCount == count ? Color.tycoonBlack : Color.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                vm.playerCount == count
                                    ? Color.cardBlush
                                    : Color.white.opacity(0.06)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
        }
        .padding(.bottom, 28)
    }

    private func actionButtons(vm: LobbyViewModel) -> some View {
        @Bindable var vm = vm
        return VStack(spacing: 12) {
            // Quick Play
            Button {
                Task { await vm.joinQuickPlay() }
            } label: {
                HStack(spacing: 14) {
                    Text("🌐")
                        .font(.system(size: 22))
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Quick Play")
                            .font(.cardTitle)
                            .foregroundStyle(Color.textPrimary)
                        Text("Join or create a random lobby")
                            .font(.tycoonCaption)
                            .foregroundStyle(Color.textTertiary)
                    }

                    Spacer()

                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.textTertiary)
                }
                .padding(20)
                .background(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)

            // Private Room
            Button {
                Task { await vm.createPrivateRoom() }
            } label: {
                HStack(spacing: 14) {
                    Text("🔒")
                        .font(.system(size: 22))
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Create Private Room")
                            .font(.cardTitle)
                            .foregroundStyle(Color.textPrimary)
                        Text("Invite friends with a code")
                            .font(.tycoonCaption)
                            .foregroundStyle(Color.textTertiary)
                    }

                    Spacer()

                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.textTertiary)
                }
                .padding(20)
                .background(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)

            // Join with code
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    TextField("Enter invite code", text: $vm.inviteCodeInput)
                        .font(.cardTitle)
                        .foregroundStyle(Color.textPrimary)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.characters)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    Button {
                        Task { await vm.joinWithCode() }
                    } label: {
                        Text("Join")
                            .font(.cardTitle)
                            .foregroundStyle(Color.tycoonBlack)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            .background(Color.cardBlush)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .disabled(vm.inviteCodeInput.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Loading

    private var loadingContent: some View {
        VStack(spacing: 20) {
            ProgressView()
                .tint(Color.cardBlush)
                .scaleEffect(1.4)
            Text("Searching for a lobby…")
                .font(.tycoonCaption)
                .foregroundStyle(Color.textSecondary)
        }
    }

    // MARK: - Error

    private func errorContent(message: String, vm: LobbyViewModel) -> some View {
        VStack(spacing: 20) {
            Text("⚠️")
                .font(.system(size: 40))
            Text(message)
                .font(.tycoonCaption)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Try Again") { vm.clearError() }
                .font(.cardTitle)
                .foregroundStyle(Color.tycoonBlack)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(Color.cardBlush)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .buttonStyle(.plain)
        }
    }
}
