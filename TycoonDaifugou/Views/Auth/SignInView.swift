import AuthenticationServices
import SwiftUI

struct SignInView: View {
    @Environment(AuthService.self) private var authService
    @State private var showingEmail: Bool = false
    @State private var showingGuestConfirm: Bool = false

    let onContinueAsGuest: () -> Void
    var requiresGuestConfirm: Bool = true

    var body: some View {
        NavigationStack {
            ZStack {
                Color.tycoonBlack.ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    header
                    Spacer(minLength: 0)
                    buttons
                    Spacer().frame(height: 24)
                    if let error = authService.authError {
                        Text(error)
                            .font(.tycoonCaption)
                            .foregroundStyle(Color.cardRed)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .padding(.bottom, 12)
                    }
                    skipButton
                        .padding(.bottom, 24)
                }
                .padding(.horizontal, 32)

                if authService.isLoading {
                    Color.tycoonBlack.opacity(0.5).ignoresSafeArea()
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                }
            }
            .navigationDestination(isPresented: $showingEmail) {
                EmailSignInView()
            }
            .preferredColorScheme(.dark)
            .toolbar(.hidden, for: .navigationBar)
            .alert("Continue without an account?", isPresented: $showingGuestConfirm) {
                Button("Continue as guest", role: .destructive) {
                    onContinueAsGuest()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You won't have access to multiplayer or saved progress across devices. You can sign in later from Settings.")
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            Text("Tycoon")
                .font(.displayL)
                .foregroundStyle(Color.cardCream)
            Text("Sign in to sync your stats and titles\nacross every device.")
                .font(.tycoonBody)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var buttons: some View {
        VStack(spacing: 12) {
            SignInWithAppleButton(.continue) { request in
                request.requestedScopes = [.fullName, .email]
                request.nonce = authService.makeAppleNonce()
            } onCompletion: { result in
                Task { await authService.completeAppleSignIn(result: result) }
            }
            .signInWithAppleButtonStyle(.white)
            .frame(height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .disabled(authService.isLoading)

            Button {
                Task { await authService.signInWithGoogle() }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "g.circle.fill")
                        .font(.system(size: 20, weight: .bold))
                    Text("Continue with Google")
                        .font(.tycoonTitle)
                }
                .foregroundStyle(Color.tycoonBlack)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.cardCream)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(authService.isLoading)

            Button {
                authService.clearError()
                showingEmail = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Continue with Email")
                        .font(.tycoonTitle)
                }
                .foregroundStyle(Color.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.tycoonBorder, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(authService.isLoading)
        }
    }

    private var skipButton: some View {
        Button {
            authService.clearError()
            if requiresGuestConfirm {
                showingGuestConfirm = true
            } else {
                onContinueAsGuest()
            }
        } label: {
            Text("Skip for now")
                .font(.tycoonBody)
                .foregroundStyle(Color.textSecondary)
                .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .disabled(authService.isLoading)
    }
}

#Preview {
    SignInView(onContinueAsGuest: {})
        .environment(AuthService())
}
