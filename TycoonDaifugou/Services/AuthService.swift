import AuthenticationServices
import CryptoKit
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
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
    var hasAppleProvider: Bool {
        currentUser?.providerData.contains { $0.providerID == "apple.com" } ?? false
    }

    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private var currentNonce: String?
    private var appleAuthCode: String?
    var needsAppleReAuthForDeletion: Bool = false
    private var appleReAuthContinuation: CheckedContinuation<ASAuthorization, Error>?

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
            let authCode = appleCredential.authorizationCode.flatMap {
                String(data: $0, encoding: .utf8)
            }

            if let existingUser = Auth.auth().currentUser {
                // Already signed in with another provider — try to attach Apple to the same account.
                do {
                    try await existingUser.link(with: credential)
                    appleAuthCode = authCode
                    authError = nil
                } catch let linkError as NSError
                    where AuthErrorCode(rawValue: linkError.code) == .credentialAlreadyInUse {
                    // This Apple ID is already tied to a different Firebase account.
                    // Sign in as that account and migrate the current account's data over.
                    let oldUID = existingUser.uid
                    do {
                        try await Auth.auth().signIn(with: credential)
                        appleAuthCode = authCode
                        authError = nil
                        if let newUID = Auth.auth().currentUser?.uid, newUID != oldUID {
                            await migrateFirestoreData(from: oldUID, to: newUID)
                        }
                    } catch {
                        authError = error.localizedDescription
                    }
                } catch {
                    authError = error.localizedDescription
                }
            } else {
                // No existing session — plain sign-in.
                do {
                    try await Auth.auth().signIn(with: credential)
                    appleAuthCode = authCode
                    authError = nil
                } catch {
                    authError = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Firestore account migration

    /// Copies all Firestore data from `oldUID` to `newUID` after a credential-already-in-use
    /// merge, then deletes the source documents. Best-effort — sign-in already succeeded.
    private func migrateFirestoreData(from oldUID: String, to newUID: String) async {
        let db = Firestore.firestore()
        let oldPlayer = db.collection("players").document(oldUID)
        let newPlayer = db.collection("players").document(newUID)
        let oldGames = oldPlayer.collection("games")
        let newGames = newPlayer.collection("games")

        do {
            // Copy the player document only when the destination account has no existing profile.
            let oldDoc = try await oldPlayer.getDocument()
            if oldDoc.exists, let data = oldDoc.data() {
                let newDoc = try await newPlayer.getDocument()
                if !newDoc.exists {
                    try await newPlayer.setData(data)
                }
            }

            // Copy the games subcollection in 400-document batches (Firestore cap is 500).
            let gameDocs = try await oldGames.getDocuments()
            for start in stride(from: 0, to: gameDocs.documents.count, by: 400) {
                let slice = gameDocs.documents[start..<min(start + 400, gameDocs.documents.count)]
                let batch = db.batch()
                for doc in slice {
                    batch.setData(doc.data(), forDocument: newGames.document(doc.documentID))
                }
                try await batch.commit()
            }

            // Delete the old account's data now that it's safely copied.
            let toDelete = try await oldGames.getDocuments()
            for start in stride(from: 0, to: toDelete.documents.count, by: 400) {
                let slice = toDelete.documents[start..<min(start + 400, toDelete.documents.count)]
                let batch = db.batch()
                for doc in slice { batch.deleteDocument(doc.reference) }
                try await batch.commit()
            }
            try await oldPlayer.delete()
        } catch {
            // Log but don't surface — the auth state is already correct.
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

        let hasApple = user.providerData.contains { $0.providerID == "apple.com" }

        do {
            if hasApple {
                let authorization = try await requestFreshAppleAuthorization()
                guard
                    let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                    let nonce = currentNonce,
                    let tokenData = appleCredential.identityToken,
                    let idToken = String(data: tokenData, encoding: .utf8),
                    let codeData = appleCredential.authorizationCode,
                    let authCode = String(data: codeData, encoding: .utf8)
                else {
                    authError = "Could not complete Apple authorization for account deletion."
                    return
                }
                let credential = OAuthProvider.appleCredential(
                    withIDToken: idToken,
                    rawNonce: nonce,
                    fullName: appleCredential.fullName
                )
                try await user.reauthenticate(with: credential)
                try await deleteFirestoreData(for: user.uid)
                try await Auth.auth().revokeToken(withAuthorizationCode: authCode)
            } else {
                try await deleteFirestoreData(for: user.uid)
            }

            try await user.delete()
            // Drive the UI back to SignInView immediately; don't wait for the auth listener's Task dispatch.
            currentUser = nil
            try? Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            appleAuthCode = nil
            authError = nil
        } catch {
            let nsError = error as NSError
            if nsError.domain == ASAuthorizationError.errorDomain,
               nsError.code == ASAuthorizationError.Code.canceled.rawValue {
                return
            }
            authError = Self.friendlyMessage(for: error)
        }
    }

    func clearError() {
        authError = nil
    }

    func provideAppleAuthForDeletion(_ result: Result<ASAuthorization, Error>) {
        needsAppleReAuthForDeletion = false
        guard let continuation = appleReAuthContinuation else { return }
        appleReAuthContinuation = nil
        switch result {
        case .success(let auth): continuation.resume(returning: auth)
        case .failure(let error): continuation.resume(throwing: error)
        }
    }

    // MARK: - Account deletion helpers

    private func deleteFirestoreData(for uid: String) async throws {
        let db = Firestore.firestore()
        let playerRef = db.collection("players").document(uid)
        let gamesRef = playerRef.collection("games")

        let games = try await gamesRef.getDocuments()
        for start in stride(from: 0, to: games.documents.count, by: 400) {
            let slice = games.documents[start..<min(start + 400, games.documents.count)]
            let batch = db.batch()
            for doc in slice { batch.deleteDocument(doc.reference) }
            try await batch.commit()
        }
        try await playerRef.delete()
    }

    private func requestFreshAppleAuthorization() async throws -> ASAuthorization {
        try await withCheckedThrowingContinuation { continuation in
            appleReAuthContinuation = continuation
            needsAppleReAuthForDeletion = true
        }
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

