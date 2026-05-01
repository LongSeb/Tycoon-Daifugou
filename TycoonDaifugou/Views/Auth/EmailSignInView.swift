import SwiftUI

struct EmailSignInView: View {
    enum Mode { case signIn, createAccount }

    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss

    @State private var mode: Mode = .signIn
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var validationError: String?

    @FocusState private var focused: Field?
    private enum Field { case email, password }

    var body: some View {
        ZStack {
            Color.tycoonBlack.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 0)
                header
                    .padding(.bottom, 32)
                fields
                Spacer().frame(height: 16)
                if let message = displayedError {
                    Text(message)
                        .font(.tycoonCaption)
                        .foregroundStyle(Color.cardRed)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 8)
                }
                primaryButton
                    .padding(.top, 8)
                Spacer().frame(height: 16)
                modeToggle
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 32)
            .padding(.top, 12)

            if authService.isLoading {
                Color.tycoonBlack.opacity(0.5).ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(Color.tycoonBlack, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .preferredColorScheme(.dark)
        .onAppear { authService.clearError() }
        .onChange(of: mode) { _, _ in
            validationError = nil
            authService.clearError()
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text(mode == .signIn ? "Sign In" : "Create Account")
                .font(.displayL)
                .foregroundStyle(Color.cardCream)
            Text(mode == .signIn
                 ? "Welcome back."
                 : "Pick an email and password.")
                .font(.tycoonBody)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var fields: some View {
        VStack(spacing: 12) {
            field(
                placeholder: "Email",
                text: $email,
                isSecure: false,
                contentType: .emailAddress,
                keyboard: .emailAddress,
                field: .email,
                submitLabel: .next,
                onSubmit: { focused = .password }
            )
            field(
                placeholder: "Password",
                text: $password,
                isSecure: true,
                contentType: mode == .signIn ? .password : .newPassword,
                keyboard: .default,
                field: .password,
                submitLabel: .go,
                onSubmit: submit
            )
        }
    }

    private func field(
        placeholder: String,
        text: Binding<String>,
        isSecure: Bool,
        contentType: UITextContentType,
        keyboard: UIKeyboardType,
        field: Field,
        submitLabel: SubmitLabel,
        onSubmit: @escaping () -> Void
    ) -> some View {
        Group {
            if isSecure {
                SecureField("", text: text, prompt: prompt(placeholder))
            } else {
                TextField("", text: text, prompt: prompt(placeholder))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .keyboardType(keyboard)
            }
        }
        .textContentType(contentType)
        .submitLabel(submitLabel)
        .onSubmit(onSubmit)
        .focused($focused, equals: field)
        .font(.tycoonBody)
        .foregroundStyle(Color.textPrimary)
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.tycoonSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.tycoonBorder, lineWidth: 1)
        )
    }

    private func prompt(_ text: String) -> Text {
        Text(text).foregroundStyle(Color.textTertiary)
    }

    private var primaryButton: some View {
        Button(action: submit) {
            Text(mode == .signIn ? "Sign In" : "Create Account")
                .font(.tycoonTitle)
                .foregroundStyle(Color.tycoonBlack)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.cardCream)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(authService.isLoading)
    }

    private var modeToggle: some View {
        HStack(spacing: 6) {
            Text(mode == .signIn ? "New here?" : "Already have an account?")
                .font(.tycoonBody)
                .foregroundStyle(Color.textSecondary)
            Button {
                mode = (mode == .signIn) ? .createAccount : .signIn
            } label: {
                Text(mode == .signIn ? "Create one" : "Sign in")
                    .font(.tycoonBody.weight(.semibold))
                    .foregroundStyle(Color.cardLavender)
            }
            .buttonStyle(.plain)
        }
    }

    private var displayedError: String? {
        validationError ?? authService.authError
    }

    private func submit() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidEmail(trimmedEmail) else {
            validationError = "Enter a valid email address."
            return
        }
        guard password.count >= 6 else {
            validationError = "Password must be at least 6 characters."
            return
        }
        validationError = nil
        focused = nil
        Task {
            switch mode {
            case .signIn:
                await authService.signInWithEmail(email: trimmedEmail, password: password)
            case .createAccount:
                await authService.createAccount(email: trimmedEmail, password: password)
            }
        }
    }

    private func isValidEmail(_ value: String) -> Bool {
        // Lightweight check — Firebase will do the authoritative validation.
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return value.range(of: pattern, options: .regularExpression) != nil
    }
}

#Preview {
    NavigationStack {
        EmailSignInView()
            .environment(AuthService())
    }
}
