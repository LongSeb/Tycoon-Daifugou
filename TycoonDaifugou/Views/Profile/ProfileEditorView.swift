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

struct ProfileEditorView: View {
    let onSave: (String, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var emoji: String
    @State private var username: String
    @State private var emojiKeyboardActive = false

    private let maxLength = 20

    init(initialEmoji: String, initialUsername: String, onSave: @escaping (String, String) -> Void) {
        self.onSave = onSave
        _emoji = State(initialValue: initialEmoji)
        _username = State(initialValue: initialUsername)
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
                Button("Done") {
                    onSave(emoji, trimmedUsername)
                    dismiss()
                }
                .font(.tycoonBody.weight(.semibold))
                .foregroundStyle(trimmedUsername.isEmpty ? Color.tycoonPink.opacity(0.4) : Color.tycoonPink)
                .disabled(trimmedUsername.isEmpty)
            }
        }
        .toolbarBackground(Color.tycoonBlack, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: - Avatar Section

    private var avatarSection: some View {
        VStack(spacing: 10) {
            ZStack {
                EmojiTextField(emoji: $emoji, isActive: $emojiKeyboardActive)
                    .frame(width: 0, height: 0)

                Button {
                    emojiKeyboardActive = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.tycoonSurface)
                            .overlay(Circle().strokeBorder(Color.tycoonBorder, lineWidth: 1))
                            .frame(width: 96, height: 96)

                        Text(emoji)
                            .font(.system(size: 48))
                    }
                }
                .buttonStyle(.plain)
            }

            Text("Tap to change avatar")
                .font(.ruleCaption)
                .foregroundStyle(Color.textSecondary)
        }
    }

    // MARK: - Username Section

    private var usernameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("USERNAME")
                .font(.sectionLabel)
                .foregroundStyle(Color.textTertiary)
                .tracking(2)

            TextField("Player", text: $username)
                .font(.tycoonBody)
                .foregroundStyle(Color.textPrimary)
                .tint(Color.tycoonPink)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.tycoonSurface)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.tycoonBorder, lineWidth: 1)
                )
                .onChange(of: username) { _, new in
                    if new.count > maxLength {
                        username = String(new.prefix(maxLength))
                    }
                }

            HStack {
                Spacer()
                Text("\(username.count) / \(maxLength)")
                    .font(.ruleCaption)
                    .foregroundStyle(Color.textTertiary)
            }
        }
    }
}
