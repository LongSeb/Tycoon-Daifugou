import SwiftUI
import UIKit

// MARK: - Emoji Keyboard Bridge

struct EmojiTextField: UIViewRepresentable {
    @Binding var emoji: String
    @Binding var isActive: Bool

    // Subclass overrides textInputMode to always open the emoji keyboard
    class EmojiUITextField: UITextField {
        override var textInputMode: UITextInputMode? {
            UITextInputMode.activeInputModes.first { $0.primaryLanguage == "emoji" }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(emoji: $emoji, isActive: $isActive)
    }

    func makeUIView(context: Context) -> EmojiUITextField {
        let tf = EmojiUITextField()
        tf.delegate = context.coordinator
        tf.autocorrectionType = .no
        tf.spellCheckingType = .no
        return tf
    }

    func updateUIView(_ uiView: EmojiUITextField, context: Context) {
        if isActive && !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
        } else if !isActive && uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var emoji: String
        @Binding var isActive: Bool

        init(emoji: Binding<String>, isActive: Binding<Bool>) {
            _emoji = emoji
            _isActive = isActive
        }

        func textField(
            _ textField: UITextField,
            shouldChangeCharactersIn range: NSRange,
            replacementString string: String
        ) -> Bool {
            if let char = string.first {
                emoji = String(char)
            }
            textField.text = ""
            return false
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            isActive = false
        }
    }
}

// MARK: - ProfileEditorView

private enum UsernameCheckStatus { case idle, checking, available, taken, inappropriate }

struct ProfileEditorView: View {
    let onSave: (String, String) async -> Bool
    let currentLevel: Int
    let unlockedBorders: [ProfileBorder]
    let currentBorderID: String?
    let onBorderSelect: (String?) -> Void
    var isUsernameEditable: Bool = true
    var checkAvailability: ((String) async -> Bool)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var emoji: String
    @State private var username: String
    @State private var selectedBorderID: String?
    @State private var emojiKeyboardActive = false
    @State private var showBorderPicker = false
    @State private var showBorderLockedAlert = false
    @State private var usernameStatus: UsernameCheckStatus = .idle
    @State private var isSaving = false
    @State private var checkTask: Task<Void, Never>? = nil

    private let initialUsername: String
    private let maxLength = 20
    private let borderUnlockLevel = 7

    init(
        initialEmoji: String,
        initialUsername: String,
        currentLevel: Int = 1,
        unlockedBorders: [ProfileBorder] = [],
        currentBorderID: String? = nil,
        onBorderSelect: @escaping (String?) -> Void = { _ in },
        isUsernameEditable: Bool = true,
        checkAvailability: ((String) async -> Bool)? = nil,
        onSave: @escaping (String, String) async -> Bool
    ) {
        self.onSave = onSave
        self.currentLevel = currentLevel
        self.unlockedBorders = unlockedBorders
        self.currentBorderID = currentBorderID
        self.onBorderSelect = onBorderSelect
        self.isUsernameEditable = isUsernameEditable
        self.checkAvailability = checkAvailability
        self.initialUsername = initialUsername
        _emoji = State(initialValue: initialEmoji)
        _username = State(initialValue: initialUsername)
        _selectedBorderID = State(initialValue: currentBorderID)
    }

    private var trimmedUsername: String {
        username.trimmingCharacters(in: .whitespaces)
    }

    var body: some View {
        ZStack {
            Color.tycoonBlack.ignoresSafeArea()

            VStack(spacing: 32) {
                avatarSection
                usernameSection
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Edit Profile")
                    .font(.drawerTitle)
                    .foregroundStyle(Color.textPrimary)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
                    .font(.tycoonBody)
                    .foregroundStyle(Color.textSecondary)
            }
            ToolbarItem(placement: .confirmationAction) {
                if isSaving {
                    ProgressView().tint(Color.tycoonMint)
                } else {
                    Button("Done") {
                        isSaving = true
                        let e = emoji; let u = trimmedUsername
                        Task {
                            let success = await onSave(e, u)
                            if success { dismiss() } else { usernameStatus = .taken; isSaving = false }
                        }
                    }
                    .font(.tycoonBody.weight(.semibold))
                    .foregroundStyle(doneEnabled ? Color.tycoonMint : Color.tycoonMint.opacity(0.4))
                    .disabled(!doneEnabled)
                }
            }
        }
        .toolbarBackground(Color.tycoonBlack, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: - Avatar Section

    private var avatarSection: some View {
        VStack(spacing: 12) {
            ZStack {
                EmojiTextField(emoji: $emoji, isActive: $emojiKeyboardActive)
                    .frame(width: 0, height: 0)

                Button {
                    emojiKeyboardActive = true
                } label: {
                    ZStack {
                        if let id = selectedBorderID,
                           let border = unlockedBorders.first(where: { $0.id == id }) {
                            HoloBorderRing(diameter: 106, lineWidth: 5, color: border.color)
                        }

                        Circle()
                            .fill(Color.tycoonSurface)
                            .overlay(Circle().strokeBorder(Color.tycoonBorder, lineWidth: 1))
                            .frame(width: 96, height: 96)

                        Text(emoji)
                            .font(.system(size: 64))
                    }
                }
                .buttonStyle(.plain)
            }

            Text("Tap to change avatar")
                .font(.ruleCaption)
                .foregroundStyle(Color.textSecondary)

            changeBorderButton
        }
    }

    // MARK: - Change Border Button

    private var changeBorderButton: some View {
        let isLocked = currentLevel < borderUnlockLevel

        return Button {
            if isLocked {
                showBorderLockedAlert = true
            } else {
                showBorderPicker = true
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isLocked ? "lock.fill" : "circle.dashed")
                    .font(.system(size: 11, weight: .medium))
                Text("Change Border")
                    .font(.custom("InstrumentSans-Regular", size: 12).weight(.semibold))
                    .tracking(0.2)
            }
            .foregroundStyle(isLocked ? Color.textTertiary : Color.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.tycoonCard)
            .overlay(
                Capsule()
                    .strokeBorder(
                        isLocked ? Color.white.opacity(0.08) : Color.white.opacity(0.12),
                        lineWidth: 1
                    )
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .alert("Border Locked", isPresented: $showBorderLockedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Reach Level \(borderUnlockLevel) to unlock profile borders.")
        }
        .sheet(isPresented: $showBorderPicker) {
            BorderPickerSheet(
                currentLevel: currentLevel,
                unlockedBorders: unlockedBorders,
                currentBorderID: currentBorderID,
                onSelect: { id in
                            selectedBorderID = id
                            onBorderSelect(id)
                        }
            )
        }
    }

    // MARK: - Username Section

    private var doneEnabled: Bool {
        !trimmedUsername.isEmpty
            && usernameStatus != .taken
            && usernameStatus != .inappropriate
            && !isSaving
    }

    private var usernameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("USERNAME")
                    .font(.sectionLabel)
                    .foregroundStyle(Color.textTertiary)
                    .tracking(2)
                if !isUsernameEditable {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.textTertiary)
                }
            }

            ZStack(alignment: .trailing) {
                TextField("TycoonPlayer", text: $username)
                    .font(.tycoonBody)
                    .foregroundStyle(isUsernameEditable ? Color.textPrimary : Color.textTertiary)
                    .tint(Color.tycoonMint)
                    .disabled(!isUsernameEditable)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .padding(.trailing, isUsernameEditable ? 36 : 0)
                    .background(Color.tycoonSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(Color.tycoonBorder, lineWidth: 1)
                    )
                    .onChange(of: username) { _, new in
                        let filtered = String(
                            new.filter { $0.isLetter || $0.isNumber || $0 == "_" || $0 == "-" }
                               .prefix(maxLength)
                        )
                        if filtered != new { username = filtered; return }
                        scheduleAvailabilityCheck(for: new)
                    }

                if isUsernameEditable {
                    availabilityIcon.padding(.trailing, 12)
                }
            }

            if !isUsernameEditable {
                Text("Sign in to change your username.")
                    .font(.ruleCaption)
                    .foregroundStyle(Color.textTertiary)
            } else {
                HStack {
                    switch usernameStatus {
                    case .taken:
                        Text("Username already taken.")
                            .font(.ruleCaption)
                            .foregroundStyle(Color.cardRed)
                    case .inappropriate:
                        Text("Username not allowed.")
                            .font(.ruleCaption)
                            .foregroundStyle(Color.cardRed)
                    default:
                        Text("Letters, numbers, _ and - only.")
                            .font(.ruleCaption)
                            .foregroundStyle(Color.textTertiary)
                    }
                    Spacer()
                    Text("\(username.count) / \(maxLength)")
                        .font(.ruleCaption)
                        .foregroundStyle(Color.textTertiary)
                }
            }
        }
    }

    @ViewBuilder private var availabilityIcon: some View {
        switch usernameStatus {
        case .checking:
            ProgressView().scaleEffect(0.75).tint(Color.textTertiary)
        case .available:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16)).foregroundStyle(Color.tycoonMint)
        case .taken, .inappropriate:
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 16)).foregroundStyle(Color.cardRed)
        case .idle:
            EmptyView()
        }
    }

    private func scheduleAvailabilityCheck(for newUsername: String) {
        checkTask?.cancel()
        checkTask = nil
        let trimmed = newUsername.trimmingCharacters(in: .whitespaces)
        guard isUsernameEditable,
              checkAvailability != nil,
              !trimmed.isEmpty,
              trimmed.lowercased() != initialUsername.lowercased() else {
            usernameStatus = .idle
            return
        }
        usernameStatus = .checking
        checkTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            guard UsernameValidator.isAppropriate(trimmed) else {
                usernameStatus = .inappropriate
                return
            }
            guard let checker = checkAvailability else { return }
            let available = await checker(trimmed)
            usernameStatus = available ? .available : .taken
        }
    }
}
