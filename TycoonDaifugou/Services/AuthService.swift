import AuthenticationServices
import CryptoKit
import FirebaseAuth
import FirebaseCore
import Foundation
import GoogleSignIn
import UIKit

@MainActor
@Observable
final class AuthService {
    var currentUser: User?
    var isLoading: Bool = false
    var authError: String?

    var isAuthenticated: Bool { currentUser != nil }
    var currentUserEmail: String? { currentUser?.email }
    var currentUserDisplayName: String? { currentUser?.displayName }

    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private var currentNonce: String?
    private var appleAuthCode: String?

    init() {
        currentUser = Auth.auth().currentUser
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
            }
        }
    }

    // MARK: - Apple

    /// Build the SHA-256 nonce for an in-flight Sign in with Apple request and remember
    /// the raw nonce so Firebase can verify the returned identity token.
    func makeAppleNonce() -> String {
        let raw = Self.randomNonceString()
        currentNonce = raw
        return Self.sha256(raw)
    }

    func completeAppleSignIn(result: Result<ASAuthorization, Error>) async {
        isLoading = true
        defer { isLoading = false }

        switch result {
        case .failure(let error):
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                authError = error.localizedDescription
            }

        case .success(let authorization):
            guard
                let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let nonce = currentNonce,
                let identityTokenData = appleCredential.identityToken,
                let idTokenString = String(data: identityTokenData, encoding: .utf8)
            else {
                authError = "Apple sign-in returned an unexpected response."
                return
            }

            let credential = OAuthProvider.appleCredential(
                withIDToken: idTokenString,
                rawNonce: nonce,
                fullName: appleCredential.fullName
            )

            do {
                try await Auth.auth().signIn(with: credential)
                authError = nil
                if let codeData = appleCredential.authorizationCode,
                   let code = String(data: codeData, encoding: .utf8) {
                    appleAuthCode = code
                }
            } catch {
                authError = error.localizedDescription
            }
        }
    }

    // MARK: - Google

    func signInWithGoogle() async {
        isLoading = true
        defer { isLoading = false }

        guard let clientID = FirebaseApp.app()?.options.clientID else {
            authError = "Missing Google client ID."
            return
        }

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

        guard let presenter = Self.topViewController() else {
            authError = "Could not present Google sign-in."
            return
        }

        do {
            let signInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)
            guard let idToken = signInResult.user.idToken?.tokenString else {
                authError = "Google sign-in did not return an ID token."
                return
            }
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: signInResult.user.accessToken.tokenString
            )
            try await Auth.auth().signIn(with: credential)
            authError = nil
        } catch {
            // GoogleSignIn surfaces .canceled as an NSError under its own domain.
            let nsError = error as NSError
            if nsError.domain == kGIDSignInErrorDomain,
               nsError.code == GIDSignInError.canceled.rawValue {
                return
            }
            authError = error.localizedDescription
        }
    }

    // MARK: - Email / password

    func signInWithEmail(email: String, password: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
            authError = nil
        } catch {
            authError = Self.friendlyMessage(for: error)
        }
    }

    func createAccount(email: String, password: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await Auth.auth().createUser(withEmail: email, password: password)
            authError = nil
        } catch {
            authError = Self.friendlyMessage(for: error)
        }
    }

    // MARK: - Session

    func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            appleAuthCode = nil
            authError = nil
        } catch {
            authError = error.localizedDescription
        }
    }

    /// Required for App Store compliance — Apple mandates an in-app "delete account" path.
    func deleteAccount() async {
        guard let user = Auth.auth().currentUser else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            // Best-effort Apple token revocation when we still hold a fresh authorization code.
            if let code = appleAuthCode,
               user.providerData.contains(where: { $0.providerID == "apple.com" }) {
                try? await Auth.auth().revokeToken(withAuthorizationCode: code)
            }
            try await user.delete()
            GIDSignIn.sharedInstance.signOut()
            appleAuthCode = nil
            authError = nil
        } catch {
            authError = Self.friendlyMessage(for: error)
        }
    }

    func clearError() {
        authError = nil
    }

    // MARK: - Helpers

    private static func friendlyMessage(for error: Error) -> String {
        let nsError = error as NSError
        guard nsError.domain == AuthErrorDomain,
              let code = AuthErrorCode(rawValue: nsError.code)
        else {
            return error.localizedDescription
        }
        switch code {
        case .invalidEmail: return "That email address looks invalid."
        case .emailAlreadyInUse: return "An account already exists for that email."
        case .weakPassword: return "Password must be at least 6 characters."
        case .wrongPassword, .invalidCredential: return "Email or password is incorrect."
        case .userNotFound: return "No account found for that email."
        case .userDisabled: return "This account has been disabled."
        case .networkError: return "Network error — check your connection and try again."
        case .tooManyRequests: return "Too many attempts. Try again in a moment."
        case .requiresRecentLogin: return "Please sign in again before deleting your account."
        default: return nsError.localizedDescription
        }
    }

    private static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var bytes = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        precondition(status == errSecSuccess, "Unable to generate nonce: \(status)")
        let charset: [Character] = Array(
            "0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._"
        )
        return String(bytes.map { charset[Int($0) % charset.count] })
    }

    private static func sha256(_ input: String) -> String {
        let hashed = SHA256.hash(data: Data(input.utf8))
        return hashed.map { String(format: "%02x", $0) }.joined()
    }

    private static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
            ?? UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        guard var top = scene?.keyWindow?.rootViewController else { return nil }
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }
}
