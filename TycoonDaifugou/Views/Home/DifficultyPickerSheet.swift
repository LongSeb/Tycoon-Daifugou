import SwiftUI
import TycoonDaifugouKit

/// Bottom sheet shown after tapping Classic mode. The user picks Easy / Medium /
/// Hard to begin a match. Expert is rendered as a locked tier — visible so the
/// progression is discoverable, but not selectable in v1.
struct DifficultyPickerSheet: View {
    @Binding var isPresented: Bool
    var isExpertUnlocked: Bool = false

    /// Called once the user picks a difficulty. The sheet writes the value to
    /// AppStorage before invoking, so callers don't need to thread it through.
    let onSelect: (Difficulty) -> Void

    @AppStorage(AppSettings.Key.difficulty) private var difficultyRaw: String = AppSettings.defaultDifficulty.rawValue

    var body: some View {
        ZStack {
            Color.tycoonBlack.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                card
                Spacer(minLength: 16)
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 6) {
            Text("Choose difficulty")
                .font(.brandTitle)
                .foregroundStyle(Color.textPrimary)
                .tracking(-0.2)

            Text("How sharply CPU opponents play.")
                .font(.tycoonCaption)
                .foregroundStyle(Color.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 28)
        .padding(.bottom, 24)
    }

    // MARK: - Card

    private var card: some View {
        VStack(spacing: 0) {
            ForEach(Array(Difficulty.allCases.enumerated()), id: \.element) { index, difficulty in
                row(for: difficulty)
                if index < Difficulty.allCases.count - 1 {
                    Rectangle()
                        .fill(Color.white.opacity(0.05))
                        .frame(height: 1)
                }
            }
        }
        .background(Color.tycoonSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.tycoonBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func row(for difficulty: Difficulty) -> some View {
        let isLocked = difficulty == .expert ? !isExpertUnlocked : difficulty.isLocked
        Button {
            guard !isLocked else { return }
            difficultyRaw = difficulty.rawValue
            isPresented = false
            onSelect(difficulty)
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(difficulty.displayName)
                        .font(.settingsRowTitle)
                        .foregroundStyle(Color.textPrimary)

                    Text(subtitle(for: difficulty))
                        .font(.settingsRowSubtitle)
                        .foregroundStyle(Color.textTertiary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.textTertiary)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.textTertiary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isLocked)
        .opacity(isLocked ? 0.45 : 1.0)
    }

    // MARK: - Copy

    private func subtitle(for difficulty: Difficulty) -> String {
        switch difficulty {
        case .easy:   return "Casual. Plenty of mistakes."
        case .medium: return "Solid. Holds combos, fights for tempo."
        case .hard:   return "Sharp. Rarely passes up an edge."
        case .expert:
            return isExpertUnlocked
                ? "Maximum challenge. Card counting, 1-ply lookahead."
                : "Reach Level 20 with 10 Hard wins to unlock."
        }
    }
}

#if DEBUG
#Preview("Difficulty Picker") {
    Color.tycoonBlack.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            DifficultyPickerSheet(isPresented: .constant(true), onSelect: { _ in })
        }
}
#endif
